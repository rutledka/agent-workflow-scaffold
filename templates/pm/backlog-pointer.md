# {{PROJECT_NAME}} — Backlog (pointer document)

**Live execution status lives in {{PM_TOOL_NAME}}** — workspace {{PM_TOOL_WORKSPACE_URL}}, {{PM_TOOL_TEAM_OR_PROJECT_LABEL}} `{{PM_TOOL_TEAM_OR_PROJECT_NAME}}`, issue prefix `{{PM_ISSUE_PREFIX}}`. **This document is not the source of truth for tickets, milestones, or status.** It exists for the orchestrator dispatch loop's reference to the milestone framework, for cross-linking from `pm/management.md` and `pm/roadmap.md`, and as an offline-readable summary of the framework — but the live state is in {{PM_TOOL_NAME}}.

For canonical milestone exit criteria, persona ownership, ticket detail, status, and assignments, **read {{PM_TOOL_NAME}}** (or query the `pm-{{PM_TOOL_SLUG}}-{{PROJECT_SLUG}}` skill at `.claude/skills/pm-{{PM_TOOL_SLUG}}-{{PROJECT_SLUG}}/SKILL.md`).

---

## Milestone framework

| Milestone | Target | One-line summary |
|---|---|---|
| <a id="m0"></a>**{{FIRST_MILESTONE_NAME}}** | {{FIRST_MILESTONE_TARGET}} | *(populate as the project's first milestone is scoped — keep this row to one line; full exit criteria live in {{PM_TOOL_NAME}})* |

When a milestone is added, append a row here so the orchestrator can match labels in {{PM_TOOL_NAME}} against the framework. Don't try to mirror status here — that's what {{PM_TOOL_NAME}} is for.

---

## Conventions for tickets

These are the conventions agents and contributors follow when reading or writing tickets in {{PM_TOOL_NAME}}. Keeping them here means a contributor without {{PM_TOOL_NAME}} access can still understand the structure.

- **Issue prefix:** `{{PM_ISSUE_PREFIX}}` (e.g. `{{PM_ISSUE_PREFIX}}-123`).
- **Epic concept:** {{PM_EPIC_MAPPING}}.
- **Persona ownership:** {{PM_PERSONA_LABEL_CONVENTION}}.
- **Milestone labels:** {{PM_MILESTONE_LABEL_CONVENTION}}.
- **Quarter labels:** {{PM_QUARTER_LABEL_CONVENTION}}.
- **Other labels:** {{PM_OTHER_LABEL_CONVENTION}}.

When a ticket changes status (Backlog → In Progress → In Review → Done) update the {{PM_TOOL_NAME}} issue, not this document. The {{PM_TOOL_NAME}} GitHub integration may auto-update status when a PR opens / merges; verify rather than trust.

---

## Cross-references

- [`pm/management.md`](./management.md) — leadership-readable plan: RACI, decision log, risk register. Each milestone in management.md cross-links to the {{PM_TOOL_NAME}} project for that milestone.
- [`pm/roadmap.md`](./roadmap.md) — product strategy narrative. References this document for milestone targets.
- [`pm/codebases.md`](./codebases.md) — codebase registry; tickets in {{PM_TOOL_NAME}} reference codebases by name from there.
- [`docs/adr/`](../docs/adr/) — Architecture Decision Records. Tickets that produce or reference an ADR include the ADR number in the ticket description.

---

*This file is a pointer, not a backlog. Update {{PM_TOOL_NAME}}.*
