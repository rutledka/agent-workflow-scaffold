#!/usr/bin/env bash
#
# with-resource-lock.sh — capacity-N semaphore for physical shared resources.
#
# A resource declared in orchestration/graph.yaml `resources:` (a shared local
# database, a device farm, a rate-limited API) is enforced HERE, in code —
# not by two concurrent sessions each remembering to read a Markdown
# paragraph and voluntarily yielding.
#
# Usage:
#   scripts/with-resource-lock.sh <resource-name> -- <command> [args...]
#   scripts/with-resource-lock.sh <resource-name> --status
#
# Exit codes:
#   0   — command ran (its own exit code is propagated when non-zero)
#   75  — resource at capacity (EX_TEMPFAIL). The caller records a
#         hold_reason and moves on; it does NOT busy-wait.
#
# Locks live under $(git rev-parse --git-common-dir)/orchestration-locks/ —
# shared across every worktree of this clone and every session on this
# machine ("scope: global" in graph.yaml). Known limitation: a second clone
# of the repo has its own lock dir; one clone per machine is the assumption.
#
set -uo pipefail

die() { echo "with-resource-lock: $*" >&2; exit 1; }

RESOURCE="${1:-}"; [ -n "$RESOURCE" ] || die "usage: with-resource-lock.sh <resource> -- <cmd...>"
shift

REPO_ROOT="$(git rev-parse --show-toplevel)" || die "not in a git repo"
GRAPH="$REPO_ROOT/orchestration/graph.yaml"
command -v yq >/dev/null 2>&1 || die "yq is required (checked by preflight)"

capacity="$(yq -r ".resources.\"$RESOURCE\".capacity // \"\"" "$GRAPH")"
[ -n "$capacity" ] || die "resource '$RESOURCE' not declared in orchestration/graph.yaml"
ttl_min="$(yq -r ".resources.\"$RESOURCE\".stale_lock_ttl_min // 90" "$GRAPH")"

LOCK_DIR="$(git rev-parse --git-common-dir)/orchestration-locks/$RESOURCE"
mkdir -p "$LOCK_DIR"

# Reclaim stale slots: holder files older than the TTL, or whose PID is gone.
for holder in "$LOCK_DIR"/holder-*; do
  [ -e "$holder" ] || continue
  pid="$(sed -n '1p' "$holder" 2>/dev/null)"
  if [ -n "$(find "$holder" -mmin +"$ttl_min" 2>/dev/null)" ]; then
    echo "with-resource-lock: reclaiming stale lock $(basename "$holder") (>${ttl_min}min)" >&2
    rm -f "$holder"
  elif [[ "$pid" =~ ^[0-9]+$ ]] && ! kill -0 "$pid" 2>/dev/null; then
    echo "with-resource-lock: reclaiming dead-pid lock $(basename "$holder")" >&2
    rm -f "$holder"
  fi
done

if [ "${1:-}" = "--status" ]; then
  held="$(ls "$LOCK_DIR"/holder-* 2>/dev/null | wc -l | tr -d ' ')"
  echo "$RESOURCE: $held/$capacity slots held"
  exit 0
fi

[ "${1:-}" = "--" ] || die "expected '--' before the command"
shift
[ $# -gt 0 ] || die "no command given after '--'"

# Acquire: atomic via noclobber. Race window between count and create is
# closed by re-counting after create and backing off if over capacity.
SLOT="$LOCK_DIR/holder-$$-$(date +%s)"
held="$(ls "$LOCK_DIR"/holder-* 2>/dev/null | wc -l | tr -d ' ')"
if [ "$held" -ge "$capacity" ]; then
  echo "with-resource-lock: '$RESOURCE' at capacity ($held/$capacity) — holding, not waiting" >&2
  exit 75
fi
( set -o noclobber; { echo "$$"; date -u +%Y-%m-%dT%H:%M:%SZ; echo "$*"; } > "$SLOT" ) 2>/dev/null \
  || die "could not create lock slot"
held="$(ls "$LOCK_DIR"/holder-* 2>/dev/null | wc -l | tr -d ' ')"
if [ "$held" -gt "$capacity" ]; then
  rm -f "$SLOT"
  echo "with-resource-lock: lost acquire race on '$RESOURCE' ($held/$capacity) — holding" >&2
  exit 75
fi

release() { rm -f "$SLOT"; }
trap release EXIT INT TERM

"$@"
rc=$?
exit "$rc"
