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
  mkdir -p "$project_dir/.doyaken/state"
  mkdir -p "$project_dir/.doyaken/logs"

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
  export STATE_DIR="$DATA_DIR/state"
  export LOGS_DIR="$DATA_DIR/logs"
  export AGENT_ID="test-worker"

  mkdir -p "$STATE_DIR"
  mkdir -p "$LOGS_DIR"
}
