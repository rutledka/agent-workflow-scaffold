# {{PROJECT_NAME}} — Project Management Plan

**Document owners:** Engineering Manager, Project Manager
**Companion to:** [`pm/backlog.md`](./backlog.md), [`pm/roadmap.md`](./roadmap.md)
**Version:** 0.1
**Date:** {{TODAY_ISO}}

---

## 1. Executive Summary

*(replace this with a 5-sentence summary of what {{PROJECT_NAME}} is, who it's for, the near-term milestone, and the longer-term ambition. Leadership reads this first — make it crisp.)*

### 1.1 Scope

What this project delivers in v1 and what it deliberately defers. Be specific about what's **not** in scope so stakeholders calibrate expectations.

### 1.2 Timeline at a glance

| Milestone | Target | Status |
| --------- | ------ | ------ |
| {{FIRST_MILESTONE_NAME}} | *(target date)* | In Progress |

### 1.3 Team Assumptions

Who is on this project, what each role owns at a high level, and any capacity constraints. Personas in `agents/` describe the role; this section describes the people and capacity.

---

## 2. How this document is structured

This document is the **leadership-readable plan**. It narrates scope, timeline, team shape, RACI, decision log, risk register, and sign-offs.

For the working backlog (every ticket, with sizes and dependencies), read [`pm/backlog.md`](./backlog.md). For the product roadmap (stakeholder-facing milestone view), read [`pm/roadmap.md`](./roadmap.md).

When this document and the backlog disagree about a milestone or epic name, the **backlog is authoritative for execution** and this document is updated to match.

---

## 3. Team & operating model

*(describe the team shape: who plays which persona, any external collaborators, any working-hours / time-zone realities. Edit `agents/` persona files to match the actual people.)*

---

## 4. Cadence & ceremonies

*(describe the rhythm: standups, weekly syncs, milestone reviews, retros. The orchestrator's dispatch loop is the daily/weekly engine — describe how often it runs and who reviews dispatch logs.)*

---

## 5. Milestones at-a-glance

For exit-criteria detail, see [`pm/backlog.md`](./backlog.md) §1.

| Milestone | Target | Headline deliverable |
| --------- | ------ | -------------------- |
| {{FIRST_MILESTONE_NAME}} | *(target date)* | *(one-line description)* |

---

## 6. Critical path narrative

*(prose description of what blocks what right now. This is the section leadership re-reads when something slips. Keep it current — when the critical path shifts, update this within 48 hours.)*

---

## 7. RACI Summary by Epic

*(populate as you add epics. Each epic in `pm/backlog.md` should have a row here showing Responsible / Accountable / Consulted / Informed.)*

| Epic | R | A | C | I |
|------|---|---|---|---|

---

## 8. Risk Register

| # | Risk | Source | Likelihood | Impact | Owner | Mitigation |
| - | ---- | ------ | ---------- | ------ | ----- | ---------- |

*(empty at scaffold time. Add risks as they're identified. Use IDs `R1, R2, …` and never recycle an ID — retired risks stay in the table marked "Resolved.")*

---

## 9. Definition of Done (Project-Level)

*(bullet list of what makes a ticket / PR / milestone "done" at the project level. Examples: "PR has been reviewed by a non-author", "milestone exit criteria signed off by EM", "documentation updated in the same PR as the code change".)*

---

## 10. Decision log

The decision log captures **load-bearing decisions** that change the shape of the plan. Tactical engineering decisions live in ADRs in `docs/adr/`; this is the cross-functional / leadership cut.

| # | Date | Decision | Driver / context | Consequence |
| - | ---- | -------- | ---------------- | ----------- |

*(empty at scaffold time. The first entry should describe the decision to adopt this multi-agent workflow itself — it's load-bearing and worth recording.)*

---

## 11. Sign-offs

This plan is a working document; sign-offs are captured at version boundaries.

| Role | Name | Version signed | Date | Notes |
| ---- | ---- | -------------- | ---- | ----- |
| Engineering Manager | _placeholder_ | v0.1 | _placeholder_ | |
| Product Manager | _placeholder_ | v0.1 | _placeholder_ | |

---

*End of Project Management Plan — {{PROJECT_NAME}} v0.1.*
