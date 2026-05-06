# Agents

This directory holds **agent persona files** — one per role on the project. Each file is a system prompt that defines who that role is, what they own, and how they work.

## Why personas?

Personas turn "Claude, work on this project" into "Claude, work on this project **as the Backend Engineer**." That framing carries scope (Backend owns the API contract, not the frontend), conventions (Backend uses the project's schema-validation library on every route handler), and relationships (Backend coordinates with QA on integration tests). The persona file is what gets passed as a system prompt when an agent is dispatched on a ticket.

## Persona file structure

Every persona file in this directory follows the same skeleton:

0. **Frontmatter** — YAML block declaring `required_skills:` (see below).
1. **Role** — one paragraph. Who you are, what you own, what you don't own.
2. **Documents owned / updated** — what files this role writes or maintains.
3. **Branch prefix** *(for engineering roles)* — e.g. `backend/*`. Used by the orchestrator to attribute PRs to a role.
4. **Working patterns** — bullet list. The 3–7 things this role does that distinguish it from "just write code." Convention-bearing.
5. **Relationships** — how this role interacts with each other persona.
6. **Key references** — the documents this role reads first.

For execution-style personas (the Orchestrator), the file is structured as a procedure with numbered steps instead of working patterns.

### Required-skills frontmatter

Each persona starts with a YAML frontmatter block declaring the Claude Code skills it depends on:

```yaml
---
required_skills: []
---

# Backend Engineer — Agent Persona
…
```

When a persona uses a skill — for example, a Product Designer persona that calls Figma's `use_figma` MCP tool needs the `figma:figma-use` skill loaded first — list it:

```yaml
---
required_skills:
  - figma:figma-use
  - figma:figma-code-connect
  - figma:figma-generate-design
---

# Product Designer — Agent Persona
…
```

The canonical list of known skills (with install commands) lives in [`docs/skills-registry.md`](../docs/skills-registry.md). The scaffold's Step 4c reads each persona's frontmatter, cross-references the registry, checks the user's installed skills, and prompts to install anything missing — both during the first scaffold run and on every re-run.

Empty `required_skills: []` is the default. If the persona doesn't need a skill, leave the list empty rather than removing the field — that way the field is discoverable when a future contributor wants to add a skill.

## Adding a new persona

1. Create `<role-slug>.md` in this directory.
2. Use the skeleton above.
3. Add the role to the **Agent role map** in `orchestrator.md`.
4. Add any owned epics/documents to `pm/backlog.md` and `pm/management.md` RACI section.

## Personas this project ships with

*(this list is generated from the discovery interview at scaffold time — only the personas you confirmed appear here; edit the list as you add or remove roles later)*

The scaffold's eleven off-the-shelf templates:

- `orchestrator.md` — runnable dispatch loop; the keystone of the workflow.
- `project-manager.md` — backlog, roadmap, scope owner, stakeholder comms.
- `engineering-manager.md` — milestone exit, risk register, architecture tie-breaker.
- `backend-engineer.md` — server-side code, API contract, schema.
- `frontend-engineer.md` — client-side code, UX surface, accessibility, perf.
- `qa-engineer.md` — test strategy, regression nets, CI infrastructure.
- `platform-engineer.md` — IaC, cloud, CI/CD pipelines, on-call, cost.
- `product-designer.md` — design system, UX flows, accessibility, Figma + Code Connect.
- `legal-advisor.md` — T&C, privacy policy, IP, regulatory compliance, launch sign-off.
- `pilot-lead.md` — partner recruiting, launch operations, pilot go/no-go.
- `custom-skeleton.md` — generic template the scaffold fills in for any role not covered above.

## Adding a new persona later

1. Copy any persona file in this directory or `custom-skeleton.md`, edit role + working patterns.
2. Add the role to the **Agent role map** in `orchestrator.md`.
3. Add any owned epics/documents to `pm/backlog.md` and `pm/management.md` RACI section.
4. If the new persona depends on Claude Code skills, list them in the `required_skills:` frontmatter — see below.

When in doubt, **start with fewer personas**. A persona that nobody reads creates noise. Add a persona when you find yourself repeatedly explaining the same scope to a generic agent — that's the signal that the role wants its own file. Re-running `/agent-workflow-scaffold` revisits the discovery and proposes additions/removals without re-asking what hasn't changed.

## Personas vs. project-local skills

A common pitfall is creating a new persona for niche codebase knowledge — "AR Engineer" for an 8th Wall codebase, "FPGA Engineer" for a hardware codebase, etc. Don't do this. Personas describe **roles** (what someone does); the niche knowledge is **technical context** (how to do the thing in this specific codebase). Technical context belongs in a project-local Claude Code skill at `.claude/skills/<codebase-slug>/SKILL.md`.

The scaffold's Step 2b.7 makes this distinction automatically: when it surfaces niche tech or team-specific gotchas during a codebase scan, it drafts a project-local skill instead of suggesting a custom persona. Every persona's **Before starting work** section instructs it to check `.claude/skills/` and load any matching skill before doing the work — the standard persona + the local skill is the right shape.
