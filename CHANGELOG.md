# Changelog

All notable changes to `agent-workflow-scaffold` are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.3.0] — 2026-08-30

The graph-orchestration retrofit: moves the agent workflow's coordination facts out of prose and into data, and turns its quality gates into commands with exit codes. Generalized from three months of field experience running a scaffolded project's orchestrator on a schedule — every observed failure (eight consecutive degraded runs, silently rotting status docs, a shared database "protected" by a paragraph, a merge gate that was a comment convention) was a scaffolding failure, not a model failure. Full design: `docs/graph-orchestration-retrofit.md`.

### The work graph as data (Layer 0)

- **`templates/orchestration/graph.yaml`** — the policy graph: personas + file domains, capacity-N resource semaphores with recorded reasons, a gates registry, `merge_gate_mode`, dispatch budgets, and frontier-selection weights. Policy lives here; **ticket status stays in the PM tool** — the ownership boundary is one-directional in each direction, never bidirectional sync.
- **`orchestration/state.json`** — derived per cycle by `scripts/graph-sync.sh`: computed frontier (in-degree 0 over open blocking edges), scored ranking, collision flags against in-flight PRs, machine-readable `hold_reason`s, and invariant-check results. Committed each cycle so the diff between runs is the execution record. Never hand-edited.
- **Generated views** — `pm/delivery-status.md` (PM-tool projects) and any block between `GENERATED FROM orchestration/graph.yaml` markers render from the single declaration, making "the epic exists but isn't in the index" impossible by construction.

### The loop as a state machine (Layer 1)

- **`scripts/preflight.sh`** — guard node + circuit breaker: cheap ordered checks (push reachability, `gh` auth, CLIs, graph parse, worktree/lock hygiene), a ONE-SCREEN failure report, and exit 2 at N consecutive failures = stop scheduling, alert a human.
- **`scripts/with-resource-lock.sh`** — the semaphore as code; exit 75 = at capacity → a `hold_reason`, not a wedged resource.
- **`templates/agents/orchestrator.md` rewritten** from a 322-line essay into a thin operator: preflight → sync → plan → dispatch → collect → report, with fixed failure-routing policy, budget-bounded typed dispatches (`--max-budget-usd` + `--json-schema orchestration/schemas/dispatch-result.json`), and a JSON dispatch-log twin so the caps and weights can finally be tuned from outcomes.

### The merge gate as a command (Layer 2)

- **`scripts/policy-lint.sh`** — the AGENTS.md hard rules as diff checks; composes existing project lints, never re-implements them.
- **`orchestration/schemas/qa-verdict.json`** — the evaluator's sign-off becomes a head-SHA-pinned artifact with a *computed* verdict; `deferred` requires a reason (+ follow-up ticket) — deferral is countable, never free.
- **`scripts/qa-merge.sh`** — the evaluator persona's only merge path: green checks on the PR's *current* head, valid verdict artifact, no-self-merge, design-PR hold. **Plan-aware:** Step 1 probes the branch-protection API; private repos on free personal plans (the common case) get `merge_gate_mode: merge-command` with the script as the enforcement point, public/paid repos get `github-native` plus the script. Merge queue is never proposed for user-owned repos.
- **`AGENTS.md` autonomy table** — who decides what, binding every agent: roadmap human; planning agentic; merge = evaluator via `qa-merge.sh`; design merges, prod deploys, and spend human.

### Discovery + generation wiring

- **Step 1** merge-gate probe; **Step 2** Q16 (shared resources → semaphores) and Q17 (gates; opt-in advisory-until-calibrated LLM judge, default off); **Step 2b.8** harvests gate candidates and file-domain globs from the codebase scan; **Step 3f** presents the graph plan with an explicit sign-off on the real-money dispatch budget; **Step 4c** writes `orchestration/` + `scripts/` and gitignores `orchestration/.runtime/`.

### Migration to v1.3 for existing scaffolded projects

- **Step 1.5 D13–D19** — drift detectors for the missing graph, prose-shaped orchestrator, absent guard scripts, unmechanized policy rules, missing merge gate, hand-maintained delivery status (PM-tool projects), and missing autonomy table. Ordering enforced: D13's **ownership audit** precedes anything that generates from the persona map — never publish a wrong owner with a machine's authority.
- **`scripts/migrate-to-graph-orchestration.sh`** — standalone one-shot mirroring the v1.1 migration contract: phase-0 pipeline-health checklist, worktree + one commit per detector + PR, `--dry-run`/`--no-pr`, idempotent. Judgment stays human: the ownership audit pauses for acknowledgment, the orchestrator rewrite is staged beside the existing persona, the backlog split is detect-and-print.

### Working principles

- **A gate is a command with an exit code, or it is not a gate.** Prose gates decay into conventions; conventions decay into nothing.
- **Buy the graph discipline, not the graph framework.** Typed state, guard edges, budgets, structured traces — no LangGraph/Temporal runtime for an eight-node loop.
- **Everything is bounded.** Budgets, timeouts, retries, and consecutive failures all have declared limits; unbounded is what turns a bad run into a bad week.

## [1.2.0] — 2026-05-07

