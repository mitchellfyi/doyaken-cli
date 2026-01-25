#!/usr/bin/env bash
#
# protect-sensitive-files.sh - PreToolUse hook to protect sensitive files
#
# This hook blocks or warns when editing sensitive files like .env, credentials,
# package-lock.json, etc.
#
# Usage: Configure in .claude/settings.json as a PreToolUse hook for Edit|Write tools
#
# Input: JSON via stdin with tool_input.file_path
# Output: Exit 0 (allow), Exit 2 (block with stderr message)
#
set -euo pipefail

# Read JSON input
INPUT=$(cat)

# Extract file path from tool input
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""' 2>/dev/null || echo "")

if [ -z "$FILE_PATH" ]; then
  exit 0  # No file path, allow
fi

# Patterns to block (exit 2)
BLOCKED_PATTERNS=(
  ".env"
  ".env.local"
  ".env.production"
  "credentials.json"
  "secrets.yaml"
  "id_rsa"
  "id_ed25519"
  ".pem"
  ".key"
)

# Patterns to warn about (allow but add context)
WARN_PATTERNS=(
  "package-lock.json"
  "yarn.lock"
  "pnpm-lock.yaml"
  "Gemfile.lock"
  "poetry.lock"
  "Cargo.lock"
  ".git/"
)

# Check blocked patterns
for pattern in "${BLOCKED_PATTERNS[@]}"; do
  if [[ "$FILE_PATH" == *"$pattern"* ]]; then
    echo "BLOCKED: Cannot edit sensitive file: $FILE_PATH" >&2
    echo "This file contains secrets or credentials that should not be modified by the agent." >&2
    exit 2
  fi
done

# Check warn patterns (allow but provide context)
for pattern in "${WARN_PATTERNS[@]}"; do
  if [[ "$FILE_PATH" == *"$pattern"* ]]; then
    # Output JSON with additional context for Claude
    cat << EOF
{
  "hookSpecificOutput": {
    "additionalContext": "WARNING: You are editing $FILE_PATH which is typically auto-generated. Make sure this is intentional and consider whether the change should be made to the source file instead."
  }
}
EOF
    exit 0
  fi
done

# Allow all other files
exit 0
