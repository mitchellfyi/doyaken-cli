#!/usr/bin/env bash
#
# test_helper.bash - Common setup for bats tests
#
# This file is sourced by bats tests to provide common utilities

# Get the root directory of the project
export PROJECT_ROOT
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Set DOYAKEN_HOME to project root for testing
export DOYAKEN_HOME="$PROJECT_ROOT"

# Create a temporary directory for each test
setup() {
  export TEST_TEMP_DIR
  TEST_TEMP_DIR="$(mktemp -d)"
}

# Clean up temporary directory after each test
teardown() {
  if [[ -d "${TEST_TEMP_DIR:-}" ]]; then
    rm -rf "$TEST_TEMP_DIR"
  fi
}

# Source a library file
load_lib() {
  local lib_name="$1"
  source "$PROJECT_ROOT/lib/${lib_name}.sh"
}

# Assert that a command succeeds
assert_success() {
  if [[ "$status" -ne 0 ]]; then
    echo "Expected success, got status: $status"
    echo "Output: $output"
    return 1
  fi
}

# Assert that a command fails
assert_failure() {
  if [[ "$status" -eq 0 ]]; then
    echo "Expected failure, got success"
    echo "Output: $output"
    return 1
  fi
}

# Assert output contains a string
assert_output_contains() {
  local expected="$1"
  if [[ "$output" != *"$expected"* ]]; then
    echo "Expected output to contain: $expected"
    echo "Actual output: $output"
    return 1
  fi
}

# Assert output equals a string
assert_output_equals() {
  local expected="$1"
  if [[ "$output" != "$expected" ]]; then
    echo "Expected: $expected"
    echo "Actual: $output"
    return 1
  fi
}

# Create a mock project for testing
create_mock_project() {
  local project_dir="${1:-$TEST_TEMP_DIR/project}"
  mkdir -p "$project_dir/.doyaken/tasks/1.blocked"
  mkdir -p "$project_dir/.doyaken/tasks/2.todo"
  mkdir -p "$project_dir/.doyaken/tasks/3.doing"
  mkdir -p "$project_dir/.doyaken/tasks/4.done"
  mkdir -p "$project_dir/.doyaken/locks"
  mkdir -p "$project_dir/.doyaken/state"

  # Create minimal manifest
  cat > "$project_dir/.doyaken/manifest.yaml" << 'EOF'
version: 1
project:
  name: "test-project"
agent:
  model: "sonnet"
EOF

  echo "$project_dir"
}

# ============================================================================
# Lock Management Helpers
# ============================================================================

# Create a test lock file with specified parameters
# Usage: create_test_lock task_id [agent_id] [pid] [timestamp]
create_test_lock() {
  local task_id="$1"
  local agent_id="${2:-test-agent}"
  local pid="${3:-$$}"
  local timestamp="${4:-$(date '+%Y-%m-%d %H:%M:%S')}"
  local lock_file="$DOYAKEN_PROJECT/.doyaken/locks/${task_id}.lock"

  mkdir -p "$(dirname "$lock_file")"
  cat > "$lock_file" << EOF
AGENT_ID="$agent_id"
LOCKED_AT="$timestamp"
PID="$pid"
TASK_ID="$task_id"
EOF
}

# Create a stale lock (backdated beyond timeout threshold)
# Usage: create_stale_lock task_id [agent_id] [pid]
create_stale_lock() {
  local task_id="$1"
  local agent_id="${2:-old-agent}"
  local pid="${3:-99999}"  # Use a PID that's likely not running
  # Backdate by 4 hours (well beyond 3h default timeout)
  local stale_time
  if date -v-4H &>/dev/null; then
    # macOS
    stale_time=$(date -v-4H '+%Y-%m-%d %H:%M:%S')
  else
    # Linux
    stale_time=$(date -d '4 hours ago' '+%Y-%m-%d %H:%M:%S')
  fi

  create_test_lock "$task_id" "$agent_id" "$pid" "$stale_time"
}

