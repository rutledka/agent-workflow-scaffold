# Sub-agents registry

This registry maps the scaffold's role-based personas in `agents/*.md` to **technical-specialist sub-agents** from the [VoltAgent awesome-claude-code-subagents](https://github.com/VoltAgent/awesome-claude-code-subagents) plugin marketplace. The mapping is what the scaffold uses to decide which VoltAgent category plugins to suggest installing, and which specific sub-agents each persona should reference in its **Available sub-agents for delegation** section.

> Personas vs. sub-agents (and vs. skills). The scaffold's `agents/*.md` files describe **roles** — Backend Engineer, QA Engineer, Project Manager. VoltAgent sub-agents describe **technology specializations** — `python-pro`, `kubernetes-specialist`, `accessibility-tester`. Skills (`docs/skills-registry.md`) describe **knowledge / context-packs** the persona loads before doing work. The three layers stack: a Backend Engineer persona, working in Python, dispatches the `python-pro` sub-agent for deep language work, having loaded the `claude-api` skill for Anthropic SDK context.

## How it's used

The scaffold reads this file at three points:

1. **Step 3 — Proposal.** When synthesizing the persona shortlist, the scaffold also lists the matching VoltAgent plugins and sub-agents per persona for the user to confirm.
2. **Step 4 — Persona generation.** Each off-the-shelf persona template ships with a hand-curated **Available sub-agents for delegation** section based on this registry. For `custom-skeleton.md`-based custom personas, the scaffold reads the user's role description and matches against this registry to inject a relevant sub-agent list.
3. **Step 7h — Plugin install.** The scaffold aggregates the matching plugins across all confirmed personas, deduplicates, and either runs `claude plugin install <plugin>` (with consent) or coaches the user if `claude` CLI isn't available.

## The marketplace

Add the marketplace once per machine:

```bash
claude plugin marketplace add VoltAgent/awesome-claude-code-subagents
```

Then install one or more category plugins:

```bash
claude plugin install voltagent-core-dev      # backend / frontend / fullstack / mobile / API
claude plugin install voltagent-lang          # language specialists (Python, TS, Go, Rust, …)
claude plugin install voltagent-infra         # DevOps, cloud, k8s, Terraform, SRE
claude plugin install voltagent-qa-sec        # testing, security, code review
claude plugin install voltagent-data-ai       # data engineering, ML, LLM
claude plugin install voltagent-dev-exp       # tooling, CLI, docs, build, dx
claude plugin install voltagent-domains       # blockchain, fintech, gaming, IoT, payments
claude plugin install voltagent-biz           # PM, legal, scrum, UX research
claude plugin install voltagent-meta          # orchestration, multi-agent coordination
claude plugin install voltagent-research      # market / competitive / scientific research
```

`voltagent-meta` works best with at least one of the other plugins installed.

## Persona-to-plugin mapping

