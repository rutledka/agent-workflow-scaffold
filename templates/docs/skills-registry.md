# Skills registry

Personas in `agents/*.md` declare the Claude Code skills they depend on via the `required_skills:` YAML frontmatter at the top of each persona file. This registry is the canonical lookup the scaffold uses to translate a skill name into an install command.

> Personas without skill dependencies leave `required_skills: []`. The scaffold's Step 4c (in the upstream `agent-workflow-scaffold/SKILL.md`) reads each persona's frontmatter, cross-references this registry, checks the user's installed skills, and prompts for any missing.

## Where Claude Code looks for skills

Skills resolve from three locations, in order:

1. **Claude Code plugin marketplace** — namespaced like `<plugin>:<skill>` (e.g. `figma:figma-use`). Installed via `/plugin install <plugin>` from inside Claude Code.
2. **User-scoped:** `~/.claude/skills/<skill-name>/` — available in every Claude Code session for that user. Typically a `git clone` of a skill repo.
3. **Project-scoped:** `.claude/skills/<skill-name>/` (relative to repo root) — committed with the project, available only when running inside the project. Usually a `git submodule` or `git clone`.

Claude Code automatically lists available skills in every session's system prompt. If a persona's `required_skills` entry doesn't appear there, it isn't installed.

## How to read a registry entry

Each entry below has:

- **Name** — the exact string that goes in `required_skills:` and the string Claude Code surfaces in `<available-skills>`.
- **Source** — `plugin` (Claude Code marketplace plugin), `git` (clone or submodule from a public repo), `builtin` (ships with Claude Code; nothing to install), or `private` (lives in a non-public location; the team handles distribution itself).
- **Install** — the canonical command. Pick `user` (clone to `~/.claude/skills/`) or `project` (submodule into `.claude/skills/`) flavor as appropriate.
- **Docs** — link to the skill's source / docs.

## Registry

### `agent-workflow-scaffold`

The scaffold itself — the source of these personas. A persona that wants to re-run the scaffold (e.g. to add another role) declares this skill.

- **Source:** git
- **Install (user-scoped):**
  ```sh
  git clone git@github.com:rutledka/agent-workflow-scaffold.git \
    ~/.claude/skills/agent-workflow-scaffold
  ```
- **Install (project-scoped, recommended for teams):**
  ```sh
  git submodule add git@github.com:rutledka/agent-workflow-scaffold.git \
    .claude/skills/agent-workflow-scaffold
  git commit -m "tooling: add agent-workflow-scaffold skill"
  ```
- **Docs:** <https://github.com/rutledka/agent-workflow-scaffold>

### `figma:figma-use`

Mandatory prerequisite before invoking the `use_figma` MCP tool. Loads guidance for executing JS in the Figma plugin context (create / edit / delete nodes, set variables, build components, modify auto-layout).

- **Source:** plugin (`figma`)
- **Install:** Inside Claude Code: `/plugin install figma`
- **Docs:** <https://github.com/figma/code-connect> and the `figma` Claude Code plugin marketplace listing

### `figma:figma-implement-design`

Translates Figma designs into production code with 1:1 visual fidelity. Triggers on phrases like "implement design", "generate code from Figma", or when the user pastes a Figma URL.

- **Source:** plugin (`figma`)
- **Install:** `/plugin install figma`
- **Docs:** Figma plugin marketplace listing

### `figma:figma-generate-design`

Inverse of `figma-implement-design` — pushes app code into Figma as a screen / page / multi-section view. Use alongside `figma-use` when "writing to Figma."

- **Source:** plugin (`figma`)
- **Install:** `/plugin install figma`

### `figma:figma-code-connect`

Authors and maintains Code Connect template files (`*.figma.ts`) that map Figma components to code snippets.

- **Source:** plugin (`figma`)
- **Install:** `/plugin install figma`

### `figma:figma-generate-diagram`

Mandatory prerequisite before invoking the `generate_diagram` tool. Routes to type-specific guidance (generic flowchart, architecture flowchart, etc.).

- **Source:** plugin (`figma`)
- **Install:** `/plugin install figma`

### `figma:figma-generate-library`

Builds or updates a design system in Figma from a codebase — variables / tokens / component variants / theming. Pairs with `figma-use`.

- **Source:** plugin (`figma`)
- **Install:** `/plugin install figma`

### `figma:figma-create-design-system-rules`

Generates custom design-system rules tailored to a codebase. Used once per project to establish project-specific conventions for Figma-to-code workflows.

- **Source:** plugin (`figma`)
- **Install:** `/plugin install figma`

### `figma:figma-use-figjam`

FigJam-specific extension to `figma-use`. Load alongside `figma-use` when working in a FigJam (whiteboard) file rather than a Figma design file.

- **Source:** plugin (`figma`)
- **Install:** `/plugin install figma`

### `legal-advisor`

Domain-specialized skill for legal-posture work — Terms & Conditions, privacy policy, IP/copyright, GDPR/CCPA compliance, vendor agreements. Enforces a structured assessment → implementation → excellence workflow with a consistent audit trail.

- **Source:** private (the canonical install location is the team's; substitute the URL the team uses)
- **Install (user-scoped, example):**
  ```sh
  git clone <team-private-url>/legal-advisor.git \
    ~/.claude/skills/legal-advisor
  ```
- **Docs:** team-private; ask the legal-advisor persona owner

### `claude-api`

Anthropic-published skill for building, debugging, and tuning Claude API / Anthropic SDK applications. Triggers automatically when code imports `anthropic` / `@anthropic-ai/sdk` or when the user asks about Claude API features (caching, thinking, tool use, batch, files, citations, memory).

- **Source:** builtin (Anthropic-shipped; available in every Claude Code session by default)
- **Install:** none — already present
- **Docs:** built-in skill description in the Claude Code session

### `init`, `review`, `security-review`, `update-config`, `simplify`, `loop`, `schedule`, `keybindings-help`, `fewer-permission-prompts`

Built-in Claude Code skills shipped with the CLI itself. None of these need to be installed.

- **Source:** builtin
- **Install:** none

---

## Adding a new entry

When a persona starts depending on a skill that isn't listed here:

1. Add a new section to this file with the canonical install command.
2. Add the skill name to the persona's `required_skills:` frontmatter list.
3. If the skill is private to your team, document the install URL the team uses (Git over SSH, internal artifact server, etc.). The scaffold treats `private` skills as "tell the user where to look" rather than auto-installing.

## Updating after a re-run of `agent-workflow-scaffold`

The scaffold ships an updated copy of this registry every time it runs. If you've added project-specific entries between runs, the scaffold will detect the conflict in Step 1 and prompt you (overwrite, merge, abort) before clobbering.
