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

The skill will:

1. Detect whether the project already has any of the artifacts it would create (`CLAUDE.md`, `agents/`, `pm/`, `docs/dispatch-logs/`). If so, it asks before overwriting.
2. Ask four scoping questions: project name, project slug, GitHub repo, primary stack.
3. Ask whether to include the optional Backend / Frontend / QA personas (defaults to all three).
4. Generate the universal-subset files: `CLAUDE.md`, `agents/orchestrator.md` + chosen personas, `pm/backlog.md`, `pm/management.md`, `pm/roadmap.md`, `docs/README.md`, `docs/adr/0000-template.md`, `docs/dispatch-logs/.gitkeep`, `.gitignore`.
5. Ask follow-up questions specific to your stack (Zod / typecheck / migration policy / API spec / etc.) and add the answers to a "Project-specific rules" section in `CLAUDE.md`.
6. Bootstrap five starter memory entries about the workflow's conventions (worktree+PR discipline, worktrees-not-siblings, document version+history, decisions-via-ADR, prefer-concrete-comparisons).
7. Print a summary of what was written and the recommended next steps.

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
    ├── adr/
    │   └── 0000-template.md
    └── dispatch-logs/
        └── .gitkeep
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

The methodology is described in more depth in [`docs/workflow-philosophy.md`](./docs/workflow-philosophy.md).

---

## License

MIT — see [LICENSE](./LICENSE).
