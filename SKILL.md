---
name: agent-workflow-scaffold
description: Scaffold a multi-agent workflow into a new or existing project — agent personas, PM artifacts (backlog/management/roadmap), CLAUDE.md rules, ADR + dispatch-log structure, and starter user memories. Triggered when the user wants to set up a multi-agent project, install agent personas, or bring this workflow methodology into a new repo. Asks the user a few scoping questions, then writes templated files into the repo and bootstraps memory. Designed to be `git submodule`'d or `curl`'d into projects.
---

# Agent Workflow Scaffold

You are scaffolding a multi-agent project workflow into the user's current working directory. The user invoked this skill because they want to bring a structured, persona-led, PM-driven engineering workflow into their project. Your job is to walk them through it, ask the minimum number of clarifying questions, generate the files, and stop.

## What this workflow gives the project

A repo that is set up so that:

- **Every task moves through a worktree → PR**, never directly to `main` (rules in `CLAUDE.md`).
- **Each role is a persona file in `agents/`** that you (Claude) can adopt as a system prompt — Orchestrator, Project Manager, Engineering Manager, Backend, Frontend, QA, plus optional ones the user picks.
- **The Orchestrator persona is a runnable dispatch loop** — it reads the backlog and open PRs, decides what each agent works on next, and writes a dispatch log to `docs/dispatch-logs/YYYY-MM-DD.md`. This is the keystone of the system.
- **PM artifacts live in `pm/`** — `backlog.md` (milestones / epics / tickets), `management.md` (RACI + decision log + risk register), `roadmap.md`. They cross-link to each other.
- **Decisions are captured as ADRs in `docs/adr/`**, not in chat or Slack. Every load-bearing decision gets a numbered ADR.
- **User memory is bootstrapped** with starter feedback entries about how this workflow operates, so future sessions inherit the discipline.

## Templates this skill ships with

This skill's repo contains a `templates/` directory. Each file is the source of truth for a generated artifact. Some files contain `{{PLACEHOLDER}}` tokens that you must substitute before writing into the user's project.

```
templates/
├── CLAUDE.md                          # universal rules subset
├── .gitignore                         # adds .worktrees/
├── agents/
│   ├── orchestrator.md                # the dispatch loop (most valuable)
│   ├── project-manager.md
│   ├── engineering-manager.md
│   ├── backend-engineer.md            # optional
│   ├── frontend-engineer.md           # optional
│   ├── qa-engineer.md                 # optional
│   └── README.md                      # how to add more personas
├── pm/
│   ├── backlog.md
│   ├── management.md
│   ├── roadmap.md
│   └── README.md
├── docs/
│   ├── README.md
│   ├── adr/0000-template.md           # ADR template
│   └── dispatch-logs/.gitkeep
└── memory/
    ├── MEMORY.md                      # index, with starter entries linked
    ├── feedback-worktrees-not-siblings.md
    ├── feedback-worktree-pr-discipline.md
    ├── feedback-document-version-history.md
    ├── feedback-decisions-via-adr.md
    └── user-prefer-concrete-comparisons.md
```

The skill repo is at the path where this `SKILL.md` lives — you'll find `templates/` as a sibling of this file.

## Procedure

When the user invokes you, follow these steps in order. Do not skip any.

### Step 1 — Detect context

Read the current working directory. Determine:

1. Is this a git repo already (`.git/` exists)? If not, recommend the user run `git init` first, but offer to scaffold anyway and remind them at the end.
2. Does the project already have any of `CLAUDE.md`, `agents/`, `pm/`, or `docs/dispatch-logs/`? If yes, **stop and ask the user how to proceed** — overwrite, merge, or abort. Don't blindly overwrite their existing artifacts.

### Step 2 — Ask the user the scoping questions

Ask all of these in a single message. Wait for the user's answers before generating anything.

**Required:**

1. **Project name** — used in document titles and headings. Example: "Acme Widgets".
2. **Project slug** — used in memory paths and identifiers. Example: `acme-widgets` (lowercase, hyphenated).
3. **GitHub repo** — `owner/repo` (e.g., `acme/widgets`). Used in the orchestrator persona for `gh` commands. If the project isn't on GitHub yet, the user can answer "none" and you'll skip the GitHub-specific lines.
4. **Primary stack** — short description of the runtime/language/framework. Examples: "Node 22 + TypeScript + NestJS + Postgres", "Python 3.12 + FastAPI + Redis", "Go + sqlc + Postgres". This is used to decide which **project-specific** rules to add to `CLAUDE.md` (see Step 4).

