#!/usr/bin/env bash
#
# uninstall.sh — undo what `agent-workflow-scaffold` produced in this project.
#
# Removes the artifacts the scaffold created — agents/, pm/, the registry
# files in docs/, the .mcp config, the .claude/skills symlink, and the
# AGENTS.md/CLAUDE.md pair (restoring a user-authored CLAUDE.md if the merge
# delimiter is present). Runs inside a worktree and opens a PR so you can
# review the diff before merging.
#
# Usage:
#   cd <your-scaffolded-project>
#   bash <path-to-scaffold>/uninstall.sh [flags]
#
# Flags:
#   --dry-run            List what would be removed without changing anything.
#   --keep-pm            Don't touch pm/ (the backlog often has user content).
#   --keep-docs          Don't touch the registry files in docs/. ADR files in
#                        docs/adr/00NN-*.md are never touched regardless.
#   --keep-skills        Don't touch skills/ or .claude/skills.
#   --keep-personas      Don't touch agents/.
#   --keep-mcp           Don't touch .mcp.example.json / .mcp.json.
#   --keep-claude-md     Don't touch AGENTS.md / CLAUDE.md.
#   --remove-memory      Also remove the user-scoped memory entries at
#                        ~/.claude/projects/<slug>/memory/. Off by default —
#                        memory is user data, not project artifact.
#   --no-pr              Stage changes in a worktree and commit, but don't
#                        push or open a PR.
#   --yes                Skip the single confirmation prompt.
#   -h|--help            This help.
#
# Notes:
#   - The script is conservative. ADR files (docs/adr/00NN-*.md) are never
#     touched — they're load-bearing project decisions, not scaffold artifacts.
#   - Hand-authored docs in docs/ (TDDs, API specs, etc.) are not touched.
#   - .gitignore additions from the scaffold (.worktrees/, .mcp.json, .env*)
#     are left in place — they're harmless and the user may want them anyway.
#   - .env file content is not touched (only .env.example is removed).
#

set -euo pipefail

# ---------------------------------------------------------------------------
# Flags
# ---------------------------------------------------------------------------

dry_run=false
keep_pm=false
keep_docs=false
keep_skills=false
keep_personas=false
keep_mcp=false
keep_claude_md=false
remove_memory=false
no_pr=false
auto_yes=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)         dry_run=true;        shift ;;
    --keep-pm)         keep_pm=true;        shift ;;
    --keep-docs)       keep_docs=true;      shift ;;
    --keep-skills)     keep_skills=true;    shift ;;
    --keep-personas)   keep_personas=true;  shift ;;
    --keep-mcp)        keep_mcp=true;       shift ;;
    --keep-claude-md)  keep_claude_md=true; shift ;;
    --remove-memory)   remove_memory=true;  shift ;;
    --no-pr)           no_pr=true;          shift ;;
    --yes)             auto_yes=true;       shift ;;
    -h|--help)
      sed -n '2,40p' "${BASH_SOURCE[0]}" | sed 's|^# *||'
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

if ! git diff-index --quiet HEAD -- 2>/dev/null; then
  echo "ERROR: working tree has uncommitted changes. Commit or stash first." >&2
  echo "       (The script needs a clean tree so the uninstall PR is reviewable.)" >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# Plan: identify what would be removed
# ---------------------------------------------------------------------------

declare -a PATHS_TO_REMOVE=()
declare -a CLAUDE_MD_RESTORE_NOTE=()
declare -a DOCS_TO_REMOVE=()
declare -a NOTES=()

DOCS_REGISTRY_FILES=(
  docs/skills-registry.md
  docs/tech-docs-registry.md
  docs/feature-overlap-registry.md
  docs/subagents-registry.md
  docs/integrations.md
  docs/README.md
  docs/adr/0000-template.md
  docs/dispatch-logs
)

if ! $keep_personas && [[ -d agents ]]; then
  PATHS_TO_REMOVE+=("agents")
fi

if ! $keep_pm && [[ -d pm ]]; then
  PATHS_TO_REMOVE+=("pm")
fi

