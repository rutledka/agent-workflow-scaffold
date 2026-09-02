# scripts/ — the orchestration loop's guard rails

Every script here exists to turn a rule that was previously prose ("remember to check X")
into a command with an exit code. They are installed by the scaffold alongside
`orchestration/` and are read/driven by `orchestration/graph.yaml`.

| Script | Node in the loop | One-liner |
|---|---|---|
| `preflight.sh` | guard | Cheap ordered checks before any dispatch; one-screen failure report; circuit breaker at N consecutive failures (exit 2 = stop scheduling, alert a human). |
| `graph-sync.sh` | sync | Regenerates `orchestration/state.json` (computed frontier, scores, hold reasons, invariants) and renders the generated views. Deterministic: same inputs → same output. |
| `with-resource-lock.sh` | dispatch | Capacity-N semaphore for physical shared resources; exit 75 = at capacity, record a `hold_reason` and move on. |
| `policy-lint.sh` | verify (rung 2) | Mechanizes the AGENTS.md hard rules as diff checks; composes existing project lints rather than re-implementing them. |
| `qa-merge.sh` | merge gate | The evaluator persona's only permitted merge path: head-SHA-pinned green checks + valid verdict artifact + no-self-merge + design hold, else non-zero exit. |

## Dependencies

`git`, `gh` (authenticated), `jq`, and `yq` ([mikefarah/yq](https://github.com/mikefarah/yq)).
`preflight.sh` verifies all four — run it first, always.

## Wiring notes for the scaffold (and for humans re-wiring by hand)

- `chmod +x scripts/*.sh` after copying.
- Add `orchestration/.runtime/` to `.gitignore` — lockfiles, failure counters, and
  checkpoints are per-machine state, never committed.
- `policy-lint.sh` carries `{{PLACEHOLDER}}` tokens (source glob, migrations dir, routes
  pattern, contract doc, existing lint commands) that the scaffold substitutes from the
  Step 2b scan. Unsubstituted sections skip themselves safely.
- Wire `policy_lint` into CI so the branch goes red — locally it's advice, in CI it's a
  gate.
- The loop's caller order is: `preflight.sh` → (ticket extract) → `graph-sync.sh` →
  dispatch (each budget-bounded, semaphore-guarded) → `qa-merge.sh` per cleared PR.
  `agents/orchestrator.md` is the operator that runs this order and applies judgment
  between the nodes.
