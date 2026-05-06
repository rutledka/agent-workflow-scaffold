# agent-workflow-scaffold

A Claude Code skill that scaffolds a multi-agent project workflow into any new or existing repo. Drop it into a project, invoke `/agent-workflow-scaffold`, answer four questions, and the skill writes a `CLAUDE.md`, a set of agent persona files in `agents/`, PM artifacts in `pm/`, an ADR + dispatch-log structure in `docs/`, and bootstraps user-scoped memory with starter preferences.

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

Add the skill as a submodule under the project's `.claude/skills/` directory:

```bash
cd <your-project>
git submodule add git@github.com:rutledka/agent-workflow-scaffold.git .claude/skills/agent-workflow-scaffold
git commit -m "tooling: add agent-workflow-scaffold skill"
```

The skill is now scoped to that project and version-controlled with it. Updates to the skill are pulled in by `git submodule update --remote`.

### Option 3 — Project-scoped via `curl`

If you don't want a submodule, copy the skill into the project once:

```bash
cd <your-project>
mkdir -p .claude/skills
curl -L https://github.com/rutledka/agent-workflow-scaffold/archive/refs/heads/main.tar.gz \
  | tar -xz -C .claude/skills/ --strip-components=1 --one-top-level=agent-workflow-scaffold
```

This snapshots the skill at a point in time. Updates require re-running the curl.

---

## Use

Once installed, invoke the skill from inside the project you want to scaffold:

```
/agent-workflow-scaffold
```

The skill is **discovery-driven**. It does not generate a fixed set of personas by default — instead it interviews you about your role and work, then proposes a tailored persona set you confirm before any files are written.

1. **Detect** whether the project already has any of the artifacts it would create (`CLAUDE.md`, `agents/`, `pm/`, `docs/dispatch-logs/`). If so, it asks before overwriting.
2. **Discovery interview** — one message of 11 questions covering: your role + decisions you own, daily work + recent task examples + recurring pain points, project name + slug + GitHub repo + primary stack, collaborators, active tools, specialty workflows, first milestone. You skip whatever doesn't apply.
3. **Synthesize a proposal** — based on your answers, propose 3–7 personas tailored to your work (citing the discovery answer that triggered each), plus a shortlist of trusted MCP integrations and Claude Code skills that fit. You confirm or edit before any writes happen. Off-the-shelf templates exist for Backend / Frontend / QA / Platform / Designer / Legal / Pilot Lead / Project Manager / Engineering Manager / Orchestrator; off-list roles get authored from a `custom-skeleton.md`.
4. **Generate the universal subset and confirmed personas** — only what you agreed to. A solo founder might end up with 3 personas; a 12-person team might end up with 11.
5. **Project-specific rules** — stack-specific follow-ups (Zod / typecheck / migration policy / API spec / etc.) appended to `CLAUDE.md`'s "Project-specific rules" section.
6. **MCP integrations** — for each confirmed integration, flips `_enabled: true` in `.mcp.example.json`, optionally copies it to `.mcp.json` (gitignored) on consent, copies `docs/integrations.md` into the project, and notes the integration in `agents/orchestrator.md`. OAuth happens on first use of each MCP. The list is restricted to vendor-published, OAuth-secured MCPs — see [`templates/integrations.md`](./templates/integrations.md) for the trust criteria.
7. **Skills — install or coach** — reads each generated persona's `required_skills:` frontmatter, cross-references [`templates/docs/skills-registry.md`](./templates/docs/skills-registry.md), and acts:
   - **Git skills** → `git clone` into `~/.claude/skills/` or `.claude/skills/` (single batched consent prompt).
   - **Plugin skills** → coach you through `/plugin install <plugin>` from inside Claude Code (slash commands aren't safely scriptable).
   - **Built-in skills** → already installed; nothing to do.
   - **Private skills** → print the placeholder install URL and tell you to substitute the team's URL.
8. **Bootstrap memory** — six starter entries: workflow conventions (worktree+PR discipline, worktrees-not-siblings, document version+history, decisions-via-ADR, prefer-concrete-comparisons) plus a `user-role-profile.md` derived from your discovery answers, so future scaffold runs (in other projects) can suggest personas faster.
9. **Print a summary** — personas generated, files written, MCPs enabled, skills installed / pending / coaching-needed, and next steps.

Re-running the skill on the same project re-detects existing files and asks before overwriting — so it's safe to run again after a major project pivot.

---

## What you get — file map

```
<your-project>/
├── CLAUDE.md                          # universal rules + your project-specific rules
├── .gitignore                         # adds .worktrees/ if not already present
├── agents/
│   ├── orchestrator.md                # the runnable dispatch loop (the keystone)
│   ├── project-manager.md
│   ├── engineering-manager.md
│   ├── backend-engineer.md            # if selected
│   ├── frontend-engineer.md           # if selected
│   ├── qa-engineer.md                 # if selected
│   └── README.md
├── pm/
│   ├── backlog.md                     # milestones / epics / tickets
│   ├── management.md                  # exec summary / RACI / decision log / risk register
│   ├── roadmap.md
│   └── README.md
└── docs/
    ├── README.md
    ├── integrations.md                # if any MCP integration was enabled
    ├── skills-registry.md             # known Claude Code skills + install commands
    ├── adr/
    │   └── 0000-template.md
    └── dispatch-logs/
        └── .gitkeep

# `agents/` only contains the personas the discovery interview produced —
# typically 3–7 of the eleven off-the-shelf templates plus any custom roles.
# Solo projects may have only 3; team projects may have all 11.

# plus, at the repo root, if any integration was enabled:
.mcp.example.json                      # example MCP server config (committed)
.mcp.json                              # active config (gitignored; user creates from example)
```

Plus user-scoped memory at `~/.claude/projects/<your-project-slug>/memory/`:

- `MEMORY.md` (index)
- `feedback-worktree-pr-discipline.md`
- `feedback-worktrees-not-siblings.md`
- `feedback-document-version-history.md`
- `feedback-decisions-via-adr.md`
- `user-prefer-concrete-comparisons.md`

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
