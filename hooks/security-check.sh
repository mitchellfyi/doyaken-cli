#!/usr/bin/env bash
#
# security-check.sh - PostToolUse hook to flag security-sensitive changes
#
# This hook detects when security-sensitive code is modified and adds context
# suggesting a security review. It references the library/security-review.md prompt.
#
# Usage: Configure in .claude/settings.json as a PostToolUse hook for Edit|Write tools
#
# Input: JSON via stdin with tool_input.file_path
# Output: JSON with additionalContext if security-sensitive
#
set -euo pipefail

# Read JSON input
INPUT=$(cat)

# Extract file path
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""' 2>/dev/null || echo "")

if [ -z "$FILE_PATH" ] || [ ! -f "$FILE_PATH" ]; then
  exit 0
fi

# Security-sensitive file patterns
SECURITY_PATTERNS=(
  "auth"
  "login"
  "password"
  "credential"
  "token"
  "session"
  "crypto"
  "encrypt"
  "decrypt"
  "secret"
  "permission"
  "access"
  "security"
  "oauth"
  "jwt"
  "api-key"
  "apikey"
)

# Security-sensitive code patterns to grep for
SECURITY_CODE_PATTERNS=(
  "password"
  "secret"
  "token"
  "Bearer"
  "Authorization"
  "api_key"
  "apiKey"
  "private_key"
  "privateKey"
  "exec("
  "eval("
  "innerHTML"
  "dangerouslySetInnerHTML"
  "SELECT.*FROM"
  "INSERT INTO"
  "UPDATE.*SET"
  "DELETE FROM"
)

# Check if file path contains security-sensitive patterns
is_sensitive_path() {
  local path_lower
  path_lower=$(echo "$FILE_PATH" | tr '[:upper:]' '[:lower:]')

  for pattern in "${SECURITY_PATTERNS[@]}"; do
    if [[ "$path_lower" == *"$pattern"* ]]; then
      return 0
    fi
  done
  return 1
}

# Check if file contains security-sensitive code
has_sensitive_code() {
  for pattern in "${SECURITY_CODE_PATTERNS[@]}"; do
    if grep -qiE "$pattern" "$FILE_PATH" 2>/dev/null; then
      return 0
    fi
  done
  return 1
}

# Determine prompt path (check project first, then global)
get_prompt_path() {
  local prompt_name="library/security-review.md"
  local project_root="${CLAUDE_PROJECT_DIR:-$(pwd)}"

  # Check project prompts
  if [ -f "$project_root/.doyaken/prompts/$prompt_name" ]; then
    echo "$project_root/.doyaken/prompts/$prompt_name"
    return 0
  fi

  # Check global prompts
  local doyaken_home="${DOYAKEN_HOME:-$HOME/.doyaken}"
  if [ -f "$doyaken_home/prompts/$prompt_name" ]; then
    echo "$doyaken_home/prompts/$prompt_name"
    return 0
  fi

  return 1
}

# Check if this is a security-sensitive change
if is_sensitive_path || has_sensitive_code; then
  PROMPT_PATH=$(get_prompt_path) || PROMPT_PATH=""

  if [ -n "$PROMPT_PATH" ]; then
    cat << EOF
{
  "hookSpecificOutput": {
    "additionalContext": "SECURITY NOTE: This file ($FILE_PATH) contains security-sensitive code. Consider running a security review. Prompt available at: $PROMPT_PATH"
  }
}
EOF
  else
    cat << EOF
{
  "hookSpecificOutput": {
    "additionalContext": "SECURITY NOTE: This file ($FILE_PATH) contains security-sensitive code. Consider reviewing for OWASP Top 10 vulnerabilities."
  }
}
EOF
  fi
fi

exit 0
