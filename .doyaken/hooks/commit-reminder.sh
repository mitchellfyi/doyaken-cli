#!/usr/bin/env bash
#
# commit-reminder.sh - Stop hook to remind about uncommitted changes
#
# This hook checks for uncommitted changes when Claude stops and suggests
# committing if there are meaningful changes.
#
# Usage: Configure in .claude/settings.json as a Stop hook
#
# Input: JSON via stdin with stop reason
# Output: JSON with additionalContext if uncommitted changes exist
#
set -euo pipefail

# Read JSON input
INPUT=$(cat 2>/dev/null || echo "{}")

# Get project root
PROJECT_ROOT="${CLAUDE_PROJECT_DIR:-$(pwd)}"

# Check if git repo
if [ ! -d "$PROJECT_ROOT/.git" ]; then
  exit 0
fi

cd "$PROJECT_ROOT"

# Check for uncommitted changes
CHANGES=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')

if [ "$CHANGES" -eq 0 ]; then
  exit 0
fi

# Get summary of changes
MODIFIED=$(git status --porcelain 2>/dev/null | grep -c "^ M" || echo "0")
ADDED=$(git status --porcelain 2>/dev/null | grep -c "^A " || echo "0")
UNTRACKED=$(git status --porcelain 2>/dev/null | grep -c "^??" || echo "0")

# Only remind if there are significant changes
if [ "$CHANGES" -gt 0 ]; then
  cat << EOF
{
  "hookSpecificOutput": {
    "additionalContext": "REMINDER: You have $CHANGES uncommitted change(s) ($MODIFIED modified, $ADDED staged, $UNTRACKED untracked). Consider committing your work with a descriptive message."
  }
}
EOF
fi

exit 0
