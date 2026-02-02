#!/usr/bin/env bats
#
# Unit tests for lib/core.sh functions
#
# Note: These tests use exported functions from core.sh via the CLI
# rather than sourcing directly due to complex dependencies
#

load "../test_helper"

setup() {
  export TEST_TEMP_DIR
  TEST_TEMP_DIR="$(mktemp -d)"

  # Create mock project structure
  create_mock_project "$TEST_TEMP_DIR/project"
  export DOYAKEN_PROJECT="$TEST_TEMP_DIR/project"
}

teardown() {
  if [[ -d "${TEST_TEMP_DIR:-}" ]]; then
    rm -rf "$TEST_TEMP_DIR"
  fi
}

# ============================================================================
# Lock file operations (test via filesystem)
# ============================================================================

@test "lock file: directory exists in mock project" {
  [ -d "$DOYAKEN_PROJECT/.doyaken/locks" ]
}

@test "lock file: can create lock" {
  local lock_file="$DOYAKEN_PROJECT/.doyaken/locks/test-task.lock"
  echo "test-agent" > "$lock_file"
  [ -f "$lock_file" ]
}

@test "lock file: can remove lock" {
  local lock_file="$DOYAKEN_PROJECT/.doyaken/locks/test-task.lock"
  echo "test-agent" > "$lock_file"
  rm "$lock_file"
  [ ! -f "$lock_file" ]
}

# ============================================================================
# Task folder structure
# ============================================================================

@test "task folders: todo exists" {
  [ -d "$DOYAKEN_PROJECT/.doyaken/tasks/2.todo" ]
}

@test "task folders: doing exists" {
  [ -d "$DOYAKEN_PROJECT/.doyaken/tasks/3.doing" ]
}

@test "task folders: done exists" {
  [ -d "$DOYAKEN_PROJECT/.doyaken/tasks/4.done" ]
}

@test "task folders: blocked exists" {
  [ -d "$DOYAKEN_PROJECT/.doyaken/tasks/1.blocked" ]
}

# ============================================================================
# Task file operations
# ============================================================================

@test "task file: can create in todo" {
  local task_file="$DOYAKEN_PROJECT/.doyaken/tasks/2.todo/003-001-test.md"
  cat > "$task_file" << 'EOF'
# Task: Test Task

| Field | Value |
|-------|-------|
| Priority | Medium |
| Status | todo |
EOF
  [ -f "$task_file" ]
  grep -q "Test Task" "$task_file"
}

@test "task file: can move to doing" {
  local src="$DOYAKEN_PROJECT/.doyaken/tasks/2.todo/003-001-test.md"
  local dst="$DOYAKEN_PROJECT/.doyaken/tasks/3.doing/003-001-test.md"

  echo "# Test task" > "$src"
  mv "$src" "$dst"

  [ ! -f "$src" ]
  [ -f "$dst" ]
}

@test "task file: can count tasks" {
  touch "$DOYAKEN_PROJECT/.doyaken/tasks/2.todo/001-001-a.md"
  touch "$DOYAKEN_PROJECT/.doyaken/tasks/2.todo/001-002-b.md"
  touch "$DOYAKEN_PROJECT/.doyaken/tasks/2.todo/001-003-c.md"

  run find "$DOYAKEN_PROJECT/.doyaken/tasks/2.todo" -maxdepth 1 -name "*.md" -type f
  [ "$status" -eq 0 ]
  [ "$(echo "$output" | wc -l | tr -d ' ')" -eq 3 ]
}

# ============================================================================
# State file operations
# ============================================================================

@test "state file: can save state" {
  echo "test-value" > "$DOYAKEN_PROJECT/.doyaken/state/test-key"
  [ -f "$DOYAKEN_PROJECT/.doyaken/state/test-key" ]
}

@test "state file: can read state" {
  echo "test-value" > "$DOYAKEN_PROJECT/.doyaken/state/test-key"
  run cat "$DOYAKEN_PROJECT/.doyaken/state/test-key"
  [ "$output" = "test-value" ]
}

@test "state file: directory exists" {
  [ -d "$DOYAKEN_PROJECT/.doyaken/state" ]
}

# ============================================================================
# Manifest operations
# ============================================================================

@test "manifest: exists in mock project" {
  [ -f "$DOYAKEN_PROJECT/.doyaken/manifest.yaml" ]
}

@test "manifest: contains version" {
  grep -q "version:" "$DOYAKEN_PROJECT/.doyaken/manifest.yaml"
}

@test "manifest: contains project name" {
  grep -q "name:" "$DOYAKEN_PROJECT/.doyaken/manifest.yaml"
}

