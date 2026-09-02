#!/usr/bin/env bash
#
# migrate-to-graph-orchestration.sh
#
# Standalone migration for projects scaffolded before v1.3: installs the
# graph-orchestration layer (orchestration/graph.yaml + schemas + guard
# scripts, QA merge-gate section, AGENTS.md autonomy table).
#
# Same logic as Step 1.5 detectors D13–D19 in the scaffold's SKILL.md, but
# packaged as a one-shot bash invocation — useful for users who want the
# v1.3 upgrade without re-running the full discovery interview.
#
# Two detectors are deliberately NOT fully automated, because they need
# judgment a bash script must not exercise alone:
#   D13 — graph.yaml is generated as a SKELETON (personas enumerated from
#         agents/*.md, file_domains left TODO) and the script pauses for
#         you to acknowledge the OWNERSHIP AUDIT: reconcile persona-file
#         claims against your PM tool's ownership labels BEFORE trusting
#         anything generated from the map. Never publish a wrong owner
#         with a machine's authority.
#   D14 — the operator-shaped orchestrator is staged NEXT TO your persona
#         (agents/orchestrator.md.graph-operator), never over it. You (or
#         a scaffold re-run) merge project-specific content into
#         graph.yaml and swap the files.
#   D18 — (PM-tool projects) splitting a hand-maintained backlog into
#         generated delivery-status + human conventions is printed as a
#         manual step, not performed.
#
# Usage:
#   cd <your-scaffolded-project>
#   bash <path-to-scaffold>/scripts/migrate-to-graph-orchestration.sh
#
# Flags:
#   --no-pr     Stage changes in a worktree and commit, but don't push or
#               open a PR. Useful for offline runs or local-only review.
#   --dry-run   Print what would change without modifying any files.
#   -h|--help   This help.
#

set -euo pipefail

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCAFFOLD_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
T_ORCH="$SCAFFOLD_ROOT/templates/orchestration"
T_SCRIPTS="$SCAFFOLD_ROOT/templates/scripts"
T_AGENTS="$SCAFFOLD_ROOT/templates/agents"
T_AGENTSMD="$SCAFFOLD_ROOT/templates/AGENTS.md"

for p in "$T_ORCH/graph.yaml" "$T_SCRIPTS/preflight.sh" "$T_AGENTS/qa-engineer.md" "$T_AGENTSMD"; do
  [ -f "$p" ] || { echo "error: scaffold template missing at $p — is the scaffold checkout up to date (v1.3+)?" >&2; exit 1; }
done

# ---------------------------------------------------------------------------
# Flags
# ---------------------------------------------------------------------------

no_pr=false
dry_run=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-pr)   no_pr=true;   shift ;;
    --dry-run) dry_run=true; shift ;;
    -h|--help) sed -n '2,40p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "unknown flag: $1 (see --help)" >&2; exit 1 ;;
  esac
done

git rev-parse --show-toplevel >/dev/null 2>&1 || { echo "error: run from inside your scaffolded project" >&2; exit 1; }
PROJECT_ROOT="$(git rev-parse --show-toplevel)"
cd "$PROJECT_ROOT"
[ -d agents ] || { echo "error: no agents/ directory — is this a scaffolded project?" >&2; exit 1; }

# ---------------------------------------------------------------------------
# Phase 0 — pipeline health. None of the graph machinery matters on a dead
# pipeline; the historical motivating failure was eight scheduled runs
# against broken credentials.
# ---------------------------------------------------------------------------

echo "Phase 0 — pipeline health"
p0_warn=false
git push --dry-run origin HEAD >/dev/null 2>&1 && echo "  ok    origin push reachable" \
  || { echo "  WARN  cannot push to origin (credentials?)"; p0_warn=true; }
gh api user >/dev/null 2>&1 && echo "  ok    gh authenticated" \
  || { echo "  WARN  gh not authenticated"; p0_warn=true; }
git worktree list --porcelain | grep -q '^prunable' \
  && { echo "  WARN  prunable worktree registrations (git worktree prune)"; p0_warn=true; } \
  || echo "  ok    no orphan worktrees"
[ -n "$(git status --porcelain docs/dispatch-logs/ 2>/dev/null)" ] \
  && { echo "  WARN  uncommitted dispatch logs"; p0_warn=true; } \
  || echo "  ok    no uncommitted dispatch logs"
if $p0_warn && ! $dry_run; then
  printf "Phase 0 warnings above. Continue anyway? [y/N] "
  read -r ans; [[ "$ans" =~ ^[Yy]$ ]] || { echo "Aborting — fix the pipeline first."; exit 1; }
fi

# ---------------------------------------------------------------------------
# Detect drift (idempotent — all-current exits with no migration needed)
# ---------------------------------------------------------------------------

