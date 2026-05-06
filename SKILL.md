---
name: agent-workflow-scaffold
description: Scaffold a multi-agent workflow into a new or existing project — agent personas, PM artifacts (backlog/management/roadmap), AGENTS.md rules, ADR + dispatch-log structure, and starter user memories. Triggered when the user wants to set up a multi-agent project, install agent personas, or bring this workflow methodology into a new repo. Asks the user a few scoping questions, then writes templated files into the repo and bootstraps memory. Designed to be `git submodule`'d or `curl`'d into projects.
---

# Agent Workflow Scaffold

You are scaffolding a multi-agent project workflow into the user's current working directory. The user invoked this skill because they want to bring a structured, persona-led, PM-driven engineering workflow into their project. Your job is to walk them through it, ask the minimum number of clarifying questions, generate the files, and stop.

## What this workflow gives the project

A repo that is set up so that:

- **Every task moves through a worktree → PR**, never directly to `main` (rules in `AGENTS.md`).
- **Each role is a persona file in `agents/`** that you (Claude) can adopt as a system prompt — Orchestrator, Project Manager, Engineering Manager, Backend, Frontend, QA, plus optional ones the user picks.
- **The Orchestrator persona is a runnable dispatch loop** — it reads the backlog and open PRs, decides what each agent works on next, and writes a dispatch log to `docs/dispatch-logs/YYYY-MM-DD.md`. This is the keystone of the system.
- **PM artifacts live in `pm/`** — `backlog.md` (milestones / epics / tickets), `management.md` (RACI + decision log + risk register), `roadmap.md`. They cross-link to each other.
- **Decisions are captured as ADRs in `docs/adr/`**, not in chat or Slack. Every load-bearing decision gets a numbered ADR.
- **User memory is bootstrapped** with starter feedback entries about how this workflow operates, so future sessions inherit the discipline.

## Templates this skill ships with

This skill's repo contains a `templates/` directory. Each file is the source of truth for a generated artifact. Some files contain `{{PLACEHOLDER}}` tokens that you must substitute before writing into the user's project.

```
templates/
├── AGENTS.md                          # universal rules subset (incl. multi-codebase PR rule + local-skills rule).
│                                      #   Vendor-neutral filename per agents.md convention. The scaffold
│                                      #   creates a CLAUDE.md → AGENTS.md symlink in Step 4a so Claude
│                                      #   Code finds it without a parallel file.
├── .gitignore                         # adds .worktrees/
├── skills/                            # project-local skills live here (vendor-neutral path).
│   │                                  #   The scaffold creates .claude/skills → ../skills symlink in
│   │                                  #   Step 4a so Claude Code's skill loader finds them without
│   │                                  #   moving content.
│   ├── README.md                      # explains project-local skill convention
│   ├── codebase-skill-template/       # template the scaffold copies + customizes (Step 2b.7a)
│   │   └── SKILL.md
│   ├── pm-skill-template/             # template the scaffold copies + customizes (Step 5b-MCP)
│   │   └── SKILL.md                   # for Linear / Jira / Notion / GitHub PM-tool wiring
│   └── pm-skill-api-template/         # API-based PM skill template (Step 5b-API)
│       └── SKILL.md                   # for Asana / Trello / Monday / ClickUp / Shortcut / etc.
├── agents/
│   ├── orchestrator.md                # the dispatch loop — proposed by default in Step 3
│   ├── personal-assistant.md          # multi-horizon goal tracker; READ-ONLY email + team-comms;
│   │                                  #   nudges on stalls; prompts user before agent dispatch.
│   │                                  #   Proposed by default in Step 3 (user can opt out).
│   ├── project-manager.md             # proposed when discovery indicates PM work
│   ├── engineering-manager.md         # proposed when discovery indicates EM work
│   ├── backend-engineer.md            # proposed when discovery indicates server-side work
│   ├── frontend-engineer.md           # proposed when discovery indicates client-side work
│   ├── qa-engineer.md                 # proposed when discovery indicates QA work
│   ├── platform-engineer.md           # proposed when discovery mentions IaC / cloud / on-call
│   ├── product-designer.md            # proposed when discovery mentions Figma / design system
│   ├── legal-advisor.md               # proposed when discovery mentions T&C / GDPR / compliance
│   ├── pilot-lead.md                  # proposed when discovery mentions pilot / launch ops
│   ├── custom-skeleton.md             # filled in for off-list ROLES (e.g. Growth Lead). NOT
│   │                                  #   used for codebase-niche knowledge — that goes into
│   │                                  #   skills/<codebase-slug>/SKILL.md instead.
│   └── README.md                      # the persona-file convention + frontmatter docs
├── pm/
│   ├── backlog.md                     # rich, file-based source of truth (used when no PM tool)
│   ├── backlog-pointer.md             # thin pointer doc (used when PM tool is configured, Step 5b)
│   ├── management.md
│   ├── roadmap.md
│   ├── codebases.md                   # multi-codebase registry (Step 2b); points at local skills
│   ├── goals.md                       # Personal Assistant's multi-horizon goal tracker
│   ├── assistant-log.md               # Personal Assistant's append-only audit log
│   └── README.md
├── docs/
│   ├── README.md
│   ├── adr/0000-template.md           # ADR template
│   ├── skills-registry.md             # known Claude Code skills + install commands (Step 7)
│   ├── tech-docs-registry.md          # library / framework → official docs URL (Step 2b scan)
│   ├── feature-overlap-registry.md    # overlapping libs → deprecation candidates (Step 2b scan)
│   └── dispatch-logs/.gitkeep
└── memory/
    ├── MEMORY.md                      # index, with starter entries linked
    ├── feedback-worktrees-not-siblings.md
    ├── feedback-worktree-pr-discipline.md
    ├── feedback-document-version-history.md
    ├── feedback-decisions-via-adr.md
    ├── user-prefer-concrete-comparisons.md
    └── personal-assistant-context.md  # private user memory for the Personal Assistant
                                       # persona; only seeded if persona is confirmed
```

Persona files are **not all generated by default**. Step 2's discovery interview + Step 3's synthesis decide which off-the-shelf templates to use, which `custom-skeleton.md` instances to author, and which to skip entirely. A solo founder's project might end up with three personas (orchestrator, founder, custom-design-lead); a 12-person team's project might end up with all eleven.

The skill repo is at the path where this `SKILL.md` lives — you'll find `templates/` as a sibling of this file.

## Procedure

When the user invokes you, follow these steps in order. Do not skip any. The flow is **discovery-first** — you do not generate any persona files, install any skills, or wire any MCP integrations until the user confirms a synthesized proposal that you build from their answers.

### Step 1 — Detect context

Read the current working directory. Determine:

1. Is this a git repo already (`.git/` exists)? If not, recommend the user run `git init` first, but offer to scaffold anyway and remind them at the end.
2. Does the project already have any of `AGENTS.md`, `agents/`, `pm/`, or `docs/dispatch-logs/`? If yes, **stop and ask the user how to proceed** — overwrite, merge, or abort. Don't blindly overwrite their existing artifacts.

### Step 2 — Discovery interview

Replace the old "checkbox of six personas" question with a discovery interview. The persona set is **derived from the user's actual work**, not defaulted. Ask the questions below in a **single message**, grouped for legibility, and tell the user to skip any item that doesn't apply.

```
Before suggesting personas I'd like to understand your role, the
project, and the codebase(s) you work in. Answer whichever apply;
skip the rest.

About you:
1) What's your role / job title?
2) What kinds of decisions do you own end-to-end? (e.g. "ship/don't-ship",
   "API contract shape", "merge / not merge a PR", "approve a vendor
   contract", "sign off on a launch milestone")

About your work:
3) What do you spend most of your time doing? (e.g. backend code,
   PR review, UX design + Figma handoff, drafting legal docs,
   infrastructure ops, project planning, partner recruiting,
   incident response)
4) Walk me through one or two recent tasks end-to-end. What were the
   touchpoints — code, docs, tools, people?
5) What's the hardest recurring problem the workflow should help with?
   (e.g. "decisions evaporate", "design and code drift", "compliance
   gates surprise us late", "QA finds the same regression twice")

About your project:
6) Project name + slug + GitHub repo (owner/repo, or "none").
7) Primary stack — one line. (e.g. "Node 22 + TypeScript + NestJS +
   Postgres + GCP Cloud Run", "Python 3.12 + FastAPI + Redis",
   "Go + sqlc + Postgres + AWS Fargate")
8) Are there other people contributing? If yes, what roles? Use this
   to suggest personas for collaborators, not just yourself.

About your tools:
9a) Project-management source of truth — pick one. This decides whether
    pm/backlog.md is the live ticket list or a thin pointer doc, and
    how agents read / write the backlog:
      - Linear         (vendor-official MCP)
      - Jira / Atlassian Cloud (vendor-official MCP)
      - Notion (database-backed PM)  (vendor-official MCP)
      - GitHub Issues / Projects     (GitHub MCP, complements `gh`)
      - Asana / Trello / Monday / ClickUp / Shortcut / Pivotal / etc.
        (no vendor MCP, but I'll wire the tool's REST/GraphQL API as
        a project-local skill — you'll add a personal access token
        to `.env`)
      - Files only — pm/backlog.md is the source of truth (default if
        you skip; great for solo / pre-team / small projects)
9b) Other tools the team actively uses (for non-PM integrations):
    Slack / Figma / Datadog / something else?
10) Any specialty workflows? (e.g. AR/SLAM, ML training, mobile native,
    regulatory compliance, multi-cloud DR, payments / Stripe, on-call rota)
11) First milestone — name + target. (e.g. "M0 Foundation, end of W3",
    or "M0 Foundation, target TBD" if it's not pinned yet)

About your codebases:
12) Do you work in a single codebase, multiple, or a monorepo? If
    multiple, list the absolute path on this machine for each one
    (e.g. /Users/you/Code/api-server, /Users/you/Code/mobile-app).
    If "none yet" — i.e. this project is itself the codebase — say so.
13) For each codebase you listed in 12, are there any technologies,
    frameworks, or domain skills *distinct to that codebase* that
    would benefit from its own persona? Niche examples include
    AR/SLAM rendering pipelines, FPGA toolchains, ML training
    infrastructure, embedded firmware, regulatory-specific code.
    "No, the standard personas cover it" is a fine answer.
```

