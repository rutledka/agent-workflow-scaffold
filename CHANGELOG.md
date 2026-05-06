# Changelog

All notable changes to `agent-workflow-scaffold` are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] — 2026-05-06

First public release. The scaffold is a Claude Code skill that drops a multi-agent project workflow into any new or existing repository — agent personas, PM artifacts, ADRs, dispatch logs, registries, and bootstrapped user memory — through a single discovery-driven invocation.

### Workflow scaffolding

- **Discovery-driven persona generation.** A Step 2 interview replaces an older fixed-checklist approach. The scaffold proposes 3–7 personas tailored to the user's role, daily work, and team shape; the user confirms before any files are written.
- **Eleven off-the-shelf persona templates** — Orchestrator, Project Manager, Engineering Manager, Backend, Frontend, QA, Platform, Designer, Legal, Pilot Lead, Personal Assistant — plus a `custom-skeleton.md` for off-list roles (Growth Lead, ML Researcher, Data Engineer, etc.).
- **Runnable Orchestrator persona.** A dispatch loop with explicit steps: sync `main`, read backlog + roadmap, fetch open PRs, classify review items as HIGH/MEDIUM/LOW, run a strict-priority decision tree per agent, dispatch sub-agents, write a dispatch log to `docs/dispatch-logs/YYYY-MM-DD.md`. The sub-agent write-permission gotcha is documented in the dispatch flow.
- **Personal Assistant persona** (proposed by default; opt-out): multi-horizon goal tracker (Daily / Weekly / Monthly / Quarterly / Annual), read-only signals from email + team-comms, nudges on stalls, never-assignable goal categories, private user-scoped memory.
- **Bootstrap memory** at `~/.claude/projects/<project-slug>/memory/` with six starter feedback entries (worktree+PR discipline, worktrees-not-siblings, document version+history, decisions-via-ADR, sub-agent write permissions, prefer-concrete-comparisons) plus a `user-role-profile.md` derived from the discovery answers, so future scaffold runs in other projects can suggest personas faster.

### Multi-codebase support

