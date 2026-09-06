#!/usr/bin/env bash
#
# graph-sync.sh — regenerate orchestration/state.json (the derived graph) and
# render the generated views. Run by the orchestrator's `sync` node every
# cycle; safe to run standalone at any time.
#
# Inputs:
#   orchestration/graph.yaml          — policy (personas, weights, invariants config)
#   orchestration/tickets.json        — ticket extract: [{id, title, persona,
#                                       milestone, status, blocked_by[], blocks[],
#                                       epic?, created_at?}]
#       * PM-tool projects: the orchestrator session produces this via the
#         project's pm-<tool> skill before calling graph-sync (LLM-driven
#         extraction, deterministic computation — this script never talks to
#         the PM tool itself).
#       * Files-only projects: produce it from pm/backlog.md the same way.
#   gh (GitHub CLI)                   — open-PR overlay + changed-file collision data
#
# Outputs:
#   orchestration/state.json          — committed each cycle; the diff between
#                                       runs is the execution record
#   pm/delivery-status.md             — only when --render-delivery is passed
#                                       (PM-tool projects)
#   generated blocks                  — any tracked file containing
#                                       <!-- GENERATED FROM orchestration/graph.yaml -->
#                                       markers gets its persona table re-rendered
#
# Deliberately deterministic: same inputs → same state.json. The CI drift
# check for delivery-status re-renders FROM THE COMMITTED state.json — it must
# never re-query the live PM tool (live state moves between commit and CI run,
# which makes the gate flaky by design).
#
set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"
GRAPH="orchestration/graph.yaml"
TICKETS="orchestration/tickets.json"
STATE="orchestration/state.json"

for tool in yq jq gh; do
  command -v "$tool" >/dev/null 2>&1 || { echo "graph-sync: $tool required" >&2; exit 1; }
done
[ -f "$GRAPH" ]   || { echo "graph-sync: $GRAPH missing" >&2; exit 1; }
[ -f "$TICKETS" ] || { echo "graph-sync: $TICKETS missing — run the ticket extractor first (see header)" >&2; exit 1; }
jq -e 'type == "array"' "$TICKETS" >/dev/null || { echo "graph-sync: $TICKETS is not a JSON array" >&2; exit 1; }

render_delivery=false
render_from_state=false
for arg in "$@"; do
  case "$arg" in
    --render-delivery) render_delivery=true ;;
    --render-from-committed-state) render_delivery=true; render_from_state=true ;;
    *) echo "graph-sync: unknown flag $arg" >&2; exit 1 ;;
  esac
done

