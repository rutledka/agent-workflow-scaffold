---
name: Feedback — sub-agents in isolation:"worktree" can't write files
description: When orchestrating, the main session must author files; sub-agents in isolation:"worktree" mode cannot create/edit files because the harness denies their Write/Edit calls.
type: feedback
---

When the orchestrator dispatches sub-agents via the `Agent` tool with `isolation: "worktree"`, those sub-agents typically **cannot write files** — the harness creates the isolated worktree but denies the sub-agent's `Write` and `Edit` tool calls. The sub-agent will often report "done" successfully even though no files were actually created.

**Why:** This is a Claude Code harness behavior, not a sub-agent bug. The isolated mount is set up read-only-from-the-sub-agent's-perspective for safety; writes are reserved for the calling (main) session. There may be harness modes that enable sub-agent writes, but assume they're denied unless you've verified otherwise on this machine.

**How to apply:**

- **Main session authors files; sub-agents do read-only research.** Dispatch sub-agents for search, analysis, file inspection, and synthesis. The main session takes their report and does the actual writing, committing, and PR opening.
- **If you must have a sub-agent write**, run it without `isolation: "worktree"` (in the same worktree as the main session). Accept the conflict-write risk and serialize dispatches that touch the same files.
- **Verify after every dispatch** with `git status` / `git diff --stat` from the main session before moving to the next dispatch job. If the worktree is empty, the dispatch silently failed; re-do it from the main session.

This pattern is documented in `agents/orchestrator.md` "Step 4 — Sub-agent write permissions" and `AGENTS.md` "Rule: Dispatching sub-agents."
