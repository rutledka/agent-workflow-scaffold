---
name: pm-{{PM_TOOL_SLUG}}-{{PROJECT_SLUG}}
description: Project-management operations for {{PROJECT_NAME}} via {{PM_TOOL_NAME}}. {{PM_TOOL_NAME}} is the source of truth for tickets, milestones, and status — `pm/backlog.md` is a stale pointer. Load this skill before any task that involves backlog state, ticket creation, status updates, milestone tracking, sprint planning, or PR-to-ticket linking. Project context: workspace {{PM_TOOL_WORKSPACE_URL}}, {{PM_TOOL_TEAM_OR_PROJECT_LABEL}} {{PM_TOOL_TEAM_OR_PROJECT_NAME}}, issue prefix `{{PM_ISSUE_PREFIX}}`.
---

# {{PROJECT_NAME}} — PM operations via {{PM_TOOL_NAME}}

This skill wraps {{PM_TOOL_NAME}}-MCP usage with **{{PROJECT_NAME}}-specific context**. Every persona file in `agents/` instructs Claude to check `skills/` and load matching skills before starting work; this skill auto-loads when the task involves any of the operations listed in the trigger description above.

> **Source of truth.** {{PM_TOOL_NAME}} is authoritative for ticket status, milestone progress, and assignments. `pm/backlog.md` exists in this repo as a thin pointer + milestone framework summary — it is **not** updated as tickets move. Any "what's the current state?" question routes here, not to the file.

---

## Project-specific {{PM_TOOL_NAME}} context

- **Workspace URL:** {{PM_TOOL_WORKSPACE_URL}}
- **{{PM_TOOL_TEAM_OR_PROJECT_LABEL}}:** `{{PM_TOOL_TEAM_OR_PROJECT_NAME}}`
- **Issue prefix:** `{{PM_ISSUE_PREFIX}}` (e.g. `{{PM_ISSUE_PREFIX}}-123`)
- **Epic concept:** {{PM_EPIC_MAPPING}} *(e.g. "one {{PM_TOOL_NAME}} Project per epic, named `EPIC-NN — <title>`")*
- **Persona ownership:** {{PM_PERSONA_LABEL_CONVENTION}} *(e.g. "single-select label group `Persona` with one value per `agents/*.md` file")*
- **Milestone labels:** {{PM_MILESTONE_LABEL_CONVENTION}} *(e.g. "labels `M0`-`M8` applied to issues + projects")*
- **Quarter labels:** {{PM_QUARTER_LABEL_CONVENTION}} *(e.g. "`Q3-2026`-`Q2-2027` for time-boxing")*
- **Other labels:** {{PM_OTHER_LABEL_CONVENTION}} *(e.g. "`tech-freshness`, `monetization`, `infra`, `dr`, `multi-org`, `deferred`")*

---

## MCP tool reference

Available {{PM_TOOL_NAME}} MCP tools (load via Claude Code's standard MCP wiring; see [`docs/integrations.md`](../../../docs/integrations.md) for setup):

{{PM_MCP_TOOL_LIST}}

---

## Common operations

### Read the current backlog state

Use {{PM_LIST_ISSUES_TOOL}} with the project's team/project filter. Useful filters:

- `state` — "Backlog", "In Progress", "In Review", "Done"
- A milestone label (e.g. `M0`) to scope to one milestone
- A persona label (e.g. `backend-engineer`) to find one role's open work
- `assignee=<user>` to find a specific contributor's plate

Returns the full ticket list with status, labels, assignee, and {{PM_TOOL_NAME}} URL.

### Move a ticket through states

Use {{PM_SAVE_ISSUE_TOOL}} with `id={{PM_ISSUE_PREFIX}}-N` and `state="In Review"` (or whatever state name the workspace uses). State names are workspace-specific — do not assume them.

The flow is typically:

```
Backlog  →  In Progress  →  In Review  →  Done
```

When opening a PR for a ticket, move it to **In Review**. When the PR merges, the {{PM_TOOL_NAME}} GitHub integration may auto-move it to **Done**; verify rather than trust.

### Create a new ticket

Use {{PM_SAVE_ISSUE_TOOL}} (no `id`) with:

- `team` / `project` (per the project-specific context above)
- `title` — the ticket title; for `EPIC-XX-TYY` legacy IDs include them in the title for greppability
- `description` — markdown body; use real newlines, not `\n`
- `labels` — list of label names (persona, milestone, quarter, plus any feature labels)
- `priority` — 0=None, 1=Urgent, 2=High, 3=Medium, 4=Low (numeric; do not pass strings)

For follow-ups discovered while working another ticket, file a new {{PM_TOOL_NAME}} issue and link it from the current ticket's description rather than burying it in chat.

### Link a PR to a ticket

{{PM_TOOL_NAME}}'s GitHub integration auto-links any PR whose **branch name** or **PR title** contains an `{{PM_ISSUE_PREFIX}}-N` reference. Branch and title conventions are documented in `AGENTS.md`'s git workflow section. The orchestrator's dispatch loop verifies the link reflects reality after each PR opens.

### Filter / group by persona at planning time

The persona label group is single-select per issue, so grouping or filtering by persona produces a clean per-role view of in-flight work. The orchestrator's dispatch loop uses this view at every run to decide which agent works on what next.

---

## What stays in files (not in {{PM_TOOL_NAME}})

Some artifacts don't fit a ticket-tracker shape and stay in the repo's `pm/` directory:

| File | Purpose | Why it's not in {{PM_TOOL_NAME}} |
|---|---|---|
| `pm/management.md` | Leadership-readable plan: RACI, decision log, risk register, sign-offs | Cross-functional readability; signed at version boundaries; needs git history for audit. |
| `pm/roadmap.md` | Product strategy narrative: vision, personas, GTM, KPIs, market analysis | Strategic prose, not ticket detail; shared with external stakeholders; reads as a doc, not a ticket list. |
| `pm/backlog.md` | Milestone framework summary + pointer to {{PM_TOOL_NAME}} | A thin pointer doc — do **not** edit it as a backlog. {{PM_TOOL_NAME}} is the source. |
| `pm/codebases.md` | Multi-codebase registry with paths, base branches, user feature branches | Versioned alongside agent config; describes infra, not tickets. |
| `docs/adr/` | Architecture Decision Records | One file per decision; cross-linked from tickets but not maintained inside them. |

When a `pm/management.md` decision references a ticket, link to the {{PM_TOOL_NAME}} URL — not to a `pm/backlog.md` heading.

---

## Updating this skill

When the project's {{PM_TOOL_NAME}} setup changes — new label group, new milestone tier, renamed team, new ticket-naming convention — edit this `SKILL.md` directly. The scaffold's re-run path will not overwrite a customized skill (it surfaces a "drift detected — review?" prompt instead).

To regenerate from scratch (e.g. after a workspace migration), delete this file and re-run `/agent-workflow-scaffold`; Step 5b's PM-tool setup will produce a fresh draft.
