#!/usr/bin/env bash
#
# format-on-save.sh - PostToolUse hook to auto-format edited files
#
# This hook runs code formatters after Edit/Write operations based on file extension.
# It detects available formatters and uses them if configured.
#
# Usage: Configure in .claude/settings.json as a PostToolUse hook for Edit|Write tools
#
# Input: JSON via stdin with tool_input.file_path and tool_response
# Output: Exit 0 (success), non-zero (warning, logged but doesn't block)
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

# Detect project root (look for common markers)
PROJECT_ROOT="${CLAUDE_PROJECT_DIR:-$(pwd)}"

# Check for project-specific formatter config
format_file() {
  local file="$1"

  # Try prettier for web files
  if [[ "$EXT" =~ ^(js|jsx|ts|tsx|json|css|scss|md|html|yaml|yml)$ ]]; then
    if [ -f "$PROJECT_ROOT/node_modules/.bin/prettier" ]; then
      "$PROJECT_ROOT/node_modules/.bin/prettier" --write "$file" 2>/dev/null || true
      return 0
    elif command -v prettier &>/dev/null; then
      prettier --write "$file" 2>/dev/null || true
      return 0
    fi
  fi

  # Try black for Python
  if [[ "$EXT" == "py" ]]; then
    if command -v black &>/dev/null; then
      black --quiet "$file" 2>/dev/null || true
      return 0
    elif command -v ruff &>/dev/null; then
      ruff format "$file" 2>/dev/null || true
      return 0
    fi
  fi

  # Try gofmt for Go
  if [[ "$EXT" == "go" ]]; then
    if command -v gofmt &>/dev/null; then
      gofmt -w "$file" 2>/dev/null || true
      return 0
    fi
  fi

  # Try rustfmt for Rust
  if [[ "$EXT" == "rs" ]]; then
    if command -v rustfmt &>/dev/null; then
      rustfmt "$file" 2>/dev/null || true
      return 0
    fi
  fi

  # Try shfmt for shell scripts
  if [[ "$EXT" =~ ^(sh|bash)$ ]] || head -1 "$file" 2>/dev/null | grep -q "^#!.*\(bash\|sh\)"; then
    if command -v shfmt &>/dev/null; then
      shfmt -w "$file" 2>/dev/null || true
      return 0
    fi
  fi

  return 0
}

# Run formatter
format_file "$FILE_PATH"

exit 0
