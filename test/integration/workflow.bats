#!/usr/bin/env bats
#
# Integration tests for the full doyaken workflow
#

load "../test_helper"

setup() {
  export TEST_TEMP_DIR
  TEST_TEMP_DIR="$(mktemp -d)"
  export DOYAKEN_HOME="$PROJECT_ROOT"
  # Clear any inherited project context to ensure proper detection
  unset DOYAKEN_PROJECT
  unset DOYAKEN_DIR
}

teardown() {
  if [[ -d "${TEST_TEMP_DIR:-}" ]]; then
    rm -rf "$TEST_TEMP_DIR"
  fi
}

# ============================================================================
# Init workflow
# ============================================================================

@test "workflow: init creates project structure" {
  cd "$TEST_TEMP_DIR"

  run "$PROJECT_ROOT/bin/doyaken" init
  [ "$status" -eq 0 ]
  [ -d ".doyaken" ]
  [ -d ".doyaken/tasks/2.todo" ]
  [ -f ".doyaken/manifest.yaml" ]
}

@test "workflow: init creates agent files" {
  cd "$TEST_TEMP_DIR"

  "$PROJECT_ROOT/bin/doyaken" init
  [ -f "AGENTS.md" ]
  [ -f "CLAUDE.md" ]
}

# ============================================================================
# Task workflow
# ============================================================================

@test "workflow: create task" {
  cd "$TEST_TEMP_DIR"
  "$PROJECT_ROOT/bin/doyaken" init

  run "$PROJECT_ROOT/bin/doyaken" tasks new "Test task"
  [ "$status" -eq 0 ]

  # Verify task was created
  [ "$(find .doyaken/tasks/2.todo -name '*.md' | wc -l | tr -d ' ')" -gt 0 ]
}

@test "workflow: list tasks" {
  cd "$TEST_TEMP_DIR"
  "$PROJECT_ROOT/bin/doyaken" init
  "$PROJECT_ROOT/bin/doyaken" tasks new "Test task"

  run "$PROJECT_ROOT/bin/doyaken" tasks
  [ "$status" -eq 0 ]
  [[ "$output" == *"Test task"* ]] || [[ "$output" == *"test-task"* ]]
}

# ============================================================================
# Status workflow
# ============================================================================

@test "workflow: status shows project info" {
  cd "$TEST_TEMP_DIR"
  "$PROJECT_ROOT/bin/doyaken" init

  run "$PROJECT_ROOT/bin/doyaken" status
  [ "$status" -eq 0 ]
  [[ "$output" == *"Project"* ]]
}

# ============================================================================
# Doctor workflow
# ============================================================================

@test "workflow: doctor runs and shows health check" {
  cd "$TEST_TEMP_DIR"
  "$PROJECT_ROOT/bin/doyaken" init

  run "$PROJECT_ROOT/bin/doyaken" doctor
  # May exit non-zero if yq is missing, but should still show output
  [[ "$output" == *"Health Check"* ]]
}

# ============================================================================
# Version workflow
# ============================================================================

@test "workflow: version shows version" {
  run "$PROJECT_ROOT/bin/doyaken" version
  [ "$status" -eq 0 ]
  # Output is "doyaken version X.Y.Z"
  [[ "$output" == *"version"* ]]
  [[ "$output" =~ [0-9]+\.[0-9]+\.[0-9]+ ]]
}

# ============================================================================
# Help workflow
# ============================================================================

@test "workflow: help shows usage" {
  run "$PROJECT_ROOT/bin/doyaken" help
  [ "$status" -eq 0 ]
  [[ "$output" == *"doyaken"* ]] || [[ "$output" == *"Usage"* ]]
}

# ============================================================================
# Task State Transitions (using core functions)
# ============================================================================

# Setup for core function integration tests
_setup_integration_test() {
  cd "$TEST_TEMP_DIR"
  "$PROJECT_ROOT/bin/doyaken" init
  source "$PROJECT_ROOT/test/unit/core_functions.sh"

  export DOYAKEN_PROJECT="$TEST_TEMP_DIR"
  export DATA_DIR="$TEST_TEMP_DIR/.doyaken"
  export TASKS_DIR="$DATA_DIR/tasks"
  export LOCKS_DIR="$DATA_DIR/locks"
  export STATE_DIR="$DATA_DIR/state"
  export AGENT_ID="integration-test"
  export AGENT_LOCK_TIMEOUT=10800

  HELD_LOCKS=()
}

@test "transition: task moves from todo to doing on pickup" {
  _setup_integration_test

  # Create a task in todo
  create_test_task "003-001-test-transition" "todo"

  # Count initial state
  [ "$(count_tasks todo)" -eq 1 ]
  [ "$(count_tasks doing)" -eq 0 ]

  # Simulate pickup: acquire lock and move
  local task_file="$TASKS_DIR/2.todo/003-001-test-transition.md"
  acquire_lock "003-001-test-transition"
  mv "$task_file" "$TASKS_DIR/3.doing/"

  # Verify transition
  [ "$(count_tasks todo)" -eq 0 ]
  [ "$(count_tasks doing)" -eq 1 ]
  [ -f "$LOCKS_DIR/003-001-test-transition.lock" ]
}

@test "transition: task moves from doing to done on completion" {
  _setup_integration_test

  # Create a task in doing with lock
  create_test_task "003-002-complete" "doing"
  acquire_lock "003-002-complete"

  [ "$(count_tasks doing)" -eq 1 ]
  [ "$(count_tasks done)" -eq 0 ]

  # Simulate completion: move and release lock
  mv "$TASKS_DIR/3.doing/003-002-complete.md" "$TASKS_DIR/4.done/"
  release_lock "003-002-complete"

  # Verify transition
  [ "$(count_tasks doing)" -eq 0 ]
  [ "$(count_tasks done)" -eq 1 ]
  [ ! -f "$LOCKS_DIR/003-002-complete.lock" ]
}

