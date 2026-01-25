#!/usr/bin/env bash
#
# inject-base-prompt.sh - UserPromptSubmit hook to inject base context
#
# This hook adds base instructions from the standalone/base.md prompt to every user prompt,
# ensuring consistent behavior across all interactions.
#
# Usage: Configure in .claude/settings.json as a UserPromptSubmit hook
#
# Input: JSON via stdin with user prompt
# Output: JSON with updatedUserPrompt or additionalContext
#
set -euo pipefail

# Read JSON input
INPUT=$(cat)

# Determine prompt path (check project first, then global)
get_prompt_path() {
  local prompt_name="standalone/base.md"
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

# Get base prompt path
PROMPT_PATH=$(get_prompt_path) || exit 0

# Read base prompt content
BASE_CONTENT=$(cat "$PROMPT_PATH" 2>/dev/null) || exit 0

# Only inject if we have content
if [ -n "$BASE_CONTENT" ]; then
  # Use additionalContext to provide the base instructions
  # This is cleaner than modifying the user's prompt directly
  cat << EOF
{
  "hookSpecificOutput": {
    "additionalContext": "Reference: Base instructions are available at $PROMPT_PATH. Key principles: pragmatic over dogmatic, minimal and correct, verified before shipped."
  }
}
EOF
fi

exit 0
