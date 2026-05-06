---
name: pm-{{PM_TOOL_SLUG}}-{{PROJECT_SLUG}}
description: Project-management operations for {{PROJECT_NAME}} via the {{PM_TOOL_NAME}} REST/GraphQL API. {{PM_TOOL_NAME}} is the source of truth for tickets, milestones, and status — `pm/backlog.md` is a thin pointer doc. Load this skill before any task that involves backlog state, ticket creation, status updates, milestone tracking, sprint planning, or PR-to-ticket linking. Project context: workspace {{PM_TOOL_WORKSPACE_URL}}, {{PM_TOOL_TEAM_OR_PROJECT_LABEL}} {{PM_TOOL_TEAM_OR_PROJECT_NAME}}, API auth via env var {{PM_TOOL_AUTH_ENV_VAR}}.
---

# {{PROJECT_NAME}} — PM operations via {{PM_TOOL_NAME}} (API)

> **Why API and not MCP?** {{PM_TOOL_NAME}} doesn't ship a vendor-official MCP. The scaffold wires the tool's published REST/GraphQL API as a project-local skill instead. This is rougher than MCP — agents use `curl` (or the project's preferred HTTP client) and you manage auth via a personal access token — but it's better than treating the tool as opaque to agents.

This skill captures **{{PROJECT_NAME}}-specific {{PM_TOOL_NAME}} context** plus the API call patterns agents need to read and write tickets. Every persona file in `agents/` instructs Claude to check `skills/` and load matching skills before starting work; this skill auto-loads when the task involves any of the operations listed in the trigger description above.

> **Source of truth.** {{PM_TOOL_NAME}} is authoritative for ticket status, milestone progress, and assignments. `pm/backlog.md` is a thin pointer doc + milestone framework summary — it is **not** updated as tickets move. Any "what's the current state?" question routes here, not to the file.

---

## Authentication

{{PM_TOOL_NAME}} uses {{PM_TOOL_AUTH_SCHEME}} for API auth.

### Setup (one-time)

1. Generate a personal access token: {{PM_TOOL_TOKEN_GENERATION_URL}}
2. Copy `.env.example` to `.env` if you haven't already (`.env` is gitignored).
3. Add the token to `.env`:

   ```
   {{PM_TOOL_AUTH_ENV_VAR}}=<your-token-here>
   ```

4. Verify the token is loaded in your shell or test runner. Agents read it from the environment when calling the API.

### Loading in shell sessions

```bash
# zsh / bash
export $(grep -v '^#' .env | xargs)

# or use direnv:
echo 'dotenv' > .envrc && direnv allow
```

If the agent's session doesn't have the token, every API call will fail with `401 Unauthorized`. Surface that loudly rather than silently — a missing token is a setup gap, not an API outage.

---

## Project-specific {{PM_TOOL_NAME}} context

- **Workspace URL:** {{PM_TOOL_WORKSPACE_URL}}
- **{{PM_TOOL_TEAM_OR_PROJECT_LABEL}}:** `{{PM_TOOL_TEAM_OR_PROJECT_NAME}}` (ID: `{{PM_TOOL_TEAM_OR_PROJECT_ID}}`)
- **API base URL:** `{{PM_TOOL_API_BASE_URL}}`
- **Issue identifier convention:** {{PM_ISSUE_PREFIX_NOTE}}
- **Epic concept in this project:** {{PM_EPIC_MAPPING}}
- **Persona ownership:** {{PM_PERSONA_LABEL_CONVENTION}}
- **Milestone tracking:** {{PM_MILESTONE_LABEL_CONVENTION}}
- **Quarter / time-box convention:** {{PM_QUARTER_LABEL_CONVENTION}}
- **Other labels / tags:** {{PM_OTHER_LABEL_CONVENTION}}

When you discover the project's {{PM_TOOL_NAME}} setup has shifted (renamed labels, new custom fields, a different milestone scheme), edit this section. The scaffold's re-run path won't overwrite a customized skill.

---

## Common operations

The examples below use `curl` for portability. If the project has a preferred HTTP client (`axios`, `httpx`, `fetch`, etc.) and is running these calls from app code rather than ad-hoc shell, translate to that client.

### Read the current backlog state

```bash
{{PM_API_LIST_TICKETS_EXAMPLE}}
```

Filters available: {{PM_API_LIST_FILTERS}}.

### Move a ticket through states

```bash
{{PM_API_UPDATE_TICKET_EXAMPLE}}
```

State names are workspace-specific — the project's standard flow is:

```
{{PM_STATE_FLOW}}
```

When opening a PR for a ticket, move it to **In Review** (or whatever the project's equivalent is — see `pm/backlog.md` for the convention). Some teams' workflows auto-move on merge via webhook; this skill does **not** assume that — verify rather than trust.

### Create a new ticket

```bash
{{PM_API_CREATE_TICKET_EXAMPLE}}
```

Use the project's epic / milestone / persona conventions documented above when populating fields.

### Link a PR to a ticket

{{PM_TOOL_NAME}}'s native GitHub integration (if available) is configured at: {{PM_TOOL_GITHUB_INTEGRATION_URL_OR_NOTE}}. If integrated, follow the same branch-name / PR-title convention documented in `AGENTS.md` so the integration matches.

If no native integration exists, agents post a comment on the {{PM_TOOL_NAME}} ticket from PR-open via:

```bash
{{PM_API_COMMENT_EXAMPLE}}
```

The orchestrator's dispatch loop appends this comment after `gh pr create` completes.

---

## Why this is rougher than MCP-wrapped tools

A few caveats this skill exists to surface:

- **No structured tool calls.** Agents call `curl` and parse JSON responses, rather than receiving validated typed responses. Errors surface as HTTP status codes + JSON bodies the agent has to interpret.
- **Auth lives in `.env`, not in the OAuth flow.** A leaked PAT has the same permissions as the user; rotate quarterly or after any incident. The scaffold added the env-var slot to `.env.example` but does **not** check the token in.
- **Rate limits matter.** {{PM_TOOL_NAME}}'s API has rate limits ({{PM_API_RATE_LIMIT_NOTE}}). Burst writes from the dispatch loop can hit these — back off and retry on `429`.
- **Schema can drift.** API contracts change less often than UIs but more often than MCPs. If a call starts failing with `400 Bad Request`, check the API docs for changes: {{PM_TOOL_API_DOCS_URL}}.

If {{PM_TOOL_NAME}} ships an official MCP later, re-run `/agent-workflow-scaffold` to upgrade — Step 5b will detect the MCP and replace this API-based skill with the cleaner MCP-based version.

---

## What stays in files (not in {{PM_TOOL_NAME}})

Same as the MCP path — strategy and leadership artifacts stay file-based:

| File | Purpose | Why it's not in {{PM_TOOL_NAME}} |
|---|---|---|
| `pm/management.md` | Leadership-readable plan: RACI, decision log, risk register, sign-offs | Cross-functional readability; signed at version boundaries; needs git history. |
| `pm/roadmap.md` | Product strategy narrative | Strategic prose, not ticket detail; shared with external stakeholders. |
| `pm/backlog.md` | Milestone framework summary + pointer | Pointer doc only — do not edit it as a backlog. {{PM_TOOL_NAME}} is the source. |
| `pm/codebases.md` | Multi-codebase registry | Versioned alongside agent config; describes infra, not tickets. |
| `docs/adr/` | ADRs | One file per decision; cross-linked from tickets but not maintained inside them. |

When a `pm/management.md` decision references a ticket, link to the {{PM_TOOL_NAME}} URL — not to a `pm/backlog.md` heading.

---

## Updating this skill

When the project's {{PM_TOOL_NAME}} setup changes — new label group, renamed workspace, new ticket scheme, custom fields added — edit this `SKILL.md` directly. The scaffold's re-run path will not overwrite a customized skill.

To regenerate from scratch (e.g. after migrating to a different workspace), delete this file and re-run `/agent-workflow-scaffold`; Step 5b will produce a fresh draft.
