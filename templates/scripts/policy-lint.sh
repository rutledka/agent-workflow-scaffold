#!/usr/bin/env bash
#
# policy-lint.sh — mechanizes the AGENTS.md hard rules that are otherwise
# "enforced" by every agent remembering a bullet list under load.
#
# Runs against the diff between the current branch and its merge-base with
# the default branch. Declared in orchestration/graph.yaml as the universal
# `policy_lint` gate; wired into CI so the branch is red, not the agent
# scolded.
#
# IMPORTANT (scaffold rule): if the project ALREADY has a lint script for one
# of these rules, add it to PROJECT_LINTS below and delete the built-in
# check — compose existing lints, never re-implement them.
#
# Exit codes: 0 = clean, 1 = violations found (each printed with file:line).
#
set -uo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)" || { echo "not a git repo" >&2; exit 1; }
cd "$REPO_ROOT"
DEFAULT_BRANCH="{{DEFAULT_BRANCH}}"        # usually main
BASE="$(git merge-base "origin/$DEFAULT_BRANCH" HEAD 2>/dev/null || git merge-base "$DEFAULT_BRANCH" HEAD)"
[ -n "$BASE" ] || { echo "policy-lint: cannot find merge-base with $DEFAULT_BRANCH" >&2; exit 1; }

CHANGED_FILES="$(git diff --name-only --diff-filter=ACMR "$BASE"...HEAD)"
[ -n "$CHANGED_FILES" ] || { echo "policy-lint: empty diff — PASS"; exit 0; }

violations=0
fail() { echo "  VIOLATION: $*"; violations=$((violations + 1)); }

# ---------------------------------------------------------------------------
# 0. Compose the project's existing lint scripts (fill in during scaffolding;
#    the Step 2b scan lists candidates). One command per line.
# ---------------------------------------------------------------------------
PROJECT_LINTS=(
  # "bash scripts/no-console-lint.sh"
  # {{PROJECT_LINT_COMMANDS}}
)
for lint in "${PROJECT_LINTS[@]}"; do
  echo "policy-lint: running project lint: $lint"
  if ! bash -c "$lint"; then fail "project lint failed: $lint"; fi
done

# ---------------------------------------------------------------------------
# 1. No unstructured debug logging in source. Adjust the pattern + path per
#    stack ({{SRC_GLOB}} from the Step 2b scan); delete if a project lint in
#    PROJECT_LINTS already covers it.
# ---------------------------------------------------------------------------
SRC_PATHS="{{SRC_GLOB}}"                    # e.g. "code/*/src" or "src"
DEBUG_PATTERN='console\.(log|warn|error)|print\('
hits="$(echo "$CHANGED_FILES" | grep -E "^${SRC_PATHS//\*/.*}" 2>/dev/null \
        | xargs -I{} grep -nHE "$DEBUG_PATTERN" {} 2>/dev/null || true)"
[ -z "$hits" ] || { echo "$hits"; fail "unstructured debug logging in source (use the structured logger)"; }

# ---------------------------------------------------------------------------
# 2. No bare suppression comments — @ts-ignore/@ts-expect-error/noqa/nolint
#    must carry an explanation on the same line.
# ---------------------------------------------------------------------------
hits="$(echo "$CHANGED_FILES" | xargs -I{} grep -nHE '@ts-ignore\s*$|@ts-expect-error\s*$|# noqa\s*$|//nolint\s*$' {} 2>/dev/null || true)"
[ -z "$hits" ] || { echo "$hits"; fail "bare suppression comment — explain the specific issue being worked around"; }

# ---------------------------------------------------------------------------
# 3. Migrations are additive-only: a migration file that existed at the
#    merge-base must not be modified or deleted in this diff.
# ---------------------------------------------------------------------------
MIGRATIONS_DIR="{{MIGRATIONS_DIR}}"         # e.g. code/backend/src/db/migrations — blank to skip
# (the {{*}) case skips the check when the scaffold left the token unsubstituted)
if [ -n "$MIGRATIONS_DIR" ] && case "$MIGRATIONS_DIR" in \{\{*) false;; *) true;; esac; then
  touched="$(git diff --name-only --diff-filter=MD "$BASE"...HEAD -- "$MIGRATIONS_DIR" || true)"
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    git cat-file -e "$BASE:$f" 2>/dev/null && fail "$f — existing migration modified/deleted (additive-only)"
  done <<< "$touched"

  # 3b. New migrations must not contain destructive DDL.
  new_migs="$(git diff --name-only --diff-filter=A "$BASE"...HEAD -- "$MIGRATIONS_DIR" || true)"
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    ddl="$(grep -nEi 'DROP (COLUMN|TABLE)|ALTER .* TYPE|RENAME (COLUMN|TO)' "$f" || true)"
    [ -z "$ddl" ] || { echo "$ddl"; fail "$f — destructive DDL in a new migration (split into two PRs)"; }
  done <<< "$new_migs"
fi

# ---------------------------------------------------------------------------
# 4. API contract pairing: if a route/controller file changed, the contract
#    doc must change in the same PR.
# ---------------------------------------------------------------------------
ROUTES_PATTERN="{{ROUTES_PATTERN}}"         # e.g. 'controller\.ts$|routes\.py$' — blank to skip
CONTRACT_DOC="{{CONTRACT_DOC}}"             # e.g. docs/api-specification.md
if [ -n "$ROUTES_PATTERN" ] && case "$ROUTES_PATTERN" in \{\{*) false;; *) true;; esac; then
  if echo "$CHANGED_FILES" | grep -qE "$ROUTES_PATTERN" \
     && ! echo "$CHANGED_FILES" | grep -qx "$CONTRACT_DOC"; then
    fail "route handlers changed but $CONTRACT_DOC did not (API-contract rule)"
  fi
fi

# ---------------------------------------------------------------------------
# 5. No secrets. Cheap pattern net — a real scanner (gitleaks etc.) belongs
#    in PROJECT_LINTS if the project has one.
# ---------------------------------------------------------------------------
hits="$(git diff "$BASE"...HEAD | grep -nE '^\+.*(AKIA[0-9A-Z]{16}|-----BEGIN (RSA|EC|OPENSSH) PRIVATE KEY|ghp_[A-Za-z0-9]{36}|xox[baprs]-[0-9A-Za-z-]{10,})' || true)"
[ -z "$hits" ] || { echo "$hits"; fail "credential-shaped string added in this diff"; }

# ---------------------------------------------------------------------------
# 6. One concern per PR — heuristic warning only (never a hard fail).
# ---------------------------------------------------------------------------
top_dirs="$(echo "$CHANGED_FILES" | awk -F/ 'NF>1 {print $1"/"$2}' | sort -u | wc -l | tr -d ' ')"
if [ "$top_dirs" -gt 4 ]; then
  echo "  WARN: diff spans $top_dirs top-level areas — is this one concern? (warning only)"
fi

# ---------------------------------------------------------------------------
if [ "$violations" -gt 0 ]; then
  echo "policy-lint: FAIL — $violations violation(s)"
  exit 1
fi
echo "policy-lint: PASS"