Each persona below lists its **primary plugins** (always relevant to the role) and **conditional plugins** (relevant when the user's stack or work indicates them). The "specific sub-agents" lists are starting points — every plugin includes more sub-agents than what's listed; the persona's Available-sub-agents section can reference any of them once the plugin is installed.

### Orchestrator

- **Primary:** `voltagent-meta`
- **Specific sub-agents:**
  - `multi-agent-coordinator` — coordinates multiple sub-agents on one task
  - `workflow-orchestrator` — sequences multi-step workflows with gates
  - `task-distributor` — fan-out work across specialists
  - `context-manager` — preserves state across sub-agent dispatches
  - `error-coordinator` — aggregates errors from parallel sub-agent runs
  - `agent-organizer` — picks the right specialist for a given task
  - `knowledge-synthesizer` — combines outputs from multiple sub-agents

The Orchestrator role + `voltagent-meta` is the highest-leverage pairing in the scaffold — the meta plugin's coordinators directly augment the dispatch loop in `agents/orchestrator.md`.

### Project Manager

- **Primary:** `voltagent-biz`
- **Specific sub-agents:**
  - `product-manager` — product strategy, prioritization frameworks
  - `project-manager` — schedule / scope / RACI execution
  - `business-analyst` — requirements analysis, BPMN
  - `scrum-master` — sprint mechanics if the team runs Scrum
  - `ux-researcher` — qualitative discovery for product decisions
- **Conditional:** `voltagent-research` when stakeholder reporting includes market / competitive analysis (`market-researcher`, `competitive-analyst`).

### Engineering Manager

- **Primary:** `voltagent-meta`, `voltagent-qa-sec`
- **Specific sub-agents:**
  - `architect-reviewer` (qa-sec) — architecture decision reviews; pairs with the EM's tie-breaking responsibility
  - `code-reviewer` (qa-sec) — PR-level review for systemic quality issues
  - `agent-organizer` (meta) — orchestration governance
  - `multi-agent-coordinator` (meta) — when EM oversight spans multiple workstreams
- **Conditional:** `voltagent-research` (`research-analyst`) when EM is producing technical strategy memos.

### Backend Engineer

- **Primary:** `voltagent-core-dev`, `voltagent-lang`
- **Specific sub-agents (core-dev):**
  - `backend-developer` — generalist server-side implementation
  - `api-designer` — REST contract design, versioning, deprecation
  - `microservices-architect` — service decomposition, boundaries
  - `graphql-architect` — GraphQL schema and resolver design
  - `websocket-engineer` — real-time / streaming protocols
  - `fullstack-developer` — when work crosses backend + frontend
- **Specific sub-agents (lang) — pick by stack:**
  - `python-pro`, `typescript-pro`, `golang-pro`, `rust-engineer`, `java-architect`, `kotlin-specialist`, `csharp-developer`, `php-pro`, `ruby` (via `rails-expert`), `swift-expert`, `cpp-pro`, `elixir-expert`, `node-specialist`, `javascript-pro`, `sql-pro`
  - Framework specialists: `fastapi-developer`, `django-developer`, `spring-boot-engineer`, `laravel-specialist`, `symfony-specialist`, `dotnet-core-expert`, `nextjs-developer`
- **Conditional:** `voltagent-data-ai` (`postgres-pro`, `database-optimizer`) when DB work is a major portion; `voltagent-domains` for fintech / payments / blockchain backends.

### Frontend Engineer

- **Primary:** `voltagent-core-dev`, `voltagent-lang`
- **Specific sub-agents (core-dev):**
  - `frontend-developer` — generalist client-side implementation
  - `fullstack-developer` — when work crosses backend + frontend
  - `ui-designer` — UI component design (pairs with Product Designer if present)
  - `electron-pro` — desktop-app-specific work
- **Specific sub-agents (lang) — pick by stack:**
  - `typescript-pro`, `javascript-pro`
  - Framework specialists: `react-specialist`, `vue-expert`, `angular-architect`, `nextjs-developer`, `svelte` (no dedicated agent yet — use `frontend-developer`)
- **Conditional:** `voltagent-qa-sec` (`accessibility-tester`, `ui-ux-tester`) for a11y audits embedded in frontend work; `voltagent-lang` (`expo-react-native-expert`, `flutter-expert`) for mobile-web crossover.

### QA Engineer

- **Primary:** `voltagent-qa-sec`
- **Specific sub-agents:**
  - `qa-expert` — overall test strategy, regression nets
  - `test-automator` — CI test infrastructure, fixture management
  - `accessibility-tester` — WCAG audits, screen-reader passes
  - `ui-ux-tester` — visual regression, interaction tests
  - `performance-engineer` — load/latency regression tracking
  - `debugger` — repro and minimization of intermittent failures
  - `error-detective` — log correlation, error-pattern analysis
  - `chaos-engineer` — fault injection, resilience testing
- **Conditional:** `voltagent-meta` (`error-coordinator`) when running parallel test sub-agents.

### Platform Engineer

- **Primary:** `voltagent-infra`
- **Specific sub-agents:**
  - `platform-engineer` — generalist platform / IaC
  - `devops-engineer` — CI/CD pipelines
  - `cloud-architect` — multi-cloud / multi-region topology
  - `kubernetes-specialist` — k8s-specific work
  - `terraform-engineer` / `terragrunt-expert` — IaC depth
  - `sre-engineer` — SLO / on-call / runbook authoring
  - `incident-responder` / `devops-incident-responder` — incident postmortems
  - `database-administrator` — DB tier ops
  - `network-engineer` — DNS / VPC / connectivity
  - `security-engineer` — infra-side security (encryption-at-rest, IAM)
  - `docker-expert` — container build / multi-arch
  - `deployment-engineer` — release engineering
  - `azure-infra-engineer` / cloud-specific specialists by provider
- **Conditional:** `voltagent-qa-sec` (`security-auditor`, `compliance-auditor`, `penetration-tester`) when platform work overlaps security; `voltagent-data-ai` (`mlops-engineer`) for ML-Ops.

### Product Designer

- **Primary:** `voltagent-core-dev`, `voltagent-qa-sec`
- **Specific sub-agents:**
  - `ui-designer` (core-dev) — component / screen design
  - `design-bridge` (core-dev) — design-to-code handoff
  - `accessibility-tester` (qa-sec) — a11y conformance
  - `ui-ux-tester` (qa-sec) — usability validation
- **Conditional:** `voltagent-biz` (`ux-researcher`) for qualitative discovery.

### Legal Advisor

- **Primary:** `voltagent-biz`, `voltagent-qa-sec`
- **Specific sub-agents:**
  - `legal-advisor` (biz) — generalist legal drafting / review (note: VoltAgent has a sub-agent of the same name — distinct from this scaffold's persona; the persona dispatches the sub-agent for technical drafting depth)
  - `license-engineer` (biz) — open-source / vendor licensing analysis
  - `compliance-auditor` (qa-sec) — GDPR / CCPA / SOC 2 control mapping
- **Conditional:** `voltagent-domains` (`healthcare-admin`, `fintech-engineer`, `payment-integration`) for regulated industries.

### Pilot Lead

- **Primary:** `voltagent-biz`
- **Specific sub-agents:**
  - `project-manager` — pilot ops scheduling
  - `customer-success-manager` — partner / pilot-user relationship management
  - `ux-researcher` — pilot intercept interviews + retros
  - `business-analyst` — pilot KPIs and read-out
- **Conditional:** `voltagent-research` (`market-researcher`, `trend-analyst`) when pilot read-out feeds market positioning.

### Personal Assistant

- **Primary:** *(none — the persona is purpose-built around the user's email + team-comms read scope and goal-tracking; it doesn't fit the technology-specialist sub-agent shape)*
- **Optional:** `voltagent-meta` (`context-manager`) when goal tracking spans many sub-agent dispatches and needs explicit context preservation.

The Personal Assistant deliberately stays narrow — its value comes from being the user's 1:1 channel, not from delegating to specialists. Don't over-instrument it.

### Custom personas (from `custom-skeleton.md`)

For roles that don't match the standard set (Growth Lead, ML Researcher, Data Engineer, Security Engineer, Customer Success, etc.), the scaffold matches the user's role description against the keyword index below and proposes plugins accordingly. The matched sub-agents become the custom persona's **Available sub-agents** section.

## Keyword index (for custom-persona matching)

| Keyword in role description | Recommended plugin(s) | Top matching sub-agents |
|---|---|---|
| growth, marketing, content, SEO | `voltagent-biz`, `voltagent-domains` | `content-marketer`, `seo-specialist`, `business-analyst` |
| machine learning, ML, model training, MLOps | `voltagent-data-ai` | `ml-engineer`, `mlops-engineer`, `machine-learning-engineer`, `ai-engineer`, `llm-architect` |
| data engineering, ETL, pipeline, warehouse | `voltagent-data-ai` | `data-engineer`, `database-optimizer`, `data-analyst` |
| LLM, prompt engineering, RAG, agents | `voltagent-data-ai` | `llm-architect`, `ai-engineer`, `prompt-engineer`, `nlp-engineer` |
| customer success, CSM, support | `voltagent-biz` | `customer-success-manager`, `business-analyst` |
| security, AppSec, pentest | `voltagent-qa-sec`, `voltagent-infra` | `security-auditor`, `penetration-tester`, `security-engineer`, `compliance-auditor` |
| documentation, technical writing | `voltagent-biz`, `voltagent-dev-exp` | `technical-writer`, `documentation-engineer`, `api-documenter`, `readme-generator` |
| developer experience, tooling, CLI | `voltagent-dev-exp` | `dx-optimizer`, `cli-developer`, `tooling-engineer`, `build-engineer` |
| blockchain, smart contracts, web3 | `voltagent-domains` | `blockchain-developer` |
| fintech, payments, billing | `voltagent-domains`, `voltagent-qa-sec` | `fintech-engineer`, `payment-integration`, `compliance-auditor` |
| game development, Unity, Unreal | `voltagent-domains` | `game-developer` |
| IoT, embedded, firmware | `voltagent-domains` | `iot-engineer`, `embedded-systems` |
| healthcare, HIPAA | `voltagent-domains`, `voltagent-qa-sec` | `healthcare-admin`, `compliance-auditor` |
| sales engineering | `voltagent-biz` | `sales-engineer`, `business-analyst` |
| research, scientific, literature | `voltagent-research` | `scientific-literature-researcher`, `research-analyst`, `data-researcher` |
| competitive analysis, market research | `voltagent-research` | `market-researcher`, `competitive-analyst`, `trend-analyst` |
| Microsoft 365, Azure admin, Windows | `voltagent-domains`, `voltagent-infra` | `m365-admin`, `azure-infra-engineer`, `windows-infra-admin` |

## How to extend this registry

When VoltAgent adds new sub-agents (the upstream repo updates frequently), update this file by:

1. Reading the latest list of sub-agents in `categories/<NN>-<topic>/` from <https://github.com/VoltAgent/awesome-claude-code-subagents>.
2. Adding new sub-agents under the relevant persona section above.
3. Updating the keyword index for any new specialty.
4. Re-running `/agent-workflow-scaffold` on existing projects so the persona files pick up new references — the scaffold detects existing files and asks before overwriting.

## License + attribution

VoltAgent's awesome-claude-code-subagents is MIT-licensed (see <https://github.com/VoltAgent/awesome-claude-code-subagents/blob/main/LICENSE>). The scaffold ships **only references** to the upstream sub-agents — the actual sub-agent definitions are installed by the user via `claude plugin install` and live wherever Claude Code's plugin manager places them. Re-running the scaffold doesn't redistribute or vendor any VoltAgent content.
