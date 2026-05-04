# Documentation

This directory holds **technical documents** — the engineering complement to the product-management artifacts in `pm/`.

## Layout

```
docs/
├── README.md                 # this file
├── adr/                      # Architecture Decision Records (one file per decision)
│   └── 0000-template.md
├── dispatch-logs/            # Orchestrator audit trail (YYYY-MM-DD.md per run)
└── …                         # other technical docs (TDD, architecture, API spec, data model, etc.)
```

## ADRs — Architecture Decision Records

Every load-bearing technical decision goes into an ADR in `docs/adr/`. Numbered sequentially (`0001-...md`, `0002-...md`, …). The file `docs/adr/0000-template.md` is the template — copy it for each new decision.

ADRs aren't just historical record. They're **the contract between past you and future you** about why the project is shaped the way it is. When someone asks "why are we using X instead of Y?", the answer should be a link to an ADR, not a rehash of the conversation.

What goes in an ADR:
- **Decision** — what was decided, in one sentence.
- **Context** — what forced this decision now.
- **Options considered** — the alternatives, with the actual trade-offs (not strawmen).
- **Consequences** — what breaks if this is wrong; what's locked in by saying yes.
- **Status** — Proposed / Accepted / Superseded by ADR-NNNN.

ADRs are short. One page is plenty. If an ADR runs to five pages, the decision is probably actually three decisions.

## Dispatch logs

The orchestrator (see `agents/orchestrator.md`) writes a dispatch log per run at `docs/dispatch-logs/YYYY-MM-DD.md`. These logs are the audit trail — what each agent was asked to do, what was held at PR cap, what was blocked.

The Engineering Manager reads these weekly to spot systemic issues (chronic at-cap agents, persistent blockers, work that's been blocked for >1 sprint).

## Other documents

Add technical documents here as they become useful. Common examples:

- **TDD** (`tdd.md` or `<project>-tdd.md`) — full technical design document, the engineering complement to the PM `backlog.md`.
- **API specification** (`api-specification.md`) — the API contract; updated **in the same PR** as any route or shape change.
- **Data model** (`data-model.md`) — schema and entity relationships.
- **Architecture** (`architecture.md` or `cloud-architecture.md`) — how services fit together; deployment topology; failure modes.
- **Test strategy** (`test-strategy.md`) — what's tested at what layer, what's the regression net.

Don't create a doc just because the scaffold suggests it. Create a doc when you find yourself repeatedly explaining the same thing — that's the signal that the explanation deserves a home.
