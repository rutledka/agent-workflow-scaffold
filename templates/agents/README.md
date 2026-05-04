# Agents

This directory holds **agent persona files** — one per role on the project. Each file is a system prompt that defines who that role is, what they own, and how they work.

## Why personas?

Personas turn "Claude, work on this project" into "Claude, work on this project **as the Backend Engineer**." That framing carries scope (Backend owns the API contract, not the frontend), conventions (Backend uses the project's schema-validation library on every route handler), and relationships (Backend coordinates with QA on integration tests). The persona file is what gets passed as a system prompt when an agent is dispatched on a ticket.

## Persona file structure

Every persona file in this directory follows the same skeleton:

1. **Role** — one paragraph. Who you are, what you own, what you don't own.
2. **Documents owned / updated** — what files this role writes or maintains.
3. **Branch prefix** *(for engineering roles)* — e.g. `backend/*`. Used by the orchestrator to attribute PRs to a role.
4. **Working patterns** — bullet list. The 3–7 things this role does that distinguish it from "just write code." Convention-bearing.
5. **Relationships** — how this role interacts with each other persona.
6. **Key references** — the documents this role reads first.

For execution-style personas (the Orchestrator), the file is structured as a procedure with numbered steps instead of working patterns.

## Adding a new persona

1. Create `<role-slug>.md` in this directory.
2. Use the skeleton above.
3. Add the role to the **Agent role map** in `orchestrator.md`.
4. Add any owned epics/documents to `pm/backlog.md` and `pm/management.md` RACI section.

## Personas this project ships with

*(edit this list as you add or remove personas)*

- `orchestrator.md` — runnable dispatch loop; the keystone.
- `project-manager.md` — backlog, roadmap, scope owner.
- `engineering-manager.md` — milestone exit, risk register, architecture tie-breaker.
- `backend-engineer.md` *(if applicable)* — server-side code, API contract, schema.
- `frontend-engineer.md` *(if applicable)* — client-side code, UX, accessibility, perf.
- `qa-engineer.md` *(if applicable)* — test strategy, regression nets, CI infrastructure.

## Personas you might add later

- **Platform Engineer / Cloud Architect** — infrastructure-as-code, cloud provider, deployment pipeline.
- **Product Designer** — design system, UX flows, visual fidelity, accessibility.
- **Security Engineer** — pen-test coordination, threat modeling, auth/authz reviews.
- **Legal Advisor** — terms of service, privacy policy, IP, compliance.
- **Pilot Lead / Launch Lead** — go-to-market operations, partner agreements, launch readiness.

When in doubt, **start with fewer personas**. A persona that nobody reads creates noise. Add a persona when you find yourself repeatedly explaining the same scope to a generic agent — that's the signal that the role wants its own file.