Wait for answers before doing anything else. If the user gives a partial answer — e.g. only items 1, 3, 6, 7, 12 — that's fine; proceed with what you have and infer rather than re-asking.

### Step 2b — Codebase setup (run once per codebase listed in Q12)

Before synthesizing the persona proposal in Step 3, walk each codebase the user listed and gather the operational context the agents will need at dispatch time. Skip this step entirely if the user said "none yet" in Q12 (i.e. the project itself is the only codebase, and the standard worktree-and-PR rules from `AGENTS.md` cover it).

For each codebase the user listed, perform these checks **in order**, then aggregate the results into a `pm/codebases.md` entry plan that you'll write in Step 4.

#### 2b.1 — Verify the path exists

```bash
test -d "{{LOCAL_PATH}}" && echo OK || echo MISSING
```

If the path is missing, ask the user to correct it (typo, wrong machine, etc.) before continuing. Don't skip — a wrong path means every subsequent agent dispatch fails.

#### 2b.2 — Confirm it's a git repo and capture the remote

```bash
cd "{{LOCAL_PATH}}" && git rev-parse --is-inside-work-tree && git remote get-url origin
```

If the path is a directory but not a git repo, ask the user how to proceed: (a) `git init`, (b) skip this codebase, (c) abort and re-add later. Don't auto-init — that's a destructive choice on someone else's machine.

#### 2b.3 — Detect the base branch

Try these git commands in order. Use the first one that returns a result:

```bash
# 1. Most reliable — the remote's HEAD pointer.
git -C "{{LOCAL_PATH}}" symbolic-ref refs/remotes/origin/HEAD --short 2>/dev/null \
  | sed 's|^origin/||'

# 2. Fallback — git config.
git -C "{{LOCAL_PATH}}" config --get init.defaultBranch

# 3. Fallback — check well-known names in branch list.
git -C "{{LOCAL_PATH}}" branch --list main master dev develop trunk \
  | head -1 | sed 's/^[* ]*//'
```

If none resolve, ask the user explicitly: "Couldn't auto-detect the base branch for `{{CODEBASE_NAME}}` — what is it (`main`, `master`, `dev`, `develop`, `trunk`, something else)?" Show the existing branch list to help them answer.

Record the result as the codebase's **Base branch**. This is the branch agents must NEVER push to directly.

#### 2b.4 — Determine the user's feature branch

Ask the user: "What feature branch should agents target with PRs in `{{CODEBASE_NAME}}`?" Suggest a default of `<user-handle>/<project-slug>` if the user doesn't have a preference (e.g. `khalil/ar-graffiti-orchestration`).

If the suggested branch doesn't exist on the remote, ask: "I'll create it from `{{BASE_BRANCH}}` so agents have a stable target. OK? (Y/n)" — on yes, run:

```bash
git -C "{{LOCAL_PATH}}" fetch origin
git -C "{{LOCAL_PATH}}" checkout "{{BASE_BRANCH}}"
git -C "{{LOCAL_PATH}}" pull --ff-only origin "{{BASE_BRANCH}}"
git -C "{{LOCAL_PATH}}" checkout -b "{{USER_FEATURE_BRANCH}}"
git -C "{{LOCAL_PATH}}" push -u origin "{{USER_FEATURE_BRANCH}}"
```

On no, the user is responsible for creating the branch themselves before any agent dispatches against this codebase. Note this as a follow-up in the codebase entry.

#### 2b.5 — Scan technology inventory

Walk the codebase and read manifest files to build a technology inventory. The order of preference (use the first set that produces signal):

| Manifest | Read from | Extract |
|---|---|---|
| `package.json` | repo root and any nested `apps/*/package.json` / `packages/*/package.json` | `dependencies`, `devDependencies`, `engines.node`, `scripts` |
| `package-lock.json` / `pnpm-lock.yaml` / `yarn.lock` | repo root | install dates per package (best-effort — see 2b.6) |
| `pyproject.toml` | repo root | `[tool.poetry.dependencies]` / `[project.dependencies]` / `[tool.uv]` |
| `Pipfile.lock` / `poetry.lock` / `uv.lock` | repo root | install dates per package |
| `requirements*.txt` | repo root | line-by-line packages |
| `Gemfile` / `Gemfile.lock` | repo root | gems and install dates |
| `go.mod` / `go.sum` | repo root | modules and versions |
| `Cargo.toml` / `Cargo.lock` | repo root | crates and versions |
| `Dockerfile` / `docker-compose.yml` | repo root and `code/`, `infra/`, `.docker/` if present | base images, runtime services |
| `tsconfig.json` | repo root | TypeScript presence |
| `.terraform.lock.hcl` / `versions.tf` | `infra/`, `terraform/`, or repo root | Terraform providers |
| `.github/workflows/*.yml` | repo | CI runners, action SHAs, what gets tested |

Cross-reference each detected technology against `templates/docs/tech-docs-registry.md` (which you've already written into the user's `docs/tech-docs-registry.md` in Step 4). Build a structured inventory:

```
- Languages: TypeScript, Python
- Frameworks: NestJS (web), FastAPI (data-pipelines/)
- Build / test tooling: Vitest, esbuild, ruff, pytest
- Infrastructure: Terraform 1.10, Docker, GitHub Actions
- Other notable libraries: zod, pg, ioredis, jose, axios
```

For each technology with a registry entry, capture the **Doc URL** to inject into owning personas in Step 4.

If a technology appears in the codebase but is **not** in the registry, surface it to the user with: "I detected `<tech>` but don't have a docs link on file. Want to add one to `docs/tech-docs-registry.md`?" — this is the registry-extension prompt. Don't block on it; proceed without the link if the user defers.

#### 2b.6 — Detect feature-overlap candidates and ask about deprecation

Cross-reference the detected libraries against `templates/docs/feature-overlap-registry.md` (which you've already written into the user's `docs/feature-overlap-registry.md` in Step 4). For each section in that registry where two or more listed libraries are present in this codebase, compute the **install-date gap**:

- For npm: read `package-lock.json` `packages.<name>.resolved` and check the registry tarball's `time` field via `npm view <name> time` if the lockfile doesn't carry the date directly. For better signal, prefer `git log --diff-filter=A --follow -- package.json | tail -1` lookup at the lockfile commit that introduced each library.
- For Python lockfiles (`poetry.lock`, `uv.lock`): each entry has a version; resolve install date via `pip index versions <name>` published-at, or via the lockfile's first-introduced commit.
- For Go modules: `go mod why -m <module>` and `git log --diff-filter=A -- go.mod` for the introduction commit.

If the gap between the **oldest** and **newest** library in an overlap set exceeds **365 days**, surface a deprecation question:

```
{{CODEBASE_NAME}}'s overlap detection:

  In <category>, I found two libraries with significant feature overlap:
    - <older-lib> (last touched <older-date>)
    - <newer-lib> (introduced <newer-date>)

  These typically don't coexist. Is <older-lib> deprecated in this
  project — i.e. should new code use <newer-lib> exclusively?  (Y/n/skip)
```

On `Y`, record a deprecation note to add to the codebase's `pm/codebases.md` entry **and** to the relevant persona's Working patterns. The note format:

> Use `<newer-lib>`; `<older-lib>` is deprecated in this project (since <date> per scaffold scan / user confirmation). Do not extend `<older-lib>`-using code; migrate to `<newer-lib>` opportunistically when touching adjacent files.

On `n` or `skip`, record nothing — the libraries legitimately coexist or the user isn't sure yet. The scaffold can re-ask on the next run if the gap widens.

#### 2b.7 — Decide whether the codebase warrants a project-local skill

Niche codebase knowledge belongs in a **project-local skill** under `skills/<codebase-slug>/`, not in a separate persona. Roles describe *what someone does*; skills describe *technical knowledge for doing the thing*. Treat codebase-specific gotchas, conventions, and niche-tech overviews as the latter.

Use best judgement against the user's answer to Q13 and the inventory from 2b.5 to decide whether to draft a local skill for this codebase. Surface a *suggestion* to the user — don't auto-create.

Heuristics for "yes, draft a project-local skill":

- The user said "yes" to Q13 and named distinct skills / domain knowledge.
- The codebase contains a niche framework with non-obvious gotchas (e.g. 8th Wall WebAR, Unity, Unreal, FPGA toolchain, embedded firmware, regulated-finance code).
- The codebase has team-specific conventions or repeated bug patterns that any contributor should know before touching the code.
- The codebase is large enough (>500 LoC of non-vendored source) and self-contained that knowing its surface is meaningfully different from knowing the rest of the project.

Heuristics for "no, standard personas cover it via the codebase's tech inventory":

- The user said "no" to Q13.
- The codebase is a standard Node / Python / Go service whose conventions are already encoded in the standard persona's working patterns.
- The codebase is small (<500 LoC) or is a thin wrapper around external services with no team-specific gotchas.

#### 2b.7a — Draft the local skill (only if 2b.7 said "yes")

If a local skill is warranted, scaffold it at `skills/<codebase-slug>/SKILL.md` from the template at `templates/skills/codebase-skill-template/SKILL.md`. Substitutions:

