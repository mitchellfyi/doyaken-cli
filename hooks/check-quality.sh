#!/usr/bin/env bash
#
# quality-check.sh - PostToolUse hook to run quality checks after code changes
#
# This hook runs lint/typecheck/test after Edit or Write operations to catch
# issues immediately. It helps maintain high code quality during AI coding.
#
# Usage: Configure in .claude/settings.json as a PostToolUse hook for Edit|Write tools
#
# Input: JSON via stdin with tool_input.file_path
# Output: JSON with additionalContext if quality issues found
#
set -euo pipefail

# Read JSON input
INPUT=$(cat)

# Extract file path
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""' 2>/dev/null || echo "")

if [ -z "$FILE_PATH" ] || [ ! -f "$FILE_PATH" ]; then
  exit 0
fi

# Get file extension
EXT="${FILE_PATH##*.}"

# Determine project root
PROJECT_ROOT="${CLAUDE_PROJECT_DIR:-$(pwd)}"

# Check if this is a code file worth checking
is_code_file() {
  case "$EXT" in
    ts|tsx|js|jsx|py|go|rs|rb|java|kt|swift|c|cpp|h|hpp)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

# Skip non-code files
if ! is_code_file; then
  exit 0
fi

# Run quality checks based on project type
ISSUES=""

# Node.js projects
if [ -f "$PROJECT_ROOT/package.json" ]; then
  # Check if lint script exists
  if grep -q '"lint"' "$PROJECT_ROOT/package.json" 2>/dev/null; then
    if ! npm run lint --silent 2>/dev/null; then
      ISSUES="$ISSUES\n- Lint errors detected. Run 'npm run lint' to see details."
    fi
  fi

  # Check if typecheck script exists
  if grep -q '"typecheck"' "$PROJECT_ROOT/package.json" 2>/dev/null; then
    if ! npm run typecheck --silent 2>/dev/null; then
      ISSUES="$ISSUES\n- Type errors detected. Run 'npm run typecheck' to see details."
    fi
  fi
fi

# Python projects
if [ -f "$PROJECT_ROOT/pyproject.toml" ] || [ -f "$PROJECT_ROOT/requirements.txt" ]; then
  # Check with ruff if available
  if command -v ruff &>/dev/null; then
    if ! ruff check "$FILE_PATH" --quiet 2>/dev/null; then
      ISSUES="$ISSUES\n- Ruff found issues. Run 'ruff check $FILE_PATH' to see details."
    fi
  fi

  # Check with mypy if available
  if command -v mypy &>/dev/null; then
    if ! mypy "$FILE_PATH" --no-error-summary 2>/dev/null | grep -q "Success"; then
      ISSUES="$ISSUES\n- Type errors detected. Run 'mypy $FILE_PATH' to see details."
    fi
  fi
fi

# Go projects
if [ -f "$PROJECT_ROOT/go.mod" ]; then
  if ! go vet "$FILE_PATH" 2>/dev/null; then
    ISSUES="$ISSUES\n- Go vet found issues. Run 'go vet $FILE_PATH' to see details."
  fi
fi

# Output issues if found
if [ -n "$ISSUES" ]; then
  cat << EOF
{
  "hookSpecificOutput": {
    "additionalContext": "QUALITY CHECK: Issues detected after modifying $FILE_PATH:$ISSUES\n\nPlease fix these issues before continuing. Refer to prompts/library/quality.md for quality standards."
  }
}
EOF
fi

exit 0
