# Graph orchestration retrofit — design outline for v1.3

**Status:** Proposed · **Date:** 2026-08-30 · **Target release:** v1.3.0
**Source:** field experience from the Strata project (AR-487, `docs/agent-graph-retrofit.md`
in that repo) — the first scaffolded project to run the orchestrator on a schedule long
enough to expose the failure modes this design fixes.

This document outlines the **generic** changes; implementation is split into follow-up PRs
per section. Nothing here is Strata-specific — project specifics are called out explicitly
as *what does not port*.

---

## 1. Why the scaffold needs this

The scaffold's orchestrator is an essay describing an algorithm (`templates/agents/
orchestrator.md`, 322 lines) that an LLM re-derives from scratch every run. Running it on a
schedule for three months in the field produced a taxonomy of failures that are all
**scaffolding** failures, not model failures:

| Failure observed | Root cause | Fix (this design) |
|---|---|---|
| 8 consecutive degraded scheduled runs, each writing an excellent forensic report and doing zero work | No guard on the front of the loop; no circuit breaker | `preflight` script + breaker (§3.2) |
| Delivery status in a Markdown file rotted for 8 weeks after being flagged | Derived state hand-maintained in prose | Generated views + drift check (§3.1) |
| Epic ownership stored in 5 places, disagreeing | No single declaration | `graph.yaml` owns ownership (§3.1) |
| A capacity-1 physical resource "enforced" by two sessions reading the same paragraph | Constraints as prose | Declared resources + lockfile (§3.1, §3.2) |
| Quality gate = a comment ending in a magic phrase; deferral free and unrecorded | Gate is a convention, not a command | Verdict artifact + merge-command gate (§3.3) |
| Dispatch constants (N per cycle, max open PRs) never tuned | Prose logs — nothing computable | JSON run records (§3.4) |

The design principle throughout: **a gate is a command with an exit code, or it is not a
gate.** The scaffold already believes this about worktrees and PRs; v1.3 extends it to the
orchestration loop itself.

---

## 2. New artifact: `orchestration/` (Layer 0 — the work graph as data)

The scaffold gains one new top-level generated directory in the user's project:

```
orchestration/
├── graph.yaml            # POLICY — hand-maintained, code-reviewed, changes rarely
├── state.json            # DERIVED — regenerated every cycle by graph-sync; never hand-edited
└── schemas/
    ├── dispatch-result.json   # structured output contract for headless sub-agents
    └── qa-verdict.json        # structured QA gate artifact
```

### 2.1 `templates/orchestration/graph.yaml`

Rendered from the discovery interview (personas from Step 3, file domains from the Step 2b
codebase scan, gates from the Step 2b CI/manifest scan):

```yaml
version: 1
personas:
  {{PERSONA_SLUG}}:
    file: agents/{{PERSONA_SLUG}}.md
    file_domains: [{{GLOBS_FROM_CODEBASES_MD}}]
    requires_resources: []            # names from `resources:` below
    max_open_prs: 6                   # starter constants — tuned later from run records
    max_dispatch_per_cycle: 3
  # evaluator persona gets `role: evaluator`; design personas get `dispatch: interactive-only`

resources: {}                          # capacity-N semaphores for physical constraints
                                       # (shared local DB, device farm, rate-limited API...)

gates:                                 # discovered during Step 2b, confirmed in interview
  # name: { cmd | workflow, required_for: [globs], runs_in: local|ci, resource: <name>? }

policy:
  autonomy: human-gated-merge
  merge_gate_mode: {{github-native | merge-command}}   # probed at scaffold time, §3.3
  max_consecutive_preflight_failures: 2
  dispatch_budget: { max_usd: 8, timeout_min: 45 }     # spend cap needs explicit user sign-off
  selection_weights: { milestone_priority: 3.0, unblocks_count: 2.0,
                       staleness_days: 0.1, collision_risk: -2.0 }