- `{{SKILL_NAME}}` — the `<codebase-slug>` (matches the directory name).
- `{{SKILL_DESCRIPTION}}` — a one-sentence trigger description Claude Code uses to decide when to load the skill. Example: `Niche knowledge for the AR-graffiti-api codebase: 8th Wall SLAM gotchas, ENU coordinate conventions, the postgis/postgis:17-3.5 spinlock workaround, the AR-216 idempotent-shutdown pattern. Load before any task that touches files in /Users/khalil/Code/ar-graffiti-api or its subtree.`
- `{{NICHE_TECH_OVERVIEW}}` — 1-3 paragraphs covering the niche tech this codebase uses. Pull from Q13 and 2b.5.
- `{{CONVENTIONS_BULLETS}}` — list bullets of project-specific conventions (e.g. "All AR transforms use 8th Wall ENU, not Three.js Y-up — see `src/ar/coordinates.ts`").
- `{{COMMON_GOTCHAS_BULLETS}}` — list bullets of recurring bugs / surprises a new contributor should expect.
- `{{INTERNAL_DOCS_LINKS}}` — links to in-repo docs, ADRs, design memos relevant to this codebase.

The drafted skill is **a starting point**. Tell the user: "I've drafted `<path>/SKILL.md` with what I could infer from the scan. Open it, edit anything wrong, and add the gotchas only humans know about — I can't infer 'this thing crashed prod last quarter' from a file scan."

The codebase's `pm/codebases.md` entry records the path to the local skill (a new field `**Project-local skill**: skills/<codebase-slug>/SKILL.md`) so personas can find it without searching. If 2b.7 said "no, standard personas cover it", the field is empty and the codebase is owned by existing personas.

#### 2b.8 — Aggregate

After completing 2b.1 through 2b.7a for all codebases, you have:

- A list of validated codebase paths + remote URLs + base branches + user feature branches.
- A technology inventory per codebase with doc URLs ready to inject.
- A list of confirmed deprecation notes per codebase.
- A list of project-local skills drafted at `skills/<codebase-slug>/SKILL.md` (if any).

Carry all of this into Step 3's synthesis. The synthesis proposal now includes the codebase entries the user will see, the local skills drafted, and the standard personas that own each codebase (no codebase-niche personas — niche knowledge lives in the local skills instead).

### Step 3 — Synthesize a persona proposal, MCP shortlist, skill shortlist, and codebase plan; confirm with the user

Do not generate files yet. Reason over the discovery answers (Step 2) and the codebase scans (Step 2b) and produce **four rolled-up proposals** in a single message. The user confirms or edits before any writes happen.

#### 3a. Persona proposal (3–7 personas)

For each proposed persona include:

- **Name** — `Backend Engineer`, `Project Manager`, `Custom: Growth Lead`, etc.
- **Why this fits** — one sentence quoting (or paraphrasing) the discovery answer that triggered it. Example: "You said you spend most of your time on PR review + API contract calls — Backend Engineer is the standing partner for that."
- **Source template** — one of the off-the-shelf templates listed under "Templates" above, **or** `custom-skeleton.md` if no template fits. If `custom-skeleton.md`, list the placeholders you'd populate from the discovery (role paragraph, primary partner, working patterns).

**Recommendation guide.** Use this map as a starting heuristic, not a rule:

| Discovery signal | Likely persona |
|---|---|
| User describes themselves writing server-side code, owning DB schema, defining API contracts | Backend Engineer |
| User describes UI work, accessibility, perf budgets, browser testing | Frontend Engineer |
| User describes test strategy, CI infra, regression testing, device matrix QA | QA Engineer |
| User describes Terraform / IaC / Cloud Run / Kubernetes / cost ops / on-call | Platform Engineer |
| User describes Figma / design system / Code Connect / token mapping / a11y design | Product Designer |
| User describes T&C / privacy policy / vendor agreements / GDPR-CCPA-SOC2 | Legal Advisor |
| User describes partner recruiting, physical placements, beta launch ops | Pilot Lead |
| User describes backlog / roadmap / stakeholder comms / scope ownership | Project Manager |
| User describes risk register, milestone exit, architecture tie-breaking | Engineering Manager |

The **Orchestrator** persona is included by default — it's the keystone of the workflow. Surface it explicitly in the proposal so the user can opt out, but flag that opting out makes most of the workflow's value disappear (the orchestrator is what runs the dispatch loop).

The **Personal Assistant** persona is also included by default. Unlike Orchestrator, this one is about the *user* rather than the project — it tracks the user's goals across multiple time horizons (Daily / Weekly / Monthly / Quarterly / Annual), reads the user's email + team-comms feeds (read-only, via vendor MCPs the scaffold wires in Step 6), surfaces nudges when goals stall, and prompts the user before assigning any agent-scope task. It keeps a private user-scoped memory file (`personal-assistant-context.md`) of need-to-knows specific to its scope (working preferences, people-in-orbit, recurring obligations, never-assignable categories). Surface it explicitly so the user can opt out — solo founders without team-comms or users who don't want this kind of nudge layer will skip it.

The **Project Manager** and **Engineering Manager** are common-but-not-universal. Default to including both, but check the discovery — if the user is a solo founder who runs PM and EM in their head, two personas is overkill; merge them into one "Founder" persona via `custom-skeleton.md` instead.

If the user mentions a role that doesn't match any template — e.g. "Growth Lead", "Customer Success", "ML Researcher", "Data Engineer", "Security Engineer" — propose a `custom-skeleton.md`-based persona for it. Author the role paragraph + working patterns from the discovery answer rather than inventing them.

**Don't propose codebase-niche personas.** Niche codebase knowledge (8th Wall SLAM, Unity, FPGA toolchains, etc.) goes into a project-local skill at `skills/<codebase-slug>/` — see Step 2b.7a. Personas are about *roles*; skills are about *technical knowledge*. The standard personas plus the matching local skill are the right shape.

#### 3b. MCP integration shortlist

For each proposed persona, cross-reference against the trusted-MCP catalog in `templates/integrations.md` and the user's answer to discovery question 9. Propose the integrations that match:

- **Project Manager + Linear / Jira / Notion** → propose the relevant PM-tool MCP. If the user picks Linear and indicates it's the source of truth (rather than the document), set `_authoritative_pm_tool: linear` in the .mcp.example.json plan.
- **Anyone + GitHub** → propose the GitHub MCP if the team needs structured PR/issue access beyond `gh` CLI.
- **Anyone + Slack** → propose the Slack MCP for outbound dispatch summaries (orchestrator's daily report posts here).
- **Product Designer + Figma** → propose the Figma MCP. (This *also* implies the `figma:*` skills in 3c below.)

If a tool the user listed doesn't have a vendor-official MCP, say so explicitly in the proposal and don't suggest a community MCP.

#### 3c. Skill shortlist

For each proposed persona, look at its template's `required_skills:` frontmatter (and any additional skills implied by the user's answers — e.g. a Backend Engineer who mentioned "Anthropic SDK" implies the `claude-api` skill). Cross-reference against `templates/docs/skills-registry.md`. Group skills by install method:

- **Plugin** — install via `/plugin install <plugin>` from inside Claude Code (figma family, etc.).
- **Git** — install via `git clone` to `~/.claude/skills/` (user-scoped) or `git submodule add` to `skills/` (project-scoped).
- **Builtin** — already shipped with Claude Code; nothing to install.
- **Private** — placeholder URL in registry; user must substitute the team-private URL.

#### 3c-bis. PM-tool plan

Based on Q9a, summarize the project-management plan in one of three modes:

- **Mode A — PM tool with vendor MCP** (Linear / Jira / Notion / GitHub Issues): tell the user the scaffold will (1) generate `pm/backlog.md` as a thin pointer doc rather than the rich template, (2) draft a project-local PM skill at `skills/pm-<tool>-<project-slug>/SKILL.md` (from `pm-skill-template`) that captures workspace + label conventions, (3) auto-enable the PM-tool MCP in `.mcp.example.json`, and (4) add two `## Project-specific rules` to `AGENTS.md` (PM tool is source of truth; PR titles must include the issue prefix). `pm/management.md` and `pm/roadmap.md` still ship as files since they hold strategy and leadership prose, not ticket detail.
- **Mode B — PM tool with API but no vendor MCP** (Asana / Trello / Monday / ClickUp / Shortcut / Pivotal / etc.): tell the user the scaffold will (1) generate `pm/backlog.md` as a thin pointer doc, (2) draft a project-local PM skill at `skills/pm-<tool>-<project-slug>/SKILL.md` (from `pm-skill-api-template`) that wraps the tool's REST/GraphQL API with project-specific conventions and `curl` / fetch examples, (3) add a `<TOOL>_PERSONAL_ACCESS_TOKEN=` slot to `.env.example` (and append to `.env` if it exists, leaving it empty for the user to fill), and (4) add the same two `## Project-specific rules` to `AGENTS.md` as Mode A. The user provides their PAT on first use; the scaffold does **not** ship credentials.
- **Mode C — Files only**: tell the user `pm/backlog.md` is the live source of truth (rich template). No PM skill is created. No `.env` mutations.

Show one example of what `pm/backlog.md` will look like in their chosen mode (paraphrased — don't reproduce the full template). The user confirms or amends in 3e.

#### 3d. Codebase plan summary

Summarize the codebase plan from Step 2b. For each codebase, show:

- Local path
- Detected base branch (or "manual entry from user" if 2b.3 fell through)
- Proposed user's feature branch (or "user creates manually" if 2b.4's offer was declined)
- Tech inventory bullets (one line each)
- Deprecation candidates the user confirmed (if any)
- Owning persona(s) — point at one or more entries from 3a
- **Project-local skill** at `skills/<codebase-slug>/SKILL.md` if Step 2b.7 surfaced one, with a one-line description of what the drafted skill contains

Example:

