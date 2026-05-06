#!/usr/bin/env bash
#
# migrate-personas-to-voltagent-subagents.sh
#
# Standalone migration for v1.0.0-scaffolded projects: appends the
# "## Available sub-agents for delegation" section to each persona file
# in agents/ that doesn't already have it, and creates docs/subagents-registry.md
# from the scaffold template if missing.
#
# Same logic as Step 1.5 detectors D10 + D11 in the scaffold's SKILL.md, but
# packaged as a one-shot bash invocation — useful for users who want to pick
# up the post-v1 sub-agents wiring without re-running the full discovery
# interview.
#
# Usage:
#   cd <your-scaffolded-project>
#   bash <path-to-scaffold>/scripts/migrate-personas-to-voltagent-subagents.sh
#
# Flags:
#   --no-pr     Stage changes in a worktree and commit, but don't push or
#               open a PR. Useful for offline runs or local-only review.
#   --dry-run   Print what would change without modifying any files.
#   -h|--help   This help.
#

set -euo pipefail

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCAFFOLD_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TEMPLATES_AGENTS="$SCAFFOLD_ROOT/templates/agents"
TEMPLATES_DOCS="$SCAFFOLD_ROOT/templates/docs"

OFFTHESHELF_PERSONAS=(
  orchestrator
  project-manager
  engineering-manager
  backend-engineer
  frontend-engineer
  qa-engineer
  platform-engineer
  product-designer
  legal-advisor
  pilot-lead
  personal-assistant
)

# ---------------------------------------------------------------------------
# Flags
# ---------------------------------------------------------------------------

no_pr=false
dry_run=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-pr)   no_pr=true;   shift ;;
    --dry-run) dry_run=true; shift ;;
    -h|--help)
      sed -n '2,25p' "${BASH_SOURCE[0]}" | sed 's|^# *||'
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 2
      ;;
  esac
done

# ---------------------------------------------------------------------------
# Sanity checks
# ---------------------------------------------------------------------------

if [[ ! -d ".git" ]]; then
  echo "ERROR: run this from the project root (no .git/ found here)." >&2
  exit 1
fi

if [[ ! -d "agents" ]]; then
  echo "ERROR: no agents/ directory found. Is this a scaffolded project?" >&2
  exit 1
fi

if [[ ! -d "$TEMPLATES_AGENTS" ]]; then
  echo "ERROR: scaffold templates not found at $TEMPLATES_AGENTS" >&2
  echo "       The migration script needs to read from the scaffold install." >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# Extract everything from "## Available sub-agents for delegation" to EOF
# from a template file. Used to copy the section into the user's persona.
extract_subagents_section() {
  local template="$1"
  awk '/^## Available sub-agents for delegation$/{flag=1} flag' "$template"
}

# Match a user persona filename to an off-the-shelf template name, if any.
# Returns the template basename (e.g. "backend-engineer") or empty.
match_offtheshelf() {
  local persona_file="$1"
  local base
  base="$(basename "$persona_file" .md)"
  for ots in "${OFFTHESHELF_PERSONAS[@]}"; do
    if [[ "$base" == "$ots" ]]; then
      echo "$ots"
      return 0
    fi
  done
  return 1
}

has_subagents_section() {
  grep -q '^## Available sub-agents for delegation' "$1"
}

# ---------------------------------------------------------------------------
# Plan
# ---------------------------------------------------------------------------

declare -a TO_MIGRATE=()       # persona file paths needing append
declare -a CUSTOM_MANUAL=()    # custom personas the user must edit themselves
declare -a ALREADY_MIGRATED=() # skip
need_registry_copy=false

