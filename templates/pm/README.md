# PM Artifacts

This directory holds the project's **product-management artifacts**. Three documents, three audiences, three purposes.

## Files

| File | Audience | Purpose |
|------|----------|---------|
| `backlog.md` | Engineering team + PM | **Either** the live source of truth for delivery (when no PM tool is configured) **or** a thin pointer to the live state in Linear / Jira / Notion / GitHub (when one is configured via Step 5b of `agent-workflow-scaffold`). The first paragraph of the file tells you which mode applies. In pointer mode, agents query the PM tool via the `pm-<tool>-<project-slug>` skill at `.claude/skills/`; in live mode, the orchestrator reads this file directly. |
| `management.md` | Leadership / stakeholders | Leadership-readable plan — scope, timeline, RACI, decision log, risk register, sign-offs. Updated weekly. Always file-based; doesn't fit a ticket tracker. |
| `roadmap.md` | External stakeholders, investors, partners | What's being built and when, in user-facing terms. No ticket detail. Always file-based; strategic prose. |
| `codebases.md` | Engineering team + agents | External codebases this project's agents work on. One section per codebase: local path, base branch, **user's feature branch (PR target)**, tech inventory (auto-scanned), deprecation notes, owning personas. Only present if the project references at least one external codebase. |

## How they relate

- **Authority order**: `backlog.md` is authoritative for execution. When `management.md` or `roadmap.md` disagree about a milestone or scope item, the backlog wins and the others are updated to match.
- **Cross-links**: Every milestone in `backlog.md` should be referenced from `management.md` (RACI, risk register where applicable) and `roadmap.md` (stakeholder summary).
- **Update cadence**: Backlog updates as tickets move (continuous). Management updates weekly (Fridays) by PM. Roadmap updates when milestones land or shift.

## When to add a new doc here

If a multi-epic initiative is large enough that it deserves its own execution plan — gates, phases, persona assignments, schedule risks — author it as `pm/orchestration-<initiative>.md`. Don't try to cram orchestration detail into `backlog.md`; the backlog is the ticket list, not the execution plan.

Example: a project might have `pm/orchestration-q1-platform-migration.md` describing how a 30-ticket migration sequences across 3 personas and 4 weeks, with explicit gates between phases.
