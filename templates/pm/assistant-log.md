# {{PROJECT_NAME}} — Personal Assistant audit log

**Maintained by:** Personal Assistant persona (`agents/personal-assistant.md`)

This is an **append-only** log of every nudge, summary, and assignment proposal the Personal Assistant surfaces to the user. The user reads this during their weekly review to (a) audit what the assistant has been suggesting, (b) catch stale recommendations the assistant should drop, (c) see which tickets came from assistant-driven dispatch.

---

## Configuration

Edit these to taste; the assistant reads them at session start.

- **Weekly-review cadence:** Monday mornings (default). Change to whichever day works.
- **Stall thresholds:** Daily 2d / Weekly 5d / Monthly 2w / Quarterly 4w / Annual 8w (defaults from `agents/personal-assistant.md`).
- **External signal sources:** *(populated when Step 6 wires MCPs — Gmail read scope, Slack read scope, etc.)*
- **Personal goals to NEVER auto-suggest as agent-assignable:** *(list any goal categories that are personal / private / never-engineering: e.g. medical, family, personal-admin, sensitive comms)*

---

## Log entries

Each entry is a heading with the date + a short title, followed by free-form notes.

```
### 2026-MM-DD — <one-line summary>

- <bullet list of what the assistant did, what it proposed, and what the user decided>
```

The assistant **never** removes log entries. The user can.

---

*(empty until the assistant runs its first session)*
