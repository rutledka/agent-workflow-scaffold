#!/usr/bin/env bash
# UserPromptSubmit hook — Learning Opportunities cadence check-in.
#
# Every N minutes of cumulative wall-clock interaction time, this hook nudges
# Claude to RE-CHECK whether the `learning-opportunities` skill's own trigger
# conditions apply (architectural work in the recent turn, session not already
# at its 2-exercise cap, last offer not declined). The skill's native rhythm —
# what counts as "significant architectural work" and when to suppress — is
# always authoritative. This hook only re-opens the question on a clock; it
# never overrides the skill's invocation logic or its suppression rules.
#
# Cadence is read from the `learning-opportunities-frequency-minutes:` line in
# the user-scoped memory file at:
#   ~/.claude/projects/<project-slug>/memory/learning-opportunities-context.md
#
# Last-trigger timestamp is stored at:
#   ~/.claude/projects/<project-slug>/memory/.learning-opportunities-last-trigger
#
# Set the frequency line to `0` to disable. Deleting the timestamp file resets
# the cadence (the next prompt re-arms the timer).
#
# Installed by the agent-workflow-scaffold.

set -euo pipefail

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
PROJECT_SLUG="$(basename "$PROJECT_DIR")"
MEMORY_DIR="$HOME/.claude/projects/$PROJECT_SLUG/memory"
CONTEXT_FILE="$MEMORY_DIR/learning-opportunities-context.md"
STATE_FILE="$MEMORY_DIR/.learning-opportunities-last-trigger"

FREQ_MIN=60
if [ -f "$CONTEXT_FILE" ]; then
  parsed=$(grep -E '^learning-opportunities-frequency-minutes:[[:space:]]*[0-9]+' "$CONTEXT_FILE" 2>/dev/null | head -1 | sed -E 's/.*:[[:space:]]*([0-9]+).*/\1/' || true)
  if [ -n "${parsed:-}" ]; then
    FREQ_MIN="$parsed"
  fi
fi

if [ "$FREQ_MIN" -eq 0 ]; then
  exit 0
fi

now=$(date +%s)
last=0
if [ -f "$STATE_FILE" ]; then
  last=$(cat "$STATE_FILE" 2>/dev/null || echo 0)
  case "$last" in ''|*[!0-9]*) last=0 ;; esac
fi
elapsed=$(( now - last ))
threshold=$(( FREQ_MIN * 60 ))

if [ "$elapsed" -lt "$threshold" ]; then
  exit 0
fi

mkdir -p "$MEMORY_DIR"
echo "$now" > "$STATE_FILE"

context_msg="Cadence check-in: it has been at least ${FREQ_MIN} minutes since the last learning-opportunities review. Re-evaluate the 'learning-opportunities' skill's OWN trigger conditions for the current turn — significant architectural work (new file, schema change, refactor) AND the skill's session-level suppression rules (max 2 exercises per session, respect any earlier 'no'). If those conditions are met, invoke the skill. If not, defer silently and let the skill's native rhythm decide; the next cadence check-in fires in ${FREQ_MIN} minutes. This hook is a clock-based re-check, not an override. To change cadence, edit 'learning-opportunities-frequency-minutes:' in ${CONTEXT_FILE} (set to 0 to disable)."

if command -v python3 >/dev/null 2>&1; then
  python3 -c 'import json,sys; print(json.dumps({"hookSpecificOutput":{"hookEventName":"UserPromptSubmit","additionalContext":sys.argv[1]}}))' "$context_msg"
elif command -v jq >/dev/null 2>&1; then
  jq -nc --arg msg "$context_msg" '{hookSpecificOutput:{hookEventName:"UserPromptSubmit",additionalContext:$msg}}'
else
  echo "$context_msg"
fi
