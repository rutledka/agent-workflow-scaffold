# Project-local skills (`skills/`)

This directory holds **project-scoped, vendor-neutral skills** — knowledge committed to the repo and shared across the team. The directory path is intentionally not named `.claude/skills/` so the content is portable to other AI coding tools; Claude Code reads it via a `.claude/skills → ../skills` symlink the scaffold sets up in Step 4a.

The format inside each `<name>/SKILL.md` follows Claude Code's skill convention (YAML frontmatter with `name` + `description`, free-form markdown body). That format is the most-developed convention for this kind of content; other AI tools have their own equivalents (see "Cross-tool conventions" below) but they don't have to be duplicates — most users keep `skills/<name>/SKILL.md` as the canonical source and use per-tool aliases or refs as needed.

Project-local skills complement, not replace, user-scoped skills (in `~/.claude/skills/`) and Claude Code plugin skills (installed via `/plugin install`).

Use a project-local skill when the knowledge:

- Is specific to *this* project or one of its referenced codebases.
- Is non-obvious enough that a new contributor would benefit from explicit guidance.
- Belongs in version control because it changes over time alongside the code (versioned alongside the things it describes).
- Is too narrow in scope to belong in a user-scoped skill, but too project-specific to belong in a public skill.

## What lives here

The scaffold (Step 2b.7) drafts a project-local skill for any *referenced codebase* (see `pm/codebases.md`) where Q13 indicated niche tech / domain knowledge or where the scan surfaced patterns that aren't covered by the standard personas. Each codebase that warrants one gets its own subdirectory:

```
skills/
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

1. Create a directory under `skills/<your-skill-name>/`.
2. Author `SKILL.md` with YAML frontmatter (`name`, `description`) and the body content.
3. Add supporting files in the same directory if the skill needs reference material.
4. Commit the skill — it's intentionally version-controlled so contributors share the same context.

The scaffold's `templates/skills/codebase-skill-template/SKILL.md` is the canonical template for codebase-niche skills. For other skill types, the [Claude Code skill authoring guide](https://docs.claude.com/en/docs/claude-code/skills) is the reference.

## What to NOT put here

- **Generic engineering advice** — that belongs in `AGENTS.md` Project-specific rules.
- **Decisions and rationale** — that belongs in `docs/adr/`.
- **Per-task instructions** — that belongs in the ticket body in `pm/backlog.md`.
- **Personal productivity hacks** — those go in user-scoped skills at `~/.claude/skills/`, not here.

## Updating after a codebase scan re-run

Re-running `/agent-workflow-scaffold` on a project with existing local skills **will not overwrite them**. The re-run's Step 2b detects existing entries in `skills/` and surfaces a "drift detected — review?" prompt rather than clobbering. If you want a fresh scan-derived draft for a codebase whose skill has gotten stale, delete the codebase's subdirectory and re-run; the scaffold will produce a fresh starting point you can re-edit.

## Cross-tool conventions

Different AI coding tools have different conventions for project-local skills, rules, or instructions. The scaffold targets `skills/<name>/SKILL.md` because Claude Code's format is the most-developed; the table below documents how each tool finds project-local content for the team's adopted set (Q14 in the discovery interview).

| Tool | Reads `AGENTS.md` natively? | Project-local equivalent of `skills/` | How to wire (manual; not auto-created by Step 4a) |
|------|-----------------------------|---------------------------------------|---------------------------------------------------|
| **Claude Code** | No — uses `CLAUDE.md` (symlinked to `AGENTS.md`) | `skills/<name>/SKILL.md` (canonical) — found via `.claude/skills → ../skills` symlink (auto-created) | Already wired by Step 4a |
| **OpenCode** | ✅ Yes | `.opencode/agents/<name>.md` — full subagent definitions with frontmatter (`description`, `mode`, `permission`, `model`, `temperature`). Different concept from `skills/`. | Manually create `.opencode/agents/<name>.md` files where the OpenCode subagent shape is needed; reference `skills/<name>/SKILL.md` from the agent's body if content overlaps |
| **GitHub Copilot** | ✅ Yes (proximity-based precedence in repo tree) | `.github/instructions/<name>.instructions.md` — frontmatter with `applyTo` glob; different concept (path-targeted instructions, not full skills) | Step 4a creates `.github/copilot-instructions.md → ../AGENTS.md` for repo-wide. For path-specific, manually author `.github/instructions/*.instructions.md` files |
| **Cline** | ✅ Yes | `.clinerules/` directory of `.md` / `.txt` files (concatenated into instructions) | Manually create `.clinerules/from-skills.md` that references or mirrors content from `skills/`, OR symlink individual files |
| **Cursor** | ✅ Yes (recent versions) | `.cursor/rules/<name>.mdc` — frontmatter with `description`, `globs`, `alwaysApply`. Different concept. | Manually author `.cursor/rules/*.mdc` files; Cursor's frontmatter shape isn't directly compatible with `SKILL.md` |
| **Aider** | ❌ No auto-discovery | None — Aider only loads files explicitly listed in `.aider.conf.yml` `read:` or `/read` command | Step 4a appends `read: AGENTS.md` to `.aider.conf.yml`. For per-skill content, append more entries to the `read:` list pointing at `skills/<name>/SKILL.md` |
| **Continue** | ✅ Yes (recent versions) | `.continue/rules/<name>.md` (newer rules feature) and `.continue/config.json` for slash-commands | Manually author rule files where Continue-specific behavior is needed |

**Summary:** the canonical content for project-local skills lives at `skills/<name>/SKILL.md`. Most modern tools find AGENTS.md natively, so general instructions are shared automatically. For tool-specific *skill formats* (Cursor's `.mdc`, Copilot's `.instructions.md`, OpenCode's full agents), the scaffold doesn't try to auto-translate — the formats are different enough that translation can lose nuance. Where you need them, author them manually and reference the canonical `skills/<name>/SKILL.md` from the body.

If a tool you use isn't in the table, file a follow-up to add a row. The conventions are evolving; the table is updated when new tools adopt AGENTS.md or change their rule format.
