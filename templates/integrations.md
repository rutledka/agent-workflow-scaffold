# Trusted MCP Integrations for PM and Design Workflows

This document lists the **vendor-official, OAuth-secured** Model Context Protocol (MCP) servers that this scaffold's workflow is designed to integrate with, and how each one fits into the multi-agent model.

**Last reviewed:** May 2026.

---

## Trust criteria

Not every MCP listed in a public registry is safe to wire into a project. The criteria this skill uses:

1. **Vendor-published.** The MCP server is published and operated by the same company that owns the underlying product (Linear, Atlassian, Notion, Slack, GitHub, Figma). Third-party / community MCPs are explicitly excluded from this scaffold's recommendations.
2. **OAuth 2.1 authentication.** No API tokens committed to repos. Each user authenticates once via the vendor's OAuth flow; the OAuth session is bound to that user's permissions.
3. **Hosted by the vendor (preferred).** The MCP server runs on infrastructure the vendor controls. The user's machine connects out via TLS — no local server to expose, patch, or audit.
4. **Active maintenance.** Released or updated within the last 90 days; documented release cadence.
5. **Explicit scope model.** The OAuth scope dialog tells the user exactly what data the MCP will read and write. Over-broad scopes ("full account access") are a red flag.

The `modelcontextprotocol/servers` repository's legacy reference servers for GitHub, Slack, Google Drive, etc. are now **archived**. The official vendor versions below are the supported path.

---

## The integration matrix

