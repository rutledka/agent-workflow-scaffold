# Codebases

This document tracks the codebases **{{PROJECT_NAME}}** agents may modify. It exists because:

1. **Each codebase has its own technology stack.** Personas check this file to find the stack inventory and the canonical doc links for the libraries that codebase depends on. The scaffold scans for languages, frameworks, and libraries on add and the inventory feeds the personas that own that codebase.
2. **Niche codebase knowledge lives in a project-local skill, not in a separate persona.** When a codebase has distinct domain knowledge (8th Wall SLAM, FPGA toolchains, regulated-finance code, team-specific conventions), the scaffold drafts a project-local skill at `skills/<codebase-slug>/SKILL.md` that captures it. Personas check `skills/` before starting work and load any matching skill — this keeps the persona set tight (just roles) while still surfacing the right context for niche work.
3. **External codebases get an additional rule.** When an agent works in a codebase outside this project's repo, that codebase typically has its own base branch (`main` / `master` / `dev` / `develop` / etc.) which is shared with other contributors and is **read-only to agents**. PRs target a user-owned feature branch in that codebase, not the base branch. This rule does **not** apply to in-repo workstreams in this project — for those, the standard worktree flow in `AGENTS.md` is authoritative.

## Two codebase shapes

The entries below come in two variants. The scaffold picks the right shape per codebase based on whether the path is inside this project's repo or external.

### Variant A — external codebase

The codebase lives at an absolute path elsewhere on the user's machine. It has its own remote, its own base branch shared with other contributors, and a user-owned feature branch that agents target with PRs. The "never push to base branch" rule applies. Use this shape for partner repos, separate-app repos, and any codebase the user contributes to alongside other people.

### Variant B — in-repo workstream

The codebase is a subdirectory of this project (e.g. `code/backend/`, `code/infra/`, `apps/web/`). It shares this repo's git history, this repo's base branch, and this repo's worktree-and-PR flow per `AGENTS.md` — no separate base or feature branches. Use this shape for monorepo workstreams and the "single repo, one project" case where Q12 was answered "none yet" or "monorepo".

The scaffold's Step 2b.8 selects the variant per entry: if the codebase path resolves *inside* this project's repo root, Variant B; otherwise Variant A.

## How agents use this file

When an agent is dispatched on work that touches one of the codebases below, it:

1. Reads this file to find the codebase entry.
2. Loads any project-local skill listed under **Project-local skill**.
3. **For Variant A (external codebase):** `cd` into the **Local path**, run `git fetch origin`, confirm the **User's feature branch** is up to date, create a worktree off the user's feature branch (NOT the base branch), do its work, push, and open a PR back to the user's feature branch. Stash or fail loudly if local changes conflict.
4. **For Variant B (in-repo workstream):** follow the standard `AGENTS.md` worktree flow — branch off the project's default branch, PR back to it.

## How to add or update a codebase

Re-run `/agent-workflow-scaffold`. The scaffold's discovery interview includes codebase questions; the codebase setup step (Step 2b) verifies the path, picks the variant (Variant A vs. Variant B), detects the base branch from git for external codebases, creates or reuses the user's feature branch on consent, and scans the codebase for technology inventory.

## How to interpret the deprecation notes

The scaffold scans lock files (`package-lock.json`, `poetry.lock`, `Gemfile.lock`, `go.sum`, `Cargo.lock`, etc.) for install dates of libraries with known feature overlap. When two overlapping libraries are present and the older one was installed more than a year before the newer one, the scaffold asks the user whether the older library is deprecated in this project. If the user confirms, the deprecation appears in the Deprecation notes section below and is also added to the relevant persona's Working patterns ("Use `<newer>`; `<older>` is deprecated in this project — do not extend it").

---

<!--
The blocks below are templates. The scaffold writes a populated copy of
the appropriate variant per codebase the user listed in Q12 and removes
this comment from the rendered file.
-->

## Variant A — external codebase entry template

## Codebase: {{CODEBASE_NAME}}

- **Local path**: `{{LOCAL_PATH}}` *(absolute path on the user's machine)*
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

## Variant B — in-repo workstream entry template

## Codebase: {{CODEBASE_NAME}} (in-repo workstream)

- **Local path**: `{{LOCAL_PATH}}` *(relative to project root — in-repo workstream; branches and PRs follow this repo's main-branch flow per `AGENTS.md`. No separate base or user feature branches.)*
- **Last scanned**: `{{SCAN_DATE}}`
- **Project-local skill** (if any): `{{LOCAL_SKILL_PATH}}` *(empty if Step 2b.7 decided this workstream didn't warrant one)*

### Stack inventory

*(populated by the codebase scan; edit if anything is wrong)*

- **Runtime / language(s)**: {{LANGUAGES}}
- **Frameworks**: {{FRAMEWORKS}}
- **Build / test tooling**: {{BUILD_TOOLING}}
- **Infrastructure**: {{INFRASTRUCTURE}}
- **Other notable libraries**: {{OTHER_LIBRARIES}}

### Owning personas

The personas listed here treat this workstream as part of their working surface.

- {{OWNING_PERSONAS}}

### Documentation links

(Sourced from `docs/tech-docs-registry.md`. Update the registry when adding a new dependency; this list mirrors the most-load-bearing ones for this workstream.)

- {{DOC_LINKS}}

### Deprecation notes

*(populated by Step 2b's overlap detection; empty if no candidates found or the user said "still in use")*

- {{DEPRECATION_NOTES}}

---

## External codebases

*(if no Variant A entries above, the project does not currently reference any external codebases)*

When this project starts contributing to a codebase outside this repo, add a Variant A entry following the template above. Until then, the standard `main`-branch workflow in `AGENTS.md` covers all agent work.

---

*Add another codebase by re-running `/agent-workflow-scaffold`. The scaffold detects existing entries here and offers to update or append.*