```

Ownership boundary, stated in the file header and in `AGENTS.md`: **the PM tool owns ticket
status; `graph.yaml` owns ownership and policy.** Status flows PM-tool → generated docs;
ownership flows `graph.yaml` → PM-tool labels → generated docs. Never bidirectional.

### 2.2 `graph-sync` and `state.json`

A `scripts/graph-sync` step (invoked by the orchestrator each cycle, runnable standalone)
pulls tickets + relations from the wired PM tool (via the project's pm-skill from Step 5b),
plus open PRs from `gh`, and emits `state.json`: per-ticket `blocked_by`/`blocks`, a
**computed frontier** (in-degree 0 over open blocking edges), a scored ranking using
`selection_weights`, machine-readable `hold_reason`s, and invariant-check results.
Committed each cycle so the diff between runs is the execution record.

**File-backlog projects** (no PM tool wired): `graph-sync` parses `pm/backlog.md` ticket
tables instead. The frontier computation is identical; only the extractor differs.

### 2.3 Generated views

- `pm/delivery-status.md` — epic index, milestone roll-up, sync timestamp. Opens with
  `<!-- GENERATED BY graph-sync — DO NOT EDIT -->`. Only generated **when a PM tool is
  wired** (Step 5b); file-backlog projects keep `pm/backlog.md` as the live source of truth
  and skip this split.
- `pm/backlog.md` (PM-tool projects) is trimmed to human-owned content: milestone exit
  criteria, sizing legend, status mapping, query cookbook. It keeps its filename for link
  stability.
- The orchestrator role map and README persona table become generated blocks
  (`<!-- GENERATED FROM orchestration/graph.yaml -->` … `<!-- /GENERATED -->`), rendered
  by `graph-sync` from the single declaration.
- Optional CI drift check: re-renders the generated views **from the committed
  `state.json`** and fails on diff. It must never re-query the live PM tool — live state
  moves between commit and CI run, which makes the gate flaky by design.

---

## 3. Changed templates

### 3.1 `templates/agents/orchestrator.md` — from essay to operator

Rewritten (and shortened) as a thin operator of the declared graph:

```
schedule → preflight → sync → plan → dispatch ×N → collect → evaluate → report → commit+PR
              │fail
              ▼
        halt_and_alert (circuit breaker)
