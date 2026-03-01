#!/usr/bin/env bats
#
# Integration tests for the full doyaken workflow
#

load "../test_helper"

setup() {
  export TEST_TEMP_DIR
  TEST_TEMP_DIR="$(mktemp -d)"
  # Use temp DOYAKEN_HOME to avoid polluting real registry with temp dir entries.
  # Symlink lib/ so the binary can find its scripts, but projects/ is isolated.
  export DOYAKEN_HOME="$TEST_TEMP_DIR/doyaken_home"
  mkdir -p "$DOYAKEN_HOME/projects"
  # Symlink install dirs so the binary can find scripts
  ln -s "$PROJECT_ROOT/lib" "$DOYAKEN_HOME/lib"
  ln -s "$PROJECT_ROOT/bin" "$DOYAKEN_HOME/bin"
  ln -s "$PROJECT_ROOT/config" "$DOYAKEN_HOME/config" 2>/dev/null || true
  ln -s "$PROJECT_ROOT/scripts" "$DOYAKEN_HOME/scripts" 2>/dev/null || true
  ln -s "$PROJECT_ROOT/templates" "$DOYAKEN_HOME/templates" 2>/dev/null || true
  # Copy VERSION file if it exists
  cp "$PROJECT_ROOT/VERSION" "$DOYAKEN_HOME/VERSION" 2>/dev/null || true
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
  [ -d ".doyaken/logs" ]
  [ -f ".doyaken/manifest.yaml" ]
}

@test "workflow: init creates agent files" {
  cd "$TEST_TEMP_DIR"

  "$PROJECT_ROOT/bin/doyaken" init
  [ -f "AGENTS.md" ]
  [ -f "CLAUDE.md" ]
}

@test "workflow: re-init repairs missing logs and state directories" {
  cd "$TEST_TEMP_DIR"

  # First init creates full structure
  "$PROJECT_ROOT/bin/doyaken" init
  [ -d ".doyaken/logs" ]
  [ -d ".doyaken/state" ]

  # Simulate incomplete directory structure
  rm -rf ".doyaken/logs" ".doyaken/state"
  [ ! -d ".doyaken/logs" ]
  [ ! -d ".doyaken/state" ]

  # Re-init should repair missing directories
  run "$PROJECT_ROOT/bin/doyaken" init
  [ "$status" -eq 0 ]
  [ -d ".doyaken/logs" ]
  [ -d ".doyaken/state" ]
  [ -f ".doyaken/logs/.gitkeep" ]
  [ -f ".doyaken/state/.gitkeep" ]

  # Verify permissions (700 = rwx------)
  local logs_perms state_perms
  logs_perms=$(stat -f '%Lp' ".doyaken/logs" 2>/dev/null || stat -c '%a' ".doyaken/logs" 2>/dev/null)
  state_perms=$(stat -f '%Lp' ".doyaken/state" 2>/dev/null || stat -c '%a' ".doyaken/state" 2>/dev/null)
  [ "$logs_perms" = "700" ]
  [ "$state_perms" = "700" ]
}

@test "workflow: re-init on complete project does not error" {
  cd "$TEST_TEMP_DIR"

  "$PROJECT_ROOT/bin/doyaken" init

  # Re-init should succeed without error
  run "$PROJECT_ROOT/bin/doyaken" init
  [ "$status" -eq 0 ]
  # Should still have all directories intact
  [ -d ".doyaken/logs" ]
  [ -d ".doyaken/state" ]
  [ -f ".doyaken/manifest.yaml" ]
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
# Health workflow
# ============================================================================

@test "workflow: health outputs JSON with required fields" {
  cd "$TEST_TEMP_DIR"

  run "$PROJECT_ROOT/bin/doyaken" health
  # Accept any exit code — environment may lack yq/timeout/claude
  [[ "$output" == *'"status"'* ]]
  [[ "$output" == *'"version"'* ]]
  [[ "$output" == *'"agent"'* ]]
  [[ "$output" == *'"agent_available"'* ]]
  [[ "$output" == *'"checks_passed"'* ]]
  [[ "$output" == *'"checks_total"'* ]]
}

@test "workflow: health reports correct version" {
  cd "$TEST_TEMP_DIR"

  local expected_version
  expected_version=$(cat "$PROJECT_ROOT/VERSION")

  run "$PROJECT_ROOT/bin/doyaken" health
  [[ "$output" == *"\"version\":\"$expected_version\""* ]]
}

@test "workflow: health --quiet produces no output" {
  cd "$TEST_TEMP_DIR"

  run "$PROJECT_ROOT/bin/doyaken" health --quiet
  [ -z "$output" ]
  [ "$status" -le 2 ]
}

@test "workflow: help health shows usage" {
  run "$PROJECT_ROOT/bin/doyaken" help health
  [ "$status" -eq 0 ]
  [[ "$output" == *"doyaken health"* ]]
  [[ "$output" == *"USAGE"* ]]
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
# Core Function Integration Tests
# ============================================================================

_setup_integration_test() {
  cd "$TEST_TEMP_DIR"
  "$PROJECT_ROOT/bin/doyaken" init
  source "$PROJECT_ROOT/test/unit/core_functions.sh"

  export DOYAKEN_PROJECT="$TEST_TEMP_DIR"
  export DATA_DIR="$TEST_TEMP_DIR/.doyaken"
  export STATE_DIR="$DATA_DIR/state"
  export AGENT_ID="integration-test"
}

@test "error: model fallback triggers on rate limit detection" {
  _setup_integration_test

  CURRENT_AGENT="claude"
  CURRENT_MODEL="opus"
  AGENT_NO_FALLBACK="0"

  fallback_to_sonnet
  [ "$CURRENT_MODEL" = "sonnet" ]
  [ "$MODEL_FALLBACK_TRIGGERED" = "1" ]

  run fallback_to_sonnet
  [ "$status" -eq 1 ]
}
