# Memory Index

- [Feedback: Worktree + PR discipline](feedback-worktree-pr-discipline.md) — Every task ships through a worktree → PR; never commit directly to main
- [Feedback: Worktrees not siblings](feedback-worktrees-not-siblings.md) — Worktrees go inside `.worktrees/` in the repo, never as a sibling directory
- [Feedback: Document version + history](feedback-document-version-history.md) — Every document carries a version, date, and history table at the bottom
- [Feedback: Decisions via ADR](feedback-decisions-via-adr.md) — Load-bearing decisions go into numbered ADRs in `docs/adr/`, not chat or commit messages
- [Feedback: Sub-agent write permissions](feedback-subagent-write-permissions.md) — Sub-agents in `isolation: "worktree"` mode typically can't write files; the main session must author files and delegate only read-only research
- [User: Prefer concrete comparisons](user-prefer-concrete-comparisons.md) — When asked "should we use X?", offer a comparison table; user wants to decide, not be told
