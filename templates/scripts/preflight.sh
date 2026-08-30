#!/usr/bin/env bash
#
# preflight.sh — the guard node at the front of the orchestrator loop.
#
# Runs cheap ordered checks BEFORE any dispatch work. On failure: writes a
# ONE-SCREEN status file (not a forensic essay), increments a persisted
# failure counter, and — at policy.max_consecutive_preflight_failures — trips
# the circuit breaker: exit code 2, which the orchestrator treats as "disable
# the scheduled task and tell the human."
#
# Exit codes:
#   0 — all checks green (failure counter reset)
#   1 — a check failed; counter incremented, below breaker threshold
#   2 — breaker tripped: counter >= threshold. STOP SCHEDULING. ALERT A HUMAN.
#
# Optional hook: set NOTIFY_CMD (env or graph.yaml is fine to wrap this) to a
# command that receives the one-screen report on stdin on every failure.
#
set -uo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || {
  echo "preflight: not inside a git repo" >&2; exit 1; }
GRAPH="$REPO_ROOT/orchestration/graph.yaml"
RUNTIME="$REPO_ROOT/orchestration/.runtime"
COUNTER_FILE="$RUNTIME/preflight-failures"
STATUS_FILE="$RUNTIME/preflight-status.txt"
mkdir -p "$RUNTIME"

threshold=2
if command -v yq >/dev/null 2>&1 && [ -f "$GRAPH" ]; then
  t="$(yq -r '.policy.max_consecutive_preflight_failures // 2' "$GRAPH" 2>/dev/null)"
  [[ "$t" =~ ^[0-9]+$ ]] && threshold="$t"
fi

failures=()
check() { # check <label> <cmd...>
  local label="$1"; shift
  if "$@" >/dev/null 2>&1; then
    echo "  ok    $label"
  else
    echo "  FAIL  $label"
    failures+=("$label")
  fi
}

echo "preflight @ $(date -u +%Y-%m-%dT%H:%M:%SZ)"

# 1. Required CLIs first — everything below depends on them.
check "git present"  command -v git
check "gh present"   command -v gh
check "jq present"   command -v jq
check "yq present"   command -v yq
check "claude present" command -v claude

# 2. Can we actually push? (The single check whose absence once cost eight
#    consecutive wasted scheduled runs.)
check "origin push reachable (dry-run)" git push --dry-run origin HEAD

# 3. GitHub API auth.
check "gh auth (api /user)" gh api user

# 4. PM-tool reachability. Project-specific: the scaffold fills this in when a
#    PM tool is wired (e.g. a cheap authenticated read via the pm-skill's API
#    path). Files-only projects check the backlog file exists.
# {{PM_TOOL_REACHABILITY_CHECK}}
[ -f "$REPO_ROOT/pm/backlog.md" ] && echo "  ok    pm/backlog.md present" || {
  echo "  FAIL  pm/backlog.md present"; failures+=("pm/backlog.md present"); }

# 5. Policy graph parses.
check "orchestration/graph.yaml parses" yq -e '.version' "$GRAPH"

# 6. Worktree + lock hygiene.
if git worktree list --porcelain | grep -q '^prunable'; then
  echo "  FAIL  no prunable worktree registrations (run: git worktree prune)"
  failures+=("prunable worktrees present")
else
  echo "  ok    no prunable worktree registrations"
fi
stale_locks="$(find "$RUNTIME/locks" -name 'holder-*' -mmin +180 2>/dev/null | head -5)"
if [ -n "$stale_locks" ]; then
  echo "  FAIL  stale resource locks >3h old (with-resource-lock.sh reclaims on next acquire)"
  failures+=("stale resource locks")
else
  echo "  ok    no stale resource locks"
fi

# ---------------------------------------------------------------------------
if [ "${#failures[@]}" -eq 0 ]; then
  rm -f "$COUNTER_FILE" "$STATUS_FILE"
  echo "preflight: PASS"
  exit 0
fi

count=$(( $(cat "$COUNTER_FILE" 2>/dev/null || echo 0) + 1 ))
echo "$count" > "$COUNTER_FILE"

{ # The one-screen report. Resist the urge to make this longer — the failure
  # mode this file exists to prevent is "beautiful reports about being unable
  # to work."
  echo "PREFLIGHT FAILED — run $count of $threshold before circuit breaker"
  echo "when:  $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "repo:  $REPO_ROOT"
  echo "failed checks:"
  for f in "${failures[@]}"; do echo "  - $f"; done
  echo
  echo "No dispatch was attempted. Fix the checks above, then rerun."
  if [ "$count" -ge "$threshold" ]; then
    echo
    echo "CIRCUIT BREAKER TRIPPED ($count consecutive failures)."
    echo "DISABLE THE SCHEDULED ORCHESTRATOR TASK until a human clears this."
    echo "Reset after fixing: rm orchestration/.runtime/preflight-failures"
  fi
} | tee "$STATUS_FILE"

if [ -n "${NOTIFY_CMD:-}" ]; then
  "$NOTIFY_CMD" < "$STATUS_FILE" || echo "preflight: NOTIFY_CMD failed (non-fatal)" >&2
fi

[ "$count" -ge "$threshold" ] && exit 2
exit 1
