---
name: Feedback - Worktrees go inside the repo, not as siblings
description: Git worktrees live at `.worktrees/<branch-name>/` inside the repo (gitignored), never as a sibling directory next to the repo
type: feedback
---

When creating a git worktree, the path is `.worktrees/<branch-name>/` **inside the repo**, not a sibling directory next to it. The `.worktrees/` path is gitignored.

**Why:** Sibling-style worktree paths (e.g. `../my-project-feature-x/`) clutter the parent directory, make `cd ..` ambiguous, and can be accidentally tracked or backed up as if they were independent projects. Keeping them inside the repo means everything related to one project lives in one tree, and the gitignore rule makes them invisible to git.

**How to apply:**
- Always: `git worktree add .worktrees/<branch-name> -b <branch-name>`
- The `.worktrees/` line should be in the repo's `.gitignore`.
- Branch names with `/` (e.g. `frontend/login-form`) nest naturally — that's fine and intentional.
- After the PR is open, remove the worktree: `git worktree remove .worktrees/<branch-name>`. The branch on origin is preserved.
