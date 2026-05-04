---
name: Feedback - Decisions go into ADRs
description: Load-bearing technical decisions go into a numbered ADR in docs/adr/ before they're acted on; load-bearing cross-functional decisions go into pm/management.md decision log
type: feedback
---

**Load-bearing technical decisions** go into a numbered Architecture Decision Record (ADR) in `docs/adr/` **before** they're acted on. **Load-bearing cross-functional decisions** (scope, sequencing, organizational shape) go into the decision log in `pm/management.md`.

**Why:** The most expensive bugs in a project come from decisions that everyone "remembers" being made — but the memory of the decision is in chat history, in commit messages, or in nobody's head at all. Six months later, "why are we using X?" produces three different answers from three engineers, and the project re-litigates the same trade-off. ADRs and the decision log make the answer auditable. They also force the decision-maker to write down the *honest* rationale, including any non-technical drivers (deadline pressure, team familiarity, vendor lock-in concerns) that would otherwise be invisible.

**How to apply:**
- A decision is "load-bearing" if reversing it would force significant rework. If it's a one-line preference change, it doesn't need an ADR.
- ADR template lives at `docs/adr/0000-template.md`. Copy it for each new decision; number sequentially.
- Don't write an ADR after the fact "for the record". The point is to capture the trade-off **before** acting — the ADR forces the comparison rather than rationalizing the decision.
- For cross-functional decisions (e.g., "we're prioritizing X over Y this quarter"), the entry goes in the `pm/management.md` decision log, not an ADR. ADRs are for technical/architectural decisions.
- When asked to make a load-bearing decision in chat, the right answer is to draft the ADR or decision-log entry first, present the comparison, and let the user choose. Don't decide for the user and ask forgiveness.
