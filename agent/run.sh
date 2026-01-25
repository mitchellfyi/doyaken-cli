#!/usr/bin/env bash
#
# Claude Agent - Main Entry Point
#
# This is the main entry point for the Claude Agent system.
# It sets up the environment and delegates to the core library.
#
# Usage:
#   .claude/agent/run.sh        # Run 5 tasks (default)
#   .claude/agent/run.sh 3      # Run 3 tasks
#   .claude/agent/run.sh 1      # Run 1 task
#
# Or via the bin/agent wrapper:
#   ./bin/agent 5
#
# For installation in new projects, see: .claude/agent/install.sh
#
set -euo pipefail

# ============================================================================
# Path Setup
# ============================================================================

# Get the directory where this script lives
AGENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Find the project root (parent of .claude)
# Walk up until we find a directory that contains .claude
find_project_root() {
  local dir="$AGENT_DIR"
  while [ "$dir" != "/" ]; do
    # Check if parent contains .claude
    local parent="$(dirname "$dir")"
    if [ "$(basename "$dir")" = "agent" ] && [ "$(basename "$parent")" = ".claude" ]; then
      # We're in .claude/agent, so project root is parent of .claude
      echo "$(dirname "$parent")"
      return 0
    fi
    dir="$parent"
  done
  # Fallback: assume we're two levels deep from project root
  echo "$(cd "$AGENT_DIR/../.." && pwd)"
}

PROJECT_DIR="$(find_project_root)"

# Export paths for core.sh
export AGENT_DIR
export PROJECT_DIR

# ============================================================================
# Load Project Config (if exists)
# ============================================================================

CONFIG_FILE="$PROJECT_DIR/.claude/config.sh"
if [ -f "$CONFIG_FILE" ]; then
  # shellcheck source=/dev/null
  source "$CONFIG_FILE"
fi

# ============================================================================
# Run Core Agent
# ============================================================================

exec "$AGENT_DIR/lib/core.sh" "$@"
