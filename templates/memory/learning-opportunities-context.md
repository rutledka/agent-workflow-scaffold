---
name: learning-opportunities-context
description: User-scoped configuration and notes for the learning-opportunities skill. Controls how often the skill is offered via the `.claude/hooks/learning-opportunities-cadence.sh` UserPromptSubmit hook. Edit the cadence line below to tune; set to 0 to disable the cadence hook (the skill's native architectural-work triggers still apply).
type: user
---

# Learning opportunities — cadence and context

The [`learning-opportunities`](https://github.com/DrCatHicks/learning-opportunities) skill offers 10–15 minute deliberate-practice exercises after architectural work — prediction → observation → reflection, generation → comparison, trace execution, debug scenarios, teach-back, retrieval check-ins. It builds expertise through evidence-based learning techniques rather than just shipping faster.

The scaffold installs a `UserPromptSubmit` hook (`.claude/hooks/learning-opportunities-cadence.sh`) that nudges Claude to **re-check the skill's own trigger conditions** every N minutes of cumulative wall-clock interaction time. The hook never overrides the skill's native rhythm — what counts as "significant architectural work," the 2-exercise-per-session cap, and respecting an earlier decline are all the skill's call. The hook just re-opens the question on a clock so a long session doesn't drift past a moment the skill would otherwise have caught.

## Cadence

`learning-opportunities-frequency-minutes: 60`

Edit the integer above to change how often the cadence reminder fires. Set to `0` to disable the hook entirely (the skill's native triggers still apply). The hook re-reads this file on every prompt, so changes take effect immediately — no restart.

## How it works

- Each user prompt fires the hook.
- The hook compares `now - last_trigger` to the cadence threshold.
- When the threshold is crossed, the hook injects an *advisory* re-check message into Claude's context and updates the timestamp.
- Claude then re-evaluates the skill's own trigger conditions for the current turn (architectural work + session-suppression rules). If they're met, the skill is invoked. If not, the hook is deferred-to silently — no exercise is forced.
- The skill's invocation logic and suppression rules are always authoritative. The hook is a clock-based re-check, never an override.

## State

- Last-trigger timestamp lives at `~/.claude/projects/<project-slug>/memory/.learning-opportunities-last-trigger` (a single Unix timestamp).
- Delete that file to reset the cadence — the next prompt re-arms the timer immediately.

## Native triggers (independent of this cadence)

Even with the cadence hook disabled, the upstream `learning-opportunities` skill triggers itself when it detects significant architectural work in the session — new files, schema changes, refactors. The optional `learning-opportunities-auto` plugin from the same marketplace adds a post-commit hook that prompts after each commit. Both are independent of the cadence configured here.
