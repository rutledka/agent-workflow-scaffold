#!/usr/bin/env bash
set -euo pipefail

# agent-workflow-scaffold — convenience installer
#
# Usage:
#   curl -L https://raw.githubusercontent.com/rutledka/agent-workflow-scaffold/main/install.sh | bash
#   curl -L https://raw.githubusercontent.com/rutledka/agent-workflow-scaffold/main/install.sh | bash -s -- --user
#   curl -L https://raw.githubusercontent.com/rutledka/agent-workflow-scaffold/main/install.sh | bash -s -- --project
#
# Default mode (no flag): asks interactively whether to install user-scoped or project-scoped.

REPO_URL="${AWS_REPO_URL:-git@github.com:rutledka/agent-workflow-scaffold.git}"
HTTPS_REPO_URL="https://github.com/rutledka/agent-workflow-scaffold.git"
SKILL_NAME="agent-workflow-scaffold"

mode=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --user)
      mode="user"
      shift
      ;;
    --project)
      mode="project"
      shift
      ;;
    -h|--help)
      cat <<EOF
agent-workflow-scaffold — installer

Usage:
  install.sh [--user | --project]

  --user      Install to ~/.claude/skills/$SKILL_NAME (available in every project)
  --project   Install to ./.claude/skills/$SKILL_NAME (scoped to current project)

If neither flag is given, you'll be asked interactively.
EOF
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

if [[ -z "$mode" ]]; then
  echo "Where should the skill be installed?"
  echo "  1) User-scoped — ~/.claude/skills/$SKILL_NAME (available in every project)"
  echo "  2) Project-scoped — ./.claude/skills/$SKILL_NAME (scoped to current project)"
  read -r -p "Pick 1 or 2: " choice
  case "$choice" in
    1) mode="user" ;;
    2) mode="project" ;;
    *) echo "Invalid choice." >&2; exit 1 ;;
  esac
fi

if [[ "$mode" == "user" ]]; then
  target="$HOME/.claude/skills/$SKILL_NAME"
elif [[ "$mode" == "project" ]]; then
  if [[ ! -d ".git" ]]; then
    echo "Project-scoped install requires being inside a git repo (current dir has no .git)." >&2
    exit 1
  fi
  target=".claude/skills/$SKILL_NAME"
fi

if [[ -e "$target" ]]; then
  echo "Target already exists: $target" >&2
  echo "Remove it first or choose a different mode." >&2
  exit 1
fi

mkdir -p "$(dirname "$target")"

# Try ssh first, fall back to https. Don't fail on key issues.
if git clone "$REPO_URL" "$target" 2>/dev/null; then
  echo "Installed via SSH."
elif git clone "$HTTPS_REPO_URL" "$target"; then
  echo "Installed via HTTPS."
else
  echo "git clone failed for both SSH and HTTPS." >&2
  exit 1
fi

echo
echo "agent-workflow-scaffold installed at: $target"
echo
echo "Next steps:"
echo "  1) Open Claude Code in your project."
echo "  2) Invoke the skill:  /$SKILL_NAME"
echo "  3) Answer the four scoping questions; the skill will do the rest."
echo