| Tool | Use in this workflow | Official MCP | Hosted by | Auth |
|------|----------------------|--------------|-----------|------|
| **Linear** | Backlog ↔ `pm/backlog.md` sync; orchestrator can read/update issues | [`linear.app/docs/mcp`](https://linear.app/docs/mcp) | Linear | OAuth 2.1 |
| **Atlassian (Jira + Confluence)** | Jira ↔ `pm/backlog.md`; Confluence ↔ `pm/management.md`/`docs/` | [`atlassian/atlassian-mcp-server`](https://github.com/atlassian/atlassian-mcp-server) (Rovo MCP) | Atlassian | OAuth 2.1 + API token |
| **Notion** | Docs / specs / decision log mirror of `pm/management.md` | [`makenotion/notion-mcp-server`](https://github.com/makenotion/notion-mcp-server) | Notion (hosted) or self-host | OAuth |
| **Slack** | Team comms; orchestrator can post dispatch summaries | Built in collaboration with Anthropic — see [`docs.slack.dev/ai/slack-mcp-server`](https://docs.slack.dev/ai/slack-mcp-server/) | Slack | OAuth |
| **GitHub** | PR / issue / CI orchestration (complement to `gh` CLI) | [`github/github-mcp-server`](https://github.com/github/github-mcp-server) | GitHub or local | OAuth (GitHub App) |
| **Figma** | Design system + screen sources for the orchestrator and Designer persona | Figma MCP (already widely deployed) | Figma | OAuth |

---

## How each integration plugs into the workflow

### Linear (or Jira) — ticket source of truth

The scaffold ships with `pm/backlog.md` as the source of truth for delivery. If your team already uses Linear or Jira, `pm/backlog.md` becomes a **mirror** of the live system rather than the original — you keep the document for human-readable narrative, but ticket state lives in the PM tool.

**Orchestrator implications:**

The default orchestrator (`agents/orchestrator.md`) reads `pm/backlog.md` to determine current milestone and per-agent ticket ownership. With Linear or Jira wired in, **Step 1** (read the backlog) becomes an MCP call instead of a file read:

```
list_issues(team_id=..., state=in_progress, assignee=<persona>)
```

When you scaffold a project, decide up front whether `pm/backlog.md` or the PM tool is authoritative:

- **Document-authoritative** (default): `pm/backlog.md` is the source of truth; the PM tool is a mirror updated by the orchestrator after each dispatch.
- **Tool-authoritative**: the PM tool is the source of truth; `pm/backlog.md` is regenerated from MCP queries before each orchestrator run, or omitted entirely.

Tool-authoritative is the right choice for teams that already have Linear/Jira workflows; document-authoritative is the right choice for projects that don't have an external PM tool yet.

### Atlassian — Jira + Confluence as one connection

The Atlassian Rovo MCP gives both Jira and Confluence over a single OAuth connection. Useful when:

- Tickets live in Jira and the management plan / decision log lives in Confluence.
- You want the orchestrator to update a Confluence page when a milestone gate is hit.

**Endpoint note:** Atlassian deprecates the legacy `https://mcp.atlassian.com/v1/sse` endpoint after 30 June 2026. Use `https://mcp.atlassian.com/v1/mcp/authv2` going forward.

### Notion — docs and decision log

Notion is the right home for the leadership-readable layer (`pm/management.md`-equivalent) when the team prefers it over markdown in a repo. Two valid setups:

- **Repo as source, Notion as projection.** `pm/management.md` is authored in the repo; the orchestrator (or a scheduled job) syncs it to a Notion page on every commit.
- **Notion as source.** The leadership plan lives in Notion; `pm/management.md` becomes a reference back to the Notion URL and is kept brief.

The official `makenotion/claude-code-notion-plugin` bundles the MCP plus pre-built skills and slash commands for common Notion workflows — install that if your team is Notion-heavy.

### Slack — orchestrator dispatch summaries

The Slack MCP was built in collaboration with Anthropic and is GA. The right use in this workflow is **outbound from the orchestrator**: after each dispatch run, the orchestrator can post a summary to a designated Slack channel — same content as `docs/dispatch-logs/YYYY-MM-DD.md`, but at a glance for the team.

Don't have the orchestrator scrape Slack for instructions or comments. Treat Slack as a sink for the dispatch log, not a source for ticket state.

### GitHub — augments the `gh` CLI

The default orchestrator already uses the `gh` CLI extensively (PR list, PR view, repo create). The official GitHub MCP is a **complement** for cases where structured tool calls are easier than shelling out — for example, "list all PRs touching path X" or "summarize open Dependabot alerts." It does not replace `gh`; both can coexist.

Auth via GitHub App OAuth, scoped to the specific repo(s) the project covers.

### Figma — design system and screen sources

Figma's MCP gives the Product Designer persona (and the Frontend Engineer persona during implementation) read access to design files, screen specs, design tokens (variables), and screenshots. Useful for:

- Token sync checks: comparing Figma variables to the codebase's Tailwind/CSS-variable theme.
- Screen-to-code workflows: "implement this Figma node as a React component."
- Design-system audits: list every component, find drift between Figma and code.

If your project doesn't have a Product Designer persona, Figma is still useful for the Frontend Engineer for screen reference. If your project has no UI, skip it.

---

## What about other tools?

The list above is **deliberately small**. The scaffold's recommendation is: don't wire up an MCP for every tool the team uses. Wire up MCPs that the orchestrator or a persona will actually act on. A read-only MCP that nobody invokes is just attack surface.

Common requests and the scaffold's stance:

| Tool | Stance |
|------|--------|
| **Asana, ClickUp, Trello, Monday** | If the team uses one as primary PM tool, wire it (most have community MCPs; check vendor-official status before adopting). Otherwise skip. |
| **Productboard, Aha!** | Unless leadership is in those tools, skip. The roadmap.md doc is enough for most teams. |
| **Coda, Confluence (without Jira)** | Notion's MCP is more mature; prefer Notion if you're picking a doc tool. Confluence works via the Atlassian MCP. |
| **Storybook / Chromatic** | No mature vendor MCP as of May 2026. Use file-based access from the Frontend persona instead. |
| **Sentry, Datadog, Grafana** | Useful for an Engineering Manager or QA persona reviewing prod health. Sentry has an official MCP; community MCPs exist for Datadog and Grafana. Wire if the team is on-call; skip otherwise. |
| **Calendar (Google / Outlook)** | The scaffold doesn't depend on a calendar; if the user's Claude.ai already exposes Google Calendar, the orchestrator can use it for scheduling but it's optional. |
| **Email (Gmail / Outlook)** | Skip. Email isn't a coordination surface for this workflow. |

Add to this matrix sparingly.

---

## How the scaffold wires this up

When the user invokes `/agent-workflow-scaffold`, the discovery interview (Step 2) gathers the team's PM-tool source of truth (Q9a) and other active tools (Q9b — Slack, Figma, etc.). Step 3b synthesizes a shortlist of vendor-official MCPs to propose for confirmation.

For each MCP the user confirms, **Step 6** writes:

1. An `_enabled: true` entry in `.mcp.example.json` at the repo root — the **example** file is checked in; users copy to `.mcp.json` (gitignored) and authenticate via OAuth on first use.
2. A note in `agents/orchestrator.md`'s "Repository context" section so the orchestrator knows the integration is wired.
3. A line in the `Project-specific rules` section of `AGENTS.md` if the integration affects coding rules (e.g., "PR description must include the Linear issue ID").

For PM tools, **Step 5b** also drafts a project-local skill at `skills/pm-<tool>-<project-slug>/SKILL.md` that captures workspace + label conventions and adds two PM-specific rules to `AGENTS.md` (PM tool is source of truth; PR titles must include the issue prefix).

The `.mcp.example.json` template ships with the skill at `templates/mcp.example.json`.

---

## Security notes

- **Never commit `.mcp.json`.** The example file is `.mcp.example.json`. The actual `.mcp.json` (with active session info if any) goes in `.gitignore`.
- **OAuth tokens never leave the user's machine.** Each connector authenticates per-user; tokens are stored in the OS keychain or Claude Code's secure storage. Don't try to share tokens between users — re-authenticate.
- **Scope review at OAuth time.** When the OAuth dialog appears, confirm the scopes match what the workflow actually needs. If a connector wants admin-level write to your entire workspace, that's a red flag — most workflows need read + scoped write to a specific project / channel / page.
- **Rotate when a teammate leaves.** OAuth sessions for departing teammates should be revoked at the vendor — not just removed from the repo's `.mcp.json`. The repo file doesn't hold credentials; revocation happens at Linear / Jira / Notion / Slack / GitHub / Figma directly.

---

## Documentation links

- Linear: <https://linear.app/docs/mcp>
- Atlassian Rovo MCP: <https://www.atlassian.com/platform/remote-mcp-server>
- Notion MCP: <https://developers.notion.com/guides/mcp/get-started-with-mcp>
- Slack MCP: <https://docs.slack.dev/ai/slack-mcp-server/>
- GitHub MCP: <https://github.com/github/github-mcp-server>
- Figma MCP: included in Figma Dev Mode; see the Figma in-app documentation
- Official MCP registry: <https://registry.modelcontextprotocol.io/>
- Official servers repo (reference + archived): <https://github.com/modelcontextprotocol/servers>

---

## Document History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-05-04 | Initial commit | First trusted-MCP integration guide. Vendor-official OAuth-secured set: Linear, Atlassian, Notion, Slack, GitHub, Figma. |