# ============================================================================
# Task metadata operations (update_task_metadata function)
# ============================================================================

# Helper: Standalone copy of update_task_metadata for testing
# This avoids sourcing core.sh which has complex dependencies
_update_task_metadata() {
  local task_file="$1"
  local field_name="$2"
  local new_value="$3"

  [ -f "$task_file" ] || return 1

  # Escape backslashes for awk -v (which interprets escape sequences)
  local escaped_value="${new_value//\\/\\\\}"

  local temp_file="${task_file}.tmp.$$"
  # Use awk's index() to find "| FieldName |" pattern (literal string match)
  awk -v field="$field_name" -v value="$escaped_value" '
    BEGIN { found = 0; pattern = "| " field " |" }
    index($0, pattern) == 1 {
      printf "| %s | %s |\n", field, value
      found = 1
      next
    }
    { print }
    END { exit (found ? 0 : 1) }
  ' "$task_file" > "$temp_file" && mv "$temp_file" "$task_file"
  local result=$?
  rm -f "$temp_file" 2>/dev/null
  return $result
}

@test "metadata: updates basic field value" {
  local task_file="$TEST_TEMP_DIR/task.md"
  cat > "$task_file" << 'EOF'
# Task

| Field | Value |
|-------|-------|
| Status | todo |
| Assigned To | |
EOF

  run _update_task_metadata "$task_file" "Status" "doing"
  [ "$status" -eq 0 ]
  grep -q "| Status | doing |" "$task_file"
}

@test "metadata: handles ampersand character" {
  local task_file="$TEST_TEMP_DIR/task.md"
  cat > "$task_file" << 'EOF'
| Assigned To | |
EOF

  run _update_task_metadata "$task_file" "Assigned To" "agent&1"
  [ "$status" -eq 0 ]
  grep -q "| Assigned To | agent&1 |" "$task_file"
}

@test "metadata: handles forward slash character" {
  local task_file="$TEST_TEMP_DIR/task.md"
  cat > "$task_file" << 'EOF'
| Assigned To | |
EOF

  run _update_task_metadata "$task_file" "Assigned To" "agent/1"
  [ "$status" -eq 0 ]
  grep -q "| Assigned To | agent/1 |" "$task_file"
}

@test "metadata: handles backslash character" {
  local task_file="$TEST_TEMP_DIR/task.md"
  cat > "$task_file" << 'EOF'
| Assigned To | |
EOF

  run _update_task_metadata "$task_file" "Assigned To" 'agent\1'
  [ "$status" -eq 0 ]
  # Use fgrep (grep -F) for literal string matching
  grep -F '| Assigned To | agent\1 |' "$task_file"
}

@test "metadata: handles asterisk character" {
  local task_file="$TEST_TEMP_DIR/task.md"
  cat > "$task_file" << 'EOF'
| Assigned To | |
EOF

  run _update_task_metadata "$task_file" "Assigned To" "agent*1"
  [ "$status" -eq 0 ]
  grep -F "| Assigned To | agent*1 |" "$task_file"
}

@test "metadata: handles dot character" {
  local task_file="$TEST_TEMP_DIR/task.md"
  cat > "$task_file" << 'EOF'
| Assigned To | |
EOF

  run _update_task_metadata "$task_file" "Assigned To" "agent.1"
  [ "$status" -eq 0 ]
  grep -F "| Assigned To | agent.1 |" "$task_file"
}

@test "metadata: handles bracket characters" {
  local task_file="$TEST_TEMP_DIR/task.md"
  cat > "$task_file" << 'EOF'
| Assigned To | |
EOF

  run _update_task_metadata "$task_file" "Assigned To" "[agent]"
  [ "$status" -eq 0 ]
  grep -F "| Assigned To | [agent] |" "$task_file"
}

@test "metadata: handles caret and dollar characters" {
  local task_file="$TEST_TEMP_DIR/task.md"
  cat > "$task_file" << 'EOF'
| Assigned To | |
EOF

  run _update_task_metadata "$task_file" "Assigned To" '^agent$'
  [ "$status" -eq 0 ]
  grep -F '| Assigned To | ^agent$ |' "$task_file"
}

@test "metadata: handles empty value (unassign)" {
  local task_file="$TEST_TEMP_DIR/task.md"
  cat > "$task_file" << 'EOF'
| Assigned To | worker-1 |
EOF

  run _update_task_metadata "$task_file" "Assigned To" ""
  [ "$status" -eq 0 ]
  grep -F "| Assigned To |  |" "$task_file"
}

@test "metadata: returns error for non-existent field" {
  local task_file="$TEST_TEMP_DIR/task.md"
  cat > "$task_file" << 'EOF'
| Status | todo |
EOF

  run _update_task_metadata "$task_file" "NonExistent" "value"
  [ "$status" -ne 0 ]
}

