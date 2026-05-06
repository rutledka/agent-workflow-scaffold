# agent-workflow-scaffold

A Claude Code skill that scaffolds a multi-agent project workflow into any new or existing repo. Drop it into a project, invoke `/agent-workflow-scaffold`, answer a short discovery interview, and the skill writes an `AGENTS.md` (with a `CLAUDE.md` symlink for Claude Code), a set of agent persona files in `agents/`, PM artifacts in `pm/`, an ADR + dispatch-log structure in `docs/`, project-local skills under `skills/`, and bootstraps user-scoped memory with starter preferences.

The methodology this skill encodes is opinionated. It assumes:

- **Every task ships through a worktree → PR**, never a direct commit to `main`.
- **Roles are personas**, defined as system prompts in `agents/<role>.md`, not just tagged labels.
- **A runnable Orchestrator persona** dispatches work each cycle: reads the backlog, triages open PRs, decides what each agent works on next, writes a dispatch log.
- **The backlog is the source of truth for delivery**, the management plan is for leadership, the roadmap is for stakeholders. Three documents, three audiences.
- **Load-bearing decisions live in numbered ADRs** under `docs/adr/`, not in chat history.
- **User memory carries the workflow's discipline forward** across sessions.

If that matches how you want to work, this skill gives you a working scaffold in one invocation.

---

## Install

You have three install options. Pick whichever matches how the project consumes external tooling.

### Option 1 — User-scoped (available in every project)

Clone the repo into your user-scoped Claude Code skills directory:

```bash
git clone git@github.com:rutledka/agent-workflow-scaffold.git ~/.claude/skills/agent-workflow-scaffold
```

The skill is now available in every Claude Code session as `/agent-workflow-scaffold`.

### Option 2 — Project-scoped via `git submodule`

Add the skill as a submodule under the project's `skills/` directory (the canonical, vendor-neutral path), then create the `.claude/skills → ../skills` symlink so Claude Code finds it:

```bash
cd <your-project>
git submodule add git@github.com:rutledka/agent-workflow-scaffold.git skills/agent-workflow-scaffold
mkdir -p .claude && [ -e .claude/skills ] || ln -s ../skills .claude/skills
git add skills/agent-workflow-scaffold .claude/skills .gitmodules
git commit -m "tooling: add agent-workflow-scaffold skill"
```

The skill is now scoped to that project and version-controlled with it. Updates to the skill are pulled in by `git submodule update --remote`.

### Option 3 — Project-scoped via `curl`

If you don't want a submodule, copy the skill into the project once:

```bash
cd <your-project>
mkdir -p skills
curl -L https://github.com/rutledka/agent-workflow-scaffold/archive/refs/heads/main.tar.gz \
  | tar -xz -C skills/ --strip-components=1 --one-top-level=agent-workflow-scaffold
mkdir -p .claude && [ -e .claude/skills ] || ln -s ../skills .claude/skills
```

This snapshots the skill at a point in time. Updates require re-running the curl.

> **Why `skills/` and not `.claude/skills/` directly?** The scaffold's methodology treats `skills/` as the canonical, vendor-neutral path for project-local skills; `.claude/skills` is a symlink to it so Claude Code's loader works without forcing a tool-specific directory name. Installing the scaffold to `.claude/skills/` directly works in the moment but breaks the convention — when you later run the scaffold and it tries to set up `.claude/skills → ../skills`, the directory already exists and the symlink isn't created, leaving `.claude/skills/` (containing the scaffold) split from `skills/` (containing the project-local skills the scaffold creates). The two-step install above keeps the layout consistent from day one.

### Uninstall

To remove the artifacts a scaffold run produced in a project (agents/, pm/, the registry files in docs/, .mcp config, the .claude/skills symlink, and the AGENTS.md/CLAUDE.md pair), run:

```bash
cd <your-scaffolded-project>
bash <path-to-scaffold>/uninstall.sh
```

The script lists what it would remove, asks for confirmation, runs in a worktree, and opens a PR so you can review the diff before merging. It restores a user-authored CLAUDE.md if Step 4's merge had preserved one. ADR files in `docs/adr/00NN-*.md` and any hand-authored docs are never touched.

