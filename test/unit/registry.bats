#!/usr/bin/env bats
#
# Unit tests for lib/registry.sh
#

load "../test_helper"

setup() {
  export TEST_TEMP_DIR
  TEST_TEMP_DIR="$(mktemp -d)"
  export DOYAKEN_HOME="$TEST_TEMP_DIR/doyaken_home"
  mkdir -p "$DOYAKEN_HOME/projects"

  load_lib "logging"
  load_lib "registry"
}

teardown() {
  if [[ -d "${TEST_TEMP_DIR:-}" ]]; then
    rm -rf "$TEST_TEMP_DIR"
  fi
}

# ============================================================================
# ensure_registry tests
# ============================================================================

@test "ensure_registry: creates registry file" {
  run ensure_registry
  [ "$status" -eq 0 ]
  [ -f "$DOYAKEN_HOME/projects/registry.yaml" ]
}

@test "ensure_registry: creates valid YAML" {
  ensure_registry

  # Check YAML structure
  grep -q "version: 1" "$DOYAKEN_HOME/projects/registry.yaml"
  grep -q "projects:" "$DOYAKEN_HOME/projects/registry.yaml"
}

@test "ensure_registry: idempotent" {
  ensure_registry
  local first_content
  first_content=$(cat "$DOYAKEN_HOME/projects/registry.yaml")

  ensure_registry
  local second_content
  second_content=$(cat "$DOYAKEN_HOME/projects/registry.yaml")

  [ "$first_content" = "$second_content" ]
}

# ============================================================================
# add_to_registry tests (require yq)
# ============================================================================

@test "add_to_registry: requires yq" {
  if command -v yq &>/dev/null; then
    skip "yq is installed, testing require_yq separately"
  fi

  mkdir -p "$TEST_TEMP_DIR/test_project"

  run add_to_registry "$TEST_TEMP_DIR/test_project"
  [ "$status" -ne 0 ]
  [[ "$output" == *"yq is required"* ]]
}

@test "add_to_registry: adds project with yq" {
  if ! command -v yq &>/dev/null; then
    skip "yq not installed"
  fi

  mkdir -p "$TEST_TEMP_DIR/test_project"

  run add_to_registry "$TEST_TEMP_DIR/test_project" "test-project" ""
  [ "$status" -eq 0 ]

  # Verify project was added
  grep -q "test_project" "$DOYAKEN_HOME/projects/registry.yaml"
}

@test "add_to_registry: handles existing project" {
  if ! command -v yq &>/dev/null; then
    skip "yq not installed"
  fi

  mkdir -p "$TEST_TEMP_DIR/test_project"

  add_to_registry "$TEST_TEMP_DIR/test_project" "test-project" ""

  # Add again - should succeed (update timestamp)
  run add_to_registry "$TEST_TEMP_DIR/test_project" "test-project" ""
  [ "$status" -eq 0 ]
  [[ "$output" == *"already registered"* ]]
}

# ============================================================================
# remove_from_registry tests
# ============================================================================

@test "remove_from_registry: requires yq" {
  if command -v yq &>/dev/null; then
    skip "yq is installed"
  fi

  mkdir -p "$TEST_TEMP_DIR/test_project"

  run remove_from_registry "$TEST_TEMP_DIR/test_project"
  [ "$status" -ne 0 ]
}

@test "remove_from_registry: removes project with yq" {
  if ! command -v yq &>/dev/null; then
    skip "yq not installed"
  fi

  mkdir -p "$TEST_TEMP_DIR/test_project"

  # Add project first
  add_to_registry "$TEST_TEMP_DIR/test_project" "test-project" ""

  # Remove it
  run remove_from_registry "$TEST_TEMP_DIR/test_project"
  [ "$status" -eq 0 ]

  # Verify project was removed
  ! grep -q "test_project" "$DOYAKEN_HOME/projects/registry.yaml"
}

# ============================================================================
# lookup_registry tests
# ============================================================================

@test "lookup_registry: returns path for registered project" {
  if ! command -v yq &>/dev/null; then
    skip "yq not installed"
  fi

  mkdir -p "$TEST_TEMP_DIR/test_project"
  add_to_registry "$TEST_TEMP_DIR/test_project" "test-project" ""

  run lookup_registry "$TEST_TEMP_DIR/test_project"
  [ "$status" -eq 0 ]
  [[ "$output" == *"test_project"* ]]
}

@test "lookup_registry: fails for unregistered project" {
  mkdir -p "$TEST_TEMP_DIR/unregistered"
  ensure_registry

  run lookup_registry "$TEST_TEMP_DIR/unregistered"
  [ "$status" -ne 0 ]
}

# ============================================================================
# get_project_count tests
# ============================================================================

@test "get_project_count: returns 0 for empty registry" {
  ensure_registry

  run get_project_count
  [ "$status" -eq 0 ]
  # Output may include log messages, check last line
  [[ "$output" == *"0"* ]]
}

@test "get_project_count: counts projects with yq" {
  if ! command -v yq &>/dev/null; then
    skip "yq not installed"
  fi

  mkdir -p "$TEST_TEMP_DIR/project1"
  mkdir -p "$TEST_TEMP_DIR/project2"

  add_to_registry "$TEST_TEMP_DIR/project1" "project1" ""
  add_to_registry "$TEST_TEMP_DIR/project2" "project2" ""

  run get_project_count
  [ "$status" -eq 0 ]
  [ "$output" = "2" ]
}

# ============================================================================
# require_yq tests
# ============================================================================

@test "require_yq: succeeds when yq installed" {
  if ! command -v yq &>/dev/null; then
    skip "yq not installed"
  fi

  run require_yq
  [ "$status" -eq 0 ]
}

@test "require_yq: fails with helpful message when missing" {
  if command -v yq &>/dev/null; then
    skip "yq is installed"
  fi

  run require_yq
  [ "$status" -ne 0 ]
  [[ "$output" == *"yq is required"* ]]
  [[ "$output" == *"brew install yq"* ]]
}