```

The persona keeps its judgment role — resolving ambiguous priorities, writing the
human-readable dispatch narrative — but the frontier, collision check, resource
availability, and per-persona caps come from `state.json`, not from re-reading prose.
Checkpointing is a JSON run-record written after each node so a crashed run resumes rather
than restarts. No graph framework (LangGraph/Temporal) — a fan-out with one join does not
justify a new runtime; this is a deliberate, documented decision the templates should
carry so future maintainers don't "upgrade" into one.

### 3.2 New `templates/scripts/` — the loop's guard rails

| Script | Purpose |
|---|---|
| `preflight.sh` | Cheap ordered checks before any work: `git push --dry-run` on origin, `gh` auth, PM-tool reachability, required CLIs present, worktree/lock hygiene. On failure: **one-screen** status file, notification, persisted failure counter; at `max_consecutive_preflight_failures`, disable the scheduled task and say so. This single script deletes the "eight beautiful reports about being unable to work" failure class. |
| `with-resource-lock.sh` | Generic capacity-N lockfile semaphore with stale-lock TTL, driven by the `resources:` block. A blocked dispatch becomes a `hold_reason`, not a wedged shared resource. |
| `policy-lint.sh` | Mechanizes the AGENTS.md hard rules the scaffold itself ships: no stray `console.*`/print-debugging in `src/`, migrations additive-only, API-contract doc updated when routes change, no secrets, one-concern-per-PR heuristic. **Composes** any project lint scripts found during discovery rather than re-implementing them. |
| `qa-merge.sh` | The merge gate — see §3.3. |
| `graph-sync` | See §2.2. |

Dispatch invocations gain declared limits and typed output:
`claude -p … --max-budget-usd N --output-format json --json-schema
orchestration/schemas/dispatch-result.json`. (Note for template authors: there is **no
`--max-turns` flag** in the current CLI — budget + wall-clock timeout are the runaway
bounds.)

### 3.3 `templates/agents/qa-engineer.md` — verdict artifact + merge-command gate

Two changes, both generic:

**The verdict becomes an artifact.** The QA persona posts a structured verdict
(`schemas/qa-verdict.json`) instead of a free-form magic-phrase comment: per-gate
pass/fail/not_applicable/deferred, where `deferred` **requires** a reason and a follow-up
ticket ID. The overall verdict is computed — any deterministic-gate failure ⇒ `blocked`
regardless of judgment. Rung-1/2 fields are machine-filled from CI output; the persona
does not get to type "tests pass."

**The gate becomes a command.** This is the generalized form of Strata decision D-B, and
it matters because most scaffolded projects are **private repos on free personal plans**,
where GitHub-side required status checks are unavailable (branch protection on private
repos requires GitHub Pro; merge queue is org-repos-only and never available on
user-owned repos — do not scope it). The scaffold probes at setup time:

- **Scaffold-time probe:** `gh api repos/{owner}/{repo}/branches/<default>/protection` —
  a 200/404 means branch protection is *available* (public repo or paid plan); a 403
  "Upgrade to GitHub Pro" means it is not. Record the result as
  `policy.merge_gate_mode` in `graph.yaml`.
- **`merge_gate_mode: github-native`** — scaffold recommends enabling required status
  checks, *and still ships `qa-merge.sh`* (the verdict-artifact and no-self-merge checks
  aren't expressible as status checks anyway).
- **`merge_gate_mode: merge-command`** — `qa-merge.sh` is the enforcement point,
  full stop.

`qa-merge.sh` is the **only merge path the QA persona is permitted** (bound in the
persona file and in `graph.yaml`). It: (1) resolves the PR head SHA and requires every
applicable gate green **for that exact SHA** — stale green on an older commit doesn't
count; (2) requires the verdict artifact with `verdict: ready_to_merge`; (3) re-checks
no-self-merge and the design-PR hold; (4) merges, else exits non-zero naming the failing
gate. Accepted residual risk in merge-command mode: nothing structurally prevents a
direct push to the default branch — the actors are the owner and AGENTS.md-bound agents.
Optional hardening: a tripwire Action on `push` to the default branch that flags any
commit not arriving via a green merged PR (detect-and-alert; works on free private repos).

**LLM judge — optional and off by default.** A new interview question offers a
rung-3 acceptance-criteria judge with the evidence-backed constraints baked into the
template: cross-model-family only, sees the diff/ticket/gate-output but never the
author's narrative, advisory until calibrated against a human-labeled PR sample, never
the sole gate. Most projects should decline; the deterministic ladder is the value.

### 3.4 `templates/AGENTS.md` — autonomy table + structured logs

- **Autonomy table** added as a universal section: roadmap/milestone scope/epic priority =
  human; ticket decomposition/status sync/reconciliation = agent; write code + open PR =
  agent; merge = evaluator persona via `qa-merge.sh`; prod deploys, destructive schema
  changes, spend, external comms, design-PR merges = human. Rendered with the project's
  actual persona names.
- **Dispatch logs gain a JSON twin**: `docs/dispatch-logs/YYYY-MM-DD.json` (ticket,
  persona, cost, duration, outcome, gate results, PR, merge latency) alongside the
  Markdown. A monthly roll-up finally lets the starter constants (3/cycle, 6 open PRs,
  selection weights) be tuned from outcomes instead of inherited forever.

### 3.5 SKILL.md — interview and generation changes

- **Step 1 (detect):** add the branch-protection probe (§3.3) and record plan
  constraints.
- **Step 2b (scan):** the existing manifest/CI scan additionally harvests **gate
  candidates** (workflows, lint scripts, package scripts) into the `gates:` proposal, and
  **file-domain globs** per codebase into `file_domains`.
- **Step 2 (interview):** three new questions — physical shared resources needing a
  semaphore; confirm/adjust the harvested gate list; opt into the LLM judge (default no).
- **New generation step:** write `orchestration/`, `scripts/`, and the schemas after the
  persona files; wire the orchestrator template to them.
- **Ownership audit rule:** when a PM tool is wired and ownership labels already exist,
  the scaffold audits persona-file claims against PM-tool labels **before** declaring the
  map in `graph.yaml`, surfacing disagreements to the user. Generation makes a fact
  single-sourced and visible; it does not make the source correct — never publish a wrong
  owner with a machine's authority.

---

## 4. What does NOT port (Strata-specific, for the record)

- The arm64/QEMU PostGIS constraint and its capacity-1 Postgres semaphore — the
  *mechanism* (declared resources + lockfile) ports; the specific resource does not.
- Strata's concrete gate list, Linear workspace wiring, and persona↔epic map.
- The `pm/backlog.md` → `pm/delivery-status.md` split applies only to PM-tool projects
  (§2.3); the scaffold's file-backlog mode keeps `backlog.md` primary.

---

## 5. Upgrade path for previously-scaffolded projects

Follows the scaffold's established migration machinery: **new drift detectors in the
Step 1.5 table + a standalone one-shot script**, same as the D10/D11 sub-agents
migration. Idempotent, worktree-per-migration, one commit per detector, PR for review.

### 5.1 New drift detectors (D13–D19)

| # | Drift detector | Check | Migration action if `legacy` |
|---|---|---|---|
| D13 | Missing `orchestration/graph.yaml` | `[ ! -f orchestration/graph.yaml ]` | Generate from existing `agents/*.md` + `pm/codebases.md` + CI scan. **Interactive** — runs the §3.5 ownership audit first; where persona files and PM-tool labels disagree, ask the user, fix the wrong source, then declare. |
| D14 | Orchestrator persona is the prose-loop shape | `! grep -q 'preflight' agents/orchestrator.md` | Rewrite as the §3.1 operator. Project-specific content (role map, priority rules) is extracted into `graph.yaml` **first**, then the persona body is replaced; nothing is dropped silently. |
| D15 | Missing `scripts/preflight.sh` | `[ ! -x scripts/preflight.sh ]` | Copy from template; wire the breaker threshold from `graph.yaml`; add the scheduled-task guard note to the orchestrator persona. |
| D16 | Missing `scripts/policy-lint.sh` | `[ ! -x scripts/policy-lint.sh ]` | Generate, composing any existing project lint scripts discovered by scan (never duplicate an existing lint). |
| D17 | Missing merge-command gate | `[ ! -x scripts/qa-merge.sh ]` or QA persona lacks the verdict-artifact section | Run the branch-protection probe, set `merge_gate_mode`, install `qa-merge.sh` + `schemas/qa-verdict.json`, append the verdict + only-merge-path sections to the QA persona. |
| D18 | PM tool wired but delivery status hand-maintained in `pm/backlog.md` | pm-skill exists **and** `backlog.md` contains status tables | Split per §2.3: generate `pm/delivery-status.md`, trim `backlog.md` to conventions, retitle. Skipped entirely for file-backlog projects. |
| D19 | `AGENTS.md` missing the autonomy table | `! grep -q 'Autonomy table' AGENTS.md` | Insert the universal section rendered with the project's persona names. |

Ordering constraints: D13 before D14/D15/D17 (they read `graph.yaml`); the D13 ownership
audit before anything generates from the map; D1 (legacy `CLAUDE.md` rename) still runs
first if present.

### 5.2 Standalone script

`scripts/migrate-to-graph-orchestration.sh` — the one-shot for users who don't want to
re-run the full discovery interview. Same contract as
`migrate-personas-to-voltagent-subagents.sh`: detects the scaffold install location, runs
D13–D19 in order, works in `.worktrees/migrate-graph-orchestration/`, commits per
detector (`D13: declare orchestration/graph.yaml`, …), pushes, opens a PR, and is
idempotent (all-`✓` → "no migration needed", no PR). D13's ownership audit and D14's
persona rewrite are flagged `interactive` — the script pauses and prints the
disagreements/diff for confirmation rather than deciding alone.

### 5.3 Preconditions the migration must state up front

Field lesson, verbatim: none of this matters if the pipeline itself is dead. The
migration README leads with a **phase-0 checklist** the user confirms before D13 runs —
credentials valid for scheduled runs (git push + `gh` + PM-tool API), no orphan worktree
registrations, no uncommitted dispatch logs. The `preflight.sh` from D15 then keeps it
true.

---

## 6. Sequencing (follow-up PRs)

1. `templates/orchestration/` + `templates/scripts/` (graph.yaml, schemas, preflight,
   with-resource-lock, graph-sync, policy-lint, qa-merge) — the artifacts.
2. Template rewrites: orchestrator.md, qa-engineer.md, AGENTS.md autonomy table.
3. SKILL.md: Step 1 probe, Step 2/2b additions, generation step, D13–D19 table.
4. `scripts/migrate-to-graph-orchestration.sh` + migration docs.
5. CHANGELOG v1.3.0 entry + README methodology section update.

Items 1–2 are the value; 3–4 make it reachable; nothing ships to `main` without all five
because a half-installed graph (a `graph.yaml` no script reads) is worse than none.