Flags: `--dry-run` (preview), `--keep-pm` / `--keep-docs` / `--keep-skills` / `--keep-personas` / `--keep-mcp` / `--keep-claude-md` (granular preservation), `--remove-memory` (also clean up user-scoped memory entries), `--no-pr` (stop at commits in worktree), `--yes` (skip the confirm prompt). See `bash uninstall.sh --help` for details.

---

## Use

Once installed, invoke the skill from inside the project you want to scaffold:

```
/agent-workflow-scaffold
```

The skill is **discovery-driven**. It does not generate a fixed set of personas by default — instead it interviews you about your role and work, then proposes a tailored persona set you confirm before any files are written.

1. **Detect** whether the project already has any of the artifacts it would create (`CLAUDE.md`, `agents/`, `pm/`, `docs/dispatch-logs/`). If so, it asks before overwriting.
2. **Discovery interview** — one message covering: your role + decisions you own, daily work + recent task examples + recurring pain points, project name + slug + GitHub repo + primary stack, collaborators, active tools, specialty workflows, first milestone, **the codebases you work in (single / multiple / monorepo, with paths, plus any tech distinct enough to warrant its own persona)**, and which AI coding tools the team uses (so the scaffold wires per-tool symlinks/configs). You skip whatever doesn't apply.
3. **Codebase setup (Step 2b)** — for each codebase you listed, the scaffold verifies the path, confirms it's a git repo, **auto-detects the base branch** (`main` / `master` / `dev` / `develop`), establishes the **user's feature branch** as the agent PR target (creates it on consent so agents never push to base directly), and **scans the codebase for technology inventory** by reading `package.json` / `pyproject.toml` / `Gemfile` / `go.mod` / `Cargo.toml` / lock files / Dockerfiles / Terraform / GitHub workflows. Cross-references against `docs/feature-overlap-registry.md` to find pairs of libraries with significant overlap, computes install-date gaps, and **asks about deprecation** when the gap exceeds a year.
4. **Synthesize a proposal** — based on the discovery answers + codebase scans, propose 3–7 personas tailored to your work (citing the discovery answer that triggered each), plus a shortlist of trusted MCP integrations, Claude Code skills, and a per-codebase plan (paths, base branches, feature branches, tech inventories, deprecation notes, owning personas, drafted project-local skills). You confirm or edit before any writes happen. Off-the-shelf templates exist for Backend / Frontend / QA / Platform / Designer / Legal / Pilot Lead / Project Manager / Engineering Manager / Orchestrator; off-list **roles** (e.g. Growth Lead, ML Researcher) get authored from a `custom-skeleton.md`. **Niche codebase knowledge** does *not* become a custom persona — it goes into a project-local skill at `skills/<codebase-slug>/SKILL.md` that the standard owning persona loads before starting work. Personas describe roles; skills describe technical knowledge.
5. **Generate the universal subset and confirmed personas** — only what you agreed to. A solo founder might end up with 3 personas; a 12-person team might end up with 11. Each persona owning a registered codebase has the codebase's tech-doc URLs auto-injected into its Key References section and the codebase's confirmed deprecation notes auto-injected into its Working patterns section.
6. **Project-specific rules** — stack-specific follow-ups (Zod / typecheck / migration policy / API spec / etc.) appended to `CLAUDE.md`'s "Project-specific rules" section. **Plus the multi-codebase PR rule** when at least one external codebase was registered: agents target the user's feature branch, never the codebase's base branch.
7. **MCP integrations** — for each confirmed integration, flips `_enabled: true` in `.mcp.example.json`, optionally copies it to `.mcp.json` (gitignored) on consent, copies `docs/integrations.md` into the project, and notes the integration in `agents/orchestrator.md`. OAuth happens on first use of each MCP. The list is restricted to vendor-published, OAuth-secured MCPs — see [`templates/integrations.md`](./templates/integrations.md) for the trust criteria.
8. **Skills — install or coach** — reads each generated persona's `required_skills:` frontmatter, cross-references [`templates/docs/skills-registry.md`](./templates/docs/skills-registry.md), and acts:
   - **Git skills** → `git clone` into `~/.claude/skills/` or `.claude/skills/` (single batched consent prompt).
   - **Plugin skills** → coach you through `/plugin install <plugin>` from inside Claude Code (slash commands aren't safely scriptable).
   - **Built-in skills** → already installed; nothing to do.
   - **Private skills** → print the placeholder install URL and tell you to substitute the team's URL.
9. **Bootstrap memory** — seven starter entries: workflow conventions (worktree+PR discipline, worktrees-not-siblings, document version+history, decisions-via-ADR, sub-agent write permissions, prefer-concrete-comparisons) plus a `user-role-profile.md` derived from your discovery answers, so future scaffold runs (in other projects) can suggest personas faster.
10. **Print a summary** — personas generated, codebases registered, files written, MCPs enabled, skills installed / pending / coaching-needed, and next steps.

Re-running the skill on the same project re-detects existing files, **re-runs the codebase scans** (catching new lockfile entries and new deprecation candidates), and asks before overwriting — so it's safe to run again after a major project pivot or after adding a new codebase.

---

## What you get — file map

```
<your-project>/
├── AGENTS.md                          # universal rules + your project-specific rules.
│                                      #   Vendor-neutral filename per the agents.md convention.
├── CLAUDE.md → AGENTS.md              # symlink — Claude Code reads CLAUDE.md; the symlink
│                                      #   resolves to AGENTS.md. Other AI coding tools can
│                                      #   point their convention at AGENTS.md too.
├── .gitignore                         # adds .worktrees/ if not already present
├── agents/                            # persona definitions — one .md per role
│   ├── orchestrator.md                # the runnable dispatch loop (the keystone)
│   ├── personal-assistant.md          # proposed by default; opt-out — goal tracker + read-only signals
│   ├── project-manager.md             # if proposed in Step 3
│   ├── engineering-manager.md         # if proposed
│   ├── backend-engineer.md            # if proposed
│   ├── frontend-engineer.md           # if proposed
│   ├── qa-engineer.md                 # if proposed
│   ├── platform-engineer.md           # if proposed
│   ├── product-designer.md            # if proposed
│   ├── legal-advisor.md               # if proposed
│   ├── pilot-lead.md                  # if proposed
│   └── README.md
├── pm/
│   ├── backlog.md                     # rich source of truth (Mode C) OR pointer doc (Modes A/B)
│   ├── management.md                  # exec summary / RACI / decision log / risk register
│   ├── roadmap.md
│   ├── codebases.md                   # if any external codebase was registered
│   ├── goals.md                       # if Personal Assistant was confirmed
│   ├── assistant-log.md               # if Personal Assistant was confirmed
│   └── README.md
├── docs/
│   ├── README.md
│   ├── integrations.md                # if any MCP integration was enabled
│   ├── skills-registry.md             # known agent skills + install commands
│   ├── tech-docs-registry.md          # library / framework → official docs URL
│   ├── feature-overlap-registry.md    # overlapping libs → deprecation candidates
│   ├── subagents-registry.md          # persona → VoltAgent plugin / sub-agent mapping
│   ├── adr/
│   │   └── 0000-template.md
│   └── dispatch-logs/
│       └── .gitkeep
├── skills/                            # project-local skills (vendor-neutral path)
│   ├── README.md
│   ├── <codebase-slug>/               # if any codebase warranted a local skill (Step 2b.7)
│   │   └── SKILL.md
│   └── pm-<tool>-<slug>/              # if Mode A/B configured a PM-tool skill (Step 5b)
│       └── SKILL.md
└── .claude/
    └── skills → ../skills             # symlink — Claude Code's skill loader reads
                                       #   .claude/skills/; the symlink redirects to skills/.
                                       #   Other AI tools can read skills/ directly.

# plus, at the repo root, if any integration was enabled:
.mcp.example.json                      # example MCP server config (committed)
.mcp.json                              # active config (gitignored; user creates from example)
.env.example                           # if Step 5b-API wired a PAT-based PM tool
.env                                   # gitignored; user fills in token values

# `agents/` only contains the personas the discovery interview produced —
# typically 3–7 of the eleven off-the-shelf templates plus any custom roles.
# Solo projects may have only 3; team projects may have all 11.
#
# AGENTS.md is the source; CLAUDE.md is a symlink. If you adopt another
# AI coding tool (Cursor, Cline, Aider, etc.) later, point its convention
# at AGENTS.md instead of maintaining a parallel file.
#
# skills/ is the vendor-neutral path; .claude/skills is a symlink. Same
# pattern as AGENTS.md — Claude Code's loader reads .claude/skills/, but
# the content lives at the platform-agnostic location.
```

Plus user-scoped memory at `~/.claude/projects/<your-project-slug>/memory/`:

- `MEMORY.md` (index)
- `feedback-worktree-pr-discipline.md`
- `feedback-worktrees-not-siblings.md`
- `feedback-document-version-history.md`
- `feedback-decisions-via-adr.md`
- `feedback-subagent-write-permissions.md`
- `user-prefer-concrete-comparisons.md`
- `user-role-profile.md` — generated from your discovery answers; portable across projects
- `personal-assistant-context.md` — only if the Personal Assistant persona was confirmed in Step 3

---

## The keystone: the Orchestrator persona

The single most useful thing this skill produces is `agents/orchestrator.md`. It's a runnable dispatch loop with explicit steps:

1. Sync `main` and read `CLAUDE.md`.
2. Read the backlog and roadmap; extract current milestone, next milestone, per-agent ticket ownership.
3. Fetch all open PRs and their review comments. Classify review items as HIGH / MEDIUM / LOW.
4. For each agent, run a strict-priority decision tree: address HIGH review items → check PR cap → start next unblocked ticket.
5. Dispatch sub-agents to do the work, with each sub-agent reading the persona file and following CLAUDE.md.
6. Write a dispatch log to `docs/dispatch-logs/YYYY-MM-DD.md` and open a PR for it.

The orchestrator is what turns "we have agent personas" into "we have an executable workflow." Without it, the personas are decorative.

---

## Sub-agents — VoltAgent integration

Each generated persona ships with an **Available sub-agents for delegation** section pointing at matching sub-agents in the [VoltAgent awesome-claude-code-subagents](https://github.com/VoltAgent/awesome-claude-code-subagents) plugin marketplace (10 category plugins, 141 sub-agents). The two layers stack cleanly:

- **Personas** describe **roles** — Backend Engineer, QA Engineer, Engineering Manager. Generated from the discovery interview; live in `agents/*.md`.
- **Sub-agents** describe **technology specializations** — `python-pro`, `kubernetes-specialist`, `accessibility-tester`. Installed via `claude plugin install`; dispatched by personas when work calls for deep specialization.

The mapping (which plugins each persona suggests, which specific sub-agents it lists) is documented in [`templates/docs/subagents-registry.md`](./templates/docs/subagents-registry.md) and copied into every scaffolded project as `docs/subagents-registry.md`.

The scaffold **does not auto-install** the marketplace plugins — they're user-globally persistent and `claude` CLI plugin auth may not be set up at scaffold time. Step 7h instead surfaces the install plan with a copy-paste-ready batch:

```bash
claude plugin marketplace add VoltAgent/awesome-claude-code-subagents
claude plugin install voltagent-core-dev voltagent-lang voltagent-qa-sec voltagent-meta
```

Re-runs of the scaffold reconcile the install plan against the (possibly updated) persona set and surface a delta — newly required plugins, plugins no longer required.

### Migrating a v1.0.0-scaffolded project to pick up the sub-agents wiring

Two paths:

1. **Re-run `/agent-workflow-scaffold`.** Step 1.5 detectors D10 + D11 detect missing `docs/subagents-registry.md` and missing **Available sub-agents for delegation** sections in `agents/*.md`, and present the migration plan inside a worktree-and-PR.
2. **Run the standalone migration script** for a one-shot bash invocation:

   ```bash
   cd <your-project>
   bash <path-to-scaffold>/scripts/migrate-personas-to-voltagent-subagents.sh
   ```

   The script appends the section verbatim from the scaffold templates for off-the-shelf personas, copies `docs/subagents-registry.md` if missing, runs in a worktree, and opens a PR. Custom personas are listed for manual editing against the registry's keyword index. Idempotent — re-running on an already-migrated project exits with "no migration needed."

Flags: `--no-pr` (stop at commits in worktree), `--dry-run` (preview without writes).

---

## Migrating an older scaffold

If your project was scaffolded against an older version of this skill, the layout has likely drifted from current conventions — `CLAUDE.md` may be a regular file rather than a symlink to `AGENTS.md`, `.claude/skills/` may be a real directory rather than a symlink to `../skills/`, persona files may lack the `required_skills:` frontmatter, or registry files (`docs/skills-registry.md`, `docs/tech-docs-registry.md`, `docs/feature-overlap-registry.md`) and `pm/codebases.md` may be missing entirely.

**Re-invoke `/agent-workflow-scaffold` from inside the project.** The skill's **Step 1.5 — Detect drift** runs a per-item drift scan and presents a migration plan you confirm before any writes. The migration:

- Runs inside a worktree (per the scaffold's own discipline) and opens a PR — nothing lands directly on `main`.
- Stages each drift fix as a separate commit (`D1: rename CLAUDE.md → AGENTS.md + symlink`, `D2: move .claude/skills → skills/ + symlink`, etc.) so you can review per-item.
- Preserves git history (`git mv` for renames; persona body content is preserved verbatim when frontmatter is prepended).
- Is idempotent — running on a fully-migrated project detects no drift and skips Step 1.5 entirely.

You can also pick which fixes to apply (`migrate D1 D2 D3`), skip migration to layer new work onto the existing artifacts (`skip` — drift surfaced in the Step 9 summary so you don't lose it), or abort and resolve manually.

### Existing CLAUDE.md content is preserved

The scaffold also handles a third case the migration mode used to gloss over: a project where the user authored their own `CLAUDE.md` rules without ever running this scaffold. Step 4's **AGENTS.md merge** detects pre-existing user content (in either `CLAUDE.md` or `AGENTS.md`) and writes the new file as:

```
<scaffold's universal sections — Repository, Git Workflow, Project Structure, Key Documents>

---

## Existing project rules (preserved from CLAUDE.md)

<the user's prior content, verbatim — no reformatting, no reordering>
```

The scaffold's universal sections come first because they're load-bearing for the workflow's git discipline; the user's existing rules are preserved under a clearly-marked heading. If the existing file already contains the scaffold's universal sections (a previously-rendered scaffold output, or a hand-port of it), the merge is skipped entirely — re-running the scaffold is idempotent.

---

## Customization

The scaffold is opinionated by design — it ships the patterns the methodology actually relies on, not a config-explosion of toggles. To customize:

- **Add a persona**: copy any persona file in `agents/`, edit the role and working patterns, add it to the Agent role map in `orchestrator.md`.
- **Tighten or relax a rule**: edit `CLAUDE.md`. The "Project-specific rules" section at the bottom is where most edits go.
- **Change the dispatch loop**: edit `agents/orchestrator.md`. The decision tree (review > cap > unblocked) is the load-bearing part; everything else can be reshaped.

If you find yourself fighting the scaffold, fork it. The methodology is more useful as a starting point than as a constraint.

---

## Why this exists

Multi-agent workflows fail in predictable ways: drift between documents, decisions that evaporate, the same trade-off re-litigated every quarter, agents stepping on each other's branches, "who owns this?" with no answer. This scaffold encodes the patterns that prevented those failures on the project it was extracted from.

The methodology is described in more depth in [`docs/workflow-philosophy.md`](./docs/workflow-philosophy.md). The trusted-MCP integration policy is in [`docs/integrations.md`](./docs/integrations.md).

---

## License

MIT — see [LICENSE](./LICENSE).
