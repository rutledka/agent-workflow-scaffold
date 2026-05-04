---
name: User - Prefer concrete comparisons over recommendations
description: When the user asks "should we use X?" or "is there a better way to do Y?", the helpful answer is a comparison table with the actual trade-offs, not a yes/no recommendation
type: user
---

When the user asks an open-ended technical question — "should we use X?", "is there a more robust option than Y?", "what are the alternatives to Z?" — the right answer is a **concrete comparison**, not a yes/no recommendation.

**Why:** The user is in decision mode, not implementation mode. A "yes, use X" answer skips the trade-off the user actually wanted to see. A comparison table lets them apply their own context (team familiarity, deadline pressure, vendor relationships) to the choice. The user has been clear they want to **decide**, not be told.

**How to apply:**
- When the question is clearly a decision-grade question, output a comparison table covering: each option, pros, cons, fit for the specific project, migration cost, maturity / ecosystem.
- Be honest about trade-offs. Don't lobby for a single answer; present the case for each option a reasonable engineer would pick.
- Add a one-paragraph honest recommendation **after** the table — labeled as such — so the user gets your read without being denied the comparison.
- If the question is implementation-grade ("how do I do X?"), this rule doesn't apply — just answer.
- The user's pattern when this happens: read the comparison, ask one or two follow-up questions, then make a clear decision. Then the in-flight work gets restructured around the choice. Don't push to commit before the decision is explicit.
