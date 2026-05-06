# {{PROJECT_NAME}} — Goals (multi-horizon tracker)

**Maintained by:** Personal Assistant persona (`agents/personal-assistant.md`)
**Audit log:** [`pm/assistant-log.md`](./assistant-log.md)
**Source of truth:** This document for goals. The PM tool (or `pm/backlog.md` in Files-only mode) for tickets that *implement* the goals.

---

## How this document works

The Personal Assistant tracks goals across **five time horizons**: Daily, Weekly, Monthly, Quarterly, Annual. Each horizon has a section. Goals move between horizons as their scope clarifies — a "this week" goal that drags into next quarter gets re-classified, not deleted.

A goal that's **agent-assignable** (could be delivered by a persona in `agents/`) is flagged. The Personal Assistant surfaces those to the user with "want me to dispatch this?" — but never assigns without explicit permission.

### Per-goal fields

```
- **Goal:** one-sentence target.
- **Status:** Not started / In progress / Stalled / Blocked / Done.
- **Last progress:** ISO date of last meaningful update.
- **Blocker:** *(only if Stalled or Blocked)* one sentence.
- **Agent-assignable:** Yes / No / Partial.
- **Owning persona:** *(if assignable)* the agents/*.md that would take it.
- **Source:** *(optional)* where the goal came from — email, Slack, conversation, board.
```

### Stall thresholds

The assistant surfaces a nudge when "Last progress" exceeds:
- Daily: 2 days
- Weekly: 5 days
- Monthly: 2 weeks
- Quarterly: 4 weeks
- Annual: 8 weeks

---

## Daily

*(populate as goals come up; the assistant updates Last progress as it observes activity)*

---

## Weekly

*(populate; default cadence is Monday–Sunday — change in `pm/assistant-log.md`'s preferences if different)*

---

## Monthly

*(populate)*

---

## Quarterly

*(populate; align with the project's milestones in pm/management.md when applicable)*

---

## Annual

*(populate; high-level outcomes — these are the goals that should be visible in the user's mind year-round)*

---

## Archive

Goals that finish or get explicitly dropped move here, with a one-line outcome note + closing date. The archive is read-only history; no Status updates needed.
