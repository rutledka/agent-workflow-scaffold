#!/usr/bin/env bash
#
# qa-merge.sh — the merge gate as a command with an exit code.
#
# THE ONLY MERGE PATH THE EVALUATOR PERSONA IS PERMITTED. Bound in
# agents/qa-engineer.md and orchestration/graph.yaml. Exists because on
# private repos under free personal GitHub plans, branch protection /
# required status checks are unavailable (`merge_gate_mode: merge-command`) —
# and even where they are available (`github-native`), the verdict-artifact
# and no-self-merge checks below aren't expressible as status checks.
#
# What it enforces, in order:
#   1. The PR is not authored by the evaluator persona (no self-merge — the
#      branch prefix is the persona claim).
#   2. The PR is not a design PR (design_hold in graph.yaml) — those are
#      never merged by an agent; a human eye reviews visual work first.
#   3. Every check reported on the PR's CURRENT HEAD SHA is green. A stale
#      green on an older commit does not count.
#   4. A valid verdict artifact (orchestration/schemas/qa-verdict.json) is
#      posted whose head_sha matches the current head and whose verdict is
#      ready_to_merge.
# Only then does it merge, using policy.merge_method.
#
# Usage: scripts/qa-merge.sh <pr-number>
# Exit:  0 merged · 1 gate refused (reason printed) · 2 usage/config error
#
set -uo pipefail

PR="${1:-}"
[[ "$PR" =~ ^[0-9]+$ ]] || { echo "usage: qa-merge.sh <pr-number>" >&2; exit 2; }

REPO_ROOT="$(git rev-parse --show-toplevel)" || { echo "not a git repo" >&2; exit 2; }
GRAPH="$REPO_ROOT/orchestration/graph.yaml"
SCHEMA_NOTE="orchestration/schemas/qa-verdict.json"
for tool in gh jq yq; do
  command -v "$tool" >/dev/null 2>&1 || { echo "qa-merge: $tool required" >&2; exit 2; }
done

refuse() { echo "qa-merge: REFUSED — $*" >&2; exit 1; }

evaluator="$(yq -r '.personas | to_entries[] | select(.value.role == "evaluator") | .key' "$GRAPH" | head -1)"
[ -n "$evaluator" ] || { echo "qa-merge: no persona with role: evaluator in graph.yaml" >&2; exit 2; }
merge_method="$(yq -r '.policy.merge_method // "squash"' "$GRAPH")"

pr_json="$(gh pr view "$PR" --json headRefName,headRefOid,state,labels,title,mergeable 2>/dev/null)" \
  || refuse "PR #$PR not found"
state="$(jq -r '.state' <<<"$pr_json")"
[ "$state" = "OPEN" ] || refuse "PR #$PR is $state, not OPEN"
branch="$(jq -r '.headRefName' <<<"$pr_json")"
head_sha="$(jq -r '.headRefOid' <<<"$pr_json")"
author_persona="${branch%%/*}"

# 1. No self-merge — structurally.
[ "$author_persona" != "$evaluator" ] \
  || refuse "PR #$PR branch '$branch' is authored by the evaluator persona ('$evaluator'). The no-self-merge rule has no exceptions — another persona (or the human) must own this merge."

# 2. Design hold.
while IFS= read -r prefix; do
  [ -n "$prefix" ] || continue
  case "$branch" in "$prefix"*) refuse "PR #$PR matches design_hold branch prefix '$prefix' — design PRs need a human visual review; agents never merge them." ;; esac
done < <(yq -r '.policy.design_hold.branch_prefixes // [] | .[]' "$GRAPH")
while IFS= read -r label; do
  [ -n "$label" ] || continue
  jq -e --arg l "$label" '.labels[]? | select(.name == $l)' <<<"$pr_json" >/dev/null \
    && refuse "PR #$PR carries design_hold label '$label' — human visual review required."
done < <(yq -r '.policy.design_hold.labels // [] | .[]' "$GRAPH")

# 3. Every check on the CURRENT head SHA is green. gh reports checks for the
#    head commit; verify the head hasn't moved since we read it, and fail on
#    any non-success conclusion (pending counts as not green).
checks_json="$(gh pr checks "$PR" --json name,state 2>/dev/null || echo '[]')"
not_green="$(jq -r '[.[] | select(.state != "SUCCESS" and .state != "SKIPPED" and .state != "NEUTRAL")] | .[].name' <<<"$checks_json")"
[ -z "$not_green" ] || refuse "checks not green on head $head_sha:"$'\n'"$not_green"
current_head="$(gh pr view "$PR" --json headRefOid --jq .headRefOid)"
[ "$current_head" = "$head_sha" ] || refuse "head moved during evaluation ($head_sha → $current_head) — re-run"

# 4. Verdict artifact: last PR comment containing a ```json block that parses
#    against the qa-verdict shape, matches this PR + head SHA, and says
#    ready_to_merge.
verdict="$(gh pr view "$PR" --json comments --jq '.comments[].body' \
  | awk '/^```json[[:space:]]*$/{grab=1; buf=""; next} /^```[[:space:]]*$/{if(grab){last=buf}; grab=0; next} grab{buf=buf $0 "\n"} END{printf "%s", last}')"
[ -n "$verdict" ] || refuse "no verdict artifact found in PR comments (expected a \`\`\`json block per $SCHEMA_NOTE)"
jq -e . >/dev/null 2>&1 <<<"$verdict" || refuse "verdict artifact is not valid JSON"

v_pr="$(jq -r '.pr // empty' <<<"$verdict")"
v_sha="$(jq -r '.head_sha // empty' <<<"$verdict")"
v_verdict="$(jq -r '.verdict // empty' <<<"$verdict")"
v_eval="$(jq -r '.evaluator.persona // empty' <<<"$verdict")"
v_author="$(jq -r '.author_persona // empty' <<<"$verdict")"

[ "$v_pr" = "$PR" ]                 || refuse "verdict artifact is for PR #$v_pr, not #$PR"
case "$head_sha" in "$v_sha"*) : ;; *) refuse "verdict evaluated head $v_sha but current head is $head_sha — stale verdict; re-evaluate" ;; esac
[ "$v_eval" = "$evaluator" ]        || refuse "verdict evaluator '$v_eval' is not the declared evaluator persona '$evaluator'"
[ "$v_author" != "$v_eval" ]        || refuse "verdict lists the evaluator as the author — no self-merge"
# Any deterministic-gate (rung 1/2) fail is dispositive regardless of the verdict field.
r12_fail="$(jq -r '[.gates[] | select((.rung // 1) != 3 and .status == "fail")] | .[].name' <<<"$verdict")"
[ -z "$r12_fail" ] || refuse "verdict contains failing deterministic gate(s): $r12_fail"
bad_defer="$(jq -r '[.gates[] | select(.status == "deferred" and ((.reason // "") == ""))] | .[].name' <<<"$verdict")"
[ -z "$bad_defer" ] || refuse "deferred gate(s) without a reason: $bad_defer — deferral is not a free action"
[ "$v_verdict" = "ready_to_merge" ] || refuse "verdict is '$v_verdict'"

echo "qa-merge: all gates green for PR #$PR @ $head_sha — merging (${merge_method})"
gh pr merge "$PR" --"$merge_method" --delete-branch \
  || { echo "qa-merge: gh pr merge failed" >&2; exit 1; }
echo "qa-merge: merged PR #$PR"