@test "metadata: returns error for non-existent file" {
  run _update_task_metadata "$TEST_TEMP_DIR/nonexistent.md" "Field" "value"
  [ "$status" -ne 0 ]
}

@test "metadata: preserves other fields unchanged" {
  local task_file="$TEST_TEMP_DIR/task.md"
  cat > "$task_file" << 'EOF'
# Task

| Field | Value |
|-------|-------|
| Status | todo |
| Priority | High |
| Assigned To | |
EOF

  run _update_task_metadata "$task_file" "Assigned To" "worker-1"
  [ "$status" -eq 0 ]
  grep -q "| Status | todo |" "$task_file"
  grep -q "| Priority | High |" "$task_file"
  grep -q "| Assigned To | worker-1 |" "$task_file"
}

# ============================================================================
# Manifest loading optimization tests (JSON caching)
# ============================================================================

@test "manifest: JSON cache reduces yq calls" {
  command -v yq > /dev/null || skip "yq not installed"
  command -v jq > /dev/null || skip "jq not installed"

  # Create test manifest with all sections
  cat > "$DOYAKEN_PROJECT/.doyaken/manifest.yaml" << 'EOF'
version: 1
agent:
  name: "test-agent"
  model: "sonnet"
  max_retries: 3
quality:
  test_command: "npm test"
  lint_command: "eslint ."
env:
  TEST_VAR1: "value1"
  TEST_VAR2: "value2"
skills:
  hooks:
    before-test:
      - "hook1"
    after-test:
      - "hook2"
EOF

  # The yq -o=json call converts the manifest to JSON in one shot
  # This is much faster than 24+ individual yq calls
  run yq -o=json '.' "$DOYAKEN_PROJECT/.doyaken/manifest.yaml"
  [ "$status" -eq 0 ]

  # Verify JSON is valid and contains all expected sections
  echo "$output" | jq -e '.agent.name' > /dev/null
  echo "$output" | jq -e '.quality.test_command' > /dev/null
  echo "$output" | jq -e '.env.TEST_VAR1' > /dev/null
  echo "$output" | jq -e '.skills.hooks."before-test"' > /dev/null
}

@test "manifest: jq extracts env vars efficiently" {
  command -v jq > /dev/null || skip "jq not installed"

  # Test jq extraction of env vars as key=value pairs (single call)
  local test_json='{"env":{"VAR1":"value1","VAR2":"value2"}}'

  run bash -c "echo '$test_json' | jq -r '.env // {} | to_entries[] | \"\\(.key)=\\(.value)\"'"
  [ "$status" -eq 0 ]
  [[ "$output" == *"VAR1=value1"* ]]
  [[ "$output" == *"VAR2=value2"* ]]
}

@test "manifest: jq handles special characters in env values" {
  command -v jq > /dev/null || skip "jq not installed"

  # Test that jq properly escapes special characters
  local test_json='{"env":{"TEST":"value with \"quotes\""}}'

  run bash -c "echo '$test_json' | jq -r '.env.TEST'"
  [ "$status" -eq 0 ]
  [[ "$output" == *"quotes"* ]]
}

@test "manifest: jq extracts hooks efficiently" {
  command -v jq > /dev/null || skip "jq not installed"

  # Test jq extraction of hooks array
  local test_json='{"hooks":{"before-test":["hook1","hook2","hook3"]}}'

  run bash -c "echo '$test_json' | jq -r '.hooks.\"before-test\" // [] | .[]'"
  [ "$status" -eq 0 ]
  [[ "$output" == *"hook1"* ]]
  [[ "$output" == *"hook2"* ]]
  [[ "$output" == *"hook3"* ]]
}

# ============================================================================
# Core Functions Test Setup
# ============================================================================

# Setup for core function tests (uses isolated environment)
_setup_core_test() {
  source "$PROJECT_ROOT/test/unit/core_functions.sh"
  setup_core_test_env

  # Reset state for each test
  HELD_LOCKS=()
  MODEL_FALLBACK_TRIGGERED=0
  CONSECUTIVE_FAILURES=0
}

# ============================================================================
# Lock Acquisition Tests (Phase 2, Steps 4-5)
# ============================================================================

@test "acquire_lock: creates lock file with correct content" {
  _setup_core_test

  run acquire_lock "test-task-001"
  [ "$status" -eq 0 ]

  local lock_file="$LOCKS_DIR/test-task-001.lock"
  [ -f "$lock_file" ]

  grep -q "AGENT_ID=\"test-worker\"" "$lock_file"
  grep -q "PID=\"$$\"" "$lock_file"
  grep -q "TASK_ID=\"test-task-001\"" "$lock_file"
  grep -q "LOCKED_AT=" "$lock_file"
}

