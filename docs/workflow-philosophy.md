# Workflow Philosophy

This document describes the *why* behind the patterns this skill scaffolds. If you're reading the scaffolded `CLAUDE.md`, `agents/`, and `pm/` and wondering "why this shape?", this is the explanation.

The methodology was extracted from a real multi-agent project (a mobile-first AR platform with a multi-persona delivery model: PM, EM, Backend, Frontend, Platform, Designer, QA, Legal, Pilot Lead, Orchestrator). The patterns below are the ones that made that project deliverable rather than dramatic.

---

## The core problem

Multi-agent software work fails in predictable ways:

1. **Decision drift.** A trade-off is debated in chat, a choice is made, and three weeks later the choice is forgotten. The team relitigates the same trade-off — sometimes deciding the opposite way.
2. **Document drift.** The PM doc says one thing, the architecture doc says another, and the code does a third thing. No reader trusts any of them.
3. **Branch chaos.** Agent A is editing the file Agent B is rewriting. Both push at the same time. One of them eventually force-pushes "to clean things up."
4. **"Who owns this?"** A bug or a stuck ticket sits unowned because no role explicitly maps to it.
5. **Scope creep without trade-off visibility.** Stakeholders ask for more; the team delivers more; the deadline slips quietly because nobody surfaced the cost.

The scaffold's patterns each address one of these failure modes.

---

## Pattern 1 — Worktree → PR for everything

**Failure mode addressed:** Branch chaos.

Every task — including a one-line documentation fix — moves through a git worktree at `.worktrees/<branch-name>/` and ships via a pull request. The branch name is `<role>/<short-description>`.

This is the rule that holds the rest of the system together. It works because:

- A worktree is a real, isolated checkout — two agents working in parallel can't step on each other's files, even if they're working in the same conceptual area.
- The PR is the only coordination point. If you can't open a PR, your work isn't visible. If your PR doesn't pass CI, it doesn't merge. There is no "let me just push this real quick."
- The branch-prefix convention (`backend/*`, `frontend/*`, etc.) makes ownership inference automatic — the orchestrator doesn't need a separate registry to know who's working on what.

**Why "no exceptions" matters:** the moment one task ships outside the rule, the rule becomes negotiable. Everyone learns it's negotiable. The system collapses to "ad hoc when convenient."

---

## Pattern 2 — Roles are personas, not labels

**Failure mode addressed:** "Who owns this?"

Each role is a markdown file in `agents/`. The file is a system prompt for that role — it defines scope, owned epics, working patterns, and relationships with other roles. When Claude is dispatched to do work as the Backend Engineer, the persona file is the system prompt.

A persona file is not a role description. It is a **stance** the agent takes:

- "Backend Engineer" knows the API contract is the seam with Frontend, knows that input validation happens at the route boundary, knows that destructive migrations split into two PRs.
- "Frontend Engineer" knows tokens are the seam with Designer, knows accessibility is a merge blocker, knows performance budgets are enforced in CI.
- "Engineering Manager" knows the milestone exit criteria are sacred and that capacity vs scope trade-offs go in the decision log.

The personas are deliberately **opinionated**. A generic agent has to be told the same conventions every session; a persona-led agent already knows them.

---

## Pattern 3 — The Orchestrator is a runnable program

**Failure mode addressed:** Drift between "what should happen next" and "what actually happens."

`agents/orchestrator.md` is the keystone. It's a procedure with explicit steps: sync, read backlog, fetch PRs, classify review items, run a strict-priority decision tree per agent, dispatch sub-agents, write a dispatch log.

The strict priority order matters:

1. **Address HIGH review items first.** An agent with a HIGH review item on an open PR doesn't start new feature work. This prevents "leave the PR open and pile on more work" — a common failure mode in busy teams.
2. **Then check PR cap.** Two open PRs is the cap. Beyond that, you're context-switching, not delivering.
3. **Then start the next unblocked ticket.** "Unblocked" means every dependency listed in the backlog is `Done`. Anything else is "blocked" and gets surfaced in the dispatch log.

The dispatch log at `docs/dispatch-logs/YYYY-MM-DD.md` is the audit trail. The Engineering Manager reads it weekly to spot systemic issues.

Without the orchestrator, the personas are decorative — they exist but nobody invokes them on a schedule. The orchestrator turns the system from "vocabulary" into "engine."

---

## Pattern 4 — Three PM documents, three audiences

**Failure mode addressed:** Document drift; "who is this written for?"

| Document | Audience | Purpose |
|----------|----------|---------|
| `pm/backlog.md` | Engineering team + PM | Source of truth for delivery |
| `pm/management.md` | Leadership / stakeholders | Scope, RACI, decision log, risk register |
| `pm/roadmap.md` | External stakeholders, investors, partners | What's being built and when |