# ---------------------------------------------------------------------------
# 1. Compute state.json (skipped in --render-from-committed-state mode).
# ---------------------------------------------------------------------------
if ! $render_from_state; then
  weights_json="$(yq -o=json '.policy.selection_weights // {}' "$GRAPH")"
  personas_json="$(yq -o=json '.personas // {}' "$GRAPH")"

  # Open-PR overlay: number, branch, author-persona, changed files. The
  # branch prefix resolves to a persona slug via each persona's optional
  # `branch_prefix` field (default: the slug) — short-prefix repos
  # (backend/ → backend-engineer) would otherwise get empty per-persona
  # PR counts and no collision flags.
  prefix_map="$(yq -o=json '.personas | to_entries | map({key: (.value.branch_prefix // .key), value: .key}) | from_entries' "$GRAPH")"
  prs_json="$(gh pr list --state open --json number,headRefName,files,title \
    --jq '[.[] | {number, branch: .headRefName,
                  prefix: (.headRefName | split("/")[0]),
                  files: [.files[].path], title}]' 2>/dev/null || echo '[]')"
  prs_json="$(jq --argjson pm "$prefix_map" 'map(.persona = ($pm[.prefix] // .prefix))' <<<"$prs_json")"

  jq -n \
    --slurpfile tickets "$TICKETS" \
    --argjson prs "$prs_json" \
    --argjson weights "$weights_json" \
    --argjson personas "$personas_json" \
    --arg now "$(date -u +%Y-%m-%dT%H:%M:%SZ)" '
    ($tickets[0]) as $t
    | (["done","completed","canceled","cancelled","merged"]) as $closed
    | ($t | map(select(.status as $s | $closed | index($s | ascii_downcase) | not))) as $open
    | ($open | map(.id)) as $open_ids
    # in-flight file overlap per persona domain is approximated by PR branch prefix;
    # collision_risk = count of open PRs whose files intersect the ticket persona domains
    | {
        generated_at: $now,
        sources: { tickets: "orchestration/tickets.json", github: "gh pr list" },
        tickets: ($t | map(
          (.persona // "") as $tp
        | . + {
          open_blockers: [(.blocked_by // [])[] | select(. as $b | $open_ids | index($b))],
        } | . + {
          frontier: ((.status | ascii_downcase | IN("backlog","not started","todo","planned")) and (.open_blockers | length == 0)),
          hold_reason: (if (.open_blockers | length) > 0
                        then "blocked_by " + (.open_blockers | join(", "))
                        else null end),
          collision_with: [$prs[] | select(.persona == $tp) | .number],
        } | . + {
          score: (if .frontier then
                    (($weights.milestone_priority // 0) * (.milestone_priority // 1))
                  + (($weights.unblocks_count // 0) * ((.blocks // []) | length))
                  + (($weights.staleness_days // 0) * (.staleness_days // 0))
                  + (($weights.collision_risk // 0) * ((.collision_with | length)))
                  else null end)
        })),
        personas: ($personas | to_entries | map(.key as $k | {
          key: $k,
          value: { open_prs: ([$prs[] | select(.persona == $k)] | length) }
        }) | from_entries),
        open_prs: $prs,
        invariants: []
      }' > "$STATE.tmp"

  # -------------------------------------------------------------------------
  # 2. Invariant checks — consistency rules that used to be "chores a human
  #    remembers to invoke." Each failure is a machine-readable entry; the
  #    orchestrator's plan node turns doc-only ones into a reconciliation PR
  #    and judgment ones into tickets.
  # -------------------------------------------------------------------------
  inv=()
  # Every persona declared in graph.yaml has a persona file.
  while IFS= read -r pfile; do
    [ -f "$pfile" ] || inv+=("{\"check\":\"persona_file_exists\",\"status\":\"fail\",\"detail\":\"$pfile missing\"}")
  done < <(yq -r '.personas[].file' "$GRAPH")
  # Every agents/*.md appears in graph.yaml.
  for f in agents/*.md; do
    [ "$(basename "$f")" = "README.md" ] && continue
    yq -e ".personas[] | select(.file == \"$f\")" "$GRAPH" >/dev/null 2>&1 \
      || inv+=("{\"check\":\"persona_declared_in_graph\",\"status\":\"fail\",\"detail\":\"$f not declared in graph.yaml\"}")
  done
  # No uncommitted dispatch logs.
  undisp="$(git status --porcelain docs/dispatch-logs/ | head -3 || true)"
  [ -z "$undisp" ] || inv+=("{\"check\":\"dispatch_logs_committed\",\"status\":\"fail\",\"detail\":\"uncommitted dispatch logs present\"}")
  # No prunable worktrees.
  git worktree list --porcelain | grep -q '^prunable' \
    && inv+=("{\"check\":\"no_orphan_worktrees\",\"status\":\"fail\",\"detail\":\"run git worktree prune\"}") || true

  inv_json="$(printf '%s\n' "${inv[@]:-}" | jq -s 'map(select(. != null and . != ""))' 2>/dev/null || echo '[]')"
  jq --argjson inv "$inv_json" '.invariants = $inv' "$STATE.tmp" > "$STATE"
  rm -f "$STATE.tmp"
  echo "graph-sync: wrote $STATE ($(jq '.tickets | length' "$STATE") tickets, frontier: $(jq '[.tickets[] | select(.frontier)] | length' "$STATE"), invariant failures: $(jq '.invariants | length' "$STATE"))"
fi

# ---------------------------------------------------------------------------
# 3. Render pm/delivery-status.md from state.json (PM-tool projects).
# ---------------------------------------------------------------------------
if $render_delivery; then
  {
    echo "<!-- GENERATED BY graph-sync — DO NOT EDIT. Regenerate: scripts/graph-sync.sh --render-delivery -->"
    echo "# Delivery status"
    echo
    echo "**Synced:** $(jq -r '.generated_at' "$STATE") · **Source:** the PM tool via \`orchestration/state.json\`"
    echo
    echo "| Ticket | Title | Persona | Milestone | Status | Frontier | Hold reason |"
    echo "|---|---|---|---|---|---|---|"
    jq -r '.tickets[] | "| \(.id) | \(.title // "—") | \(.persona // "—") | \(.milestone // "—") | \(.status) | \(if .frontier then "yes" else "" end) | \(.hold_reason // "") |"' "$STATE"
    echo
    echo "## Milestone roll-up"
    echo
    echo "| Milestone | Open | Total |"
    echo "|---|---|---|"
    jq -r '[.tickets[] | {m: (.milestone // "—"), open: (if (.status | ascii_downcase | IN("done","completed","merged","canceled","cancelled")) then 0 else 1 end)}]
           | group_by(.m) | .[] | "| \(.[0].m) | \(map(.open) | add) | \(length) |"' "$STATE"
  } > pm/delivery-status.md
  echo "graph-sync: rendered pm/delivery-status.md"
fi

# ---------------------------------------------------------------------------
# 4. Re-render generated persona-table blocks in place.
# ---------------------------------------------------------------------------
MARK_OPEN='<!-- GENERATED FROM orchestration/graph.yaml -->'
MARK_CLOSE='<!-- /GENERATED -->'
table="$(yq -r '.personas | to_entries[] | "| \(.key) | `\(.value.file)` | \((.value.file_domains // []) | join(", ")) |"' "$GRAPH")"
block="$MARK_OPEN
| Persona | File | File domains |
|---|---|---|
$table
$MARK_CLOSE"
grep -rl --include='*.md' -F "$MARK_OPEN" . 2>/dev/null | grep -v '^./.worktrees' | while IFS= read -r f; do
  awk -v open="$MARK_OPEN" -v close_m="$MARK_CLOSE" -v repl="$block" '
    index($0, open) { print repl; skipping = 1; next }
    index($0, close_m) { skipping = 0; next }
    !skipping { print }
  ' "$f" > "$f.tmp" && mv "$f.tmp" "$f"
  echo "graph-sync: re-rendered generated block in $f"
done