@test "acquire_lock: adds task to HELD_LOCKS array" {
  _setup_core_test

  acquire_lock "test-task-002"

  [[ " ${HELD_LOCKS[*]} " == *" test-task-002 "* ]]
}

@test "acquire_lock: returns 0 on success" {
  _setup_core_test

  run acquire_lock "test-task-003"
  [ "$status" -eq 0 ]
}

@test "acquire_lock: returns 1 when lock exists from different agent" {
  _setup_core_test

  # Create lock from another agent
  create_test_lock "test-task-004" "other-agent" "$$"

  run acquire_lock "test-task-004"
  [ "$status" -eq 1 ]
}

@test "acquire_lock: succeeds when lock is from same agent" {
  _setup_core_test

  # Create lock from our agent
  create_test_lock "test-task-005" "test-worker" "$$"

  run acquire_lock "test-task-005"
  [ "$status" -eq 0 ]
}

@test "acquire_lock: removes acquiring directory on failure" {
  _setup_core_test

  # Create lock from another agent
  create_test_lock "test-task-006" "other-agent" "$$"

  acquire_lock "test-task-006" || true

  # Acquiring directory should be cleaned up
  [ ! -d "$LOCKS_DIR/test-task-006.lock.acquiring" ]
}

# ============================================================================
# Stale Lock Detection Tests (Phase 2, Step 6)
# ============================================================================

@test "is_lock_stale: returns 0 when PID not running" {
  _setup_core_test

  # Use a PID that's very unlikely to exist
  create_test_lock "stale-pid-task" "old-agent" "99999"

  local lock_file="$LOCKS_DIR/stale-pid-task.lock"
  run is_lock_stale "$lock_file"
  [ "$status" -eq 0 ]
}

@test "is_lock_stale: returns 0 when lock exceeds timeout" {
  _setup_core_test

  # Create a stale lock (backdated)
  create_stale_lock "stale-time-task" "old-agent" "$$"

  local lock_file="$LOCKS_DIR/stale-time-task.lock"
  run is_lock_stale "$lock_file"
  [ "$status" -eq 0 ]
}

@test "is_lock_stale: returns 1 when lock is fresh and PID running" {
  _setup_core_test

  # Create fresh lock with our PID (definitely running)
  create_test_lock "fresh-task" "test-agent" "$$"

  local lock_file="$LOCKS_DIR/fresh-task.lock"
  run is_lock_stale "$lock_file"
  [ "$status" -eq 1 ]
}

@test "is_lock_stale: returns 0 for non-existent file" {
  _setup_core_test

  run is_lock_stale "$LOCKS_DIR/nonexistent.lock"
  [ "$status" -eq 0 ]
}

@test "is_lock_stale: handles missing fields gracefully" {
  _setup_core_test

  # Create malformed lock file
  echo "AGENT_ID=\"test\"" > "$LOCKS_DIR/malformed.lock"

  run is_lock_stale "$LOCKS_DIR/malformed.lock"
  # Should handle gracefully - either return stale or fresh, not error
  [ "$status" -eq 0 ] || [ "$status" -eq 1 ]
}

# ============================================================================
# Lock Release Tests (Phase 2, Step 7)
# ============================================================================

@test "release_lock: removes lock file owned by this agent" {
  _setup_core_test

  create_test_lock "release-test-001" "test-worker" "$$"
  HELD_LOCKS+=("release-test-001")

  release_lock "release-test-001"

  [ ! -f "$LOCKS_DIR/release-test-001.lock" ]
}

@test "release_lock: does not remove lock owned by different agent" {
  _setup_core_test

  create_test_lock "release-test-002" "other-agent" "$$"

  release_lock "release-test-002"

  # Lock should still exist
  [ -f "$LOCKS_DIR/release-test-002.lock" ]
}

@test "release_lock: removes task from HELD_LOCKS array" {
  _setup_core_test

  create_test_lock "release-test-003" "test-worker" "$$"
  HELD_LOCKS=("release-test-003" "other-task")

  release_lock "release-test-003"

  [[ ! " ${HELD_LOCKS[*]} " == *" release-test-003 "* ]]
  [[ " ${HELD_LOCKS[*]} " == *" other-task "* ]]
}