Each document has a clear authority order: backlog is authoritative for execution; management narrates; roadmap presents. When they disagree about a date or scope, the backlog wins and the others update to match.

Three documents, not five, not one. Five fragments leadership can't navigate; one document forces leadership to read engineering ticket detail. Three is the smallest split that respects the actual audiences.

---

## Pattern 5 — Decisions are durable

**Failure mode addressed:** Decision drift.

Two places capture decisions:

- **Architecture Decision Records** (`docs/adr/NNNN-<title>.md`) for technical decisions — framework choice, data model shape, auth model, etc.
- **Decision log in `pm/management.md`** for cross-functional decisions — scope sequencing, organizational shape, deadline trade-offs.

An ADR is not a historical record written after the fact. It's a contract: written **before** acting, capturing the alternatives considered and the honest rationale (including non-technical drivers like team familiarity or vendor relationships). The honest rationale matters most — six months later, the technical reasons everyone remembers turn out to be post-hoc; the real reason was deadline pressure or team experience.

When the user asks "should we use X?", the right answer is to draft the comparison or ADR first, present the trade-offs, and let the user decide. **Don't decide for the user.**

---

## Pattern 6 — Documents have version + history

**Failure mode addressed:** Stale documents read as authoritative.

Every document in `agents/`, `pm/`, or `docs/` carries a version number, a date, and a history table at the bottom. Updates increment the version and add a row.

This sounds like ceremony but it's load-bearing: the moment a reader can't tell if they're looking at a current document or a stale draft, the entire document layer becomes untrustworthy. Versioning is what makes "the source of truth" actually true.

---

## Pattern 7 — Audit → Plan → Execute

**Failure mode addressed:** Plans built on assumptions; rework when the assumptions are wrong.

For any non-trivial initiative (a tech-stack refresh, a security hardening, a multi-epic migration), the sequence is always:

1. **Audit.** What's actually in the codebase / dependencies / docs? Inventory the current state. No recommendations, just facts.
2. **Plan.** Based on the audit, what's the change? Author it as one or more epics in `pm/backlog.md`, with explicit ACs and dependencies.
3. **Execute.** Per-ticket PRs follow the plan. Plan changes go through an updated backlog entry, not silent drift in execution.

For multi-epic initiatives, an additional **Orchestration Plan** document (`pm/orchestration-<initiative>.md`) maps tickets to phases, gates, and persona assignments. The gates are sync points, not dates — the work moves to the next phase when the gate criteria are met, not when the calendar says so.

Skipping the audit is the most common cause of plan failure. The audit is what calibrates the plan to reality.

---

## Pattern 8 — Memory carries the discipline forward

**Failure mode addressed:** Each session starts from zero on the team's conventions.

User-scoped memory (`~/.claude/projects/<slug>/memory/`) holds five categories of entries:

- **Feedback** — corrections and validated approaches. "Don't do X because of Y." "Yes, that approach worked, keep doing it."
- **Project** — facts about the project that aren't derivable from the code (current milestone, decision context).
- **Reference** — pointers to external systems (Linear, Slack, dashboards, design libraries).
- **User** — facts about the user (role, preferences, expertise).

This scaffold seeds five starter memories — the workflow's load-bearing conventions — so future sessions inherit the discipline rather than relearning it.

---

## When to deviate

The methodology is opinionated. It's wrong sometimes. Cases where deviation is warranted:

- **Solo project, no team.** Most of the patterns assume coordination overhead is real. If you're solo, you can skip the persona dispatch loop and just let one agent work end-to-end. The PM/PR/ADR layer still earns its keep, though.
- **Throwaway prototype.** If the project's lifespan is two weeks and the goal is to learn, the document scaffolding is overkill. Keep `CLAUDE.md` for git discipline; skip the rest.
- **Different team conventions.** If your team already has a working PM stack (Jira, Notion, etc.), don't fight it — point `pm/` at links to the external system, keep the orchestrator + persona pattern, drop the local PM docs.
- **Different decision cadence.** ADRs for every load-bearing decision is the right discipline at scale. At 3 engineers, an ADR per quarter is plenty; the threshold of "load-bearing" is higher.

The pattern that holds even at the smallest scale is **worktree → PR for everything**. That's where the savings compound. Skip it last.

---

## Origin

This methodology was extracted from a multi-agent AR platform project (Creator + Viewer PWAs, Postgres+PostGIS, GCP+Cloud Run, NestJS-on-Fastify backend, React+Tailwind+shadcn frontend, ~225 tickets across 28 epics, 9 milestones). The patterns evolved over the course of building it; the scaffold is what would have saved the most time if it had existed from day one.

If you adopt the methodology and find a pattern that doesn't fit your context, fork the scaffold. It's a starting point, not a doctrine.
