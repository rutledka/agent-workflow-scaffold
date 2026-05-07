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
├── .claude/
│   └── hooks/
│       └── learning-opportunities-cadence.sh   # UserPromptSubmit hook installed in Step 7i
│                                               # when the user opts in to the learning-
│                                               # opportunities skill (Q15). Re-checks the
│                                               # skill's own trigger conditions on a clock;
│                                               # never overrides the skill's native rhythm
│                                               # or session-suppression rules.
└── memory/
    ├── MEMORY.md                      # index, with starter entries linked
    ├── feedback-worktrees-not-siblings.md
    ├── feedback-worktree-pr-discipline.md
    ├── feedback-document-version-history.md
    ├── feedback-decisions-via-adr.md
    ├── feedback-subagent-write-permissions.md
    ├── user-prefer-concrete-comparisons.md
    ├── personal-assistant-context.md  # private user memory for the Personal Assistant
    │                                  # persona; only seeded if persona is confirmed
    └── learning-opportunities-context.md  # user-scoped cadence config + notes;
                                           # only seeded if Q15 = yes
```

Persona files are **not all generated by default**. Step 2's discovery interview + Step 3's synthesis decide which off-the-shelf templates to use, which `custom-skeleton.md` instances to author, and which to skip entirely. A solo founder's project might end up with three personas (orchestrator, founder, custom-design-lead); a 12-person team's project might end up with all eleven.

The skill repo is at the path where this `SKILL.md` lives — you'll find `templates/` as a sibling of this file.

## Procedure

When the user invokes you, follow these steps in order. Do not skip any. The flow is **discovery-first** — you do not generate any persona files, install any skills, or wire any MCP integrations until the user confirms a synthesized proposal that you build from their answers.

### Step 1 — Detect context

Read the current working directory. Determine:

1. Is this a git repo already (`.git/` exists)? If not, recommend the user run `git init` first, but offer to scaffold anyway and remind them at the end.
2. Does the project already have any of `CLAUDE.md`, `AGENTS.md`, `agents/`, `pm/`, or `docs/dispatch-logs/`? If yes, this is one of three states — a **previously-scaffolded project**, a **legacy-scaffolded project** (set up against an older version of this skill that's drifted from current conventions), or a **user-customized project** (the user has authored their own `CLAUDE.md` rules without ever running this scaffold). Don't blindly overwrite — instead:
   - Run **Step 1.5 — Detect drift** below to classify which kind of "already has content" you're looking at.
   - Based on the drift report, ask the user how to proceed: **migrate** (apply the drift plan), **continue as discovery** (Step 2 interview, then layer onto existing artifacts), or **abort**.

The user's authored content (anywhere in `CLAUDE.md` or `AGENTS.md`) is **preserved** through every path — see Step 4's AGENTS.md merge behavior. The scaffold's universal sections are added *additively* under a clear delimiter heading; user rules are never deleted, reformatted, or reordered.

### Step 1.5 — Detect drift (run when Step 1 found existing artifacts)

Older scaffolded projects have a different artifact layout than the current scaffold's output — `CLAUDE.md` as a regular file (not a symlink to `AGENTS.md`), `.claude/skills/` as a real directory (not a symlink to `../skills/`), persona files without `required_skills:` frontmatter, missing `pm/codebases.md`, missing registry files. **User-customized projects** (the user authored their own `CLAUDE.md` rules without ever running the scaffold) look identical to legacy projects from the outside — `CLAUDE.md` exists as a regular file. Bare Step 1 detection (\"does `agents/` exist?\") can't distinguish all three shapes — but they need different handling. A current-scaffold project just needs Step 2's discovery to layer new work; a legacy project needs a **migration plan** first; a user-customized project needs the same D1 treatment, with the user's existing `CLAUDE.md` content **preserved verbatim** through the rename and merge.

Run these detectors **in order**, recording each as `current` (no drift) or `legacy` (needs migration). Idempotent — running on a fully-migrated project detects no drift and reports `current` everywhere.

| # | Drift detector | Bash check | Migration action if `legacy` |
|---|---|---|---|
| D1 | `CLAUDE.md` is a regular file (not a symlink) | `[ -f CLAUDE.md ] && [ ! -L CLAUDE.md ]` | `git mv CLAUDE.md AGENTS.md` (the rename preserves the user's content **verbatim** + git history); create symlink `CLAUDE.md → AGENTS.md`. The agents.md preamble and the scaffold's universal sections are added later via the Step 4 AGENTS.md merge — D1 itself touches only the filename + symlink, so the user can review the rename as a clean diff. |
| D2 | `.claude/skills/` is a real directory (not a symlink) | `[ -d .claude/skills ] && [ ! -L .claude/skills ]` | Move every subdir/file from `.claude/skills/` to `skills/` (using `git mv` so history follows), `rmdir .claude/skills`, create symlink `.claude/skills → ../skills`. Add `skills/README.md` if missing. |
| D3 | `agents/*.md` files lack YAML frontmatter | `for f in agents/*.md; do head -1 "$f" \| grep -qE '^---$' \|\| echo "$f"; done` (any output → drift) | Prepend `---\nrequired_skills: []\n---\n\n` and the standard \"## Before starting work\" prelude to each persona that lacks frontmatter. Preserve all existing body content verbatim. |
| D4 | Missing `pm/codebases.md` | `[ ! -f pm/codebases.md ]` | Author `pm/codebases.md` from `templates/pm/codebases.md`. If the user has external codebases, run Step 2b (interview Q12 only) to populate Variant A entries; otherwise produce one Variant B entry for the project itself with stack inferred from manifests at `code/*/`, `apps/*/`, etc. |
| D5 | Missing `docs/skills-registry.md` | `[ ! -f docs/skills-registry.md ]` | Copy from `templates/docs/skills-registry.md`. |
| D6 | Missing `docs/tech-docs-registry.md` | `[ ! -f docs/tech-docs-registry.md ]` | Copy from `templates/docs/tech-docs-registry.md`. |
| D7 | Missing `docs/feature-overlap-registry.md` | `[ ! -f docs/feature-overlap-registry.md ]` | Copy from `templates/docs/feature-overlap-registry.md`. |
| D8 | Missing AGENTS.md \"Rule: Dispatching sub-agents\" section | `! grep -q 'Rule: Dispatching sub-agents' AGENTS.md 2>/dev/null` (after D1 if applicable) | Insert the standard sub-agent-dispatch section in `AGENTS.md` after the referenced-codebases rule. |
| D9 | Missing `templates/memory/feedback-subagent-write-permissions.md`-equivalent in user memory | check whether `feedback-subagent-write-permissions.md` is in the user's memory dir for this project | Seed the memory file (Step 8 mechanism). |
| D10 | Missing `docs/subagents-registry.md` | `[ ! -f docs/subagents-registry.md ]` | Copy from `templates/docs/subagents-registry.md`. |
| D11 | `agents/*.md` files missing the `## Available sub-agents for delegation` section | `for f in agents/*.md; do grep -q '^## Available sub-agents for delegation' "$f" \|\| echo "$f"; done` (any output → drift) | For each persona file lacking the section, append the appropriate Available-sub-agents block. For off-the-shelf personas (filenames matching `backend-engineer.md`, `frontend-engineer.md`, etc.), copy the section from the matching `templates/agents/<name>.md`. For custom personas (any other filename), match the persona's role description against the keyword index in `docs/subagents-registry.md` (Step 4b's logic) and render a best-guess section the user can edit. The migration script at `scripts/migrate-personas-to-voltagent-subagents.sh` (in the scaffold repo) implements this same logic for users who want to run it standalone — see "Standalone migration" below. |
| D12 | Missing AGENTS.md "Rule: Brief sub-agents with persona context" section | `! grep -q 'Rule: Brief sub-agents with persona context' AGENTS.md 2>/dev/null` (after D1 if applicable) | Insert the rule after "Rule: Dispatching sub-agents" in `AGENTS.md`. The rule defines the briefing protocol every persona references in its **Available sub-agents** section. Without it, the per-persona references point to a section that doesn't exist locally. |
| D13 | Learning-opportunities cadence hook missing despite the user opting in (Q15 = yes on a re-run, but `.claude/hooks/learning-opportunities-cadence.sh` is absent OR `.claude/settings.json` doesn't reference it OR `~/.claude/projects/<slug>/memory/learning-opportunities-context.md` is absent) | `[ ! -f .claude/hooks/learning-opportunities-cadence.sh ] \|\| ! grep -q learning-opportunities-cadence.sh .claude/settings.json 2>/dev/null \|\| [ ! -f "$HOME/.claude/projects/$(basename "$PWD")/memory/learning-opportunities-context.md" ]` | Re-run Step 7i.2 to copy the hook script, register it in `.claude/settings.json`, and write the user-memory context file with the default 60-minute cadence. Skip if Q15 was "no" on the current run — D13 only applies when the user has confirmed the opt-in. |

#### Surface the drift report

After running all detectors, present the drift report to the user **before** writing anything. Use a single message:

```
This project is already scaffolded, but some artifacts are on an older
shape than the current scaffold ships. I can migrate them in place — git
history is preserved (renames use `git mv`), nothing is overwritten without
a per-item confirmation, and you'll review the plan before any writes.

Drift detected:
  D1 ✗ CLAUDE.md is a regular file        → rename to AGENTS.md + symlink
  D2 ✗ .claude/skills/ is a real directory → move to skills/ + symlink
  D3 ✗ 6 personas lack required_skills frontmatter
       (agents/backend-engineer.md, agents/frontend-engineer.md, ...)
       → prepend frontmatter + "Before starting work" prelude
  D4 ✗ pm/codebases.md is missing
       → author with one Variant B entry for `code/backend/` (NestJS detected)
  D5 ✓ docs/skills-registry.md present
  D6 ✓ docs/tech-docs-registry.md present
  D7 ✗ docs/feature-overlap-registry.md missing
       → copy from template
  D8 ✗ AGENTS.md missing "Rule: Dispatching sub-agents"
       → insert after referenced-codebases rule
  D9 ✗ feedback-subagent-write-permissions.md missing from user memory
       → seed via Step 8 mechanism

Reply:
  "migrate"     — apply all drift fixes above (recommended)
  "migrate D1 D2 D3" — apply only the listed items
  "skip"        — leave drift alone; treat this as a discovery run on top
                  of existing artifacts (Step 2 interview, layer new work)
  "abort"       — exit; user resolves drift manually
```

Do not proceed until the user confirms or amends.

#### Apply the migration plan

For each confirmed drift item, apply the migration action **inside a worktree** (the scaffold is changing files in the user's repo — same worktree-and-PR discipline AGENTS.md describes for any other work). The scaffold:

1. Creates a worktree at `.worktrees/scaffold/migrate-<YYYYMMDD-HHMM>` off the current HEAD.
2. Applies each confirmed drift fix in the worktree, in detector order (D1 → D9). Order matters: D1 (CLAUDE.md → AGENTS.md) must complete before D8 (which edits AGENTS.md), and D2 (skills move) must complete before D5–D7 (which write under `docs/` but reference `skills/README.md`).
3. Stages each fix as a separate commit so the user can review the diff per drift item: `D1: rename CLAUDE.md → AGENTS.md + symlink`, `D2: move .claude/skills → skills/ + symlink`, etc.
4. Pushes the branch and opens a PR with the drift report as the body.
5. Reports the PR URL — the user reviews and merges.

If the user picked `skip`, proceed to Step 2 with a flag noting which detectors were skipped. The Step 9 summary will surface the unmigrated drift so the user can return to it later.

#### Idempotent re-run

Running this skill on a fully-migrated project produces an all-`✓` drift report and skips Step 1.5 entirely (no PR opened, no migration prompts). Running on a partially-migrated project (e.g. user resolved D1–D5 manually but not D8–D9) produces a drift report showing only the remaining items.

#### Standalone migration

For users who don't want to re-invoke the full scaffold just to pick up D10/D11's changes (the v1.0.0 → post-v1 personas-and-sub-agents migration), the scaffold ships a standalone shell script:

```bash
# From the project root (a project scaffolded against v1.0.0 of this skill):
bash <path-to-scaffold>/scripts/migrate-personas-to-voltagent-subagents.sh
```

The script:

- Detects the scaffold install location (works whether the scaffold lives at `~/.claude/skills/agent-workflow-scaffold`, `skills/agent-workflow-scaffold`, or anywhere else).
- For each `agents/*.md` file in the user's project, checks for the `## Available sub-agents for delegation` heading.
- If missing and the filename matches an off-the-shelf persona (backend-engineer.md, frontend-engineer.md, qa-engineer.md, platform-engineer.md, product-designer.md, legal-advisor.md, project-manager.md, engineering-manager.md, pilot-lead.md, orchestrator.md, personal-assistant.md), appends the section verbatim from the matching `templates/agents/<name>.md` in the scaffold install.
- If the filename is a custom persona, prints a "manual: see docs/subagents-registry.md" line and skips that file.
- Also creates `docs/subagents-registry.md` from the scaffold's template if it doesn't already exist (the D10 step).
- Runs inside a worktree (`.worktrees/migrate-voltagent-subagents/`), commits per persona with a clear message (`migrate: add Available sub-agents section to <persona>`), pushes the branch, opens a PR — same discipline the scaffold's own Step 1.5 migration uses.
- Is idempotent: re-running on an already-migrated project detects every persona has the section and exits with "no migration needed."

The script is the same logic as Step 1.5's D10/D11 detectors — written as a one-shot for users who want a quick `bash` invocation without re-running the full discovery interview.

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

About your AI coding tools:
14) Which AI coding tools does the team use? (Pick all that apply;
    determines which per-tool symlinks/configs Step 4a creates so
    AGENTS.md and skills/ are findable by every tool without
    parallel files.)
      - Claude Code              (always wired by default)
      - OpenCode
      - GitHub Copilot
      - Cline
      - Cursor
      - Aider
      - Continue
      - Other (specify; scaffold will document but not auto-wire)

About reinforcing what you learn from the work:
15) Do you want to install the `learning-opportunities` skill?
    The skill (https://github.com/DrCatHicks/learning-opportunities)
    offers 10-15 minute deliberate-practice exercises after architectural
    work — prediction, generation, retrieval, teach-back. It builds your
    expertise alongside the agents instead of letting them carry it for
    you. The skill triggers itself on its own evidence-based conditions
    (significant architectural work; capped at 2 exercises per session;
    respects any earlier "no").

    If yes, the scaffold also installs a UserPromptSubmit hook that
    re-opens the skill's invocation question every N minutes of cumulative
    interaction time — a clock-based re-check on top of the skill's native
    rhythm, NOT an override. Default cadence: 60 minutes. Editable
    afterwards in user memory (set to 0 to disable the cadence hook; the
    skill's native triggers still apply).

      - Yes, install + 60-minute cadence
      - Yes, install + custom cadence (state minutes; "0" = native triggers only)
      - No
```

Wait for answers before doing anything else. If the user gives a partial answer — e.g. only items 1, 3, 6, 7, 12 — that's fine; proceed with what you have and infer rather than re-asking.

### Step 2b — Codebase setup (run once per codebase listed in Q12)

Before synthesizing the persona proposal in Step 3, walk each codebase the user listed and gather the operational context the agents will need at dispatch time.

**If the user said "none yet" in Q12** (i.e. the project itself is the only codebase), still produce one Variant B entry for the project — see 2b.0 below — so `pm/codebases.md` ships with the project's stack inventory ready for personas. The standard worktree-and-PR rules from `AGENTS.md` cover it; you skip 2b.2 / 2b.3 / 2b.4 (the git-remote / base-branch / user-feature-branch fields don't apply to in-repo workstreams).

**If the user said "monorepo with workstreams"**, treat each named workstream subdirectory as a separate Variant B entry.

For each codebase the user listed, perform these checks **in order**, then aggregate the results into a `pm/codebases.md` entry plan that you'll write in Step 4.

#### 2b.0 — Pick the variant (external vs. in-repo)

The `pm/codebases.md` template ships with two entry shapes:

- **Variant A — external codebase:** absolute path on the user's machine, separate git remote, separate base branch shared with other contributors, separate user-owned feature branch agents target with PRs. The "never push to base branch" rule applies. Used for partner repos, separate-app repos, any codebase the user contributes to alongside other people.
- **Variant B — in-repo workstream:** subdirectory of this project (e.g. `code/backend/`, `code/infra/`, `apps/web/`). Shares this repo's git history, this repo's base branch, this repo's worktree-and-PR flow per `AGENTS.md`. No separate base or feature branches. Used for monorepo workstreams and the "single repo, one project" case.

Pick the variant per codebase the user listed:

```bash
# Resolve project root (the directory you're scaffolding into)
project_root="$(pwd)"

# Resolve the codebase path; compare absolute paths
codebase_abs="$(cd "{{LOCAL_PATH}}" 2>/dev/null && pwd)" || codebase_abs="{{LOCAL_PATH}}"

# Variant B if the codebase path resolves inside the project root
case "$codebase_abs" in
  "$project_root"|"$project_root"/*) variant="B" ;;
  *) variant="A" ;;
esac
```

Variant A continues with 2b.1 → 2b.2 → 2b.3 → 2b.4 → 2b.5 → 2b.6 → 2b.7.
Variant B skips 2b.2 (the codebase is this project's git repo — already known), 2b.3 (the base branch is this project's default branch — already known), and 2b.4 (no separate user feature branch). It runs 2b.1 → 2b.5 → 2b.6 → 2b.7.

#### 2b.1 — Verify the path exists

```bash
test -d "{{LOCAL_PATH}}" && echo OK || echo MISSING
```

If the path is missing, ask the user to correct it (typo, wrong machine, etc.) before continuing. Don't skip — a wrong path means every subsequent agent dispatch fails.

#### 2b.2 — Confirm it's a git repo and capture the remote *(Variant A only)*

```bash
cd "{{LOCAL_PATH}}" && git rev-parse --is-inside-work-tree && git remote get-url origin
```

If the path is a directory but not a git repo, ask the user how to proceed: (a) `git init`, (b) skip this codebase, (c) abort and re-add later. Don't auto-init — that's a destructive choice on someone else's machine.

For Variant B (in-repo workstream), this step is a no-op — the codebase is the current project's git repo and the remote is already known.

#### 2b.3 — Detect the base branch *(Variant A only)*

Skip for Variant B — the workstream lives in this project's repo, so its base branch is the project's default branch (already known).

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

#### 2b.4 — Determine the user's feature branch *(Variant A only)*

Skip for Variant B — in-repo workstreams use this project's standard `AGENTS.md` worktree flow (branch off the default branch, PR back to it). No separate user feature branch.

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

##### Auto-stub unrecognized tech (don't ask-and-defer)

If a technology appears in the codebase but is **not** in `docs/tech-docs-registry.md`, **append a TODO row** to the user's local registry instead of asking and proceeding-without-the-link. The previous version's "want to add one?" prompt is too easy to defer mid-discovery; the result is a permanent gap nobody comes back to fix.

For each unrecognized tech, append a row to a dedicated section at the bottom of `<project>/docs/tech-docs-registry.md`:

```markdown
## Detected during codebase scan — needs review

| Detector | Technology | Doc URL | Notes |
| --- | --- | --- | --- |
| `<package-name>` | <inferred-pretty-name> | `# TODO: official docs URL` | Detected in `<codebase-name>`, scan date `<YYYY-MM-DD>`. Replace this row with a real entry once the URL is found. |
```

**Idempotency.** Before appending, grep the existing registry for the detector string:

```bash
grep -F "| \`<package-name>\` |" docs/tech-docs-registry.md
```

If the detector is already listed (in either the curated sections or the auto-stub section), skip — don't duplicate. The user may have already replaced the TODO with a real entry; re-running the scaffold should pick that up rather than re-stubbing.

**Heading creation.** If the `## Detected during codebase scan — needs review` heading doesn't exist yet, create it (with the table header row) before the first append. Subsequent runs append rows under the existing heading.

**Don't auto-stub the canonical templates.** These TODOs land in the user's *project copy* of the registry, not in `templates/docs/tech-docs-registry.md` in this skill repo. The canonical templates stay curated and small.

Track the count of TODO rows added (separately for first-time appends and skipped duplicates) for Step 9's summary.

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

On `n` (legitimately coexist), record nothing — the user has explicitly said the pair is fine.

##### Auto-stub deferred candidates (don't drop them on `skip`)

On `skip` (the user isn't sure yet), **append a "needs review" entry** to the user's local `docs/feature-overlap-registry.md`. Like 2b.5, the previous "skip and forget" path lost the signal entirely; the candidate disappeared between runs even though it was still real.

Append to a dedicated section at the bottom of `<project>/docs/feature-overlap-registry.md`:

```markdown
## Detected overlap — needs review

### <category description>

- `<older-lib>` — last touched <older-date>; detected in <codebase-name>
- `<newer-lib>` — introduced <newer-date>; detected in <codebase-name>

The user deferred the deprecation question on this pair (scan date <YYYY-MM-DD>). Decide whether `<older-lib>` is deprecated in this project and update the relevant persona's Working patterns accordingly.
```

**Idempotency.** Before appending, grep for the pair:

```bash
grep -F "<older-lib>" docs/feature-overlap-registry.md | grep -q "needs review"
```

If a "needs review" entry for this pair already exists, skip — the user is still deferring and re-stubbing adds noise. Re-running the scaffold after the user has resolved the pair (either by replacing the entry with a real "Use X; Y is deprecated" note or by deleting it) will re-detect and re-prompt cleanly.

Track the count of "needs review" entries added (and skipped duplicates) for Step 9's summary.

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

After completing 2b.0 through 2b.7a for all codebases, you have:

- A list of validated codebase paths, each tagged with **Variant A** or **Variant B**.
- For Variant A: remote URLs, base branches, user feature branches.
- A technology inventory per codebase with doc URLs ready to inject.
- A list of confirmed deprecation notes per codebase.
- A list of project-local skills drafted at `skills/<codebase-slug>/SKILL.md` (if any).

Carry all of this into Step 3's synthesis. When Step 4 writes the populated `pm/codebases.md`, render each codebase using the matching variant block from `templates/pm/codebases.md`:

- For Variant A entries, use the `## Variant A — external codebase entry template` block, substituting all placeholders.
- For Variant B entries, use the `## Variant B — in-repo workstream entry template` block, substituting only the placeholders that apply (no remote URL, no base branch, no user feature branch).
- Strip the `## Variant A — …` / `## Variant B — …` template-header lines and the HTML comment from the rendered output — the user's `pm/codebases.md` should contain only the populated entries plus the file's static introduction and footer.

The synthesis proposal in Step 3d (Codebase plan summary) now includes the variant per codebase entry the user will see, the local skills drafted, and the standard personas that own each codebase (no codebase-niche personas — niche knowledge lives in the local skills instead).

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

#### 3c-sub. VoltAgent sub-agent plugins

Cross-reference the confirmed persona shortlist against `templates/docs/subagents-registry.md` to compute the **VoltAgent plugin set**. Sub-agents are technology-specialist agents from the [VoltAgent awesome-claude-code-subagents](https://github.com/VoltAgent/awesome-claude-code-subagents) marketplace (10 category plugins, 141 sub-agents). They complement the scaffold's role-based personas: a Backend Engineer dispatches `python-pro` for deep Python work; an Orchestrator dispatches `multi-agent-coordinator` for fan-out tasks.

Per persona, list the **primary plugins** (always relevant) and **conditional plugins** (relevant when the user's stack indicates them). Example for a Python-stack project:

```
Backend Engineer
  Primary:     voltagent-core-dev (backend-developer, api-designer, microservices-architect, …)
               voltagent-lang     (python-pro, fastapi-developer, sql-pro)
  Conditional: voltagent-data-ai  (postgres-pro)  — recommended given Postgres in the stack

QA Engineer
  Primary:     voltagent-qa-sec   (qa-expert, test-automator, accessibility-tester, …)

Orchestrator
  Primary:     voltagent-meta     (multi-agent-coordinator, workflow-orchestrator, …)
```

Personas without a primary plugin (Personal Assistant) are noted explicitly so the user knows nothing is suggested for them.

The scaffold does **not** auto-install in this step — that's coached in Step 7h (default-NO consent prompt with copy-paste commands) since marketplace plugins are user-globally persistent and `claude` CLI may not be plugin-authenticated yet on the user's machine.

#### 3c-bis. PM-tool plan

Based on Q9a, summarize the project-management plan in one of three modes:

- **Mode A — PM tool with vendor MCP** (Linear / Jira / Notion / GitHub Issues): tell the user the scaffold will (1) generate `pm/backlog.md` as a thin pointer doc rather than the rich template, (2) draft a project-local PM skill at `skills/pm-<tool>-<project-slug>/SKILL.md` (from `pm-skill-template`) that captures workspace + label conventions, (3) auto-enable the PM-tool MCP in `.mcp.example.json`, and (4) add two `## Project-specific rules` to `AGENTS.md` (PM tool is source of truth; PR titles must include the issue prefix). `pm/management.md` and `pm/roadmap.md` still ship as files since they hold strategy and leadership prose, not ticket detail.
- **Mode B — PM tool with API but no vendor MCP** (Asana / Trello / Monday / ClickUp / Shortcut / Pivotal / etc.): tell the user the scaffold will (1) generate `pm/backlog.md` as a thin pointer doc, (2) draft a project-local PM skill at `skills/pm-<tool>-<project-slug>/SKILL.md` (from `pm-skill-api-template`) that wraps the tool's REST/GraphQL API with project-specific conventions and `curl` / fetch examples, (3) add a `<TOOL>_PERSONAL_ACCESS_TOKEN=` slot to `.env.example` (and append to `.env` if it exists, leaving it empty for the user to fill), and (4) add the same two `## Project-specific rules` to `AGENTS.md` as Mode A. The user provides their PAT on first use; the scaffold does **not** ship credentials.
- **Mode C — Files only**: tell the user `pm/backlog.md` is the live source of truth (rich template). No PM skill is created. No `.env` mutations.

Show one example of what `pm/backlog.md` will look like in their chosen mode (paraphrased — don't reproduce the full template). The user confirms or amends in 3e.

#### 3d. Codebase plan summary

Summarize the codebase plan from Step 2b. For each codebase, show:

- **Variant** — A (external codebase) or B (in-repo workstream)
- Local path
- For Variant A only: detected base branch (or "manual entry from user" if 2b.3 fell through), proposed user's feature branch (or "user creates manually" if 2b.4's offer was declined)
- Tech inventory bullets (one line each)
- Deprecation candidates the user confirmed (if any)
- Owning persona(s) — point at one or more entries from 3a
- **Project-local skill** at `skills/<codebase-slug>/SKILL.md` if Step 2b.7 surfaced one, with a one-line description of what the drafted skill contains

Example with one of each variant:

```
Codebase: api-server (Variant A — external)
  Path: /Users/khalil/Code/ar-graffiti-api
  Base branch: main (auto-detected; read-only to agents)
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

Codebase: backend (Variant B — in-repo workstream)
  Path: code/backend/  (this project's repo; AGENTS.md main-branch flow applies)
  Stack: Node 22, TypeScript, NestJS on Fastify, Postgres + PostGIS, Redis
  Deprecation: (none)
  Owned by: Backend Engineer, QA Engineer, Platform Engineer
  Project-local skill: (none — covered by standard personas)
```

If the user said "none yet" in Q12, this subsection still appears: the project itself is registered as a single Variant B entry so personas have a stack-inventory pointer (the standard `main`-branch flow in `AGENTS.md` covers the workflow side).

#### 3e. Confirmation

After presenting 3a + 3b + 3c + 3c-sub + 3c-bis + 3d, ask the user one clear confirm-or-edit question:

```
Does this look right? Reply "ship it" to generate everything as listed, or
tell me what to add / remove / rename / update.
```

Do not proceed until the user confirms or amends. If they edit the proposal, regenerate 3a–3d (including 3c-sub) with their changes and re-confirm.

### Step 4 — Generate the universal subset and the *confirmed* personas

Once the proposal is confirmed, write the files. **Personas are written from the confirmed list only** — the scaffold no longer defaults to writing all six.

#### AGENTS.md merge — never overwrite the user's content

The `AGENTS.md` write is the one entry in the universal subset that is **not a plain template render**. Before writing, the scaffold checks for pre-existing user content and merges instead of overwriting:

1. **Detect pre-existing user content.** Run these checks in order:
   - If `AGENTS.md` exists as a regular file (not a symlink): the user has prior content here — either from a Step 1.5 D1 rename earlier in this same run, from a previous scaffold run, or because the user authored their own. Read it into memory as `existing_content`.
   - Else if `CLAUDE.md` exists as a regular file (not a symlink to `AGENTS.md`): the user picked `skip` in Step 1.5 (or D1 didn't run for some other reason) and their original CLAUDE.md is still in place. `git mv CLAUDE.md AGENTS.md` and read the result as `existing_content`.
   - Else: there is no pre-existing user content. `existing_content` is empty.

2. **Detect whether `existing_content` already contains the scaffold's universal sections.** Grep for the load-bearing anchors:
   - `## Git Workflow — MANDATORY for all agents`
   - `### Rule: Work in a worktree, ship via pull request`
   - `### Rule: Working in *referenced* codebases (multi-repo work)`
   - `### Rule: Dispatching sub-agents`
   
   If all four anchors are present, the file is a previously-rendered scaffold output (or a hand-port of it) — **do nothing**, leave it as is. Re-running the scaffold should be idempotent on this file.

3. **Otherwise, merge.** Render `templates/AGENTS.md` with the standard substitutions to produce `scaffold_content`, then write `AGENTS.md` as:

   ```
   <scaffold_content rendered from templates/AGENTS.md>

   ---

   ## Existing project rules (preserved from CLAUDE.md)

   <user's existing_content, verbatim — no reformatting, no reordering>
   ```

   The delimiter heading makes the source of each section unambiguous to a future reader. The scaffold's universal sections are first (load-bearing for git discipline); the user's prior rules are second under the preservation heading. Nothing the user wrote is deleted, reformatted, or reordered. Step 5's project-specific rules append below the preserved-content block.

4. **If `existing_content` was empty**, just render `templates/AGENTS.md` straight to `<project>/AGENTS.md` (the original behavior for fresh projects).

5. **Tell the user what merged**, in the Step 9 summary:
   - "✓ AGENTS.md: scaffold's universal sections written; your existing CLAUDE.md content preserved verbatim under `## Existing project rules (preserved from CLAUDE.md)`"
   - Or "✓ AGENTS.md: written fresh (no existing user content found)"
   - Or "✓ AGENTS.md: already had the scaffold's universal sections; left untouched"

The same merge logic applies even when Step 1.5 detected the project as `current` (no drift) — if a `CLAUDE.md` or `AGENTS.md` slipped in from another source (a manual hand-edit, a copy-paste from another project), the scaffold preserves it.

#### Universal-subset files

Files **always** written (the universal subset, not persona-dependent):

| Source | Destination | Substitutions |
|---|---|---|
| `templates/AGENTS.md` | `<project>/AGENTS.md` *(merged with any pre-existing user content per the AGENTS.md merge rule above; never plain-overwrite)* | `{{PROJECT_NAME}}`, `{{REPO_OWNER_REPO}}`, `{{PRIMARY_STACK}}` |
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
| `templates/docs/subagents-registry.md` | `<project>/docs/subagents-registry.md` | none |
| `templates/pm/codebases.md` | `<project>/pm/codebases.md` | Variant-aware (see Step 2b.0). For each codebase: pick Variant A or B, render the matching template block, strip the `## Variant <X> — …` header lines and the HTML comment from the rendered output. Variant A substitutions: `{{CODEBASE_NAME}}`, `{{LOCAL_PATH}}`, `{{REMOTE_URL}}`, `{{BASE_BRANCH}}`, `{{USER_FEATURE_BRANCH}}`, `{{SCAN_DATE}}`, `{{LANGUAGES}}`, `{{FRAMEWORKS}}`, `{{BUILD_TOOLING}}`, `{{INFRASTRUCTURE}}`, `{{OTHER_LIBRARIES}}`, `{{OWNING_PERSONAS}}`, `{{DOC_LINKS}}`, `{{DEPRECATION_NOTES}}`, `{{LOCAL_SKILL_PATH}}`. Variant B substitutions: same minus `{{REMOTE_URL}}`, `{{BASE_BRANCH}}`, `{{USER_FEATURE_BRANCH}}`. |
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
| `templates/agents/custom-skeleton.md` | `<project>/agents/<role-slug>.md` | All `{{PERSONA_*}}`, `{{ROLE_PARAGRAPH}}`, `{{DOCUMENTS_LIST}}`, `{{BRANCH_PREFIX}}`, `{{WORKING_PATTERNS_BULLETS}}`, `{{PRIMARY_PARTNER_PERSONA}}`, etc. — populated from the discovery answers. `{{SUBAGENT_SECTION}}` is filled by matching the user's role description (Step 2 Q1 + Q3) against the keyword index in `templates/docs/subagents-registry.md` and rendering a "Recommended sub-agents" bullet list — see Step 4b below. |
| `templates/agents/personal-assistant.md` | `<project>/agents/personal-assistant.md` | `{{PROJECT_NAME}}` |
| `templates/pm/goals.md` *(only if Personal Assistant was confirmed in 3a)* | `<project>/pm/goals.md` | `{{PROJECT_NAME}}` |
| `templates/pm/assistant-log.md` *(only if Personal Assistant was confirmed)* | `<project>/pm/assistant-log.md` | `{{PROJECT_NAME}}` |

The MCP-integration files (`templates/mcp.example.json` → `.mcp.example.json`, `templates/integrations.md` → `docs/integrations.md`) are written by Step 6 below, after the explicit MCP confirmation. The skill installs are handled by Step 7. Step 5 below handles the rules.

After writing the personas, append a **Required skills** section to the bottom of `agents/README.md` (in the user's project) listing each (persona → skill) dependency in a small markdown table. This is the single readable summary a future contributor sees.

#### Step 4b — Render `{{SUBAGENT_SECTION}}` for custom personas

The off-the-shelf persona templates ship with a hand-curated **Available sub-agents for delegation** section already populated. Custom personas (rendered from `templates/agents/custom-skeleton.md`) have a `{{SUBAGENT_SECTION}}` placeholder the scaffold fills in here.

For each `custom-skeleton.md`-based persona:

1. Take the user's role description (Step 2 Q1 + Q3) plus the role title (Q1) and any specialty workflows (Q10).
2. Match those against the **keyword index** at the bottom of `templates/docs/subagents-registry.md`. Each keyword row maps to one or more recommended plugins and top matching sub-agents.
3. Render the matched plugins + sub-agents using the same shape as the off-the-shelf personas (intro paragraph → role-level decisions → sub-agents list):

   ```markdown
   When work calls for deep technology specialization, dispatch the relevant sub-agent from the [VoltAgent](https://github.com/VoltAgent/awesome-claude-code-subagents) plugin set. **You make the role-level decisions and write the dispatch brief; the sub-agent handles the technical depth.** See `AGENTS.md` "Rule: Brief sub-agents with persona context" for the briefing protocol.

   ### Role-level decisions you keep — never delegate

   *(infer from the user's discovery answers — what does this role uniquely decide vs. what could be delegated? Surface 4–7 bullets covering the persona's core scope. If the role description is too sparse to infer specifics, leave a placeholder telling the user to fill these in by reviewing the off-the-shelf personas as examples.)*

   - {{ROLE_LEVEL_DECISION_1}}
   - {{ROLE_LEVEL_DECISION_2}}
   - …
   - **Findings from prior dispatches.** Repeat insights across briefs so the sub-agent doesn't re-derive them.

   ### Sub-agents available

   - **`<sub-agent-name>`** (`<plugin-name>`) — <one-line description>
   - **`<sub-agent-name>`** (`<plugin-name>`) — <one-line description>
   …

   Install the plugin(s) via `claude plugin install <plugin> [<plugin>…]` (after a one-time `claude plugin marketplace add VoltAgent/awesome-claude-code-subagents`). See [`docs/subagents-registry.md`](../docs/subagents-registry.md) for the full mapping.
   ```

4. If no keyword matches the role (an unusual / one-off role), render a fallback section that still names the briefing rule:

   ```markdown
   No off-the-shelf sub-agents in the [VoltAgent](https://github.com/VoltAgent/awesome-claude-code-subagents) marketplace match this persona's role directly. See [`docs/subagents-registry.md`](../docs/subagents-registry.md) — if any of the listed sub-agents apply, edit this section to reference them. If you do dispatch sub-agents, follow `AGENTS.md` "Rule: Brief sub-agents with persona context" — surface the role-level decisions, project context, and prior findings in every dispatch brief.
   ```

5. Substitute the rendered content for `{{SUBAGENT_SECTION}}` in the rendered persona file. The retained boilerplate ("the scaffold injected the sub-agent recommendations above…") stays so the user knows the section is editable. The role-level-decisions list is the most valuable thing for the user to refine — encourage it explicitly in the post-scaffold "Next steps" summary.

#### Step 4a — Create platform-compatibility symlinks and configs

Make the project's vendor-neutral file layout discoverable by every AI coding tool the team uses (Q14). All actions below are **idempotent** — they only create files when absent, never clobber existing setup. If a real file or different setup already exists at any of these paths, surface the conflict to the user and skip that step.

##### 4a.1 — Always create (Claude Code support)

These two symlinks ship by default regardless of Q14, because Claude Code is the scaffold's home base:

```bash
# CLAUDE.md → AGENTS.md
[ -e CLAUDE.md ] || ln -s AGENTS.md CLAUDE.md

# .claude/skills → ../skills
mkdir -p .claude
[ -e .claude/skills ] || ln -s ../skills .claude/skills
```

##### 4a.2 — Per-tool actions (run once per tool the user picked in Q14)

The following table maps each tool to the action the scaffold takes. Most modern AI coding tools support `AGENTS.md` natively, so the action is "no-op + verify"; some need a symlink to a tool-specific filename or a small config entry.

| Tool | AGENTS.md native? | Action |
|------|-------------------|--------|
| **OpenCode** | ✅ YES — canonical filename | No symlink. Tell the user: "OpenCode reads AGENTS.md natively; commit it to git so the team shares the rules. OpenCode also supports project-local agents at `.opencode/agents/<name>.md` if you want full subagent definitions with permissions/mode/model — different concept from Claude Code's `skills/`. See `skills/README.md` for the cross-tool table." |
| **GitHub Copilot** | ✅ YES — proximity-based precedence | Create symlink `.github/copilot-instructions.md → ../AGENTS.md` so Copilot's repo-wide instructions resolve to the canonical source. Path-specific instructions (`.github/instructions/*.instructions.md` with `applyTo` glob frontmatter) are a different concept; document but don't auto-create. |
| **Cline** | ✅ YES | No symlink. Tell the user: "Cline reads AGENTS.md natively. Project-local Cline rules live at `.clinerules/` (directory of `.md`/`.txt` files) — different concept from `skills/`; create those manually if you want them." |
| **Cursor** | ✅ YES — recent versions | No symlink. Tell the user: "Modern Cursor reads AGENTS.md natively. Project rules in `.cursor/rules/*.mdc` use a different format (frontmatter with `globs` + `alwaysApply`) — different concept from `skills/`; create those manually if you want them." Verify Cursor version supports AGENTS.md (older versions used `.cursorrules`). |
| **Aider** | ❌ NO auto-discovery | Aider doesn't auto-scan; it only reads files explicitly loaded via `/read` or `.aider.conf.yml`. Create `.aider.conf.yml` (or append if it exists) with `read: AGENTS.md`. Sample: |
| **Continue** | ✅ YES (recent versions) | No symlink. Tell the user: "Recent Continue reads AGENTS.md natively. Custom slash-commands live in `.continue/config.json`; rules in `.continue/rules/*.md` if you use that feature." |

For Aider, the config snippet to write/append:

```yaml
# .aider.conf.yml — auto-loaded by Aider sessions in this project
read: AGENTS.md
```

If `.aider.conf.yml` already exists, append the `read:` entry to it (handle both YAML-list and YAML-scalar shapes correctly — if `read:` already lists files, add `AGENTS.md` to that list rather than duplicating the key).

For GitHub Copilot, the symlink:

```bash
mkdir -p .github
[ -e .github/copilot-instructions.md ] || ln -s ../AGENTS.md .github/copilot-instructions.md
```

##### 4a.3 — Cross-platform note

Symlinks work natively on macOS and Linux. On Windows, git's `core.symlinks` config must be enabled (true by default since Git 2.10 with developer mode, but verify) — otherwise the symlink lands as a regular text file containing the target path. If the user is on Windows, flag this in the Step 9 summary and link to <https://git-scm.com/docs/git-config#Documentation/git-config.txt-coresymlinks>.

##### 4a.4 — Surface what was wired

After running the per-tool actions, capture the result for the Step 9 summary:

- Which symlinks/configs were created (and their canonical targets).
- Which tools were "no-op + verify" (and the version users should ensure they're on).
- Any conflicts where a real file already existed and the scaffold skipped — list these so the user can resolve manually.
- For each tool whose project-local "skills" equivalent has a *different* concept than `skills/<name>/SKILL.md` (Cursor's rules, Cline's rules, OpenCode's agents, Copilot's instructions), one-line note pointing at `skills/README.md`'s cross-tool table for the manual conversion.

#### Codebase ↔ persona linking

For every codebase Step 2b scanned, edit each owning persona file (the personas listed in 3d as "Owned by") to:

1. **Inject doc links into Key References.** Append the codebase's tech inventory doc URLs (from 2b.5) to the persona's Key References section — formatted as `- [<Tech name>](<doc-url>) — used in <codebase-name>`. Skip technologies the persona's owning surface clearly doesn't cover (e.g. don't inject Terraform docs into Frontend Engineer).
2. **Inject deprecation notes into Working patterns.** For every confirmed deprecation note from 2b.6, append a working-pattern bullet of the form: "Use `<newer-lib>`; `<older-lib>` is deprecated in `<codebase-name>` (since `<date>`). Do not extend `<older-lib>`-using code; migrate when touching adjacent files." Place this in the persona whose surface the libraries cover (e.g. Backend Engineer for `jose` vs `jsonwebtoken`).
3. **Add a Codebases section.** If the persona owns one or more codebases, add a new `## Codebases owned` section between Working patterns and Relationships, listing each codebase by name with a one-line scope description and a link to its `pm/codebases.md` entry.

If the user declined to create a feature branch in 2b.4 for any **Variant A** codebase, add a follow-up note at the bottom of `pm/codebases.md` for that codebase: "**Pending user action:** create the user's feature branch (`{{USER_FEATURE_BRANCH}}`) from `{{BASE_BRANCH}}` and push to origin before any agent dispatch against this codebase." (Variant B entries don't have a separate feature branch and don't need this note.)

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

#### Multi-codebase rules (only if Step 2b registered at least one Variant A external codebase)

If `pm/codebases.md` contains at least one **Variant A** (external codebase) entry, append the following to the bottom of `AGENTS.md`'s `## Project-specific rules` (do not paraphrase — these are load-bearing for the multi-codebase PR discipline):

```
- When working in any external codebase listed in `pm/codebases.md`,
  agents MUST open PRs against that codebase's **User's feature branch**,
  NEVER against its base branch. The base branch is read-only to agents;
  the user merges from the feature branch to base via their own review
  process. (This rule applies only to Variant A entries — in-repo
  workstreams (Variant B) follow this project's standard `main`-branch
  flow.)
- Before dispatching a sub-agent on a ticket scoped to a Variant A
  codebase, the orchestrator must read the codebase's `pm/codebases.md`
  entry and pass the local path, base branch, and user's feature branch
  to the sub-agent.
```

These rules complement the existing "Rule: Working in *referenced* codebases" section in `AGENTS.md`'s Git Workflow chapter (which the universal template already includes). The Project-specific rules entry serves as the merge-time merge-blocker; the Git Workflow section is the operational handbook.

If all `pm/codebases.md` entries are **Variant B** (in-repo workstreams), skip this sub-step — the standard `AGENTS.md` worktree-and-PR rules already cover them, and adding the Variant A rule would mislead agents into looking for non-existent feature branches.

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

Substitute the answers into the API template, write to `skills/pm-<tool-slug>-<project-slug>/SKILL.md`, and edit `.env.example` / `.env`.

##### Append the empty token slot to `.env.example`

```bash
# Append to .env.example (create if missing)
echo "" >> .env.example
echo "# {{PM_TOOL_NAME}} personal access token (5b-API)" >> .env.example
echo "# Generate at: {{PM_TOOL_TOKEN_GENERATION_URL}}" >> .env.example
echo "{{PM_TOOL_AUTH_ENV_VAR}}=" >> .env.example
```

##### Append the empty token slot to `.env` if it exists — with edge-case handling

A naive `echo >> .env` corrupts the file in several real-world cases. Run these checks **before** appending; if any fails, skip the auto-append and surface the manual step in Step 9's summary instead.

```bash
if [ -e .env ]; then
  # 1. Symlink — don't auto-write through it. The target may live in a
  #    secrets store (1Password CLI agent, system keychain export) the user
  #    doesn't want a stray echo to touch.
  if [ -L .env ]; then
    echo "SKIP: .env is a symlink to $(readlink .env). Add {{PM_TOOL_AUTH_ENV_VAR}}= manually."
    skip_env_append=true

  # 2. git-crypt encrypted — the file starts with the magic bytes
  #    \x00GITCRYPT and isn't valid plaintext at scaffold time. Appending
  #    raw bytes corrupts the file. The user must decrypt, edit, re-encrypt.
  elif head -c 9 .env | od -An -c | grep -q "G I T C R Y P T"; then
    echo "SKIP: .env is git-crypt encrypted. Decrypt, add {{PM_TOOL_AUTH_ENV_VAR}}=, re-encrypt."
    skip_env_append=true

  # 3. Read-only — no write permission. The user may have set this on purpose.
  elif [ ! -w .env ]; then
    echo "SKIP: .env is read-only. chmod and add {{PM_TOOL_AUTH_ENV_VAR}}= manually if appropriate."
    skip_env_append=true

  # 4. CRLF line endings — appending LF mid-CRLF breaks parsers. Detect and
  #    match the existing file's line-ending shape.
  elif [ "$(file .env | grep -c CRLF)" = "1" ]; then
    printf '\r\n# {{PM_TOOL_NAME}} personal access token\r\n{{PM_TOOL_AUTH_ENV_VAR}}=\r\n' >> .env
  else
    # Standard case — LF line endings, regular file, writable, plaintext.
    printf '\n# {{PM_TOOL_NAME}} personal access token\n{{PM_TOOL_AUTH_ENV_VAR}}=\n' >> .env
  fi
fi
```

Verify `.env` is in `.gitignore` (the universal template puts it there; flag if it's missing).

If any of the four edge-case checks tripped, surface the file under Step 9's `Files written` section as a "manual step required" entry, not a silent failure: "**Manual step:** add `{{PM_TOOL_AUTH_ENV_VAR}}=<your-token>` to `.env` (skipped because `<reason>`)."

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

#### 7a. Validate persona frontmatter

Before aggregating skills, parse each persona file's YAML frontmatter explicitly. Persona files are user-editable; once a project is past day one, frontmatter drifts (added comments, hand-edited skill lists, accidental quote marks, list-vs-scalar shape mismatches). Without a validation pass, a malformed frontmatter silently drops that persona's skills from the install plan and the failure is invisible until a sub-agent dispatched on that persona reports a missing skill.

For each `agents/*.md` file:

1. **Read the first frontmatter block.** A valid block is fenced by `---` on its own line, opens at the top of the file, and closes before any body content. If the file doesn't open with `---`, treat it as "no frontmatter" — record this; some custom personas may legitimately not declare skills.
2. **Parse the YAML inside.** Capture parse errors verbatim — line number, the parser's message, the offending snippet (first 10 lines of the frontmatter).
3. **Validate the `required_skills:` shape.** It must be either:
   - `required_skills: []` (empty list — persona declares no skill dependencies), or
   - `required_skills:` followed by a list of one or more entries, each a string. Strings without quotes are fine (e.g. `figma:figma-use`); quoted strings are fine; mixed shapes are fine.
   - Anything else is invalid: scalar (`required_skills: figma:figma-use`), nested map, missing field with non-default-empty intent.
4. **Record the result** as one of: `clean`, `no-frontmatter`, `parse-error`, `wrong-shape`.

After scanning all personas, emit a summary block before the consent prompt in 7b:

```
Persona frontmatter scan:
  ✓ backend-engineer.md          — 0 skills
  ✓ frontend-engineer.md         — 0 skills
  ✓ orchestrator.md              — 0 skills
  ✓ project-manager.md           — 0 skills
  ✓ engineering-manager.md       — 0 skills
  ✓ product-designer.md          — 5 skills (figma:figma-use, figma:figma-code-connect, …)
  ⚠ qa-engineer.md               — frontmatter parse failed at line 3:
       expected mapping, got scalar
       ---
       required_skills: claude-api      <-- should be: required_skills: [claude-api]
       ---
  ⚠ legal-advisor.md             — no frontmatter detected (file starts with `# Legal Advisor`)

2 personas have unresolved skill declarations. Proceeding with the install plan
for the 5 personas that parsed cleanly. Fix the unresolved entries and re-run
this skill, or open the persona files and edit them directly — Step 7 picks up
the changes on the next pass.
```

The user can fix the parse errors in their editor, re-run the scaffold (which re-runs Step 7), and the install plan picks up the now-clean personas. Don't block on parse errors — proceed with the personas that parsed cleanly.

Carry the per-persona scan result forward to Step 9 so the summary surfaces which personas still have unresolved skill declarations.

#### 7b. Compute the install plan

Aggregate the `required_skills:` from cleanly-parsed personas into a deduplicated list. Cross-reference against `<project>/docs/skills-registry.md`. For each skill, classify into one of four lanes based on the registry's `Source` field:

- **`auto-install: git`** — skill source is `git`. The agent can `git clone` autonomously with consent.
- **`semi-auto: plugin`** — skill source is `plugin`. The agent prints the `/plugin install <plugin>` command for the user to run from inside Claude Code; the slash command is interactive and is not safely scriptable.
- **`already installed: builtin`** — skill source is `builtin` and it appears in the session's `<available-skills>` reminder. Nothing to do.
- **`coach: private`** — skill source is `private`. The registry's install URL is a placeholder. The agent prints the placeholder + tells the user to substitute the team-private URL or ask the persona owner.

Cross-reference against the session's `<available-skills>` reminder before classifying — anything already installed should drop out of the install plan entirely.

#### 7c. Auto-install the `auto-install: git` lane (with one-shot consent)

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

#### 7d. Coach the `semi-auto: plugin` lane

For each plugin-installable skill, group by plugin namespace and emit one line per unique namespace:

```
Run inside Claude Code (these are slash commands, not shell):
  /plugin install figma
  /plugin install <other-plugin>
```

Tell the user that after `/plugin install` completes, the plugin's skill family becomes available without restarting Claude Code.

#### 7e. Coach the `coach: private` lane

For each private-source skill, print the persona that requires it, the registry's placeholder install command, and the line:

```
The canonical install URL for `<skill-name>` is private to your team.
Substitute the URL the team uses, or ask the persona owner where to find it.
```

#### 7f. Don't block scaffold completion on install failures

If any auto-install fails or the user declines, the scaffold continues to Step 8. The summary in Step 9 surfaces what's still missing so the user can return to it. Reasons:

- The user can install skills any time after scaffolding.
- Some skills require credentials, SSO, or paid licenses the scaffold can't provide.
- Re-running the scaffold (or invoking the persona later) re-runs this step, so nothing falls through the cracks.

#### 7g. Don't auto-install without consent — even on "obvious" cases

The agent must ask before running `git clone` on the user's machine. The single batched consent prompt in 7c is the only point where it touches `~/.claude/skills/` or `skills/`. There is no implicit consent.

#### 7h. VoltAgent sub-agent plugins

For each persona confirmed in Step 3a, cross-reference [`docs/subagents-registry.md`](#) (which you've already written to the user's project in Step 4) to compute the **plugin set** to suggest. Aggregate across all confirmed personas, deduplicate, and present the plan.

##### 7h.1 — Compute the plugin set

The registry maps each off-the-shelf persona to **primary plugins** (always relevant) and **conditional plugins** (relevant when stack / work indicates them). For example:

- Backend Engineer + Python stack → `voltagent-core-dev`, `voltagent-lang`
- Backend Engineer + Postgres-heavy → also `voltagent-data-ai` (for `postgres-pro`, `database-optimizer`)
- Platform Engineer → `voltagent-infra`
- QA Engineer → `voltagent-qa-sec`
- Orchestrator persona → `voltagent-meta` (high-leverage pairing — the meta plugin's `multi-agent-coordinator` and `workflow-orchestrator` directly augment the dispatch loop)
- Personal Assistant → no primary plugin (the persona is purpose-built)

For **custom-skeleton.md**-based personas, match the user's role description (Step 2 Q1 + Q3) against the keyword index in `docs/subagents-registry.md` to pick plugins.

##### 7h.2 — Coach the marketplace add + plugin install

Print the batched commands the user can run to install the matching plugins. Don't auto-run unless the user explicitly opts in (most users won't have set up `claude` CLI plugin auth before scaffold time):

```
VoltAgent sub-agent plugins for your confirmed personas:

  Marketplace (one-time, if not already added):
    claude plugin marketplace add VoltAgent/awesome-claude-code-subagents

  Plugins to install:
    claude plugin install voltagent-core-dev      # Backend Engineer, Frontend Engineer (primary)
    claude plugin install voltagent-lang          # Backend Engineer, Frontend Engineer (primary)
    claude plugin install voltagent-qa-sec        # QA Engineer (primary), Engineering Manager
    claude plugin install voltagent-meta          # Orchestrator (primary), Engineering Manager

Run them now? (Y/n) [defaults to NO — skip]
```

The default is **NO** because:
- Marketplace plugins persist user-globally; the user should opt in explicitly.
- `claude` CLI may not be authenticated for plugin operations on this machine yet.
- Some users prefer to install only after they've reviewed each persona's Available-sub-agents section to confirm the plugins match their actual workflow.

On `Y`: run each command via Bash, capturing failures (e.g. `claude: command not found` → tell the user to install Claude Code CLI; "marketplace already added" → harmless, continue; "plugin already installed" → harmless, continue). Continue past non-fatal errors so one failed plugin doesn't block the rest.

On `N` or skipped: print the commands to copy-paste later. Surface them again in Step 9's summary.

##### 7h.3 — Don't vendor or redistribute

The scaffold ships **references** to VoltAgent sub-agents in `docs/subagents-registry.md` and in each persona's Available-sub-agents section. The actual sub-agent definitions live in the upstream marketplace; the user installs them via `claude plugin install`. The scaffold does **not** copy upstream files into the user's project, does not vendor anything, and does not commit any VoltAgent content.

##### 7h.4 — Idempotency

Re-running the scaffold reads the registry fresh, recomputes the plugin set against the (possibly updated) confirmed-persona list, and surfaces a delta:

- Plugins newly required (a new persona was confirmed → its primary plugins are added).
- Plugins no longer required (a persona was removed → its plugins move to "optional, was previously suggested").

The user decides whether to install the new ones or uninstall the old ones; the scaffold doesn't auto-uninstall.

#### 7i. Learning opportunities skill (Q15)

If Q15 was "no," skip this sub-section entirely. If yes, this sub-step installs the upstream marketplace plugin and wires the cadence re-check hook. The hook never overrides the skill's native trigger and suppression rules — it only re-opens the invocation question on a clock so a long session doesn't drift past a moment the skill would have otherwise caught.

##### 7i.1 — Coach the marketplace add + plugin install

Print the commands the user runs to install the upstream skill. Don't auto-run unless the user explicitly opts in (most users won't have set up `claude` CLI plugin auth before scaffold time):

```
Learning opportunities skill (Q15):

  Marketplace (one-time, if not already added):
    claude plugin marketplace add DrCatHicks/learning-opportunities

  Plugin to install:
    claude plugin install learning-opportunities@learning-opportunities

  Optional companion (post-commit hook from the same upstream):
    claude plugin install learning-opportunities-auto@learning-opportunities

Run them now? (Y/n) [defaults to NO — skip]
```

Default is **NO** for the same reasons as 7h.2 (marketplace plugins persist user-globally, `claude` CLI may not be authenticated yet). On `Y`: run each via Bash, treating "marketplace already added" / "plugin already installed" as harmless. On `N` or skipped: print the commands to copy-paste and surface them in Step 9's summary.

##### 7i.2 — Write the cadence hook + memory file

Independent of whether the user opted to run the plugin install in 7i.1 (they may install it manually later), wire the cadence infrastructure now:

1. **Hook script.** Copy `templates/.claude/hooks/learning-opportunities-cadence.sh` to `<project>/.claude/hooks/learning-opportunities-cadence.sh`. `chmod +x`. The script reads the cadence value from the user-memory context file at runtime, so no substitutions.

2. **Settings.json hook registration.** Register the hook on `UserPromptSubmit`. If `<project>/.claude/settings.json` doesn't exist, create it with:

   ```json
   {
     "hooks": {
       "UserPromptSubmit": [
         {
           "hooks": [
             { "type": "command", "command": "bash \"$CLAUDE_PROJECT_DIR/.claude/hooks/learning-opportunities-cadence.sh\"" }
           ]
         }
       ]
     }
   }
   ```

   If it exists, parse it as JSON, append the hook entry to `hooks.UserPromptSubmit` (creating the array if absent), and write back preserving the rest of the file. Idempotency: if a hook with this exact `command` is already registered, skip the write.

3. **User-memory cadence file.** Copy `templates/memory/learning-opportunities-context.md` to `~/.claude/projects/<project-slug>/memory/learning-opportunities-context.md`. If Q15 specified a custom cadence (e.g. "30"), substitute the integer in the `learning-opportunities-frequency-minutes:` line before writing. Default is 60. Add an entry to the project's `MEMORY.md` index pointing at the new file.

##### 7i.3 — Tell the user what was wired

Surface the three artifacts in Step 9's summary so the user knows what to edit if they want to change cadence later (the `learning-opportunities-frequency-minutes:` line in user memory). The skill's own README documents the native trigger and suppression rules; the scaffold doesn't re-document them.

##### 7i.4 — Don't override the skill's rhythm

Working principle: the cadence hook is a **clock-based re-check**, never an override. The injected message asks Claude to re-evaluate the skill's own trigger conditions on the current turn (architectural work + the 2-exercise session cap + respect for earlier declines). If those conditions don't apply, the hook is deferred-to silently — no exercise is forced. The skill author's evidence-based rhythm remains authoritative.

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
| `feedback-subagent-write-permissions.md` | feedback | Sub-agents in `isolation: "worktree"` typically cannot write files; the orchestrator's main session must author files and delegate only read-only research to sub-agents |
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

Update `MEMORY.md` to list seven entries (or eight if Personal Assistant was confirmed) with one-line descriptions.

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

AI tool wiring (from Step 4a):
  Claude Code:          ✓ CLAUDE.md → AGENTS.md, .claude/skills → ../skills
  <other tools per Q14, one line each, e.g.:>
  GitHub Copilot:       ✓ .github/copilot-instructions.md → ../AGENTS.md
  OpenCode:             native AGENTS.md (verify version >= 0.X)
  Aider:                .aider.conf.yml → read: AGENTS.md
  Cline:                native AGENTS.md (verify recent version)
  Cursor:               native AGENTS.md (verify Cursor 1.6+)
  <For tools whose project-local skill format differs from skills/<name>/SKILL.md
   (Cursor's .mdc, Copilot's .instructions.md, OpenCode's .opencode/agents/),
   one line: "see `skills/README.md` Cross-tool conventions table for
   manual wiring".>
  <Conflicts: list any path where a real file already existed and Step 4a
   skipped — user resolves manually>

PM source of truth:
  <one of:
     "Linear (workspace <url>) — pm/backlog.md is a pointer doc"
     "Jira (cloud <url>) — pm/backlog.md is a pointer doc"
     "Notion (workspace <url>) — pm/backlog.md is a pointer doc"
     "GitHub Issues (<owner/repo>) — pm/backlog.md is a pointer doc"
     "Asana / Trello / etc. (no vendor MCP) — pm/backlog.md is the live source"
     "Files only — pm/backlog.md is the live source">
  (omit this section if Q9a wasn't asked / answered)

Registry stubs added (from Step 2b.5 / 2b.6):
  Tech-docs TODOs:    <count> rows added to docs/tech-docs-registry.md
                      under "Detected during codebase scan — needs review".
                      Replace each row's "# TODO: official docs URL" with
                      a real URL when convenient.
  Overlap candidates: <count> entries added to docs/feature-overlap-registry.md
                      under "Detected overlap — needs review". For each pair,
                      decide whether the older lib is deprecated and either
                      replace the entry with a real "Use X; Y is deprecated"
                      note or delete it.
  (omit this section if no auto-stubs were added)

Migration drift (from Step 1.5):
  Migrated:    <list each drift detector that was applied via the migration PR,
                e.g. "D1, D2, D3, D4, D7, D8, D9 — see PR <url>">
  Skipped:     <list each detector the user chose to skip — these remain as
                drift in the user's working tree and should be migrated later.
                Each entry: "D<N>: <one-line description> — fix: <action>">
                Example: "D2: .claude/skills/ is still a real directory —
                fix: re-run /agent-workflow-scaffold and pick `migrate D2`"
  (omit this section if Step 1.5 didn't run, ran with no drift, or the user
   chose 'abort')

Files written:
  <list every other path you wrote, with relative paths>

AGENTS.md merge:
  <one of:
     "scaffold's universal sections written; your existing CLAUDE.md content
      preserved verbatim under '## Existing project rules (preserved from CLAUDE.md)'"
     "written fresh (no existing user content found)"
     "already had the scaffold's universal sections; left untouched">
  (always show this line — the merge behavior is load-bearing for trust)

MCPs enabled:
  <list each MCP integration enabled in .mcp.example.json,
   note whether .mcp.json was copied,
   note that OAuth happens on first use>

Skills:
  Installed: <list git-cloned skills with their install paths>
  To install yourself: <list /plugin install commands the user must run>
  Already present: <list builtin / pre-installed skills that matched>
  Coaching needed: <list private skills with the contact / placeholder URL>
  Unresolved: <list any persona whose frontmatter scan failed in 7a —
              filename + scan result (parse-error / wrong-shape / no-frontmatter).
              These personas had their skills skipped from the install plan
              until the frontmatter is fixed and the scaffold is re-run.
              Omit this line if all personas parsed cleanly.>

VoltAgent sub-agent plugins (from Step 7h):
  Installed: <list voltagent plugins the scaffold actively installed (consent-gated)>
  To install yourself: <list voltagent plugins the user opted out of installing now —
                       include the marketplace-add command if it wasn't already added>
  Already present: <list voltagent plugins that were already installed at scan time>
  (omit this section entirely if no personas had recommended plugins,
   e.g. a solo Personal-Assistant-only project)

Learning opportunities (from Step 7i):
  Plugin:    <one of:
                "installed (claude plugin install learning-opportunities@learning-opportunities)"
                "to install yourself: claude plugin marketplace add DrCatHicks/learning-opportunities
                                      claude plugin install learning-opportunities@learning-opportunities"
                "already installed">
  Cadence:   <N> minutes (re-check fires on UserPromptSubmit; the skill's native trigger
             and suppression rules are authoritative — the hook never overrides them)
  Hook:      .claude/hooks/learning-opportunities-cadence.sh (registered in .claude/settings.json)
  Edit cadence: ~/.claude/projects/<project-slug>/memory/learning-opportunities-context.md
                (change the `learning-opportunities-frequency-minutes:` line; 0 disables the hook)
  (omit this section entirely if Q15 was "no")

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
- **Personas describe roles; sub-agents describe technology specializations.** The scaffold's `agents/*.md` files are role-based (Backend Engineer, QA Engineer, Engineering Manager). VoltAgent sub-agents (`python-pro`, `kubernetes-specialist`, `accessibility-tester`) are technology-specialist delegates the role-based personas dispatch when work calls for deep specialization. The two layers stack — never collapse them. Don't propose a custom-skeleton persona for "Python Engineer"; the answer is Backend Engineer + the `python-pro` sub-agent.
- **Don't overwrite without asking.** This is the user's project — Step 1 detection is mandatory.
- **Never overwrite the user's CLAUDE.md / AGENTS.md content; merge.** When pre-existing user content is detected (a hand-authored `CLAUDE.md`, a previous scaffold's `AGENTS.md`, or anything in between), Step 4's AGENTS.md merge prepends the scaffold's universal sections **above** the user's content and preserves the user's content verbatim under `## Existing project rules (preserved from CLAUDE.md)`. Nothing gets reformatted, reordered, or deleted. The change is additive — exactly what the user requested when they invoked the scaffold on a project that already had rules.
- **Don't push to a referenced codebase's base branch.** Ever. Step 2b records the user's feature branch as the only acceptable PR target for each codebase. The orchestrator persona and AGENTS.md both restate this rule because it's load-bearing for safe multi-repo work.
- **Don't dump every file in a wall of writes.** Confirm the persona / MCP / skill / codebase plan in Step 3, then generate in Step 4 onwards. The user can interrupt.
- **Don't add rules to AGENTS.md that the user didn't agree to.** Step 5's questions matter — silent additions break trust. The exception is the multi-codebase PR rules in Step 5: those are tied to the codebases the user already confirmed in Step 3, so they're not silent.
- **Active install, but consent-gated.** Step 7 actively `git clone`s skills the agent can install — but never without one explicit batched yes. Plugin installs (`/plugin install`) and OAuth flows are user-driven and the agent only coaches. Step 2b's `git checkout -b` for the user's feature branch is the same shape — ask first, run second.
- **Don't override an upstream skill's native rhythm.** Step 7i wires a clock-based re-check hook for the `learning-opportunities` skill, but the hook only re-opens the invocation question — it does not force invocation, bypass the skill's session-suppression rules, or second-guess what the skill considers "significant architectural work." The skill author's evidence-based trigger logic is authoritative; the cadence hook is a clock-based reminder layered on top.
- **Don't substitute placeholders blindly.** If the user said "none" for the GitHub repo, comment out the GitHub-specific lines in `orchestrator.md` rather than leaving "none/none" in there. Same for `custom-skeleton.md`'s `{{PERSONA_*}}` placeholders and `codebases.md`'s `{{LOCAL_PATH}}` etc. — fill them with the discovery answers, don't ship literal `{{}}` to disk.
- **Read the templates fresh each invocation.** Templates may have been updated since the last time the skill was run; don't cache.
- **A re-run revisits the discovery and the codebase scans.** If the user re-invokes this skill on the same project — even one with existing personas and codebases — re-ask Step 2 briefly and re-run Step 2b's scans against the registered codebase paths so the proposal reflects changes (new role added, tool stack changed, new lockfile, new deprecation candidate).
- **Stop when done.** Don't proactively suggest follow-up work the user didn't ask for.
