# {{PROJECT_NAME}} — Engineering Backlog (Milestones, Epics, Tickets)

**Document owner:** Project Manager, with Engineering Manager
**Companion to:** [`pm/management.md`](./management.md), [`pm/roadmap.md`](./roadmap.md)
**Backlog version:** 0.1
**Date:** {{TODAY_ISO}}
**Last status sync:** {{TODAY_ISO}} (initial scaffold)

---

## Purpose & how to read this document

This is the **engineering and PM working backlog** — the operational source of truth for delivery. Every ticket the team picks up off the board lives here, traceable to an epic, an epic-level acceptance criterion, and a milestone. Sizes, dependencies, and owners are tracked at ticket granularity so a sprint planning session can be done by reading one document.

It is the **complement** to [`pm/management.md`](./management.md). Management is the leadership-readable plan: scope, timeline, team shape, risk register, RACI, decision log, sign-offs. Backlog is the working list. When the two documents disagree, **management.md narrates and backlog.md executes** — but the milestone tables, RACI epic names, and risk-register references in management.md should always cross-link cleanly into the headings here.

The product roadmap is in [`pm/roadmap.md`](./roadmap.md).

### Index

**Milestones (§1):** [{{FIRST_MILESTONE_NAME}}](#m0)

**Epics (§2):** *(populate as you add epics)*

**Total:** 1 milestone, 0 epics, 0 tickets.

---

## 1. Milestones

The milestone table below is the authoritative version with full exit criteria, owner, and dependencies. The summary in [`pm/management.md`](./management.md) is a one-line glance for leadership; this is the working list.

| Milestone | Status | Target | Exit Criteria | Owner Role | Dependencies |
| --------- | ------ | ------ | ------------- | ---------- | ------------ |
| <a id="m0"></a>**{{FIRST_MILESTONE_NAME}}** | 🟡 **In Progress** | {{FIRST_MILESTONE_TARGET}} | *(populate exit criteria — these are the measurable conditions that must be true to call the milestone "done")* | EM | None |

---

## 2. Epics — Overview

| ID | Epic | Status | Phase / Milestone | Primary Owner | Tickets |
| -- | ---- | ------ | ----------------- | ------------- | ------- |

*(no epics yet — add the first one in §3 and add a row here)*

**Total: 0 epics, 0 tickets.**

---

## 3. Epics & Tickets

Each epic lists a description, acceptance criteria at the epic level, and a numbered ticket list. Sizes use XS / S / M / L / XL (XS≈≤1 day, S≈2–3 days, M≈4–7 days, L≈1.5–2 weeks, XL≈>2 weeks).

### Template — copy this for each new epic

```markdown
### EPIC-XX — Epic Name

**Description.** One paragraph. What this epic delivers and why.

**Epic-level acceptance criteria.**
- Bullet list of the conditions that must be true to call the epic "done".
- Reference specific files / endpoints / behaviors so engineering and PM agree on what's being measured.

#### EPIC-XX-T01: Ticket Name
- **Description.** One or two sentences.
- **AC.** Concrete, testable acceptance criteria.
- **Size.** XS / S / M / L / XL.
- **Owner.** Persona name (e.g. Backend Engineer).
- **Deps.** Other ticket IDs this depends on, or "none".
```

---

*End of backlog — {{PROJECT_NAME}} v0.1.*
