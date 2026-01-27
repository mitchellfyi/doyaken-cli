#!/usr/bin/env bash
#
# task-context.sh - SessionStart hook to inject task context
#
# This hook checks for active tasks in .doyaken/tasks/3.doing/ and injects
# context about the current task into the session.
#
# Usage: Configure in .claude/settings.json as a SessionStart hook
#
# Input: JSON via stdin with session info
# Output: JSON with additionalContext about current task
#
set -euo pipefail

# Read JSON input (may be empty for SessionStart)
INPUT=$(cat 2>/dev/null || echo "{}")

# Determine project root
PROJECT_ROOT="${CLAUDE_PROJECT_DIR:-$(pwd)}"
DOYAKEN_DIR="$PROJECT_ROOT/.doyaken"

# Check if this is a doyaken project
if [ ! -d "$DOYAKEN_DIR" ]; then
  exit 0
fi

# Find active task in doing folder
DOING_DIR="$DOYAKEN_DIR/tasks/3.doing"
if [ ! -d "$DOING_DIR" ]; then
  DOING_DIR="$DOYAKEN_DIR/tasks/doing"
fi

if [ ! -d "$DOING_DIR" ]; then
  exit 0
fi

# Get first task file in doing
ACTIVE_TASK=$(find "$DOING_DIR" -maxdepth 1 -name "*.md" -type f 2>/dev/null | head -1)

if [ -z "$ACTIVE_TASK" ] || [ ! -f "$ACTIVE_TASK" ]; then
  # No active task, check todo
  TODO_DIR="$DOYAKEN_DIR/tasks/2.todo"
  if [ ! -d "$TODO_DIR" ]; then
    TODO_DIR="$DOYAKEN_DIR/tasks/todo"
  fi

  TODO_COUNT=$(find "$TODO_DIR" -maxdepth 1 -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')

  if [ "$TODO_COUNT" -gt 0 ]; then
    cat << EOF
{
  "hookSpecificOutput": {
    "additionalContext": "DOYAKEN PROJECT: No active task. $TODO_COUNT task(s) in todo. Run 'dk run 1' to start a task, or check TASKBOARD.md for task list."
  }
}
EOF
  fi
  exit 0
fi

# Extract task info
TASK_ID=$(basename "$ACTIVE_TASK" .md)
TASK_TITLE=$(grep -m1 "^# Task:" "$ACTIVE_TASK" 2>/dev/null | sed 's/^# Task: //' || echo "$TASK_ID")

# Get task status from metadata
TASK_STATUS=$(grep -A1 "| Status" "$ACTIVE_TASK" 2>/dev/null | tail -1 | grep -oE '`[^`]+`' | tr -d '`' || echo "doing")

cat << EOF
{
  "hookSpecificOutput": {
    "additionalContext": "ACTIVE TASK: $TASK_TITLE (ID: $TASK_ID, Status: $TASK_STATUS). Task file: $ACTIVE_TASK. Check this file for acceptance criteria and work log. Update the task file as you make progress."
  }
}
EOF

exit 0