- **`pm/codebases.md` registry** with two variants: **Variant A** for external codebases (separate remote, base branch, user feature branch — the "never push to base" rule applies), and **Variant B** for in-repo workstreams (subdirectories sharing this repo's git history). The scaffold picks the variant per codebase based on path resolution.
- **Codebase technology inventory.** The scaffold scans `package.json` / `pyproject.toml` / `Gemfile` / `go.mod` / `Cargo.toml` / lockfiles / Dockerfiles / Terraform / GitHub workflows and produces a structured stack inventory per codebase.
- **Tech-docs registry** (`docs/tech-docs-registry.md`) cross-referenced against the scan to inject canonical doc URLs into owning personas' Key References.
- **Feature-overlap registry** (`docs/feature-overlap-registry.md`) detects pairs of libraries with significant overlap (e.g. `jsonwebtoken` + `jose`, `webpack` + `vite`); when the install-date gap exceeds a year, the scaffold asks about deprecation and propagates the answer to the owning persona's Working patterns.
- **Auto-stub for unrecognized tech and deferred overlap candidates.** Rather than asking and proceeding without the link, the scaffold appends a TODO row the user can fill in later — preserving the signal across re-runs.

### PM-tool integration

- **PM source-of-truth selection** in Q9a: Linear / Jira / Notion / GitHub Issues (vendor MCP path), or Asana / Trello / Monday / ClickUp / Shortcut / Pivotal / etc. (REST/GraphQL API path), or Files-only.
- **Step 5b-MCP** wires vendor-official MCPs and drafts a project-local skill at `skills/pm-<tool>-<project-slug>/SKILL.md` that captures workspace + label conventions.
- **Step 5b-API** for tools without a vendor MCP: drafts an API-based PM skill, adds a token slot to `.env.example` (and to `.env` with edge-case handling for symlinks, git-crypt, read-only files, and CRLF line endings), and surfaces token rotation, test isolation, and credential-sharing guidance (1Password CLI, `gh secret`, system keychain, `pass`).
- **`pm/backlog.md` becomes a pointer doc** when a PM tool is configured, and stays as the rich live source of truth in Files-only mode.

### Project-local skills

- **Niche codebase knowledge → project-local skill, not a custom persona.** Personas describe roles; skills describe technical knowledge. Step 2b.7 drafts a `skills/<codebase-slug>/SKILL.md` for any codebase with niche tech or team-specific gotchas.
- **`skills/` is the canonical, vendor-neutral path**; Claude Code reads it via a `.claude/skills → ../skills` symlink the scaffold creates in Step 4a.
- **Skills registry** (`docs/skills-registry.md`) classifies each skill as `git` / `plugin` / `builtin` / `private` with install commands. Step 7 actively `git clone`s the auto-installable lane (with one batched consent prompt), coaches the `/plugin install` lane, and surfaces private-skill placeholders.
- **Persona frontmatter validation.** Each persona's `required_skills:` YAML is parsed explicitly — parse errors and shape mismatches surface in a per-persona scan summary rather than silently dropping skills from the install plan.

### Cross-tool AI-coding support

- **`AGENTS.md` is canonical** (per the [agents.md](https://agents.md) convention); `CLAUDE.md` is a symlink. OpenCode, Cline, Cursor (recent), Continue, and GitHub Copilot all read `AGENTS.md` natively.
- **Per-tool wiring in Step 4a** based on Q14 (which AI coding tools the team uses): symlink for Copilot's `.github/copilot-instructions.md`, config injection for Aider's `.aider.conf.yml`, no-op + verify for natively-supporting tools.
- **Cross-tool conventions table** in `skills/README.md` documents the project-local skill format equivalents for each tool (OpenCode's `.opencode/agents/`, Copilot's `.github/instructions/`, Cline's `.clinerules/`, Cursor's `.cursor/rules/*.mdc`, Continue's `.continue/rules/`).

### Trusted MCP integrations

- **Vendor-official, OAuth-secured set:** Linear, Atlassian (Jira + Confluence via Rovo), Notion, Slack, GitHub, Figma. Trust criteria documented in `docs/integrations.md` (vendor-published, OAuth 2.1, vendor-hosted, active maintenance, explicit scope model).
- **`.mcp.example.json`** is committed; `.mcp.json` is gitignored and copied on consent.
- **Personal Assistant read-only scopes** are enforced when the persona is confirmed — Gmail / Microsoft 365 / Slack / Teams / Discord / Calendar all wired with `read` scope and a hard "never send / compose / post" rule in `AGENTS.md`.

### Migration mode

- **Step 1.5 — Detect drift.** When the project was scaffolded against an older version of the skill (`CLAUDE.md` as a regular file, `.claude/skills/` as a real directory, personas without `required_skills:` frontmatter, missing `pm/codebases.md`, missing registries), the scaffold runs nine drift detectors and presents a per-item migration plan inside a worktree-and-PR — preserving git history (`git mv` for renames), staging each fix as a separate commit, idempotent on re-run.

### Documentation

- `README.md` — install + use, file map, migration, customization.
- `SKILL.md` — the executable skill: nine ordered steps with sub-steps, substitution maps, and working principles.
- `docs/workflow-philosophy.md` — the eight patterns and the failure modes they address.
- `docs/integrations.md` — trust criteria + integration matrix.
- 11 persona templates, 7 PM templates, 5 docs templates (ADR template, registries, dispatch-logs), 3 skills templates (codebase / PM-MCP / PM-API), 6 memory templates.

### Install

- `install.sh` — convenience installer. User-scoped (`~/.claude/skills/agent-workflow-scaffold`) or project-scoped (`skills/agent-workflow-scaffold` + `.claude/skills → ../skills` symlink); SSH with HTTPS fallback.
- Three install paths documented in `README.md`: user-scoped clone, project-scoped submodule, project-scoped curl-tarball.

[1.0.0]: https://github.com/rutledka/agent-workflow-scaffold/releases/tag/v1.0.0