for persona in agents/*.md; do
  [[ -e "$persona" ]] || continue
  if has_subagents_section "$persona"; then
    ALREADY_MIGRATED+=("$persona")
    continue
  fi
  if match_offtheshelf "$persona" >/dev/null; then
    TO_MIGRATE+=("$persona")
  else
    CUSTOM_MANUAL+=("$persona")
  fi
done

if [[ ! -f "docs/subagents-registry.md" ]]; then
  need_registry_copy=true
fi

# ---------------------------------------------------------------------------
# Report
# ---------------------------------------------------------------------------

echo "Migration plan:"
echo
if (( ${#TO_MIGRATE[@]} > 0 )); then
  echo "  Will append 'Available sub-agents for delegation' to:"
  for f in "${TO_MIGRATE[@]}"; do echo "    - $f"; done
  echo
fi
if (( ${#CUSTOM_MANUAL[@]} > 0 )); then
  echo "  Custom personas — append manually using docs/subagents-registry.md:"
  for f in "${CUSTOM_MANUAL[@]}"; do echo "    - $f"; done
  echo
fi
if (( ${#ALREADY_MIGRATED[@]} > 0 )); then
  echo "  Already migrated (skipped):"
  for f in "${ALREADY_MIGRATED[@]}"; do echo "    - $f"; done
  echo
fi
if $need_registry_copy; then
  echo "  Will create: docs/subagents-registry.md (from template)"
  echo
fi

if (( ${#TO_MIGRATE[@]} == 0 )) && ! $need_registry_copy; then
  echo "Nothing to migrate. Exiting."
  exit 0
fi

if $dry_run; then
  echo "Dry run — no changes written."
  exit 0
fi

# ---------------------------------------------------------------------------
# Worktree + apply
# ---------------------------------------------------------------------------

ts="$(date +%Y%m%d-%H%M)"
branch="migrate/voltagent-subagents-$ts"
worktree=".worktrees/$branch"

echo "Creating worktree at $worktree on branch $branch"
git worktree add "$worktree" -b "$branch" >/dev/null

cleanup_on_failure() {
  echo "Migration failed. The worktree is preserved at $worktree for inspection." >&2
  echo "Remove it with: git worktree remove --force $worktree && git branch -D $branch" >&2
}
trap cleanup_on_failure ERR

cd "$worktree"

if $need_registry_copy; then
  mkdir -p docs
  cp "$TEMPLATES_DOCS/subagents-registry.md" docs/subagents-registry.md
  git add docs/subagents-registry.md
  git commit -m "migrate: add docs/subagents-registry.md from scaffold template" >/dev/null
  echo "  ✓ created docs/subagents-registry.md"
fi

for persona in "${TO_MIGRATE[@]}"; do
  ots="$(match_offtheshelf "$persona")"
  template="$TEMPLATES_AGENTS/${ots}.md"
  if [[ ! -f "$template" ]]; then
    echo "  ✗ template missing: $template (skipping $persona)" >&2
    continue
  fi
  section="$(extract_subagents_section "$template")"
  if [[ -z "$section" ]]; then
    echo "  ✗ template has no Available-sub-agents section: $template (skipping $persona)" >&2
    continue
  fi
  # Append a leading blank line + the section.
  {
    echo
    echo "$section"
  } >> "$persona"
  git add "$persona"
  git commit -m "migrate: append Available sub-agents section to $(basename "$persona")" >/dev/null
  echo "  ✓ appended to $persona"
done

trap - ERR

# ---------------------------------------------------------------------------
# Push + PR
# ---------------------------------------------------------------------------

if $no_pr; then
  echo
  echo "Done. Worktree at $worktree is staged on branch $branch but not pushed (--no-pr)."
  echo "Push and PR yourself when ready."
  exit 0
fi

echo
echo "Pushing branch and opening PR…"
if ! git push -u origin "$branch" 2>&1; then
  echo "  push failed. The worktree is preserved at $worktree." >&2
  echo "  Push manually with: git -C $worktree push -u origin $branch" >&2
  exit 1
fi

if ! command -v gh >/dev/null 2>&1; then
  echo "  gh CLI not found — branch is pushed, please open the PR manually." >&2
  exit 0
fi

gh pr create \
  --base "$(git symbolic-ref --short HEAD)" \
  --head "$branch" \
  --title "migrate: append Available sub-agents to off-the-shelf personas" \
  --body "$(cat <<EOF
## Summary

Standalone migration adding the \`## Available sub-agents for delegation\` section to off-the-shelf personas in \`agents/\`. Same logic as Step 1.5 detectors D10 + D11 in the scaffold's SKILL.md, run via \`scripts/migrate-personas-to-voltagent-subagents.sh\`.

Personas updated:

$(for f in "${TO_MIGRATE[@]}"; do echo "- \`$f\`"; done)

$( $need_registry_copy && echo "Also created \`docs/subagents-registry.md\` from the scaffold template." )

$( (( ${#CUSTOM_MANUAL[@]} > 0 )) && cat <<MANUAL
Custom personas left for manual editing (review \`docs/subagents-registry.md\`'s keyword index and add the relevant section yourself):

$(for f in "${CUSTOM_MANUAL[@]}"; do echo "- \`$f\`"; done)
MANUAL
)

## Test plan

- [ ] Each persona file now has a \`## Available sub-agents for delegation\` section
- [ ] The Section content matches the corresponding scaffold template
- [ ] Re-running the script reports "Nothing to migrate. Exiting."
EOF
)" || {
  echo "  gh pr create failed — branch pushed; open the PR manually." >&2
  exit 1
}

echo
echo "Migration complete."
