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