Adds an opt-in for the [`learning-opportunities`](https://github.com/DrCatHicks/learning-opportunities) skill so users can reinforce their own understanding of the work the agents are facilitating. Deliberately minimal: the scaffold introduces the skill and stops — the skill's own evidence-based trigger logic stays authoritative.

### Learning opportunities

- **Q15 opt-in in the discovery interview.** Step 2 grows a binary yes/no question about installing the `learning-opportunities` skill — 10–15 minute deliberate-practice exercises (prediction, generation, retrieval, teach-back) offered after architectural work.
- **Step 7i coaches the marketplace install.** When Q15 = yes, the scaffold prints the `claude plugin marketplace add DrCatHicks/learning-opportunities` and `claude plugin install learning-opportunities@learning-opportunities` commands with a default-NO consent prompt (same shape as 7h.2 — `claude` CLI plugin auth may not be set up at scaffold time). Surfaces the optional `learning-opportunities-auto` companion plugin (post-commit hook from the same upstream).
- **Step 9 summary** gains a "Learning opportunities" section reporting installed / to install / already installed.

### Working principle

- **Don't override an upstream skill's native rhythm.** The scaffold installs `learning-opportunities` and stops. No clock-based hook, no `.claude/settings.json` edit, no user-memory cadence file. The skill triggers itself on its own conditions (significant architectural work, capped at 2 exercises per session, respects an earlier "no") and the optional `-auto` companion handles post-commit. Layering a custom cadence on top would override the skill author's deliberate-practice rhythm.

## [1.1.0] — 2026-05-06

Three feature merges land on top of v1.0.0: a safer `AGENTS.md` write path, a VoltAgent sub-agents integration that stacks technology specialization on top of role-based personas, and a symmetric `uninstall.sh`.

### AGENTS.md is a merge, not an overwrite

- **Step 4 detects pre-existing user content and merges instead of clobbering.** When the project has a hand-authored `CLAUDE.md` (or `AGENTS.md`) without the scaffold's anchors, Step 4 renders the template's universal sections first and appends the user's content verbatim under a `## Existing project rules (preserved from CLAUDE.md)` delimiter. Nothing is reformatted, reordered, or deleted.
- **Idempotent on re-run.** If the file already has all four scaffold anchors, Step 4 leaves it untouched.
- **Step 1 detection** now triggers on `CLAUDE.md` alone (a project with only `CLAUDE.md` and nothing else hits the same Step 1.5 migration path).
- **Step 9 summary** always prints an `AGENTS.md merge:` line stating which path was taken (merged / fresh / left untouched).
- **New working principle:** "Never overwrite the user's CLAUDE.md / AGENTS.md content; merge."

### VoltAgent sub-agents integration

- **Two-layer model.** Personas describe **roles** (Backend Engineer, QA Engineer); sub-agents describe **technology specializations** (`python-pro`, `kubernetes-specialist`, `accessibility-tester`). The layers stack — a custom-skeleton persona for "Python Engineer" is the wrong shape; the answer is Backend Engineer + the `python-pro` sub-agent.
- **`docs/subagents-registry.md`** — canonical persona-to-plugin mapping with primary plugins (always relevant) and conditional plugins (stack-dependent), plus a keyword index for custom-skeleton matching.
- **Per-persona "Available sub-agents for delegation" section** in all 11 off-the-shelf templates; `custom-skeleton.md` uses a `{{SUBAGENT_SECTION}}` placeholder that Step 4b fills via the registry's keyword index. Personal Assistant intentionally has no primary plugin (its scope is email + comms, not delegation).
- **Step 3 sub-section 3c-sub** proposes primary + conditional plugins per confirmed persona during the discovery interview.
- **Step 7h** coaches the install with a default-NO consent prompt (marketplace plugins are user-globally persistent and `claude` CLI plugin auth may not be set up at scaffold time) and runs the marketplace-add + plugin-install in a single batch.
- **Step 9 summary** gains a VoltAgent plugins section (installed / to install / already present).

### Migration to v1.1 for existing scaffolded projects

- **Step 1.5 D10 + D11** — drift detectors for missing `docs/subagents-registry.md` and personas without the Available-sub-agents section. Re-running the scaffold migrates inside a worktree-and-PR with one commit per persona.
- **`scripts/migrate-personas-to-voltagent-subagents.sh`** — standalone one-shot bash equivalent for users who'd rather not re-run the full scaffold. Same logic as D10 + D11. Idempotent. Flags: `--no-pr`, `--dry-run`, `--help`.

### Uninstall

- **`uninstall.sh`** — symmetric to `install.sh`. Removes scaffold-written paths (`agents/`, `pm/`, the four registry docs, `docs/integrations.md`, `docs/dispatch-logs/`, `docs/adr/0000-template.md`, `skills/`, `.claude/skills` symlink, `.mcp.example.json` / `.mcp.json`, `AGENTS.md` + `CLAUDE.md` symlink). Lists what it would remove, asks once, runs in a worktree, opens a PR.
- **Preserves load-bearing content.** ADR records (`docs/adr/00NN-*.md`), hand-authored docs outside the scaffold's known set, `.gitignore` additions, `.env` content, and `.aider.conf.yml` (its `read: AGENTS.md` line is surfaced for manual cleanup, not auto-removed) all stay.
- **CLAUDE.md merge restoration.** When `AGENTS.md` carries the v1.1 merge delimiter, the uninstall extracts the user's preserved content back into a real `CLAUDE.md` before removing `AGENTS.md` — clean undo.
- **Granular flags:** `--dry-run`, `--keep-pm`, `--keep-docs`, `--keep-skills`, `--keep-personas`, `--keep-mcp`, `--keep-claude-md`, `--remove-memory`, `--no-pr`, `--yes`.

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

[1.2.0]: https://github.com/rutledka/agent-workflow-scaffold/releases/tag/v1.2.0
[1.1.0]: https://github.com/rutledka/agent-workflow-scaffold/releases/tag/v1.1.0
[1.0.0]: https://github.com/rutledka/agent-workflow-scaffold/releases/tag/v1.0.0
