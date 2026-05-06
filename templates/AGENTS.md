# {{PROJECT_NAME}} — Agent Guidelines

> **About this file.** `AGENTS.md` is the canonical, vendor-neutral home for agent instructions in this project — following the [agents.md](https://agents.md) convention. `CLAUDE.md` (Claude Code's expected filename) is a symlink to this file. If you adopt other AI coding tools later (Cursor, Cline, Aider, codename-Y), point their convention at this same file rather than maintaining parallel copies.
>
> **Cross-tool support today.** OpenCode, Cline, Cursor (recent versions), Continue, and GitHub Copilot all read `AGENTS.md` natively. Aider does not auto-discover — the scaffold's Step 4a adds `read: AGENTS.md` to `.aider.conf.yml` if Aider was selected. GitHub Copilot's repo-wide instructions also expect `.github/copilot-instructions.md` — Step 4a creates that as a symlink to this file.
>
> **For project-local skills**, see `skills/README.md` "Cross-tool conventions" — different tools have different shapes (OpenCode's `.opencode/agents/<name>.md` is full subagents; Cursor's `.cursor/rules/*.mdc` has its own frontmatter; Copilot's `.github/instructions/*.instructions.md` is path-targeted). The canonical content lives at `skills/<name>/SKILL.md`; per-tool wiring is documented but not auto-translated.

## Repository
- Remote: `git@github.com:{{REPO_OWNER_REPO}}.git`
- Default branch: `main`
- Primary stack: {{PRIMARY_STACK}}

## Git Workflow — MANDATORY for all agents

This applies to **every AI coding agent** — primary sessions, spawned sub-agents, and any automated pipeline. **No direct commits to `main`, ever.**

### Rule: Work in a worktree, ship via pull request

1. **Create a worktree** for every task. Worktrees live inside the repo at `.worktrees/<branch-name>/` (gitignored) — never as a sibling of the repo:
   ```
   git worktree add .worktrees/<branch-name> -b <branch-name>
   ```
   Branch naming: `<agent-role>/<short-description>` — e.g. `frontend/login-form`, `backend/upload-endpoint`. If the branch name contains a `/`, the path nests naturally (e.g. `.worktrees/frontend/login-form/`).

2. **Make all changes inside the worktree.** Never edit files in the main working tree while a task is in progress.

3. **Commit inside the worktree** with a clear, descriptive message. Reference epic/ticket IDs where applicable (e.g. `EPIC-03-T01: add login form scaffold`).

4. **Push the branch** to origin:
   ```
   git push -u origin <branch-name>
   ```

5. **Open a pull request** using `gh pr create`. PR title format: `[EPIC-XX] Short description` (or `[area] Short description` for non-ticket work). Include a summary of what changed and a testing checklist in the body. **A task is not complete until the PR is open.**

6. **Report the PR URL** to the user so they can review it.

7. **Remove the worktree once the PR is open.** The branch lives on origin and is preserved by the open PR — the local worktree directory is no longer needed:
   ```
   git worktree remove .worktrees/<branch-name>
   ```

8. **Do not merge your own PR.** Leave it open for review unless the user explicitly asks you to merge.

### Rule: Working in *referenced* codebases (multi-repo work)

The scaffolded project may reference one or more **external codebases** at paths on the user's machine — listed in [`pm/codebases.md`](./pm/codebases.md). These are codebases the user contributes to alongside other people. The same worktree-and-PR discipline applies, plus an additional rule:

- **Never push to a referenced codebase's base branch.** The base branch (`main`, `master`, `dev`, `develop`, etc.) is recorded in `pm/codebases.md` and is **read-only** to agents. Other contributors merge to that branch via their own review process.
- **PRs target the user's feature branch in that codebase.** Each codebase entry in `pm/codebases.md` records `User's feature branch` — the branch the user owns and uses to integrate agent work. Open PRs against that branch, not against the base branch. The user merges their feature branch to base themselves, after their own review.
- **Worktrees still go inside the codebase.** When working in a referenced codebase at `<codebase-path>/`, create the worktree at `<codebase-path>/.worktrees/<branch-name>/`. Branch names follow the same `<agent-role>/<short-description>` pattern. The branch is created off the user's feature branch (not the base branch).
- **`cd` into the codebase before starting work.** Agents dispatched on cross-codebase tickets must change directory into the codebase listed in `pm/codebases.md`, run `git fetch origin`, and confirm the user's feature branch is up to date before creating a worktree.

This rule does **not** apply to the project where this `AGENTS.md` lives — that one's git workflow uses `main` (or whatever the default branch is) as the PR target, per the previous section.

### Commit message style
- Imperative mood: `add`, `fix`, `refactor`, `remove` — not `added`, `fixed`.
- Reference epic/ticket IDs where applicable: `EPIC-03-T02: integrate login flow`.
- Keep subject line under 72 characters.

### Hard rules — no exceptions

**Git safety**
- Never use `--no-verify`. If a hook fails, fix the underlying issue.
- Never force-push (`--force` or `--force-with-lease`) to `main` or any branch another agent is working on.
- Never commit secrets, API keys, tokens, or credentials — not even in tests or fixtures.

**PRs**
- One concern per PR. Don't bundle a feature with a refactor or an unrelated fix.
- Delete the branch after the PR is merged.

**Decisions**
- Load-bearing decisions (architecture choices, framework selection, schema structure, auth model) go into a numbered ADR in `docs/adr/`, not into chat or commit messages. ADR template: `docs/adr/0000-template.md`.

**Project-local skills**
- Before starting any task, check `skills/` for project-local skills relevant to the codebase or section you're touching. Skills there capture niche knowledge that the generic persona working patterns don't cover (e.g. codebase-specific gotchas, team conventions, framework quirks). If a skill's `description:` matches the task at hand, **load it via the Skill tool before doing the work** — the skill's conventions and gotchas take precedence over the generic working patterns in your persona file. `pm/codebases.md` records which codebases have a paired local skill. Claude Code reads skills via a symlink at `.claude/skills` → `../skills`; other AI agent platforms can read `skills/` directly without indirection.

## Project Structure

```
agents/         — agent persona definitions (one .md per role)
docs/           — technical documents, ADRs, dispatch logs, registries (skills, tech docs, feature overlap)
pm/             — product backlog, roadmap, management notes, codebase registry, goals
skills/         — project-local agent skills (codebase-niche knowledge, on-call playbooks, etc.).
                  Vendor-neutral path. Claude Code reads via .claude/skills → ../skills symlink.
.claude/skills  — symlink to ../skills (Claude Code's expected path; do not create files here)
CLAUDE.md       — symlink to AGENTS.md (Claude Code's expected filename; do not edit directly)
AGENTS.md       — this file. The canonical source for agent guidelines. Edit here.
```

## Key Documents
- `pm/backlog.md` — milestones, epics, tickets (source of truth for delivery)
- `pm/management.md` — leadership-readable plan: scope, RACI, decision log, risk register
- `pm/roadmap.md` — milestone roadmap
- `pm/codebases.md` — external codebases this project's agents work on, with paths, base branches, user feature branches, tech inventory, and deprecation notes
- `docs/adr/` — Architecture Decision Records (one file per decision)
- `docs/dispatch-logs/` — orchestrator audit trail (`YYYY-MM-DD.md` per run)
- `docs/skills-registry.md` — known agent skills + install commands (Claude Code-flavored today; structure is portable to other tools)
- `docs/tech-docs-registry.md` — library / framework → official docs URL map; consumed by the codebase scan
- `docs/feature-overlap-registry.md` — pairs of libraries with significant feature overlap; consumed by the codebase scan to surface deprecation candidates

## Project-specific rules

<!--
Rules below are added by the user during scaffolding (or later, by editing this file).
Each rule should be one or two sentences and should be enforceable in code review.

Examples (add only the ones that apply to this project):
- All route handlers must validate inputs with Zod before touching the database or calling external services. No raw `req.body` access.
- No `console.log`, `console.warn`, or `console.error` in `src/` code. Use the structured logger.
- Run `npm run typecheck && npm test` in the affected package before pushing. Do not push code that fails either check.
- DB migrations are additive-only. Never drop columns, rename columns, or change column types in an existing migration. Destructive schema changes require two PRs.
- Any change to a request/response shape, new route, or removed route must update `docs/api-specification.md` in the same PR.
- TypeScript strict mode is enforced. Never use `// @ts-ignore` or `// @ts-expect-error` without a comment explaining the specific compiler bug.
-->

*(none yet — populate during scaffolding or as conventions emerge)*
