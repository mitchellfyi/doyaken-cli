#!/usr/bin/env bash
# PostToolUse hook (Bash) — validates commits after creation
# Checks conventional commit format, then delegates to guard-handler.py
# for markdown-based guard evaluation.
set -euo pipefail

# Only run after actual git commit commands.
# Uses word-boundary matching to avoid false positives on git commit-tree,
# comments containing "git commit", etc.
TOOL_INPUT="${CLAUDE_TOOL_USE_INPUT:-}"
if ! printf '%s\n' "$TOOL_INPUT" | grep -qE '(^|[;&|]\s*)git\s+commit(\s|$)'; then
  exit 0
fi

# Check if a commit was actually created (exit code 0 means success)
TOOL_EXIT="${CLAUDE_TOOL_USE_EXIT_CODE:-0}"
if [[ "$TOOL_EXIT" != "0" ]]; then
  exit 0
fi

# Delegate to guard handler for markdown-based guard evaluation
source "${DOYAKEN_DIR:-$HOME/work/doyaken}/lib/common.sh"
COMMITTED_FILES=$(git diff-tree --no-commit-id --name-only -r HEAD 2>/dev/null || echo "")
COMMIT_MSG=$(git log -1 --pretty=format:%s 2>/dev/null || echo "")

export DOYAKEN_GUARD_EVENT="commit"
export CLAUDE_TOOL_USE_INPUT="${COMMITTED_FILES}"$'\n'"${COMMIT_MSG}"

GUARD_EXIT=0
python3 "$DOYAKEN_DIR/hooks/guard-handler.py" || GUARD_EXIT=$?

# Validate conventional commit format (handled here, not in guards, because
# it needs to check the commit message specifically, not the combined text)
# Full set of conventional commit types per https://www.conventionalcommits.org
CONVENTIONAL_REGEX='^(feat|fix|refactor|perf|docs|test|chore|build|ci|style|revert)(\([^)]+\))?!?: .+'
if [[ -n "$COMMIT_MSG" ]] && ! printf '%s\n' "$COMMIT_MSG" | grep -qE "$CONVENTIONAL_REGEX"; then
  echo "Commit message does not follow conventional format." >&2
  echo "Expected: <type>[(<scope>)][!]: <description>" >&2
  echo "Got: $COMMIT_MSG" >&2
  echo "Amend the commit with a properly formatted message." >&2
  GUARD_EXIT=2
fi

exit $GUARD_EXIT