```
Codebase: api-server
  Path: /Users/khalil/Code/ar-graffiti-api
  Base branch: main (auto-detected)
  Your feature branch: khalil/ar-graffiti-api-orchestration
    (will be created from main, pushed to origin)
  Stack: TypeScript, NestJS, Postgres + PostGIS, ioredis
  Deprecation: jsonwebtoken (added 2023-04) is deprecated in this project;
               jose (added 2025-08) is the active library.
  Owned by: Backend Engineer, Platform Engineer
  Project-local skill: skills/ar-graffiti-api/SKILL.md
    Drafted with: NestJS+Fastify cold-start budget, ZodValidationPipe
    pinning gotcha, postgis/postgis:17-3.5 spinlock workaround, the
    idempotent-shutdown pattern. Open it after scaffolding and add
    anything I couldn't infer from the file scan.
```

If the user said "none yet" in Q12, omit this subsection — the project itself is the only codebase, and its base branch is the standard `main` covered in `AGENTS.md`.

#### 3e. Confirmation

After presenting 3a + 3b + 3c + 3c-bis + 3d, ask the user one clear confirm-or-edit question:

```
Does this look right? Reply "ship it" to generate everything as listed, or
tell me what to add / remove / rename / update.
```

Do not proceed until the user confirms or amends. If they edit the proposal, regenerate 3a–3d with their changes and re-confirm.

### Step 4 — Generate the universal subset and the *confirmed* personas

Once the proposal is confirmed, write the files. **Personas are written from the confirmed list only** — the scaffold no longer defaults to writing all six.

Files **always** written (the universal subset, not persona-dependent):