if ! $keep_docs; then
  for f in "${DOCS_REGISTRY_FILES[@]}"; do
    [[ -e "$f" ]] && DOCS_TO_REMOVE+=("$f")
  done
  if (( ${#DOCS_TO_REMOVE[@]} > 0 )); then
    PATHS_TO_REMOVE+=("${DOCS_TO_REMOVE[@]}")
  fi
fi

if ! $keep_skills; then
  [[ -L .claude/skills ]] && PATHS_TO_REMOVE+=(".claude/skills")
  if [[ -d skills ]]; then
    PATHS_TO_REMOVE+=("skills")
  fi
fi

if ! $keep_mcp; then
  [[ -e .mcp.example.json ]] && PATHS_TO_REMOVE+=(".mcp.example.json")
  [[ -e .mcp.json ]] && PATHS_TO_REMOVE+=(".mcp.json")
fi

if ! $keep_claude_md; then
  if [[ -L CLAUDE.md ]]; then
    PATHS_TO_REMOVE+=("CLAUDE.md")
  fi
  if [[ -f AGENTS.md && ! -L AGENTS.md ]]; then
    PATHS_TO_REMOVE+=("AGENTS.md")
    if grep -q '^## Existing project rules (preserved from CLAUDE.md)' AGENTS.md; then
      CLAUDE_MD_RESTORE_NOTE+=("AGENTS.md contains a preserved CLAUDE.md merge delimiter — your original CLAUDE.md content will be restored as a regular file at CLAUDE.md before AGENTS.md is removed.")
    fi
  fi
fi

# Per-tool wiring (always removed with --keep-claude-md=false; harmless symlinks)
if ! $keep_claude_md; then
  [[ -L .github/copilot-instructions.md ]] && PATHS_TO_REMOVE+=(".github/copilot-instructions.md")
fi

# Memory entries (opt-in)
declare -a MEMORY_DIRS=()
if $remove_memory; then
  project_slug="$(pwd | sed 's|^/||; s|/|-|g')"
  candidate="$HOME/.claude/projects/-$project_slug/memory"
  if [[ -d "$candidate" ]]; then
    MEMORY_DIRS+=("$candidate")
  fi
fi

# ---------------------------------------------------------------------------
# Report
# ---------------------------------------------------------------------------

if (( ${#PATHS_TO_REMOVE[@]} == 0 )) && (( ${#MEMORY_DIRS[@]} == 0 )); then
  echo "Nothing to remove. The project doesn't appear to have scaffold artifacts."
  exit 0
fi

echo "Uninstall plan for: $(pwd)"
echo
if (( ${#PATHS_TO_REMOVE[@]} > 0 )); then
  echo "  Will remove from working tree:"
  for p in "${PATHS_TO_REMOVE[@]}"; do echo "    - $p"; done
  echo
fi
if (( ${#CLAUDE_MD_RESTORE_NOTE[@]} > 0 )); then
  echo "  Notes:"
  for n in "${CLAUDE_MD_RESTORE_NOTE[@]}"; do echo "    - $n"; done
  echo
fi
if (( ${#MEMORY_DIRS[@]} > 0 )); then
  echo "  Will remove user memory:"
  for d in "${MEMORY_DIRS[@]}"; do echo "    - $d"; done
  echo
fi
echo "  NOT touched:"
echo "    - .gitignore additions (left in place; harmless)"
echo "    - docs/adr/00NN-*.md decision records (load-bearing)"
echo "    - any hand-authored files outside the scaffold's known set"
echo "    - .env file content (only .env.example is removed)"
echo "    - .aider.conf.yml content (the scaffold appended a 'read: AGENTS.md' line; remove manually if you want)"
echo

if $dry_run; then
  echo "Dry run — no changes written."
  exit 0
fi

if ! $auto_yes; then
  read -r -p "Proceed? (y/N) " confirm
  case "$confirm" in
    y|Y|yes|YES) ;;
    *) echo "Aborted."; exit 0 ;;
  esac
fi

# ---------------------------------------------------------------------------
# Worktree + apply
# ---------------------------------------------------------------------------

ts="$(date +%Y%m%d-%H%M)"
branch="uninstall/agent-workflow-scaffold-$ts"
worktree=".worktrees/$branch"

echo
echo "Creating worktree at $worktree on branch $branch"
git worktree add "$worktree" -b "$branch" >/dev/null

cleanup_on_failure() {
  echo "Uninstall failed. The worktree is preserved at $worktree for inspection." >&2
  echo "Remove it with: git worktree remove --force $worktree && git branch -D $branch" >&2
}
trap cleanup_on_failure ERR

cd "$worktree"

# Restore user's CLAUDE.md content from AGENTS.md merge (if applicable),
# BEFORE removing AGENTS.md.
if ! $keep_claude_md && [[ -f AGENTS.md && ! -L AGENTS.md ]]; then
  if grep -q '^## Existing project rules (preserved from CLAUDE.md)' AGENTS.md; then
    awk '/^## Existing project rules \(preserved from CLAUDE\.md\)/{flag=1; next} flag' AGENTS.md > /tmp/uninstall-claude-md-restore.$$.md
    if [[ -L CLAUDE.md ]]; then
      rm CLAUDE.md
    fi
    mv /tmp/uninstall-claude-md-restore.$$.md CLAUDE.md
    git add CLAUDE.md
    git commit -m "uninstall: restore CLAUDE.md from AGENTS.md merge delimiter" >/dev/null
    echo "  ✓ restored CLAUDE.md from AGENTS.md merge"
  fi
fi

# Remove paths.
for p in "${PATHS_TO_REMOVE[@]}"; do
  if [[ -L "$p" ]]; then
    rm "$p"
    git rm "$p" >/dev/null 2>&1 || git add "$p"
  elif [[ -e "$p" ]]; then
    git rm -rf "$p" >/dev/null
  fi
done

# .claude/ might be empty after the symlink removal; remove the empty dir.
if [[ -d .claude && -z "$(ls -A .claude 2>/dev/null)" ]]; then
  rmdir .claude
fi

if (( ${#PATHS_TO_REMOVE[@]} > 0 )); then
  git commit -m "uninstall: remove agent-workflow-scaffold artifacts" >/dev/null
  echo "  ✓ removed scaffold artifacts (${#PATHS_TO_REMOVE[@]} paths)"
fi

trap - ERR

# ---------------------------------------------------------------------------
# Memory removal (out-of-tree, no commit needed)
# ---------------------------------------------------------------------------

cd - >/dev/null
if (( ${#MEMORY_DIRS[@]} > 0 )); then
  for d in "${MEMORY_DIRS[@]}"; do
    rm -rf "$d"
    echo "  ✓ removed memory dir: $d"
  done
fi

# ---------------------------------------------------------------------------
# Push + PR
# ---------------------------------------------------------------------------

cd "$worktree"

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

base_branch="$(git -C "$worktree" symbolic-ref refs/remotes/origin/HEAD --short 2>/dev/null | sed 's|^origin/||' || echo main)"

paths_md="$(printf -- '- `%s`\n' "${PATHS_TO_REMOVE[@]}")"
memory_md=""
if (( ${#MEMORY_DIRS[@]} > 0 )); then
  memory_md="

User memory removed (not in this PR — out-of-tree):
$(printf -- '- `%s`\n' "${MEMORY_DIRS[@]}")"
fi
restore_md=""
if (( ${#CLAUDE_MD_RESTORE_NOTE[@]} > 0 )); then
  restore_md="

Note: a preserved CLAUDE.md merge delimiter was detected in AGENTS.md; the original CLAUDE.md content was restored as a regular file before AGENTS.md was removed. Verify this in the diff."
fi

body_file="$(mktemp -t uninstall-pr-body.XXXXXX)"
{
  echo "## Summary"
  echo
  echo "Generated by \`uninstall.sh\` to remove the artifacts the agent-workflow-scaffold produced in this project."
  echo
  echo "Paths removed:"
  echo
  echo "$paths_md"
  if [[ -n "$restore_md" ]]; then echo "$restore_md"; fi
  if [[ -n "$memory_md" ]]; then echo "$memory_md"; fi
  echo
  echo "Not touched:"
  echo "- \`.gitignore\` additions (\`.worktrees/\`, \`.mcp.json\`, \`.env\`) — harmless even after uninstall"
  echo "- \`docs/adr/00NN-*.md\` decision records (load-bearing project history)"
  echo "- Any hand-authored files outside the scaffold's known artifact set"
  echo "- \`.env\` file content (only \`.env.example\` was removed)"
  echo "- \`.aider.conf.yml\` — the scaffold appended a \`read: AGENTS.md\` line; remove manually if you want"
  echo
  echo "## Test plan"
  echo
  echo "- [ ] Review the diff — confirm no hand-authored files were caught accidentally"
  echo "- [ ] Verify any preserved CLAUDE.md content was restored cleanly (if applicable)"
  echo "- [ ] Run \`gh pr checks\` if you have CI; this is a delete-only PR so CI should pass trivially"
} > "$body_file"

if ! gh pr create \
    --base "$base_branch" \
    --head "$branch" \
    --title "uninstall: remove agent-workflow-scaffold artifacts" \
    --body-file "$body_file"; then
  echo "  gh pr create failed — branch pushed; open the PR manually." >&2
  rm -f "$body_file"
  exit 1
fi
rm -f "$body_file"

echo
echo "Uninstall PR opened. Review the diff and merge when ready."