# Create a test task file in a specific folder
# Usage: create_test_task task_id folder [content]
# folder: "todo", "doing", "done", "blocked"
create_test_task() {
  local task_id="$1"
  local folder="$2"
  local content="${3:-# Task: Test task for $task_id}"

  local folder_num
  case "$folder" in
    blocked) folder_num="1.blocked" ;;
    todo)    folder_num="2.todo" ;;
    doing)   folder_num="3.doing" ;;
    done)    folder_num="4.done" ;;
    *)       folder_num="$folder" ;;
  esac

  local task_file="$DOYAKEN_PROJECT/.doyaken/tasks/$folder_num/${task_id}.md"
  mkdir -p "$(dirname "$task_file")"

  cat > "$task_file" << EOF
$content

## Metadata

| Field | Value |
|-------|-------|
| ID | \`$task_id\` |
| Status | \`$folder\` |
| Priority | \`003\` Medium |
| Created | \`$(date '+%Y-%m-%d %H:%M')\` |
| Assigned To | |
| Assigned At | |
EOF

  echo "$task_file"
}

# Wait for a lock file to appear or disappear
# Usage: wait_for_lock task_id [timeout_seconds] [condition]
# condition: "exists" (default) or "gone"
wait_for_lock() {
  local task_id="$1"
  local timeout="${2:-5}"
  local condition="${3:-exists}"
  local lock_file="$DOYAKEN_PROJECT/.doyaken/locks/${task_id}.lock"

  local elapsed=0
  while [ "$elapsed" -lt "$timeout" ]; do
    if [ "$condition" = "exists" ]; then
      [ -f "$lock_file" ] && return 0
    else
      [ ! -f "$lock_file" ] && return 0
    fi
    sleep 0.1
    elapsed=$((elapsed + 1))
  done

  return 1
}

# Track background process PIDs for cleanup
BACKGROUND_PIDS=()

# Start a background process and track its PID
# Usage: track_background command [args...]
track_background() {
  "$@" &
  BACKGROUND_PIDS+=($!)
}

# Cleanup all tracked background processes
cleanup_background_processes() {
  for pid in "${BACKGROUND_PIDS[@]+"${BACKGROUND_PIDS[@]}"}"; do
    if kill -0 "$pid" 2>/dev/null; then
      kill "$pid" 2>/dev/null || true
      wait "$pid" 2>/dev/null || true
    fi
  done
  BACKGROUND_PIDS=()
}

# ============================================================================
# Core Function Sourcing Helpers
# ============================================================================

# Source core functions in isolation for testing
# This creates minimal stubs for dependencies
source_core_functions() {
  local core_functions_file="$PROJECT_ROOT/test/unit/core_functions.sh"
  if [ -f "$core_functions_file" ]; then
    source "$core_functions_file"
  fi
}

# Create mock directories needed for core.sh testing
setup_core_test_env() {
  export DOYAKEN_PROJECT="$TEST_TEMP_DIR/project"
  export DATA_DIR="$DOYAKEN_PROJECT/.doyaken"
  export TASKS_DIR="$DATA_DIR/tasks"
  export LOCKS_DIR="$DATA_DIR/locks"
  export STATE_DIR="$DATA_DIR/state"
  export LOGS_DIR="$DATA_DIR/logs"
  export AGENT_ID="test-worker"
  export AGENT_LOCK_TIMEOUT=10800
  export AGENT_HEARTBEAT=3600

  mkdir -p "$TASKS_DIR/1.blocked"
  mkdir -p "$TASKS_DIR/2.todo"
  mkdir -p "$TASKS_DIR/3.doing"
  mkdir -p "$TASKS_DIR/4.done"
  mkdir -p "$LOCKS_DIR"
  mkdir -p "$STATE_DIR"
  mkdir -p "$LOGS_DIR"
}