| Source | Destination | Substitutions |
|---|---|---|
| `templates/AGENTS.md` | `<project>/AGENTS.md` | `{{PROJECT_NAME}}`, `{{REPO_OWNER_REPO}}`, `{{PRIMARY_STACK}}` |
| `templates/.gitignore` | `<project>/.gitignore` *(or appended)* | none |
| `templates/agents/README.md` | `<project>/agents/README.md` | `{{PROJECT_NAME}}` |
| `templates/pm/backlog.md` *(only if Q9a chose "Files only" or a no-MCP fallback tool)* | `<project>/pm/backlog.md` | `{{PROJECT_NAME}}`, `{{FIRST_MILESTONE_NAME}}`, `{{FIRST_MILESTONE_TARGET}}`, `{{TODAY_ISO}}` |
| `templates/pm/backlog-pointer.md` *(only if Q9a chose Linear / Jira / Notion / GitHub — handled in Step 5b, listed here for completeness)* | `<project>/pm/backlog.md` | `{{PROJECT_NAME}}`, `{{FIRST_MILESTONE_NAME}}`, `{{FIRST_MILESTONE_TARGET}}`, plus all `{{PM_TOOL_*}}` and `{{PM_*}}` placeholders from 5b-MCP.2 |
| `templates/pm/management.md` | `<project>/pm/management.md` | `{{PROJECT_NAME}}`, `{{TODAY_ISO}}` |
| `templates/pm/roadmap.md` | `<project>/pm/roadmap.md` | `{{PROJECT_NAME}}`, `{{FIRST_MILESTONE_NAME}}`, `{{FIRST_MILESTONE_TARGET}}` |
| `templates/pm/README.md` | `<project>/pm/README.md` | `{{PROJECT_NAME}}` |
| `templates/docs/README.md` | `<project>/docs/README.md` | `{{PROJECT_NAME}}` |
| `templates/docs/adr/0000-template.md` | `<project>/docs/adr/0000-template.md` | none |
| `templates/docs/skills-registry.md` | `<project>/docs/skills-registry.md` | none |
| `templates/docs/tech-docs-registry.md` | `<project>/docs/tech-docs-registry.md` | none |
| `templates/docs/feature-overlap-registry.md` | `<project>/docs/feature-overlap-registry.md` | none |
| `templates/pm/codebases.md` | `<project>/pm/codebases.md` | per-codebase: `{{CODEBASE_NAME}}`, `{{LOCAL_PATH}}`, `{{REMOTE_URL}}`, `{{BASE_BRANCH}}`, `{{USER_FEATURE_BRANCH}}`, `{{SCAN_DATE}}`, `{{LANGUAGES}}`, `{{FRAMEWORKS}}`, `{{BUILD_TOOLING}}`, `{{INFRASTRUCTURE}}`, `{{OTHER_LIBRARIES}}`, `{{OWNING_PERSONAS}}`, `{{DOC_LINKS}}`, `{{DEPRECATION_NOTES}}`, `{{LOCAL_SKILL_PATH}}` (all from Step 2b's scan) |
| `templates/skills/README.md` | `<project>/skills/README.md` | none |
| `templates/skills/codebase-skill-template/SKILL.md` | *(only if Step 2b.7a drafted at least one)* `<project>/skills/<codebase-slug>/SKILL.md` per codebase | `{{SKILL_NAME}}`, `{{SKILL_DESCRIPTION}}`, `{{CODEBASE_NAME}}`, `{{LOCAL_PATH}}`, `{{NICHE_TECH_OVERVIEW}}`, `{{CONVENTIONS_BULLETS}}`, `{{COMMON_GOTCHAS_BULLETS}}`, `{{INTERNAL_DOCS_LINKS}}` |
| `templates/skills/pm-skill-template/SKILL.md` | *(only if Q9a chose Linear / Jira / Notion / GitHub — handled in Step 5b-MCP)* `<project>/skills/pm-<tool-slug>-<project-slug>/SKILL.md` | all `{{PM_TOOL_*}}` and `{{PM_*}}` placeholders from 5b-MCP.2's substitution map |
| `templates/skills/pm-skill-api-template/SKILL.md` | *(only if Q9a chose Asana / Trello / Monday / ClickUp / Shortcut / etc. — handled in Step 5b-API)* `<project>/skills/pm-<tool-slug>-<project-slug>/SKILL.md` | placeholders from 5b-API's substitution map (auth env-var name, API base URL, curl examples) |
| `.env.example` *(only Step 5b-API; created if missing or appended-to)* | `<project>/.env.example` | `{{PM_TOOL_AUTH_ENV_VAR}}=` (empty value — never write a token) |
| `templates/docs/dispatch-logs/.gitkeep` | `<project>/docs/dispatch-logs/.gitkeep` | none |

Persona files written **only if** they appeared in the confirmed list from Step 3a:

| Source | Destination | Substitutions |
|---|---|---|
| `templates/agents/orchestrator.md` | `<project>/agents/orchestrator.md` | `{{PROJECT_NAME}}`, `{{REPO_OWNER_REPO}}`, `{{PROJECT_SLUG}}` |
| `templates/agents/project-manager.md` | `<project>/agents/project-manager.md` | `{{PROJECT_NAME}}`, `{{FIRST_MILESTONE_NAME}}`, `{{FIRST_MILESTONE_TARGET}}` |
| `templates/agents/engineering-manager.md` | `<project>/agents/engineering-manager.md` | `{{PROJECT_NAME}}`, `{{FIRST_MILESTONE_NAME}}` |
| `templates/agents/backend-engineer.md` | `<project>/agents/backend-engineer.md` | `{{PROJECT_NAME}}` |
| `templates/agents/frontend-engineer.md` | `<project>/agents/frontend-engineer.md` | `{{PROJECT_NAME}}` |
| `templates/agents/qa-engineer.md` | `<project>/agents/qa-engineer.md` | `{{PROJECT_NAME}}` |
| `templates/agents/platform-engineer.md` | `<project>/agents/platform-engineer.md` | `{{PROJECT_NAME}}` |
| `templates/agents/product-designer.md` | `<project>/agents/product-designer.md` | `{{PROJECT_NAME}}` |
| `templates/agents/legal-advisor.md` | `<project>/agents/legal-advisor.md` | `{{PROJECT_NAME}}` |
| `templates/agents/pilot-lead.md` | `<project>/agents/pilot-lead.md` | `{{PROJECT_NAME}}` |
| `templates/agents/custom-skeleton.md` | `<project>/agents/<role-slug>.md` | All `{{PERSONA_*}}`, `{{ROLE_PARAGRAPH}}`, `{{DOCUMENTS_LIST}}`, `{{BRANCH_PREFIX}}`, `{{WORKING_PATTERNS_BULLETS}}`, `{{PRIMARY_PARTNER_PERSONA}}`, etc. — populated from the discovery answers |
| `templates/agents/personal-assistant.md` | `<project>/agents/personal-assistant.md` | `{{PROJECT_NAME}}` |
| `templates/pm/goals.md` *(only if Personal Assistant was confirmed in 3a)* | `<project>/pm/goals.md` | `{{PROJECT_NAME}}` |
| `templates/pm/assistant-log.md` *(only if Personal Assistant was confirmed)* | `<project>/pm/assistant-log.md` | `{{PROJECT_NAME}}` |

The MCP-integration files (`templates/mcp.example.json` → `.mcp.example.json`, `templates/integrations.md` → `docs/integrations.md`) are written by Step 6 below, after the explicit MCP confirmation. The skill installs are handled by Step 7. Step 5 below handles the rules.

After writing the personas, append a **Required skills** section to the bottom of `agents/README.md` (in the user's project) listing each (persona → skill) dependency in a small markdown table. This is the single readable summary a future contributor sees.

#### Step 4a — Create platform-compatibility symlinks

Two symlinks make the project's vendor-neutral file layout discoverable by Claude Code's expected paths. **Always create both** — they're cheap, idempotent (only created if absent), and let other AI coding tools point at the same source files later without parallel copies.

```bash
# 1. CLAUDE.md → AGENTS.md
#    AGENTS.md is the canonical, vendor-neutral filename (agents.md convention).
#    Claude Code looks for CLAUDE.md; the symlink lets it find AGENTS.md.
[ -e CLAUDE.md ] || ln -s AGENTS.md CLAUDE.md

# 2. .claude/skills → ../skills
#    Project-local skills live at <project>/skills/ (vendor-neutral path).
#    Claude Code's skill loader reads .claude/skills/; the symlink redirects.
mkdir -p .claude
[ -e .claude/skills ] || ln -s ../skills .claude/skills
```

**Why both files use `[ -e ... ] || ln -s ...`:** if a contributor or a different tool already created a real file at `CLAUDE.md` or a different `.claude/skills` setup, the scaffold should not clobber it. Surface the conflict to the user instead.

**Cross-platform note:** symlinks work natively on macOS and Linux. On Windows, git's `core.symlinks` config must be enabled (true by default since Git 2.10 with developer mode, but verify) — otherwise the symlink lands as a regular text file containing the target path. If the user is on Windows, mention this in the Step 9 summary and link to <https://git-scm.com/docs/git-config#Documentation/git-config.txt-coresymlinks>.

**Why this matters:** when the user adopts another AI coding tool later — Cursor, Cline, Aider, or whatever ships next — they point that tool's expected filename at `AGENTS.md` (and skills directory at `skills/`) rather than maintaining parallel copies. The vendor-neutral path is the source; symlinks are the per-tool aliases.

#### Codebase ↔ persona linking

For every codebase Step 2b scanned, edit each owning persona file (the personas listed in 3d as "Owned by") to:

1. **Inject doc links into Key References.** Append the codebase's tech inventory doc URLs (from 2b.5) to the persona's Key References section — formatted as `- [<Tech name>](<doc-url>) — used in <codebase-name>`. Skip technologies the persona's owning surface clearly doesn't cover (e.g. don't inject Terraform docs into Frontend Engineer).
2. **Inject deprecation notes into Working patterns.** For every confirmed deprecation note from 2b.6, append a working-pattern bullet of the form: "Use `<newer-lib>`; `<older-lib>` is deprecated in `<codebase-name>` (since `<date>`). Do not extend `<older-lib>`-using code; migrate when touching adjacent files." Place this in the persona whose surface the libraries cover (e.g. Backend Engineer for `jose` vs `jsonwebtoken`).
3. **Add a Codebases section.** If the persona owns one or more codebases, add a new `## Codebases owned` section between Working patterns and Relationships, listing each codebase by name with a one-line scope description and a link to its `pm/codebases.md` entry.

If the user declined to create a feature branch in 2b.4 for any codebase, add a follow-up note at the bottom of `pm/codebases.md` for that codebase: "**Pending user action:** create the user's feature branch (`{{USER_FEATURE_BRANCH}}`) from `{{BASE_BRANCH}}` and push to origin before any agent dispatch against this codebase."

### Step 5 — Project-specific rules

The universal `AGENTS.md` covers git workflow, branch naming, PR discipline, secrets safety. **Project-specific rules need user input** and are derived from the primary stack the user gave in Step 2 Q7.

Ask only the relevant questions in a single message, grouped:

- **Node / TypeScript** — Zod (or equivalent) on every route handler before DB / external calls? Forbid `console.log/warn/error` in `src/`? Run `npm run typecheck && npm test` before push?
- **Python** — Forbid `print()` in source; require structured logger? Type hints + mypy strict on changed files?
- **Postgres / migrations** — Additive-only migrations (no destructive column drops in a single PR)?
- **API / REST / GraphQL** — API contract changes update a spec document in the same PR?
- **Go** — `go vet` + `go test ./...` before push? Forbid `fmt.Println` in non-main packages?
- **Frontend (React / Vue / etc.)** — Bundle-size budget gate? Accessibility audit gate?
- **Mobile native** — Device-matrix QA gate before merging UI changes?

For each "yes", append a one-line rule to the `## Project-specific rules` section at the bottom of `AGENTS.md`. Reference the file path or tool the rule applies to. Keep each rule to one or two sentences — these are merge-blockers, not essays.

If the user is unsure about a question, default to "yes" — rules are easier to relax than to introduce later. Tell them they can edit `AGENTS.md` to remove a rule any time.

#### Multi-codebase rules (only if Step 2b scanned at least one codebase)

If `pm/codebases.md` was generated, append the following to the bottom of `AGENTS.md`'s `## Project-specific rules` (do not paraphrase — these are load-bearing for the multi-codebase PR discipline):

```
- When working in any codebase listed in `pm/codebases.md`, agents MUST
  open PRs against that codebase's **User's feature branch**, NEVER
  against its base branch. The base branch is read-only to agents; the
  user merges from the feature branch to base via their own review
  process.
- Before dispatching a sub-agent on a ticket scoped to a referenced
  codebase, the orchestrator must read the codebase's `pm/codebases.md`
  entry and pass the local path, base branch, and user's feature branch
  to the sub-agent.
```

These rules complement the existing "Rule: Working in *referenced* codebases" section in `AGENTS.md`'s Git Workflow chapter (which the universal template already includes). The Project-specific rules entry serves as the merge-time merge-blocker; the Git Workflow section is the operational handbook.

### Step 5b — PM-tool wiring (run unless Q9a picked "Files only")

Run this step **unless** Q9a was answered "Files only" or skipped. The procedure below has two parallel paths — the **MCP path** (5b-MCP) for Linear / Jira / Notion / GitHub, and the **API path** (5b-API) for Asana / Trello / Monday / ClickUp / Shortcut / Pivotal / etc. They share most steps but differ in template choice and auth handling.

The point of this step: when the user has a PM tool, **the tool becomes the source of truth for tickets**, `pm/backlog.md` is reduced to a thin pointer doc, and a project-local **PM skill** at `skills/pm-<tool>-<project-slug>/SKILL.md` captures the project-specific conventions agents need to operate the tool correctly (workspace URL, team / project name, issue prefix, label conventions for milestones / personas / quarters). The skill template differs based on whether the tool has a vendor MCP (cleaner) or only a REST/GraphQL API (rougher but workable).

#### Path 5b-API — for tools without a vendor MCP

Run **5b-API** when Q9a was answered with Asana / Trello / Monday / ClickUp / Shortcut / Pivotal or any other tool with a public API but no vendor-official Claude Code MCP. The differences from the MCP path:

1. **Template:** use `templates/skills/pm-skill-api-template/SKILL.md` (not `pm-skill-template`).
2. **Auth:** instead of OAuth-on-first-use, the user adds a personal access token to `.env`. The scaffold:
   - Appends `{{PM_TOOL_AUTH_ENV_VAR}}=` (empty) to `.env.example` (creating the file if missing).
   - Appends the same line, also empty, to `.env` if `.env` already exists; **never** writes a non-empty token.
   - Tells the user to fill in the token from {{PM_TOOL_TOKEN_GENERATION_URL}} before any agent dispatch against the tool.
3. **MCP wiring (Step 6) is skipped for this tool** — there's no MCP entry to flip. Other MCPs the user mentioned (Slack, Figma, etc.) still go through Step 6 normally.

The substitution map for the API template covers the same `{{PM_TOOL_*}}`/`{{PM_*}}` placeholders as Mode A *plus*:

| Placeholder | Source / format |
|---|---|
| `{{PM_TOOL_AUTH_SCHEME}}` | Tool-specific. Asana/Monday/ClickUp/Shortcut: "Bearer token via `Authorization` header". Trello: "API key + token query params". |
| `{{PM_TOOL_AUTH_ENV_VAR}}` | Convention: `<TOOL>_PERSONAL_ACCESS_TOKEN`. E.g. `ASANA_PERSONAL_ACCESS_TOKEN`, `TRELLO_API_TOKEN`, `MONDAY_API_TOKEN`. |
| `{{PM_TOOL_TOKEN_GENERATION_URL}}` | The tool's PAT-generation page. Asana: <https://app.asana.com/0/my-apps>. Trello: <https://trello.com/app-key>. Monday: <https://monday.com/developers/v2#authentication-section>. ClickUp: <https://app.clickup.com/settings/apps>. Shortcut: <https://app.shortcut.com/settings/account/api-tokens>. |
| `{{PM_TOOL_API_BASE_URL}}` | Asana: `https://app.asana.com/api/1.0`. Trello: `https://api.trello.com/1`. Monday: `https://api.monday.com/v2`. ClickUp: `https://api.clickup.com/api/v2`. Shortcut: `https://api.app.shortcut.com/api/v3`. |
| `{{PM_TOOL_API_DOCS_URL}}` | The tool's API reference URL. |
| `{{PM_API_LIST_TICKETS_EXAMPLE}}` | A working `curl` snippet for "list tickets". Use the project's team/project IDs from 5b-API.1 below. |
| `{{PM_API_UPDATE_TICKET_EXAMPLE}}` | A working `curl` snippet for "move ticket to In Review". |
| `{{PM_API_CREATE_TICKET_EXAMPLE}}` | A working `curl` snippet for "create new ticket". |
| `{{PM_API_COMMENT_EXAMPLE}}` | A working `curl` snippet for "post comment on ticket". |
| `{{PM_API_LIST_FILTERS}}` | One-line description of available filters per the tool's API. |
| `{{PM_API_RATE_LIMIT_NOTE}}` | E.g. "150 req/min for free tier" — verify against current docs. |
| `{{PM_TOOL_GITHUB_INTEGRATION_URL_OR_NOTE}}` | If the tool has a native GitHub integration, link to its docs; else "no native integration — agents post comments via the API on PR open". |
| `{{PM_STATE_FLOW}}` | Tool-specific state names. Most tools have configurable workflows — ask the user in 5b-API.1. |

Example `curl` snippets the scaffold can use as a starting point for each tool:

**Asana — list tasks:**
```bash
curl -s -H "Authorization: Bearer ${ASANA_PERSONAL_ACCESS_TOKEN}" \
  "https://app.asana.com/api/1.0/projects/${ASANA_PROJECT_ID}/tasks?opt_fields=name,completed,assignee.name,custom_fields"
```

**Trello — list cards on a board:**
```bash
curl -s "https://api.trello.com/1/boards/${TRELLO_BOARD_ID}/cards?key=${TRELLO_API_KEY}&token=${TRELLO_API_TOKEN}&fields=name,idList,labels,due"
```

**Monday — query items in a board (GraphQL):**
```bash
curl -s -X POST -H "Authorization: ${MONDAY_API_TOKEN}" -H "Content-Type: application/json" \
  -d '{"query":"{ boards(ids: ['${MONDAY_BOARD_ID}']) { items_page { items { id name column_values { text } } } } }"}' \
  "https://api.monday.com/v2"
```

**ClickUp — list tasks in a list:**
```bash
curl -s -H "Authorization: ${CLICKUP_PERSONAL_ACCESS_TOKEN}" \
  "https://api.clickup.com/api/v2/list/${CLICKUP_LIST_ID}/task"
```

**Shortcut — list stories in a project:**
```bash
curl -s -H "Shortcut-Token: ${SHORTCUT_API_TOKEN}" \
  "https://api.app.shortcut.com/api/v3/projects/${SHORTCUT_PROJECT_ID}/stories"
```

These are starting points — the scaffold should refine them based on the user's answers in 5b-API.1.

#### 5b-API.1 — Capture project-specific PM context (API path)

Ask the user, in a single message, the questions tailored to the chosen tool:

```
{{PM_TOOL_NAME}}-specific questions:

1) Workspace / account URL — e.g. https://app.asana.com/0/<workspace-id>/
2) The team / project / board ID where this work lives. (Tool-specific —
   e.g. Asana project ID, Trello board ID, Monday board ID, ClickUp list ID,
   Shortcut project ID. Find it in the URL.)
3) Status / state convention — what's your workflow? (e.g. "Backlog → To Do
   → In Progress → In Review → Done", or whatever the team uses)
4) Persona ownership — what field tracks ownership? (Asana: custom field /
   assignee; Trello: label; Monday: a People column; ClickUp: assignee /
   custom field; Shortcut: owner_ids / labels)
5) Milestone tracking — how do you track milestones? (often a "due date"
   grouping, a custom field, or a separate "milestones" board)
6) Issue prefix in titles (if any) — e.g. "ACME-123 — ..." or no prefix
```

Wait for answers. Partial answers are OK.

#### 5b-API.2 — Generate the API skill + .env hooks

Substitute the answers into the API template, write to `skills/pm-<tool-slug>-<project-slug>/SKILL.md`, and edit `.env.example` / `.env`:

```bash
# Append to .env.example (create if missing)
echo "" >> .env.example
echo "# {{PM_TOOL_NAME}} personal access token (5b-API)" >> .env.example
echo "# Generate at: {{PM_TOOL_TOKEN_GENERATION_URL}}" >> .env.example
echo "{{PM_TOOL_AUTH_ENV_VAR}}=" >> .env.example

# If .env exists, append the same empty slot — DO NOT write a token value
if [ -f .env ]; then
  echo "" >> .env
  echo "{{PM_TOOL_AUTH_ENV_VAR}}=" >> .env
fi
```

Verify `.env` is in `.gitignore` (the universal template puts it there; flag if it's missing).

#### Path 5b-MCP — for tools with a vendor MCP

Run **5b-MCP** when Q9a was answered with Linear / Jira / Notion / GitHub. Steps 5b-MCP.1 through 5b-MCP.6 follow.

#### 5b-MCP.1 — Capture project-specific PM context

Ask the user, in a single message, the questions tailored to the chosen PM tool:

**Linear:**

```
Linear-specific questions:

1) Workspace URL — e.g. https://linear.app/your-workspace
2) Team name — e.g. "Acme Engineering" (Linear's primary scoping unit)
3) Issue prefix — e.g. "ACME" (Linear shows this as ACME-123 etc.)
4) Are you using Linear's "Project" feature for epics? (Y/n) — most teams
   say yes; one Linear Project per epic, named "EPIC-NN — <title>"
5) Persona ownership — pick a label group name (default: "Persona") that
   agents will use to record which agents/*.md owns each issue
6) Milestone labels — what's your milestone label convention? (e.g.
   M0-M8, or M1/M2/M3/GA, or "milestone:<n>", or "none"). The orchestrator
   uses these to filter "what's in the current milestone".
7) Quarter / time-box labels — convention if any (e.g. Q3-2026, FY25Q4)
```

**Jira / Atlassian Cloud:**

```
Jira-specific questions:

1) Cloud URL — e.g. https://your-team.atlassian.net
2) Project key — e.g. "ACME" (Jira shows issues as ACME-123)
3) Project name — e.g. "Acme Engineering"
4) Are you using Jira Epics for epics or a custom hierarchy? (Epic / Custom)
5) Persona ownership — pick a custom field or label name agents use
6) Milestone tracking — Jira "fixVersion", a label, or Advanced Roadmaps?
7) Sprint cadence — fixed sprints (Y/n)? If yes, sprint length in weeks.
```

**Notion:**

```
Notion-specific questions:

1) Workspace URL — e.g. https://www.notion.so/your-workspace
2) PM database URL — the database that holds tickets (Notion uses
   databases for PM, not a dedicated ticket type)
3) "Status" property name — typically "Status" but workspaces customize
4) "Persona" / "Owner" property name — the property agents read/write
   for ownership
5) "Milestone" / "Phase" property name — the property milestones live in
6) Issue prefix convention — Notion has no native prefix; do you use one
   in titles (e.g. "ACME-123 — ...") or none? "None" is fine.
```

**GitHub Issues / Projects:**

```
GitHub-specific questions:

1) Owner / repo — e.g. "acme/widgets" (issues live per-repo) or
   "acme" (org-level Projects span multiple repos)
2) Are issues scoped to a specific Project (v2)? URL if so.
3) Persona ownership — issue label, custom field, or assignee?
4) Milestone tracking — GitHub Milestones or Project iteration field?
5) Issue prefix — GitHub shows #123; you can prefix titles ("ACME #123 —")
   or leave just the number. "None" is fine.
```

Wait for answers. Partial answers are OK — proceed with what you have and document the gaps in the generated skill so the user can fill them in by editing.

#### 5b-MCP.2 — Generate the PM skill

Read `templates/skills/pm-skill-template/SKILL.md` and substitute. The path is `<project>/skills/pm-<tool-slug>-<project-slug>/SKILL.md`. Slug examples:

- `pm-linear-acme-widgets/SKILL.md`
- `pm-jira-acme-widgets/SKILL.md`
- `pm-notion-acme-widgets/SKILL.md`
- `pm-github-acme-widgets/SKILL.md`

Substitution map per tool:

| Placeholder | Linear | Jira | Notion | GitHub |
|---|---|---|---|---|
| `{{PM_TOOL_NAME}}` | Linear | Jira | Notion | GitHub Issues |
| `{{PM_TOOL_SLUG}}` | linear | jira | notion | github |
| `{{PM_TOOL_TEAM_OR_PROJECT_LABEL}}` | Team | Project | Workspace + Database | Owner/repo (or Project v2) |
| `{{PM_TOOL_TEAM_OR_PROJECT_NAME}}` | (5b-MCP.1 Q2) | (5b-MCP.1 Q2 + Q3) | (5b-MCP.1 Q2) | (5b-MCP.1 Q1 + Q2) |
| `{{PM_TOOL_WORKSPACE_URL}}` | (5b-MCP.1 Q1) | (5b-MCP.1 Q1) | (5b-MCP.1 Q1) | https://github.com/(5b-MCP.1 Q1) |
| `{{PM_ISSUE_PREFIX}}` | (5b-MCP.1 Q3) | (5b-MCP.1 Q2) | (5b-MCP.1 Q6 or "—") | (5b-MCP.1 Q5 or "#") |
| `{{PM_EPIC_MAPPING}}` | "one Linear Project per epic; project name `EPIC-NN — <title>`" | "Jira Epic per epic" or custom (per Q4) | "an `Epic` value in the Type property" or per the user's setup | "GitHub Project (v2) per epic" or "milestone per epic" |
| `{{PM_PERSONA_LABEL_CONVENTION}}` | "single-select label group `<name>` (per 5b-MCP.1 Q5)" | "custom field or label `<name>` (per 5b-MCP.1 Q5)" | "select property `<name>` (per 5b-MCP.1 Q4)" | "label, custom field, or assignee (per 5b-MCP.1 Q3)" |
| `{{PM_MILESTONE_LABEL_CONVENTION}}` | (5b-MCP.1 Q6) | (5b-MCP.1 Q6) | (5b-MCP.1 Q5) | (5b-MCP.1 Q4) |
| `{{PM_QUARTER_LABEL_CONVENTION}}` | (5b-MCP.1 Q7) | (none typically) | (Quarter property if used) | (none typically) |
| `{{PM_OTHER_LABEL_CONVENTION}}` | freeform (e.g. tech-freshness, infra) | freeform | freeform | freeform |
| `{{PM_LIST_ISSUES_TOOL}}` | `mcp__claude_ai_Linear__list_issues` | `mcp__claude_ai_Atlassian__list_issues` (verify exact name) | `mcp__claude_ai_Notion__query_database` | `mcp__github__list_issues` |
| `{{PM_SAVE_ISSUE_TOOL}}` | `mcp__claude_ai_Linear__save_issue` | `mcp__claude_ai_Atlassian__save_issue` | `mcp__claude_ai_Notion__update_page` / `create_page` | `mcp__github__create_issue` / `update_issue` |
| `{{PM_MCP_TOOL_LIST}}` | bullet list of all `mcp__claude_ai_Linear__*` tools available | same for Atlassian | same for Notion | same for GitHub |

Verify the exact MCP tool names against the user's session — if a tool's MCP isn't yet authenticated, surface that as a "you'll authenticate this on first use" note rather than blocking.

#### 5b-MCP.3 — Generate `pm/backlog.md` as a pointer (instead of the rich template)

When this step runs, **override Step 4's `pm/backlog.md` write** with the pointer template at `templates/pm/backlog-pointer.md`. Substitute the same `{{PM_TOOL_*}}` placeholders. The rich `templates/pm/backlog.md` is **not** copied for projects with a PM tool.

Note: `pm/management.md` and `pm/roadmap.md` are still generated normally — they hold strategy and leadership-readable plans, not ticket detail, and don't fit a ticket tracker.

#### 5b-MCP.4 — Add a "PM source of truth" rule to AGENTS.md

Append the following to the bottom of `AGENTS.md`'s `## Project-specific rules` section (substituting the tool name):

```
- **{{PM_TOOL_NAME}} is the source of truth for ticket status, milestones,
  and assignments.** When a ticket changes state, update {{PM_TOOL_NAME}},
  not `pm/backlog.md`. The pointer doc at `pm/backlog.md` is intentionally
  not a live mirror — agents reading "what's in progress?" route to
  {{PM_TOOL_NAME}} via the pm-<tool>-<project-slug> skill at
  `skills/`.
- PR titles and branch names must include an `{{PM_ISSUE_PREFIX}}-N`
  reference so the {{PM_TOOL_NAME}} GitHub integration auto-links the PR
  to the ticket. Example branch: `<role>/{{PM_ISSUE_PREFIX}}-123-short-slug`.
  Example PR title: `[{{PM_ISSUE_PREFIX}}-123] <description>`.
```

These two rules are load-bearing for the workflow when a PM tool is in play. The first one prevents drift between the file and the tool. The second is what the orchestrator's dispatch loop relies on to attribute PRs to tickets.

#### 5b-MCP.5 — Add the PM-tool MCP to the integrations plan

The PM tool's MCP has already been surfaced by Q9a. Skip the Q9b prompt for *this* MCP in Step 6 — it's effectively pre-confirmed by 5b-MCP.1's tool-specific questions. Set `_enabled: true` for the matching entry in `.mcp.example.json` (Step 6 will write the file as usual). Set `_authoritative_pm_tool` to the chosen tool name (`linear` / `jira` / `notion` / `github`) instead of the default `document`.

#### 5b-MCP.6 — Coach the user on remaining setup

Print a short reminder to the user:

```
PM-tool wiring complete:

  - Source of truth: {{PM_TOOL_NAME}} (workspace: <url>)
  - PM skill at skills/pm-<tool>-<project-slug>/SKILL.md
  - pm/backlog.md is now a pointer doc — do NOT edit for status changes
  - AGENTS.md got two project-specific rules covering this

Remaining manual steps:
  1) On first use, Claude Code will prompt you to OAuth into {{PM_TOOL_NAME}}.
  2) Open skills/pm-<tool>-<project-slug>/SKILL.md and verify the
     conventions section matches your actual workspace setup. Anything I
     guessed wrong or left as a placeholder, edit it.
  3) (If using Linear) Make sure the persona label group exists in your
     workspace with one value per agents/*.md persona. The orchestrator
     dispatch loop relies on it.
```

---

### Step 6 — MCP integrations: confirm, edit `.mcp.example.json`, copy `.mcp.json`, coach OAuth

The MCP shortlist from Step 3b is now ready to wire. Confirm the list one more time (the user may have changed their mind since 3d) and then **act on it** rather than just printing instructions.

For each confirmed MCP integration:

1. **Set `_enabled: true`** for that entry in the `.mcp.example.json` file before writing it to the user's project. (Read `templates/mcp.example.json`, edit in memory, write to `<project>/.mcp.example.json`.)
2. **Add a one-line "Integration: <Tool> via official MCP" entry** to the `## Repository context` section in `agents/orchestrator.md` (which you've already written in Step 4). Include the documentation URL.
3. **If the integration affects coding rules** (e.g. "PR description must include the Linear issue ID"), append a rule to the `## Project-specific rules` section in `AGENTS.md`.
4. **Copy `templates/integrations.md`** into `<project>/docs/integrations.md` (only on first integration enabled — subsequent integrations don't re-copy).
5. **Offer to copy `.mcp.example.json` → `.mcp.json`** for the user, with a one-line consent prompt: "Want me to copy `.mcp.example.json` to `.mcp.json` so the MCPs are wired in this project? (`.mcp.json` is gitignored.) (Y/n)". On yes: do the copy. On no: tell the user to do it manually when they're ready.
6. **Coach the OAuth flow.** For each enabled MCP, print one line: "On first use, Claude Code will prompt you to authenticate with `<Tool>` via OAuth in your browser. No further action needed before then." This is the *only* MCP step that the scaffold cannot automate — OAuth requires the user's browser.

For the authoritative-PM-source answer:

- Set `_authoritative_pm_tool` in `.mcp.example.json` to the chosen value (`document` | `linear` | `jira` | `notion`).
- If the user picked a tool, add a note at the top of `pm/backlog.md` saying "This document mirrors `<Tool>`; `<Tool>` is the source of truth for live ticket status."

#### Personal-assistant read-only scopes (only if Personal Assistant was confirmed)

When the Personal Assistant persona is in the confirmed list, ensure these MCPs are wired with **read-only** scope:

- **Gmail / Microsoft 365 / equivalent email MCP** — `read` scope only. The persona reads inbox state, surfaces unanswered threads, and flags items the user owes a reply on. It must **never** acquire send / compose / delete scopes.
- **Slack / Teams / Discord / equivalent team-comm MCP** — `read` scope only. Same shape: read channels the user follows, surface direct mentions and pending replies, group activity by tracked goals.
- **Calendar MCP** *(optional)* — `read` scope only. The persona correlates goal stalls with calendar load.

For each, set the entry's `scopes` field in `.mcp.example.json` to the read-only set explicitly, with a comment:

```json
"scopes": ["read"],  // Personal Assistant: read-only — no send/compose/post
```

If a vendor MCP doesn't expose a read-only scope distinction (some are all-or-nothing), surface that to the user explicitly: "Gmail's MCP grants both read and send scopes in one OAuth flow — Personal Assistant ignores the send surface, but the OAuth grant is broader. Continue? (Y/n)"

Add a one-line constraint to `AGENTS.md`'s `## Project-specific rules`:

```
- The Personal Assistant persona reads email + team-comms via vendor
  MCPs but NEVER sends, composes, posts, or modifies. If a vendor MCP
  exposes a write surface, the persona ignores it. The user takes every
  outbound action themselves.
```

**Constraints on what this step modifies:**

- Modifies `.mcp.example.json` (committed) and `.mcp.json` (with consent; gitignored). ✓
- Modifies `AGENTS.md` (`## Project-specific rules` only) and `agents/orchestrator.md` (`## Repository context` only). ✓
- Does **not** modify `~/.claude/settings.json` or other personal Claude Code config without explicit per-change consent (see Step 7 for the one exception — skill installs).
- Does **not** recommend community / unofficial MCPs from this scaffold. If the user asks for one not on the list, tell them to evaluate vendor-official status before adopting.

### Step 7 — Skills: actively install where possible, coach the rest

The skill shortlist from Step 3c is now ready to install. Unlike the previous version of this scaffold, this step is **active, not informational** — for skills the agent can install autonomously, install them with a single batched consent prompt rather than listing commands and waiting.

#### 7a. Compute the install plan

Walk the just-written persona files in `agents/` and aggregate their `required_skills:` frontmatter into a deduplicated list. Cross-reference against `<project>/docs/skills-registry.md`. For each skill, classify into one of four lanes based on the registry's `Source` field:

- **`auto-install: git`** — skill source is `git`. The agent can `git clone` autonomously with consent.
- **`semi-auto: plugin`** — skill source is `plugin`. The agent prints the `/plugin install <plugin>` command for the user to run from inside Claude Code; the slash command is interactive and is not safely scriptable.
- **`already installed: builtin`** — skill source is `builtin` and it appears in the session's `<available-skills>` reminder. Nothing to do.
- **`coach: private`** — skill source is `private`. The registry's install URL is a placeholder. The agent prints the placeholder + tells the user to substitute the team-private URL or ask the persona owner.

Cross-reference against the session's `<available-skills>` reminder before classifying — anything already installed should drop out of the install plan entirely.

#### 7b. Auto-install the `auto-install: git` lane (with one-shot consent)

For each git-installable skill:

1. **Choose the install scope.** Default to project-scoped (`skills/<name>/`) when the project is a git repo and the skill is one the team should share (most cases). Default to user-scoped (`~/.claude/skills/<name>/`) when the skill is personal-productivity rather than team-workflow (rare in this context).
2. **Show the user the batch and ask once.** Single message:

   ```
   I can install these skills now:
     - agent-workflow-scaffold → ~/.claude/skills/agent-workflow-scaffold (git clone)
     - <other> → <path> (<command>)

   Run them? (Y/n) [defaults to Yes]
   ```

3. **On yes:** run the `git clone` (or `git submodule add` for project-scoped, when the project is a git repo) via the Bash tool. After each, verify the directory exists and contains `SKILL.md` (a sanity check that the clone produced a valid skill). On any failure, surface the error and continue with the rest of the batch.
4. **On no:** print the commands the user can run themselves later, formatted to copy-paste, and continue. Do not block on this.
5. **For project-scoped installs**, the resulting `skills/` directory is **intentionally version-controlled**. Don't add it to `.gitignore`.

#### 7c. Coach the `semi-auto: plugin` lane

For each plugin-installable skill, group by plugin namespace and emit one line per unique namespace:

```
Run inside Claude Code (these are slash commands, not shell):
  /plugin install figma
  /plugin install <other-plugin>
```

Tell the user that after `/plugin install` completes, the plugin's skill family becomes available without restarting Claude Code.

#### 7d. Coach the `coach: private` lane

For each private-source skill, print the persona that requires it, the registry's placeholder install command, and the line:

```
The canonical install URL for `<skill-name>` is private to your team.
Substitute the URL the team uses, or ask the persona owner where to find it.
```

#### 7e. Don't block scaffold completion on install failures

If any auto-install fails or the user declines, the scaffold continues to Step 8. The summary in Step 9 surfaces what's still missing so the user can return to it. Reasons:

- The user can install skills any time after scaffolding.
- Some skills require credentials, SSO, or paid licenses the scaffold can't provide.
- Re-running the scaffold (or invoking the persona later) re-runs this step, so nothing falls through the cracks.

#### 7f. Don't auto-install without consent — even on "obvious" cases

The agent must ask before running `git clone` on the user's machine. The single batched consent prompt in 7b is the only point where it touches `~/.claude/skills/` or `skills/`. There is no implicit consent.

### Step 8 — Bootstrap memory

Memory paths are user-scoped, not repo-scoped. They live at:

```
~/.claude/projects/-Users-{{USER}}-...-{{PROJECT_SLUG}}/memory/
```

Claude Code resolves this path automatically based on the current working directory. **Do not write to a hard-coded user path.** Instead, write the memory files using the user's existing memory location for this project — invoke the standard memory mechanism by writing to whatever path the auto-memory section of your prompt indicates for the current cwd.

If the user has any existing memory entries already, do **not** overwrite them. Add the new starter entries **alongside** existing entries and update `MEMORY.md` to include both. If `MEMORY.md` doesn't exist, create it.

Starter entries to seed (read each from `templates/memory/` and copy verbatim, no substitutions needed):

| File | Type | Why it's seeded |
|---|---|---|
| `feedback-worktree-pr-discipline.md` | feedback | The single most important rule of this workflow — never commit to main |
| `feedback-worktrees-not-siblings.md` | feedback | Worktrees go inside `.worktrees/`, not as a sibling of the repo |
| `feedback-document-version-history.md` | feedback | Every doc has a version + history table at the bottom |
| `feedback-decisions-via-adr.md` | feedback | Load-bearing decisions go to `docs/adr/`, not chat |
| `user-prefer-concrete-comparisons.md` | user | When the user asks "should we use X?", offer a comparison table, not just a yes/no |

Plus a **role profile** memory entry, generated from the discovery answers so future scaffold runs (in other projects) can suggest personas faster:

| File | Type | Content |
|---|---|---|
| `user-role-profile.md` | user | One paragraph summarizing: role / job title (Q1), decisions owned (Q2), primary work (Q3), tools (Q9), specialty workflows (Q10). No project-specific details — keep this portable across projects. |

The role-profile entry's body is short — 4–6 sentences. Example shape: "User is a {{role}} who owns {{decision-area}}. Primary work is {{work}}, typical tasks involve {{touchpoints}}. Active tools: {{tools}}. Specialty workflows: {{specialty}}." Future scaffold runs read this entry first and skip discovery questions the user has already answered.

Plus, **only if the Personal Assistant persona was confirmed in 3a**, seed its private memory:

| File | Type | Content |
|---|---|---|
| `personal-assistant-context.md` | user | Read template at `templates/memory/personal-assistant-context.md` and copy verbatim. The file ships with seed sections (Working preferences / People in their orbit / Recurring personal context / Communication-source filters / Never-assignable goal categories / Trust history) populated with examples — the user fills them in over the first few sessions. The persona reads this file at every session start and updates it as it learns. |

Update `MEMORY.md` to list six entries (or seven if Personal Assistant was confirmed) with one-line descriptions.

### Step 9 — Print next-step instructions to the user

After all writes, installs, and memory entries complete, output a summary message to the user with these sections:

```
## Scaffolding complete

Personas generated:
  <list each persona file written, with the source template it came from>

Codebases registered:
  <for each codebase: name, local path, base branch, user's feature branch,
   tech inventory summary, deprecation notes if any, owning personas,
   path to drafted local skill if any>
  (omit this section if no codebases were registered)

Project-local skills drafted:
  <list each skills/<codebase-slug>/SKILL.md the scaffold drafted,
   with a one-line summary of what it covers and a reminder to open and
   edit it to add human-only knowledge>
  <list the PM skill at skills/pm-<tool>-<project-slug>/SKILL.md
   if Step 5b ran>
  (omit this section if neither Step 2b.7 nor Step 5b drafted any)

PM source of truth:
  <one of:
     "Linear (workspace <url>) — pm/backlog.md is a pointer doc"
     "Jira (cloud <url>) — pm/backlog.md is a pointer doc"
     "Notion (workspace <url>) — pm/backlog.md is a pointer doc"
     "GitHub Issues (<owner/repo>) — pm/backlog.md is a pointer doc"
     "Asana / Trello / etc. (no vendor MCP) — pm/backlog.md is the live source"
     "Files only — pm/backlog.md is the live source">
  (omit this section if Q9a wasn't asked / answered)

Files written:
  <list every other path you wrote, with relative paths>

MCPs enabled:
  <list each MCP integration enabled in .mcp.example.json,
   note whether .mcp.json was copied,
   note that OAuth happens on first use>

Skills:
  Installed: <list git-cloned skills with their install paths>
  To install yourself: <list /plugin install commands the user must run>
  Already present: <list builtin / pre-installed skills that matched>
  Coaching needed: <list private skills with the contact / placeholder URL>

Memory bootstrapped:
  <list the memory entries seeded, including user-role-profile.md>

## Next steps

1. Review AGENTS.md and edit any rule you want to relax. The Project-specific rules
   section at the bottom is where you tweak.
2. Open agents/orchestrator.md and confirm the GitHub repo + branch-prefix rows match
   your project. Adjust if needed.
3. Run any /plugin install commands listed under "Skills: To install yourself" from
   inside Claude Code. Each one takes a few seconds and the plugin's skills become
   available immediately.
4. Open pm/backlog.md and replace the placeholder M0 milestone with your real first
   milestone. Add your first epic.
5. (If codebases were registered) Open pm/codebases.md and verify each entry — paths,
   base branches, user feature branches, tech inventories, deprecation notes. Anything
   the scaffold guessed wrong, edit. The owning personas have already been linked.
5b. (If local skills were drafted) Open each skills/<codebase-slug>/SKILL.md
   and add the human-only knowledge — recurring bugs, the thing that broke prod last
   quarter, the gotchas you can't infer from a file scan. The drafted skill is a
   starting point, not a finished artifact.
6. Commit the scaffolded files: git add . && git commit -m "scaffold: agent workflow"
   Don't push yet — review the diff first.
7. Once you've populated at least one epic and one ticket in pm/backlog.md, you can run
   the orchestrator dispatch loop by invoking Claude with the orchestrator persona.

To re-run this scaffold (e.g. after a project pivot, adding a new codebase, or a new
persona need), invoke this skill again — it will detect existing files and ask before
overwriting, will re-run Step 2b for any codebases (catching drift in tech inventory
and new deprecation candidates), and will re-run the skill check so newly-required
skills get installed.
```

Stop. Do not proceed to do additional work unless the user asks.

## Working principles for this skill

- **Discovery before generation.** Never write a persona file the user didn't confirm. Step 2 (interview) → Step 2b (codebase setup) → Step 3 (synthesis + confirmation) → Step 4 (write only what's confirmed) is the load-bearing sequence; do not collapse it.
- **Niche codebase knowledge goes in a project-local skill, not a separate persona.** Personas describe *roles* (what someone does); skills describe *technical knowledge* (how to do the thing). When Step 2b.7 surfaces a codebase with niche tech or team-specific gotchas, the output is a draft `skills/<codebase-slug>/SKILL.md` — not a `custom-skeleton.md` persona. The standard persona that owns the codebase loads the local skill before starting work.
- **PM-tool conventions go in a project-local skill, not in `pm/backlog.md`.** When the user has Linear / Jira / Notion / GitHub as their PM source of truth (Q9a), the live ticket state is in the tool — not in a markdown file the scaffold has to keep up to date. Step 5b drafts a `pm-<tool>-<project-slug>` skill at `skills/` that wraps the tool's MCP with project-specific conventions (workspace, team / project, issue prefix, label groups). The skill auto-loads when any persona starts PM-adjacent work. `pm/backlog.md` becomes a thin pointer doc, not a live mirror.
- **Don't overwrite without asking.** This is the user's project — Step 1 detection is mandatory.
- **Don't push to a referenced codebase's base branch.** Ever. Step 2b records the user's feature branch as the only acceptable PR target for each codebase. The orchestrator persona and AGENTS.md both restate this rule because it's load-bearing for safe multi-repo work.
- **Don't dump every file in a wall of writes.** Confirm the persona / MCP / skill / codebase plan in Step 3, then generate in Step 4 onwards. The user can interrupt.
- **Don't add rules to AGENTS.md that the user didn't agree to.** Step 5's questions matter — silent additions break trust. The exception is the multi-codebase PR rules in Step 5: those are tied to the codebases the user already confirmed in Step 3, so they're not silent.
- **Active install, but consent-gated.** Step 7 actively `git clone`s skills the agent can install — but never without one explicit batched yes. Plugin installs (`/plugin install`) and OAuth flows are user-driven and the agent only coaches. Step 2b's `git checkout -b` for the user's feature branch is the same shape — ask first, run second.
- **Don't substitute placeholders blindly.** If the user said "none" for the GitHub repo, comment out the GitHub-specific lines in `orchestrator.md` rather than leaving "none/none" in there. Same for `custom-skeleton.md`'s `{{PERSONA_*}}` placeholders and `codebases.md`'s `{{LOCAL_PATH}}` etc. — fill them with the discovery answers, don't ship literal `{{}}` to disk.
- **Read the templates fresh each invocation.** Templates may have been updated since the last time the skill was run; don't cache.
- **A re-run revisits the discovery and the codebase scans.** If the user re-invokes this skill on the same project — even one with existing personas and codebases — re-ask Step 2 briefly and re-run Step 2b's scans against the registered codebase paths so the proposal reflects changes (new role added, tool stack changed, new lockfile, new deprecation candidate).
- **Stop when done.** Don't proactively suggest follow-up work the user didn't ask for.
