# Codebases

This document tracks codebases that **{{PROJECT_NAME}}** agents may modify on the user's machine. It exists because:

1. **Agents may run from outside any codebase.** A user might invoke an agent from an orchestration hub (`~/Code/my-projects/`) and have it work on a separate codebase (`~/Code/some-app/`). Without explicit pointers, the agent has no way to know where the codebase lives.
2. **Each codebase is shared with other people.** Agents must **never** push directly to a codebase's base branch (`main` / `master` / `dev` / `develop` / etc.). Every PR targets the **user's feature branch** in that codebase. The user merges from their feature branch to base themselves, after review.
3. **Each codebase has its own technology stack.** The scaffold scans for languages, frameworks, and libraries on add and the inventory feeds the personas that own that codebase. When two libraries with significant feature overlap appear and one looks abandoned, the scaffold surfaces it.
4. **Niche codebase knowledge lives in a project-local skill, not in a separate persona.** When a codebase has distinct domain knowledge (8th Wall SLAM, FPGA toolchains, regulated-finance code, team-specific conventions), the scaffold drafts a project-local skill at `.claude/skills/<codebase-slug>/SKILL.md` that captures it. Personas check `.claude/skills/` before starting work and load any matching skill — this keeps the persona set tight (just roles) while still surfacing the right context for niche work.

## How agents use this file

When an agent is dispatched on work that touches one of the codebases below, it:

1. Reads this file to find the codebase entry.
2. `cd` into the **Local path**.
3. `git fetch origin` and check the **User's feature branch** is up to date with the user's expected state. Stash or fail loudly if local changes conflict.
4. Create a worktree off the **User's feature branch** (NOT the base branch) — branch naming: `<agent-role>/<short-description>`, mirrored into `.worktrees/`.
5. Do its work in the worktree.
6. Push the worktree branch to origin and open a PR with the **User's feature branch** as the target — never the base branch.
7. Report the PR URL.

## How to add or update a codebase

Re-run `/agent-workflow-scaffold`. The scaffold's discovery interview includes codebase questions; the codebase setup step (Step 2b) detects each codebase's base branch from git, creates or reuses the user's feature branch, and scans the codebase for technology inventory.

## How to interpret the deprecation notes

The scaffold scans lock files (`package-lock.json`, `poetry.lock`, `Gemfile.lock`, `go.sum`, `Cargo.lock`, etc.) for install dates of libraries with known feature overlap. When two overlapping libraries are present and the older one was installed more than a year before the newer one, the scaffold asks the user whether the older library is deprecated in this project. If the user confirms, the deprecation appears in the Deprecation notes section below and is also added to the relevant persona's Working patterns ("Use `<newer>`; `<older>` is deprecated in this project — do not extend it").

---

## Codebase: {{CODEBASE_NAME}}

- **Local path**: `{{LOCAL_PATH}}`
- **Git remote**: `{{REMOTE_URL}}`
- **Base branch** (do **NOT** target directly): `{{BASE_BRANCH}}`
- **User's feature branch** (PR target for all agent work): `{{USER_FEATURE_BRANCH}}`
- **Last scanned**: `{{SCAN_DATE}}`
- **Project-local skill** (if any): `{{LOCAL_SKILL_PATH}}` *(empty if Step 2b.7 decided this codebase didn't warrant one)*

### Stack inventory

*(populated by the codebase scan; edit if anything is wrong)*

- **Runtime / language(s)**: {{LANGUAGES}}
- **Frameworks**: {{FRAMEWORKS}}
- **Build / test tooling**: {{BUILD_TOOLING}}
- **Infrastructure**: {{INFRASTRUCTURE}}
- **Other notable libraries**: {{OTHER_LIBRARIES}}

### Owning personas

The personas listed here treat this codebase as part of their working surface. When a ticket scoped to this codebase is dispatched, one of these personas takes it.

- {{OWNING_PERSONAS}}

### Documentation links

The links below come from `docs/tech-docs-registry.md`. Personas that own this codebase have these links injected into their **Key References** section automatically.

- {{DOC_LINKS}}

### Deprecation notes

*(populated by Step 2b's overlap detection; empty if no candidates found or the user said "still in use")*

- {{DEPRECATION_NOTES}}

---

*Add another codebase by re-running `/agent-workflow-scaffold`. The scaffold detects existing entries here and offers to update or append.*