declare -a PLAN=()
d13=false; d14=false; d15=false; d16=false; d17=false; d19=false
[ -f orchestration/graph.yaml ]        || { d13=true; PLAN+=("D13: declare orchestration/graph.yaml (skeleton) + schemas + README + .gitignore entry"); }
grep -q 'preflight' agents/orchestrator.md 2>/dev/null \
                                       || { d14=true; PLAN+=("D14: stage operator-shaped orchestrator at agents/orchestrator.md.graph-operator (manual swap)"); }
[ -x scripts/preflight.sh ]            || { d15=true; PLAN+=("D15: install preflight / with-resource-lock / graph-sync + scripts README"); }
[ -x scripts/policy-lint.sh ]          || { d16=true; PLAN+=("D16: install policy-lint.sh (fill {{tokens}} after — unfilled checks self-skip)"); }
if [ ! -x scripts/qa-merge.sh ] || ! grep -q 'qa-merge' agents/qa-engineer.md 2>/dev/null; then
  d17=true; PLAN+=("D17: install qa-merge.sh + qa-verdict schema; append QA merge-authority section; probe merge_gate_mode")
fi
grep -q 'Autonomy table' AGENTS.md 2>/dev/null \
                                       || { d19=true; PLAN+=("D19: insert the Autonomy table into AGENTS.md"); }
# D18 is detect-and-print only:
d18_note=""
if ls skills/pm-*-*/SKILL.md >/dev/null 2>&1 && [ -f pm/backlog.md ] && grep -qE '^\|.*(Status|status)' pm/backlog.md; then
  d18_note="D18: a PM tool is wired but pm/backlog.md still hand-maintains status tables — after this migration, run 'scripts/graph-sync.sh --render-delivery' and trim pm/backlog.md to human-owned conventions (manual; see SKILL.md Step 1.5 D18)."
fi

if [ "${#PLAN[@]}" -eq 0 ]; then
  echo "Nothing to migrate. Exiting."
  [ -n "$d18_note" ] && echo "note: $d18_note"
  exit 0
fi

echo
echo "Migration plan:"
for item in "${PLAN[@]}"; do echo "  - $item"; done
[ -n "$d18_note" ] && echo "  - (manual) $d18_note"