**Optional (default if the user doesn't specify):**

5. **Personas to include** — checkbox list. Mandatory and always included: Orchestrator, Project Manager, Engineering Manager. Optional: Backend Engineer, Frontend Engineer, QA Engineer. Default = all six.
6. **First milestone** — name and target. Example: "M0 Foundation, end of W3". Default = "M0 Foundation, target TBD".

### Step 3 — Confirm the plan, then generate the universal subset

When the user has answered, briefly confirm what you're about to do (one paragraph). Then generate the universal-subset files. For each file, read the template under `templates/`, substitute `{{PLACEHOLDERS}}`, and write to the user's project.

Files always written:

| Source | Destination | Substitutions |
|---|---|---|
| `templates/CLAUDE.md` | `<project>/CLAUDE.md` | `{{PROJECT_NAME}}`, `{{REPO_OWNER_REPO}}`, `{{PRIMARY_STACK}}` |
| `templates/.gitignore` | `<project>/.gitignore` *(or appended)* | none |
| `templates/agents/orchestrator.md` | `<project>/agents/orchestrator.md` | `{{PROJECT_NAME}}`, `{{REPO_OWNER_REPO}}`, `{{PROJECT_SLUG}}` |
| `templates/agents/project-manager.md` | `<project>/agents/project-manager.md` | `{{PROJECT_NAME}}`, `{{FIRST_MILESTONE_NAME}}`, `{{FIRST_MILESTONE_TARGET}}` |
| `templates/agents/engineering-manager.md` | `<project>/agents/engineering-manager.md` | `{{PROJECT_NAME}}`, `{{FIRST_MILESTONE_NAME}}` |
| `templates/agents/README.md` | `<project>/agents/README.md` | `{{PROJECT_NAME}}` |
| `templates/pm/backlog.md` | `<project>/pm/backlog.md` | `{{PROJECT_NAME}}`, `{{FIRST_MILESTONE_NAME}}`, `{{FIRST_MILESTONE_TARGET}}`, `{{TODAY_ISO}}` |
| `templates/pm/management.md` | `<project>/pm/management.md` | `{{PROJECT_NAME}}`, `{{TODAY_ISO}}` |
| `templates/pm/roadmap.md` | `<project>/pm/roadmap.md` | `{{PROJECT_NAME}}`, `{{FIRST_MILESTONE_NAME}}`, `{{FIRST_MILESTONE_TARGET}}` |
| `templates/pm/README.md` | `<project>/pm/README.md` | `{{PROJECT_NAME}}` |
| `templates/docs/README.md` | `<project>/docs/README.md` | `{{PROJECT_NAME}}` |
| `templates/docs/adr/0000-template.md` | `<project>/docs/adr/0000-template.md` | none |
| `templates/docs/dispatch-logs/.gitkeep` | `<project>/docs/dispatch-logs/.gitkeep` | none |

Files written conditionally (per Step 2 Q5):

- `templates/agents/backend-engineer.md` → if Backend Engineer selected
- `templates/agents/frontend-engineer.md` → if Frontend Engineer selected
- `templates/agents/qa-engineer.md` → if QA Engineer selected

### Step 4 — Ask follow-up questions to add **project-specific** rules to `CLAUDE.md`

The universal `CLAUDE.md` covers git workflow, branch naming, PR discipline, secrets safety, and other things that apply to any project. **Project-specific rules need user input.**

Based on the primary stack the user gave in Step 2 Q4, ask only the relevant questions. Examples:

- If stack mentions **Node / TypeScript**: "Should all route handlers validate inputs with Zod (or a similar schema library) before touching the database? (Y/n)" / "Forbid `console.log/warn/error` in `src/`? (Y/n)" / "Run `npm run typecheck && npm test` before pushing? (Y/n)"
- If stack mentions **Python**: "Forbid `print()` in source code; require structured logger? (Y/n)" / "Require type hints + mypy strict on changed files? (Y/n)"
- If stack mentions **Postgres / migrations**: "Should DB migrations be additive-only (no destructive column drops in a single PR)? (Y/n)"
- If stack mentions **API / REST / GraphQL**: "Must API contract changes update a spec document (e.g., `docs/api-specification.md`) in the same PR? (Y/n)"
- If stack mentions **Go**: "Run `go vet` and `go test ./...` before pushing? (Y/n)" / "Forbid `fmt.Println` in non-main packages? (Y/n)"

For each "yes" answer, append a one-line rule to the `## Project-specific rules` section at the bottom of `CLAUDE.md`. Reference the file path or tool the rule applies to. Keep each rule to one or two sentences — these are merge-blockers, not essays.

If the user is unsure about a question, default to "yes" (rules are easier to relax than to introduce later) and tell the user they can edit `CLAUDE.md` to remove a rule any time.

### Step 5 — Bootstrap memory

Memory paths are user-scoped, not repo-scoped. They live at:

```
~/.claude/projects/-Users-{{USER}}-...-{{PROJECT_SLUG}}/memory/
```

Claude Code resolves this path automatically based on the current working directory. **Do not write to a hard-coded user path.** Instead, write the memory files using the user's existing memory location for this project — invoke the standard memory mechanism by writing to whatever path the auto-memory section of your prompt indicates for the current cwd.

If the user has any existing memory entries already, do **not** overwrite them. Add the new starter entries **alongside** existing entries and update `MEMORY.md` to include both. If `MEMORY.md` doesn't exist, create it.

Starter entries to seed (read each from `templates/memory/` and copy verbatim, no substitutions needed):

| File | Type | Why it's seeded |
|---|---|---|
| `feedback-worktree-pr-discipline.md` | feedback | The single most important rule of this workflow — never commit to main |
| `feedback-worktrees-not-siblings.md` | feedback | Worktrees go inside `.worktrees/`, not as a sibling of the repo |
| `feedback-document-version-history.md` | feedback | Every doc has a version + history table at the bottom |
| `feedback-decisions-via-adr.md` | feedback | Load-bearing decisions go to `docs/adr/`, not chat |
| `user-prefer-concrete-comparisons.md` | user | When the user asks "should we use X?", offer a comparison table, not just a yes/no |

Update `MEMORY.md` to list all five with one-line descriptions.

### Step 6 — Print next-step instructions to the user

After all writes complete, output a summary message to the user with these sections:

```
## Scaffolding complete

Files written:
  <list every path you wrote, with relative paths>

Memory bootstrapped:
  <list the memory entries seeded>

## Next steps

1. Review CLAUDE.md and edit any rule you want to relax. The Project-specific rules section
   at the bottom is where you tweak.
2. Open agents/orchestrator.md and confirm the GitHub repo + branch-prefix rows match
   your project. Adjust if needed.
3. Open pm/backlog.md and replace the placeholder M0 milestone with your real first
   milestone. Add your first epic.
4. Commit the scaffolded files: git add . && git commit -m "scaffold: agent workflow"
   Don't push yet — review the diff first.
5. Once you've populated at least one epic and one ticket in pm/backlog.md, you can run
   the orchestrator dispatch loop by invoking Claude with the orchestrator persona.

To re-run this scaffold (e.g., after a major project pivot), invoke this skill again — it
will detect existing files and ask before overwriting.
```

Stop. Do not proceed to do additional work unless the user asks.

## Working principles for this skill

- **Don't overwrite without asking.** This is the user's project — Step 1 detection is mandatory.
- **Don't dump every file in a wall of writes.** Confirm the plan in Step 3, then generate. The user can interrupt.
- **Don't add rules to CLAUDE.md that the user didn't agree to.** Step 4's questions matter — silent additions break trust.
- **Don't substitute placeholders blindly.** If the user said "none" for the GitHub repo, comment out the GitHub-specific lines in `orchestrator.md` rather than leaving "none/none" in there.
- **Read the templates fresh each invocation.** Templates may have been updated since the last time the skill was run; don't cache.
- **Stop when done.** Don't proactively suggest follow-up work the user didn't ask for.
