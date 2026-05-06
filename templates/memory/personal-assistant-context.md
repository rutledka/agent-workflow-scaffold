---
name: personal-assistant-context
description: User-scoped memory for the Personal Assistant persona — working preferences, people in the user's orbit, recurring personal context, communication-source filters, never-assignable goal categories, trust history. Read at every Personal Assistant session start; updated as the assistant learns from the user. Do NOT commit this file — it's private to the user.
type: user
---

# Personal Assistant context (private user memory)

Maintained by the Personal Assistant persona (`agents/personal-assistant.md`). This file lives in user-scoped memory (`~/.claude/projects/<project-slug>/memory/`) and is **not** committed to the repo. The Personal Assistant reads it at session start and updates it as the user shares preferences, names collaborators, or corrects prior assumptions.

For what belongs here vs what doesn't, see the **Memory practice** section in `agents/personal-assistant.md`.

---

## Working preferences

*(populate as the user expresses preferences. One line per item.)*

- *Example: "Don't surface nudges before 9am or after 7pm in the user's local time."*
- *Example: "User prefers blunt phrasing; skip the encouragement framing."*
- *Example: "Weekly review goes Monday morning, not Sunday evening."*

## People in their orbit

*(populate as the user mentions collaborators, partners, report-tos, close family. One line per person — name + relationship + relevant context. Update as people come and go.)*

- *Example: "Alex Chen — co-founder; emails from alex@... should be treated as priority."*
- *Example: "Jamie — partner; emails about kid logistics are NEVER agent-assignable."*

## Recurring personal context

*(populate as the user shares standing commitments. The assistant doesn't flag these as stalled and doesn't propose them as agent-assignable.)*

- *Example: "Tuesday 4pm is a standing therapy slot — never agent-assignable."*
- *Example: "Monday 8:30am school dropoff — block from 8:00–9:30am."*
- *Example: "Q1 board meeting first week of February each year."*

## Communication-source filters

*(populate as the user identifies sources to ignore or deprioritize.)*

- *Example: "Ignore newsletter@<vendor>.com — automated digest, no action needed."*
- *Example: "Slack #general — low signal; surface only direct mentions."*
- *Example: "Linear notification emails — already covered by the PM skill; skip in inbox summaries."*

## Never-assignable goal categories

*(populate with categories the user has explicitly said are personal / private / never-engineering.)*

- *Example: medical*
- *Example: family logistics*
- *Example: personal financial admin*
- *Example: sensitive comms (legal, HR, performance reviews)*

## Trust history

*(record specific prior decisions the user has made so the assistant doesn't re-propose the same flow next session.)*

- *Example: "2026-04-12 — User declined to dispatch a draft email to a client; said 'I always review client comms myself first'. Don't re-propose this pattern."*
- *Example: "2026-05-01 — User confirmed it's OK to file engineering tickets directly from email-thread context as long as the source is cited in the ticket body."*

---

## Maintenance

The Personal Assistant prunes entries from this file during the weekly review when:

- A person no longer interacts with the user.
- A recurring commitment has ended.
- A working preference has been updated and superseded.
- A trust-history entry is obviously stale (e.g. the user has reversed the prior decision in conversation).

If the user wants to clear specific entries, they can edit this file directly — it's their memory, not the assistant's.
