# Project-local skills (`.claude/skills/`)

This directory holds **project-scoped Claude Code skills** — skills that are committed to the repo and become available to any contributor running Claude Code inside this project. They complement, not replace, user-scoped skills (in `~/.claude/skills/`) and Claude Code plugin skills (installed via `/plugin install`).

Use a project-local skill when the knowledge:

- Is specific to *this* project or one of its referenced codebases.
- Is non-obvious enough that a new contributor would benefit from explicit guidance.
- Belongs in version control because it changes over time alongside the code (versioned alongside the things it describes).
- Is too narrow in scope to belong in a user-scoped skill, but too project-specific to belong in a public skill.

## What lives here

The scaffold (Step 2b.7) drafts a project-local skill for any *referenced codebase* (see `pm/codebases.md`) where Q13 indicated niche tech / domain knowledge or where the scan surfaced patterns that aren't covered by the standard personas. Each codebase that warrants one gets its own subdirectory:

```
.claude/skills/
├── README.md                        — this file
├── <codebase-slug>/
│   ├── SKILL.md                     — frontmatter + niche knowledge + gotchas
│   └── (supporting files, if any)
└── <other-codebase-slug>/
    ├── SKILL.md
    └── …
```

You can also add **non-codebase project-local skills** here for any topic that benefits from focused, in-repo guidance. Common patterns:

- A `release-process/` skill that walks an agent through the project's release runbook.
- An `incident-response/` skill that codifies the on-call playbook.
- A `regulatory-compliance/` skill for projects with specific compliance requirements (HIPAA, PCI-DSS, GDPR-DPIA workflows).

## How personas use these

Every generated persona file in `agents/` includes a **Before starting work** section instructing it to check this directory for matching local skills *before* doing anything else. The instruction is universal across personas — Backend, Frontend, QA, etc. all check for and load matching local skills before touching code.

The Claude Code skill loader uses the `description:` field in each skill's frontmatter to decide when to load it. Make descriptions specific (path mentions, niche tech keywords, "load before any task touching X") so the loader matches reliably.

## Adding a new project-local skill

1. Create a directory under `.claude/skills/<your-skill-name>/`.
2. Author `SKILL.md` with YAML frontmatter (`name`, `description`) and the body content.
3. Add supporting files in the same directory if the skill needs reference material.
4. Commit the skill — it's intentionally version-controlled so contributors share the same context.

The scaffold's `templates/.claude/skills/codebase-skill-template/SKILL.md` is the canonical template for codebase-niche skills. For other skill types, the [Claude Code skill authoring guide](https://docs.claude.com/en/docs/claude-code/skills) is the reference.

## What to NOT put here

- **Generic engineering advice** — that belongs in `CLAUDE.md` Project-specific rules.
- **Decisions and rationale** — that belongs in `docs/adr/`.
- **Per-task instructions** — that belongs in the ticket body in `pm/backlog.md`.
- **Personal productivity hacks** — those go in user-scoped skills at `~/.claude/skills/`, not here.

## Updating after a codebase scan re-run

Re-running `/agent-workflow-scaffold` on a project with existing local skills **will not overwrite them**. The re-run's Step 2b detects existing entries in `.claude/skills/` and surfaces a "drift detected — review?" prompt rather than clobbering. If you want a fresh scan-derived draft for a codebase whose skill has gotten stale, delete the codebase's subdirectory and re-run; the scaffold will produce a fresh starting point you can re-edit.