@test "transition: orphan task can be moved back to todo" {
  _setup_integration_test

  # Create orphan task in doing (no lock)
  create_test_task "003-003-orphan" "doing"

  [ "$(count_tasks doing)" -eq 1 ]
  [ "$(count_tasks todo)" -eq 0 ]

  # Verify it's detected as orphan
  local orphan_result
  orphan_result=$(find_orphaned_doing_task) || true
  [[ "$orphan_result" == *"orphan"* ]]

  # Move back to todo
  mv "$TASKS_DIR/3.doing/003-003-orphan.md" "$TASKS_DIR/2.todo/"

  # Verify transition
  [ "$(count_tasks doing)" -eq 0 ]
  [ "$(count_tasks todo)" -eq 1 ]
}

# ============================================================================
# Concurrent Agent Simulation
# ============================================================================

@test "concurrent: second agent skips locked task" {
  _setup_integration_test

  # Create task and lock it as first agent
  create_test_task "003-004-locked" "todo"
  AGENT_ID="agent-1"
  acquire_lock "003-004-locked"

  # Switch to second agent
  AGENT_ID="agent-2"
  HELD_LOCKS=()

  # Verify second agent sees task as locked
  run is_task_locked "003-004-locked"
  [ "$status" -eq 0 ]  # 0 means locked by another agent
}

@test "concurrent: second agent takes different task" {
  _setup_integration_test

  # Create two tasks
  create_test_task "003-005-task1" "todo"
  create_test_task "003-006-task2" "todo"

  # First agent takes task1
  AGENT_ID="agent-1"
  acquire_lock "003-005-task1"

  # Second agent should get task2
  AGENT_ID="agent-2"
  HELD_LOCKS=()

  local next_task
  next_task=$(get_next_available_task)
  [[ "$next_task" == *"003-006-task2"* ]]
}

@test "concurrent: atomic lock prevents race condition" {
  _setup_integration_test

  create_test_task "003-007-race" "todo"

  # Agent 1 acquires lock
  AGENT_ID="agent-1"
  run acquire_lock "003-007-race"
  [ "$status" -eq 0 ]

  # Agent 2 cannot acquire same lock
  AGENT_ID="agent-2"
  HELD_LOCKS=()
  run acquire_lock "003-007-race"
  [ "$status" -eq 1 ]
}

# ============================================================================
# Failure Recovery
# ============================================================================

@test "recovery: stale lock is auto-removed on task selection" {
  _setup_integration_test

  # Create task with stale lock
  create_test_task "003-008-stale" "todo"
  create_stale_lock "003-008-stale" "dead-agent" "99999"

  # Stale lock should exist
  [ -f "$LOCKS_DIR/003-008-stale.lock" ]

  # Verify task is available (is_task_locked removes stale locks)
  run is_task_locked "003-008-stale"
  [ "$status" -eq 1 ]  # Returns 1 = not locked (stale lock was removed)

  # Lock should be removed
  [ ! -f "$LOCKS_DIR/003-008-stale.lock" ]
}

@test "recovery: orphan task detected in doing folder" {
  _setup_integration_test

  # Create orphan in doing (no lock)
  create_test_task "003-009-orphan-detect" "doing"

  # Verify orphan detection
  run find_orphaned_doing_task
  [ "$status" -eq 0 ]
  [[ "$output" == *"003-009-orphan-detect"* ]]
  [[ "$output" == *"nolock"* ]]
}

@test "recovery: orphan with stale lock detected" {
  _setup_integration_test

  # Create orphan with stale lock
  create_test_task "003-010-stale-orphan" "doing"
  create_stale_lock "003-010-stale-orphan" "dead-agent" "99999"

  run find_orphaned_doing_task
  [ "$status" -eq 0 ]
  [[ "$output" == *"003-010-stale-orphan"* ]]
  [[ "$output" == *"stale:"* ]]
}

# ============================================================================
# Error Scenarios
# ============================================================================

@test "error: handles empty todo queue gracefully" {
  _setup_integration_test

  # No tasks created - todo is empty
  run get_next_available_task
  [ "$status" -eq 1 ]
}

@test "error: handles all tasks locked" {
  _setup_integration_test

  # Create task and lock it
  create_test_task "003-011-all-locked" "todo"
  AGENT_ID="other-agent"
  acquire_lock "003-011-all-locked"

  # Switch agent and try to find task
  AGENT_ID="test-agent"
  HELD_LOCKS=()

  run get_next_available_task
  [ "$status" -eq 1 ]  # No available tasks
}

@test "error: handles malformed lock file gracefully" {
  _setup_integration_test

  create_test_task "003-012-malformed" "todo"

  # Create malformed lock file (missing fields)
  mkdir -p "$LOCKS_DIR"
  echo "INVALID_DATA" > "$LOCKS_DIR/003-012-malformed.lock"

  # Should handle gracefully - treat as stale
  run is_task_locked "003-012-malformed"
  # Should either work or gracefully fail
  [ "$status" -eq 0 ] || [ "$status" -eq 1 ]
}

@test "error: model fallback triggers on rate limit detection" {
  _setup_integration_test

  CURRENT_AGENT="claude"
  CURRENT_MODEL="opus"
  AGENT_NO_FALLBACK="0"

  # Fallback should work
  fallback_to_sonnet
  [ "$CURRENT_MODEL" = "sonnet" ]
  [ "$MODEL_FALLBACK_TRIGGERED" = "1" ]

  # Should fail on second fallback (already on sonnet)
  run fallback_to_sonnet
  [ "$status" -eq 1 ]
}
