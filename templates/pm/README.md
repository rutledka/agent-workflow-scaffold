# PM Artifacts

This directory holds the project's **product-management artifacts**. Three documents, three audiences, three purposes.

## Files

| File | Audience | Purpose |
|------|----------|---------|
| `backlog.md` | Engineering team + PM | Source of truth for delivery — milestones, epics, tickets, sizes, dependencies. The orchestrator reads this to decide what each agent works on next. |
| `management.md` | Leadership / stakeholders | Leadership-readable plan — scope, timeline, RACI, decision log, risk register, sign-offs. Updated weekly. |
| `roadmap.md` | External stakeholders, investors, partners | What's being built and when, in user-facing terms. No ticket detail. |

## How they relate

- **Authority order**: `backlog.md` is authoritative for execution. When `management.md` or `roadmap.md` disagree about a milestone or scope item, the backlog wins and the others are updated to match.
- **Cross-links**: Every milestone in `backlog.md` should be referenced from `management.md` (RACI, risk register where applicable) and `roadmap.md` (stakeholder summary).
- **Update cadence**: Backlog updates as tickets move (continuous). Management updates weekly (Fridays) by PM. Roadmap updates when milestones land or shift.

## When to add a new doc here

If a multi-epic initiative is large enough that it deserves its own execution plan — gates, phases, persona assignments, schedule risks — author it as `pm/orchestration-<initiative>.md`. Don't try to cram orchestration detail into `backlog.md`; the backlog is the ticket list, not the execution plan.

Example: a project might have `pm/orchestration-q1-platform-migration.md` describing how a 30-ticket migration sequences across 3 personas and 4 weeks, with explicit gates between phases.