if $d13 && ! $dry_run; then
  cat <<'AUDIT'

  ⚠ D13 OWNERSHIP AUDIT (required before you trust the generated map):
    The graph.yaml skeleton enumerates personas from agents/*.md. Before
    generating anything FROM that map (role tables, PM-tool labels,
    delivery views), reconcile each persona's ownership claims against
    your PM tool's labels and fix whichever source is wrong. Field
    lesson: a five-way ownership disagreement was faithfully published
    by generation until audited.
AUDIT
  printf "  Acknowledge the audit requirement and continue? [y/N] "
  read -r ans; [[ "$ans" =~ ^[Yy]$ ]] || { echo "Aborting."; exit 1; }
fi

$dry_run && { echo; echo "--dry-run: no files changed."; exit 0; }

# ---------------------------------------------------------------------------
# Apply in a worktree, one commit per detector
# ---------------------------------------------------------------------------

branch="migrate/graph-orchestration"
wt=".worktrees/migrate-graph-orchestration"
git worktree remove "$wt" 2>/dev/null || true
git worktree add "$wt" -b "$branch" >/dev/null 2>&1 || git worktree add "$wt" "$branch" >/dev/null
cd "$wt"

commit() { git add -A && git commit -q -m "$1" && echo "  committed: $1"; }

if $d13; then
  mkdir -p orchestration/schemas
  cp "$T_ORCH/README.md" orchestration/README.md
  cp "$T_ORCH/schemas/dispatch-result.json" "$T_ORCH/schemas/qa-verdict.json" orchestration/schemas/
  {
    sed -n '1,/^personas:/p' "$T_ORCH/graph.yaml"
    for f in agents/*.md; do
      slug="$(basename "$f" .md)"; [ "$slug" = "README" ] && continue
      echo "  $slug:"
      echo "    file: agents/$slug.md"
      echo "    file_domains: []            # TODO: fill from your codebase layout"
      case "$slug" in
        qa-engineer) echo "    role: evaluator" ;;
        product-designer) echo "    dispatch: interactive-only" ;;
      esac
    done
    sed -n '/^resources:/,$p' "$T_ORCH/graph.yaml"
  } > orchestration/graph.yaml
  grep -qx 'orchestration/.runtime/' .gitignore 2>/dev/null || echo 'orchestration/.runtime/' >> .gitignore
  commit "D13: declare orchestration/graph.yaml skeleton + schemas (ownership audit acknowledged)"
fi

if $d14; then
  sed -e "s/{{PROJECT_NAME}}/$(basename "$PROJECT_ROOT")/g" \
      "$T_AGENTS/orchestrator.md" > agents/orchestrator.md.graph-operator
  commit "D14: stage operator-shaped orchestrator for manual review/swap"
fi

if $d15; then
  mkdir -p scripts
  cp "$T_SCRIPTS/preflight.sh" "$T_SCRIPTS/with-resource-lock.sh" "$T_SCRIPTS/graph-sync.sh" scripts/
  cp "$T_SCRIPTS/README.md" scripts/README-orchestration.md
  chmod +x scripts/preflight.sh scripts/with-resource-lock.sh scripts/graph-sync.sh
  commit "D15: install preflight + resource-lock + graph-sync guard scripts"
fi

if $d16; then
  mkdir -p scripts
  cp "$T_SCRIPTS/policy-lint.sh" scripts/policy-lint.sh
  chmod +x scripts/policy-lint.sh
  commit "D16: install policy-lint.sh (fill the {{tokens}} at the top; unfilled checks self-skip)"
fi

if $d17; then
  mkdir -p scripts orchestration/schemas
  cp "$T_SCRIPTS/qa-merge.sh" scripts/qa-merge.sh && chmod +x scripts/qa-merge.sh
  [ -f orchestration/schemas/qa-verdict.json ] || cp "$T_ORCH/schemas/qa-verdict.json" orchestration/schemas/
  if [ -f agents/qa-engineer.md ] && ! grep -q 'Merge authority' agents/qa-engineer.md; then
    awk '/^## Merge authority/{grab=1} grab && /^## Working patterns/{exit} grab{print}' \
      "$T_AGENTS/qa-engineer.md" >> agents/qa-engineer.md
  fi
  # merge_gate_mode probe
  mode="merge-command"
  default_branch="$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null | sed 's|origin/||' || echo main)"
  if out="$(gh api "repos/{owner}/{repo}/branches/$default_branch/protection" 2>&1)"; then
    mode="github-native"
  elif ! grep -q "Upgrade to GitHub Pro" <<<"$out"; then
    # 404 = protection simply not configured, but configurable → native available
    grep -q "Branch not protected\|Not Found" <<<"$out" && mode="github-native"
  fi
  [ -f orchestration/graph.yaml ] && sed -i.bak "s/{{MERGE_GATE_MODE}}/$mode/" orchestration/graph.yaml && rm -f orchestration/graph.yaml.bak
  commit "D17: install qa-merge gate + verdict schema; merge_gate_mode=$mode"
fi

if $d19; then
  if [ -f AGENTS.md ]; then
    awk '/^## Autonomy table/{grab=1} grab && /^## Project Structure/{exit} grab{print}' "$T_AGENTSMD" > /tmp/autonomy.$$
    if grep -q '^## Project Structure' AGENTS.md; then
      awk -v ins="/tmp/autonomy.$$" '
        /^## Project Structure/ && !done { while ((getline l < ins) > 0) print l; done=1 }
        { print }' AGENTS.md > AGENTS.md.tmp && mv AGENTS.md.tmp AGENTS.md
    else
      cat /tmp/autonomy.$$ >> AGENTS.md
    fi
    rm -f /tmp/autonomy.$$
    commit "D19: insert Autonomy table into AGENTS.md"
  else
    echo "  skip D19: no AGENTS.md (run the scaffold's Step 1.5 D1 first)"
  fi
fi

# ---------------------------------------------------------------------------
# Push + PR
# ---------------------------------------------------------------------------

echo
[ -n "$d18_note" ] && echo "manual follow-up: $d18_note"
if $no_pr; then
  echo "--no-pr: branch '$branch' committed in $wt — review and push yourself."
  exit 0
fi

git push -u origin "$branch"
if ! command -v gh >/dev/null 2>&1; then
  echo "gh CLI not found — branch is pushed, please open the PR manually." >&2
  exit 0
fi
body_file="$(mktemp)"
cat > "$body_file" <<'EOF'
## Summary

Standalone migration installing the scaffold v1.3 graph-orchestration layer, via `scripts/migrate-to-graph-orchestration.sh` (same logic as SKILL.md Step 1.5 detectors D13-D19). One commit per detector - review each independently.

Manual follow-ups this PR deliberately leaves to you:
- Fill `file_domains` (and any `resources:`/`gates:`) in `orchestration/graph.yaml`, completing the ownership audit against your PM tool.
- Fill the `{{tokens}}` at the top of `scripts/policy-lint.sh` and wire it into CI.
EOF
[ -f agents/orchestrator.md.graph-operator ] && \
  echo '- Review `agents/orchestrator.md.graph-operator` and swap it in (moving project-specific role-map content into `graph.yaml` first).' >> "$body_file"
[ -n "$d18_note" ] && echo "- $d18_note" >> "$body_file"
cat >> "$body_file" <<'EOF'

## Test plan

- [ ] `bash scripts/preflight.sh` runs (needs `jq` + `yq`)
- [ ] `scripts/qa-merge.sh` refuses a PR without a verdict artifact
- [ ] Re-running the migration script reports "Nothing to migrate. Exiting."
EOF
gh pr create \
  --title "migrate: install graph-orchestration layer (D13-D19)" \
  --body-file "$body_file" \
  || { echo "gh pr create failed — branch pushed; open the PR manually." >&2; rm -f "$body_file"; exit 1; }
rm -f "$body_file"

echo
echo "Migration complete."