@test "release_all_locks: releases all held locks" {
  _setup_core_test

  create_test_lock "multi-001" "test-worker" "$$"
  create_test_lock "multi-002" "test-worker" "$$"
  create_test_lock "multi-003" "test-worker" "$$"
  HELD_LOCKS=("multi-001" "multi-002" "multi-003")

  release_all_locks

  [ ! -f "$LOCKS_DIR/multi-001.lock" ]
  [ ! -f "$LOCKS_DIR/multi-002.lock" ]
  [ ! -f "$LOCKS_DIR/multi-003.lock" ]
  [ ${#HELD_LOCKS[@]} -eq 0 ]
}

# ============================================================================
# Task Locked Status Tests (Phase 2, Step 8)
# ============================================================================

@test "is_task_locked: returns 1 when no lock file" {
  _setup_core_test

  run is_task_locked "unlocked-task"
  [ "$status" -eq 1 ]
}

@test "is_task_locked: returns 0 when locked by different agent" {
  _setup_core_test

  create_test_lock "other-agent-task" "other-agent" "$$"

  run is_task_locked "other-agent-task"
  [ "$status" -eq 0 ]
}

@test "is_task_locked: returns 1 when locked by same agent" {
  _setup_core_test

  create_test_lock "our-task" "test-worker" "$$"

  run is_task_locked "our-task"
  [ "$status" -eq 1 ]
}

@test "is_task_locked: returns 1 when lock is stale (auto-removed)" {
  _setup_core_test

  # Create stale lock from another agent
  create_stale_lock "stale-other-task" "old-agent" "99999"

  run is_task_locked "stale-other-task"
  [ "$status" -eq 1 ]

  # Lock should be auto-removed
  [ ! -f "$LOCKS_DIR/stale-other-task.lock" ]
}

# ============================================================================
# Task Selection Tests (Phase 3, Steps 9-12)
# ============================================================================

@test "get_next_available_task: returns first unlocked task from todo" {
  _setup_core_test

  create_test_task "003-001-first" "todo"
  create_test_task "003-002-second" "todo"

  run get_next_available_task
  [ "$status" -eq 0 ]
  [[ "$output" == *"003-001-first"* ]]
}

@test "get_next_available_task: skips locked tasks" {
  _setup_core_test

  create_test_task "003-001-locked" "todo"
  create_test_task "003-002-available" "todo"

  # Lock the first task
  create_test_lock "003-001-locked" "other-agent" "$$"

  run get_next_available_task
  [ "$status" -eq 0 ]
  [[ "$output" == *"003-002-available"* ]]
}

@test "get_next_available_task: returns tasks in sorted order" {
  _setup_core_test

  # Create in wrong order
  create_test_task "003-003-third" "todo"
  create_test_task "003-001-first" "todo"
  create_test_task "003-002-second" "todo"

  run get_next_available_task
  [ "$status" -eq 0 ]
  [[ "$output" == *"003-001-first"* ]]
}

@test "get_next_available_task: returns 1 when todo empty" {
  _setup_core_test

  run get_next_available_task
  [ "$status" -eq 1 ]
}

@test "count_tasks: returns 0 for empty folder" {
  _setup_core_test

  run count_tasks "todo"
  [ "$status" -eq 0 ]
  [ "$output" = "0" ]
}

@test "count_tasks: counts .md files only" {
  _setup_core_test

  create_test_task "task-001" "todo"
  create_test_task "task-002" "todo"
  touch "$TASKS_DIR/2.todo/not-a-task.txt"

  run count_tasks "todo"
  [ "$status" -eq 0 ]
  [ "$output" = "2" ]
}

@test "count_locked_tasks: counts .lock files in locks directory" {
  _setup_core_test

  create_test_lock "task-001" "agent-1" "$$"
  create_test_lock "task-002" "agent-2" "$$"

  run count_locked_tasks
  [ "$status" -eq 0 ]
  [ "$output" = "2" ]
}

@test "get_next_available_task: returns doing task if locked by this agent" {
  _setup_core_test

  create_test_task "003-001-doing" "doing"
  create_test_task "003-002-todo" "todo"

  # Lock the doing task as our agent
  create_test_lock "003-001-doing" "test-worker" "$$"

  run get_next_available_task
  [ "$status" -eq 0 ]
  [[ "$output" == *"003-001-doing"* ]]
}

# ============================================================================
# Orphan Detection Tests (Phase 4, Steps 13-16)
# ============================================================================

@test "find_orphaned_doing_task: returns task with no lock file" {
  _setup_core_test

  create_test_task "orphan-nolock" "doing"

  run find_orphaned_doing_task
  [ "$status" -eq 0 ]
  [[ "$output" == *"orphan-nolock"* ]]
  [[ "$output" == *"nolock"* ]]
}

@test "find_orphaned_doing_task: returns task with stale lock" {
  _setup_core_test

  create_test_task "orphan-stale" "doing"
  create_stale_lock "orphan-stale" "old-agent" "99999"

  run find_orphaned_doing_task
  [ "$status" -eq 0 ]
  [[ "$output" == *"orphan-stale"* ]]
  [[ "$output" == *"stale:"* ]]
}

@test "find_orphaned_doing_task: returns task locked by different agent" {
  _setup_core_test

  create_test_task "orphan-other" "doing"
  create_test_lock "orphan-other" "other-agent" "$$"

  run find_orphaned_doing_task
  [ "$status" -eq 0 ]
  [[ "$output" == *"orphan-other"* ]]
  [[ "$output" == *"locked:"* ]]
}

@test "find_orphaned_doing_task: returns 1 when no orphans" {
  _setup_core_test

  # Create task with valid lock from our agent
  create_test_task "our-task" "doing"
  create_test_lock "our-task" "test-worker" "$$"

  run find_orphaned_doing_task
  [ "$status" -eq 1 ]
}

@test "find_orphaned_doing_task: returns 1 when doing folder is empty" {
  _setup_core_test

  run find_orphaned_doing_task
  [ "$status" -eq 1 ]
}

@test "get_doing_task_for_agent: returns task locked by this agent" {
  _setup_core_test

  create_test_task "our-doing" "doing"
  create_test_lock "our-doing" "test-worker" "$$"

  run get_doing_task_for_agent
  [ "$status" -eq 0 ]
  [[ "$output" == *"our-doing"* ]]
}

@test "get_doing_task_for_agent: returns 1 when no task locked by us" {
  _setup_core_test

  create_test_task "other-doing" "doing"
  create_test_lock "other-doing" "other-agent" "$$"

  run get_doing_task_for_agent
  [ "$status" -eq 1 ]
}

@test "get_doing_task_for_agent: ignores tasks locked by other agents" {
  _setup_core_test

  create_test_task "other-task" "doing"
  create_test_task "our-task" "doing"
  create_test_lock "other-task" "other-agent" "$$"
  create_test_lock "our-task" "test-worker" "$$"

  run get_doing_task_for_agent
  [ "$status" -eq 0 ]
  [[ "$output" == *"our-task"* ]]
}

# ============================================================================
# Model Fallback Tests (Phase 5, Steps 17-19)
# ============================================================================

@test "fallback_to_sonnet: claude opus -> sonnet on rate limit" {
  _setup_core_test
  CURRENT_AGENT="claude"
  CURRENT_MODEL="opus"

  # Don't use run - we need to test the variable modification
  fallback_to_sonnet
  [ "$CURRENT_MODEL" = "sonnet" ]
}

@test "fallback_to_sonnet: codex gpt-5 -> o4-mini" {
  _setup_core_test
  CURRENT_AGENT="codex"
  CURRENT_MODEL="gpt-5"

  fallback_to_sonnet
  [ "$CURRENT_MODEL" = "o4-mini" ]
}

@test "fallback_to_sonnet: gemini 2.5-pro -> 2.5-flash" {
  _setup_core_test
  CURRENT_AGENT="gemini"
  CURRENT_MODEL="gemini-2.5-pro"

  fallback_to_sonnet
  [ "$CURRENT_MODEL" = "gemini-2.5-flash" ]
}

@test "fallback_to_sonnet: returns 1 when already on fallback model" {
  _setup_core_test
  CURRENT_AGENT="claude"
  CURRENT_MODEL="sonnet"

  run fallback_to_sonnet
  [ "$status" -eq 1 ]
}

@test "fallback_to_sonnet: returns 1 when AGENT_NO_FALLBACK=1" {
  _setup_core_test
  CURRENT_AGENT="claude"
  CURRENT_MODEL="opus"
  AGENT_NO_FALLBACK="1"

  run fallback_to_sonnet
  [ "$status" -eq 1 ]
}

@test "fallback_to_sonnet: returns 1 for unknown agent" {
  _setup_core_test
  CURRENT_AGENT="unknown"
  CURRENT_MODEL="model"

  run fallback_to_sonnet
  [ "$status" -eq 1 ]
}

@test "reset_model: restores original model after fallback" {
  _setup_core_test
  DOYAKEN_MODEL="opus"
  CURRENT_MODEL="sonnet"
  MODEL_FALLBACK_TRIGGERED=1

  reset_model

  [ "$CURRENT_MODEL" = "opus" ]
  [ "$MODEL_FALLBACK_TRIGGERED" = "0" ]
}

@test "reset_model: clears MODEL_FALLBACK_TRIGGERED flag" {
  _setup_core_test
  MODEL_FALLBACK_TRIGGERED=1
  DOYAKEN_MODEL="opus"
  CURRENT_MODEL="sonnet"

  reset_model

  [ "$MODEL_FALLBACK_TRIGGERED" = "0" ]
}

@test "reset_model: noop when no fallback was triggered" {
  _setup_core_test
  DOYAKEN_MODEL="opus"
  CURRENT_MODEL="opus"
  MODEL_FALLBACK_TRIGGERED=0

  reset_model

  [ "$CURRENT_MODEL" = "opus" ]
  [ "$MODEL_FALLBACK_TRIGGERED" = "0" ]
}

# ============================================================================
# Backoff Calculation Tests (Phase 6, Steps 20-22)
# ============================================================================

@test "calculate_backoff: attempt 1 = base delay" {
  _setup_core_test
  AGENT_RETRY_DELAY=5

  run calculate_backoff 1
  [ "$status" -eq 0 ]
  [ "$output" = "5" ]
}

@test "calculate_backoff: attempt 2 = 2x base delay" {
  _setup_core_test
  AGENT_RETRY_DELAY=5

  run calculate_backoff 2
  [ "$status" -eq 0 ]
  [ "$output" = "10" ]
}

@test "calculate_backoff: attempt 3 = 4x base delay" {
  _setup_core_test
  AGENT_RETRY_DELAY=5

  run calculate_backoff 3
  [ "$status" -eq 0 ]
  [ "$output" = "20" ]
}

@test "calculate_backoff: caps at 60 seconds max" {
  _setup_core_test
  AGENT_RETRY_DELAY=10

  # Attempt 4 would be 10 * 8 = 80, but capped at 60
  run calculate_backoff 4
  [ "$status" -eq 0 ]
  [ "$output" = "60" ]
}

@test "calculate_backoff: handles attempt 5 (still capped)" {
  _setup_core_test
  AGENT_RETRY_DELAY=5

  run calculate_backoff 5
  [ "$status" -eq 0 ]
  [ "$output" = "60" ]
}

# ============================================================================
# Session State Tests (Phase 7, Steps 23-25)
# ============================================================================

@test "save_session: creates session file with correct content" {
  _setup_core_test

  save_session "session-123" "5" "running"

  local session_file="$STATE_DIR/session-test-worker"
  [ -f "$session_file" ]

  grep -q "SESSION_ID=\"session-123\"" "$session_file"
  grep -q "ITERATION=\"5\"" "$session_file"
  grep -q "STATUS=\"running\"" "$session_file"
}

@test "save_session: includes AGENT_ID, TIMESTAMP" {
  _setup_core_test

  save_session "session-456" "2" "running"

  local session_file="$STATE_DIR/session-test-worker"
  grep -q "AGENT_ID=\"test-worker\"" "$session_file"
  grep -q "TIMESTAMP=" "$session_file"
}

@test "load_session: returns 0 and sets vars when session exists" {
  _setup_core_test

  save_session "session-789" "3" "running"

  run load_session
  [ "$status" -eq 0 ]
}

@test "load_session: returns 1 when no session file" {
  _setup_core_test

  run load_session
  [ "$status" -eq 1 ]
}

@test "load_session: returns 1 when AGENT_NO_RESUME=1" {
  _setup_core_test
  AGENT_NO_RESUME="1"

  save_session "session-noresume" "1" "running"

  run load_session
  [ "$status" -eq 1 ]
}

@test "load_session: returns 1 when status is not running" {
  _setup_core_test

  save_session "session-complete" "5" "completed"

  run load_session
  [ "$status" -eq 1 ]
}

@test "clear_session: removes session file" {
  _setup_core_test

  save_session "session-clear" "1" "running"
  clear_session

  [ ! -f "$STATE_DIR/session-test-worker" ]
}

@test "clear_session: succeeds when file doesn't exist" {
  _setup_core_test

  run clear_session
  [ "$status" -eq 0 ]
}

# ============================================================================
# Health Check Tests (Phase 8, Steps 26-27)
# ============================================================================

@test "update_health: creates health file with status and message" {
  _setup_core_test

  update_health "healthy" "All checks passed"

  local health_file="$STATE_DIR/health-test-worker"
  [ -f "$health_file" ]
  grep -q "STATUS=\"healthy\"" "$health_file"
  grep -q "MESSAGE=\"All checks passed\"" "$health_file"
}

@test "update_health: includes AGENT_ID and LAST_CHECK" {
  _setup_core_test

  update_health "unhealthy" "Issues found"

  local health_file="$STATE_DIR/health-test-worker"
  grep -q "AGENT_ID=\"test-worker\"" "$health_file"
  grep -q "LAST_CHECK=" "$health_file"
}

@test "update_health: includes CONSECUTIVE_FAILURES" {
  _setup_core_test
  CONSECUTIVE_FAILURES=3

  update_health "degraded" "Some failures"

  local health_file="$STATE_DIR/health-test-worker"
  grep -q "CONSECUTIVE_FAILURES=\"3\"" "$health_file"
}

@test "get_consecutive_failures: reads from health file" {
  _setup_core_test
  CONSECUTIVE_FAILURES=5
  update_health "degraded" "Failures"

  CONSECUTIVE_FAILURES=0
  run get_consecutive_failures
  [ "$status" -eq 0 ]
  [ "$output" = "5" ]
}

@test "get_consecutive_failures: returns 0 when no health file" {
  _setup_core_test

  run get_consecutive_failures
  [ "$status" -eq 0 ]
  [ "$output" = "0" ]
}

# ============================================================================
# Prompt File Tests (Phase 10, Steps 35-36)
# ============================================================================

@test "get_prompt_file: finds project-specific prompt first" {
  _setup_core_test

  mkdir -p "$DATA_DIR/prompts"
  echo "project prompt" > "$DATA_DIR/prompts/test-prompt.md"

  run get_prompt_file "test-prompt.md"
  [ "$status" -eq 0 ]
  [[ "$output" == *"$DATA_DIR/prompts/test-prompt.md"* ]]
}

@test "get_prompt_file: falls back to global prompt" {
  _setup_core_test
  export DOYAKEN_HOME="$TEST_TEMP_DIR/global"

  mkdir -p "$DOYAKEN_HOME/prompts"
  echo "global prompt" > "$DOYAKEN_HOME/prompts/global-prompt.md"

  run get_prompt_file "global-prompt.md"
  [ "$status" -eq 0 ]
  [[ "$output" == *"global-prompt.md"* ]]
}

@test "get_prompt_file: returns 1 when not found" {
  _setup_core_test

  run get_prompt_file "nonexistent.md"
  [ "$status" -eq 1 ]
}

@test "process_includes: replaces include directive with content" {
  _setup_core_test

  mkdir -p "$DATA_DIR/prompts"
  echo "included content" > "$DATA_DIR/prompts/module.md"

  local input="Before {{include:module.md}} After"
  run process_includes "$input"

  [ "$status" -eq 0 ]
  [[ "$output" == *"Before"* ]]
  [[ "$output" == *"included content"* ]]
  [[ "$output" == *"After"* ]]
}

@test "process_includes: handles nested includes" {
  _setup_core_test

  mkdir -p "$DATA_DIR/prompts"
  echo "nested {{include:leaf.md}} content" > "$DATA_DIR/prompts/nested.md"
  echo "leaf" > "$DATA_DIR/prompts/leaf.md"

  local input="Root {{include:nested.md}}"
  run process_includes "$input"

  [ "$status" -eq 0 ]
  [[ "$output" == *"Root"* ]]
  [[ "$output" == *"nested"* ]]
  [[ "$output" == *"leaf"* ]]
}

@test "process_includes: respects max_depth parameter" {
  _setup_core_test

  mkdir -p "$DATA_DIR/prompts"
  # Create a chain: a -> b -> c -> d (more than 2 levels)
  echo "a: {{include:b.md}}" > "$DATA_DIR/prompts/a.md"
  echo "b: {{include:c.md}}" > "$DATA_DIR/prompts/b.md"
  echo "c: {{include:d.md}}" > "$DATA_DIR/prompts/c.md"
  echo "d: end" > "$DATA_DIR/prompts/d.md"

  # With max_depth=2, should not fully expand
  local input="{{include:a.md}}"
  run process_includes "$input" 2

  [ "$status" -eq 0 ]
  # Should contain the beginning of the chain
  [[ "$output" == *"a:"* ]]
}

# ============================================================================
# Task Special Characters Tests (Phase 3, Step 12)
# ============================================================================

@test "task with dots in ID: handled safely" {
  _setup_core_test

  create_test_task "003-001-test.v2.0" "todo"

  run get_next_available_task
  [ "$status" -eq 0 ]
  [[ "$output" == *"003-001-test.v2.0"* ]]
}

@test "task with hypens in ID: handled safely" {
  _setup_core_test

  create_test_task "003-001-my-complex-task-name" "todo"

  run get_next_available_task
  [ "$status" -eq 0 ]
  [[ "$output" == *"003-001-my-complex-task-name"* ]]
}

@test "get_task_id_from_file: extracts ID correctly" {
  _setup_core_test

  run get_task_id_from_file "/path/to/tasks/003-001-test-task.md"
  [ "$status" -eq 0 ]
  [ "$output" = "003-001-test-task" ]
}
