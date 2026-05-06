---
name: Feedback - Worktree + PR discipline
description: Every task in this project ships through a worktree → PR; never commit directly to main, no exceptions
type: feedback
---

Every task — including small docs changes — moves through a git worktree at `.worktrees/<branch-name>/` and ships via a pull request. No direct commits to `main`, no force-pushes to shared branches, no `--no-verify` skips on hooks.

**Why:** This rule keeps the multi-agent model honest. When several agents (and the user) might be working on different parts of the project simultaneously, the only safe coordination point is a reviewable PR with a CI run against it. Bypassing it once trains future runs to bypass it again.

**How to apply:**
- Before starting any task, create a worktree with `git worktree add .worktrees/<branch-name> -b <branch-name>`.
- Do all work inside the worktree.
- Commit, push, and open a PR with `gh pr create` before reporting the task as complete.
- Remove the worktree after the PR is open; the branch lives on origin.
- If a hook fails, fix the underlying issue — never `--no-verify`.
- The exact rules live in `AGENTS.md` at the repo root; read it before each task.
