---
name: Feedback - Documents carry version + history table
description: Every document in pm/, docs/, or agents/ carries a version, date, and a history table at the bottom; updates are explicit, not implicit
type: feedback
---

Every document in `pm/`, `docs/`, or `agents/` (and any other living artifact) carries a **version, date, and a history table at the bottom**. Updates to the document increment the version and add a row to the history table describing what changed and why.

**Why:** Documents in a multi-agent workflow get edited often, sometimes by different agents in the same week. Without an explicit version + history record, a reader can't tell whether they're looking at the latest authoritative version or a stale draft, and disagreements between documents become impossible to debug. The history table is also where the "why" gets captured — not just "what changed" but the load-bearing context that justified the change.

**How to apply:**
- New documents start at version 0.1 (drafts) or 1.0 (first accepted version).
- Use semantic-ish versioning for documents: bump the major when the structure or scope changes; bump the minor when content is added or revised.
- The history table goes at the bottom of the document with columns: Version, Date, Author, Changes.
- When updating a document, update both the header (version + last-updated date) and add a row to the history table in the same edit.
- Never silently rewrite without a history entry — that breaks the trust the workflow depends on.
