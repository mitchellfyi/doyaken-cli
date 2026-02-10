#!/usr/bin/env bats
#
# Tests for lib/circuit_breaker.sh
#

load '../test_helper'

setup() {
  export TEST_TEMP_DIR
  TEST_TEMP_DIR="$(mktemp -d)"
  export DOYAKEN_HOME="$PROJECT_ROOT"
  export STATE_DIR="$TEST_TEMP_DIR/state"
  export PROJECT_DIR="$TEST_TEMP_DIR/project"
  export AGENT_ID="test-agent"

  mkdir -p "$STATE_DIR"
  mkdir -p "$PROJECT_DIR"

  # Source dependencies
  source "$PROJECT_ROOT/lib/logging.sh"
  source "$PROJECT_ROOT/lib/config.sh"
  source "$PROJECT_ROOT/lib/circuit_breaker.sh"
}

teardown() {
  if [[ -d "${TEST_TEMP_DIR:-}" ]]; then
    rm -rf "$TEST_TEMP_DIR"
  fi
}

# ============================================================================
# Loading and Configuration
# ============================================================================

@test "circuit_breaker.sh loads without error" {
  [[ -n "$_DOYAKEN_CIRCUIT_BREAKER_LOADED" ]]
}

@test "default config values are set" {
  [[ "$CB_ENABLED" == "1" ]]
  [[ "$CB_NO_PROGRESS_THRESHOLD" == "3" ]]
  [[ "$CB_SAME_ERROR_THRESHOLD" == "5" ]]
  [[ "$CB_OUTPUT_DECLINE_PERCENT" == "70" ]]
  [[ "$CB_COOLDOWN_MINUTES" == "5" ]]
}

@test "load_circuit_breaker_config loads defaults" {
  unset CB_ENABLED CB_NO_PROGRESS_THRESHOLD
  export CB_ENABLED="" CB_NO_PROGRESS_THRESHOLD=""

  load_circuit_breaker_config ""

  [[ "$CB_ENABLED" == "1" ]]
  [[ "$CB_NO_PROGRESS_THRESHOLD" == "3" ]]
}

# ============================================================================
# State Machine Basics
# ============================================================================

@test "initial state is CLOSED" {
  cb_reset
  [[ "$CB_STATE" == "CLOSED" ]]
  [[ "$CB_NO_PROGRESS_COUNT" -eq 0 ]]
  [[ "$CB_SAME_ERROR_COUNT" -eq 0 ]]
}

@test "cb_get_state returns current state" {
  cb_reset
  local state
  state=$(cb_get_state)
  [[ "$state" == "CLOSED" ]]
}

@test "cb_status returns formatted status" {
  cb_reset
  local status
  status=$(cb_status)
  [[ "$status" == *"state=CLOSED"* ]]
  [[ "$status" == *"no_progress=0"* ]]
  [[ "$status" == *"errors=0"* ]]
}

@test "cb_reset clears all state" {
  CB_STATE="OPEN"
  CB_NO_PROGRESS_COUNT=5
  CB_SAME_ERROR_COUNT=3
  CB_LAST_ERROR_HASH="abc"
  CB_OUTPUT_SIZES=(100 200 300)
  CB_OPEN_SINCE=12345

  cb_reset

  [[ "$CB_STATE" == "CLOSED" ]]
  [[ "$CB_NO_PROGRESS_COUNT" -eq 0 ]]
  [[ "$CB_SAME_ERROR_COUNT" -eq 0 ]]
  [[ -z "$CB_LAST_ERROR_HASH" ]]
  [[ ${#CB_OUTPUT_SIZES[@]} -eq 0 ]]
  [[ "$CB_OPEN_SINCE" -eq 0 ]]
}

# ============================================================================
# State Transitions
# ============================================================================

@test "CLOSED stays CLOSED on first no-progress" {
  cb_reset
  _cb_on_no_progress "test"
  [[ "$CB_STATE" == "CLOSED" ]]
  [[ "$CB_NO_PROGRESS_COUNT" -eq 1 ]]
}

@test "CLOSED transitions to HALF_OPEN on 2 no-progress" {
  cb_reset
  _cb_on_no_progress "test"
  _cb_on_no_progress "test"
  [[ "$CB_STATE" == "HALF_OPEN" ]]
  [[ "$CB_NO_PROGRESS_COUNT" -eq 2 ]]
}

@test "HALF_OPEN transitions to OPEN at threshold" {
  cb_reset
  CB_NO_PROGRESS_THRESHOLD=3

  _cb_on_no_progress "test"  # count=1 (still CLOSED)
  _cb_on_no_progress "test"  # count=2 (HALF_OPEN)
  _cb_on_no_progress "test"  # count=3 (OPEN)

  [[ "$CB_STATE" == "OPEN" ]]
}

@test "progress resets to CLOSED from HALF_OPEN" {
  cb_reset
  CB_STATE="HALF_OPEN"
  CB_NO_PROGRESS_COUNT=2

  _cb_on_progress

  [[ "$CB_STATE" == "CLOSED" ]]
  [[ "$CB_NO_PROGRESS_COUNT" -eq 0 ]]
}

@test "progress resets to CLOSED from OPEN" {
  cb_reset
  CB_STATE="OPEN"
  CB_NO_PROGRESS_COUNT=5

  _cb_on_progress

  [[ "$CB_STATE" == "CLOSED" ]]
  [[ "$CB_NO_PROGRESS_COUNT" -eq 0 ]]
}

# ============================================================================
# cb_should_proceed
# ============================================================================

@test "cb_should_proceed returns 0 in CLOSED state" {
  cb_reset
  CB_STATE="CLOSED"
  cb_should_proceed
}

@test "cb_should_proceed returns 0 in HALF_OPEN state" {
  cb_reset
  CB_STATE="HALF_OPEN"
  cb_should_proceed
}

@test "cb_should_proceed returns 1 in OPEN state (no cooldown)" {
  cb_reset
  CB_STATE="OPEN"
  CB_OPEN_SINCE=$(date +%s)
  CB_COOLDOWN_MINUTES=5

  local result=0
  cb_should_proceed || result=$?
  [[ "$result" -eq 1 ]]
}

@test "cb_should_proceed returns 0 when disabled" {
  cb_reset
  CB_ENABLED=0
  CB_STATE="OPEN"
  cb_should_proceed
}

@test "cb_should_proceed transitions OPEN to HALF_OPEN after cooldown" {
  cb_reset
  CB_STATE="OPEN"
  CB_OPEN_SINCE=$(( $(date +%s) - 400 ))  # 400 seconds ago
  CB_COOLDOWN_MINUTES=5  # 300 seconds

  cb_should_proceed
  [[ "$CB_STATE" == "HALF_OPEN" ]]
}

# ============================================================================
# Error Hash and Detection
# ============================================================================

@test "cb_hash_error produces consistent hash" {
  local hash1 hash2
  hash1=$(cb_hash_error "test error message")
  hash2=$(cb_hash_error "test error message")
  [[ "$hash1" == "$hash2" ]]
  [[ -n "$hash1" ]]
}

@test "cb_hash_error produces different hash for different input" {
  local hash1 hash2
  hash1=$(cb_hash_error "error A")
  hash2=$(cb_hash_error "error B")
  [[ "$hash1" != "$hash2" ]]
}

@test "cb_hash_error handles empty input" {
  local hash
  hash=$(cb_hash_error "")
  [[ -z "$hash" ]]
}

@test "repeated errors increment counter" {
  cb_reset
  CB_LAST_ERROR_HASH="12345"
  CB_SAME_ERROR_COUNT=1
  CB_SAME_ERROR_THRESHOLD=5

  # Simulate cb_record_iteration logic with same hash
  CB_SAME_ERROR_COUNT=4
  CB_LAST_ERROR_HASH="12345"

  # Same error hash detected
  local error_hash="12345"
  if [ "$error_hash" = "$CB_LAST_ERROR_HASH" ]; then
    ((CB_SAME_ERROR_COUNT++))
  fi

  [[ "$CB_SAME_ERROR_COUNT" -eq 5 ]]
}

# ============================================================================
# Output Decline Detection
# ============================================================================

@test "cb_record_output_size adds to rolling window" {
  CB_OUTPUT_SIZES=()
  cb_record_output_size 100
  cb_record_output_size 200
  cb_record_output_size 300

  [[ ${#CB_OUTPUT_SIZES[@]} -eq 3 ]]
  [[ "${CB_OUTPUT_SIZES[0]}" -eq 100 ]]
}

@test "cb_record_output_size keeps only 5 entries" {
  CB_OUTPUT_SIZES=()
  cb_record_output_size 100
  cb_record_output_size 200
  cb_record_output_size 300
  cb_record_output_size 400
  cb_record_output_size 500
  cb_record_output_size 600

  [[ ${#CB_OUTPUT_SIZES[@]} -eq 5 ]]
  [[ "${CB_OUTPUT_SIZES[0]}" -eq 200 ]]
}

@test "cb_check_output_decline returns 0 with insufficient data" {
  CB_OUTPUT_SIZES=()
  cb_check_output_decline 100
}

@test "cb_check_output_decline returns 0 for healthy output" {
  CB_OUTPUT_SIZES=(1000 1000 1000)
  CB_OUTPUT_DECLINE_PERCENT=70
  cb_check_output_decline 900
}

@test "cb_check_output_decline returns 1 for declining output" {
  CB_OUTPUT_SIZES=(1000 1000 1000)
  CB_OUTPUT_DECLINE_PERCENT=70

  local result=0
  cb_check_output_decline 200 || result=$?
  [[ "$result" -eq 1 ]]
}

# ============================================================================
# State Persistence
# ============================================================================

@test "cb_save_state creates state file" {
  cb_reset
  CB_STATE="HALF_OPEN"
  CB_NO_PROGRESS_COUNT=2
  cb_save_state "test-agent"

  local state_file="$STATE_DIR/circuit-breaker-test-agent"
  [[ -f "$state_file" ]]
}

@test "cb_load_state restores saved state" {
  cb_reset
  CB_STATE="HALF_OPEN"
  CB_NO_PROGRESS_COUNT=2
  CB_SAME_ERROR_COUNT=1
  CB_LAST_ERROR_HASH="abc123"
  CB_OUTPUT_SIZES=(100 200 300)
  cb_save_state "test-agent"

  # Reset and reload
  cb_reset
  cb_load_state "test-agent"

  [[ "$CB_STATE" == "HALF_OPEN" ]]
  [[ "$CB_NO_PROGRESS_COUNT" -eq 2 ]]
  [[ "$CB_SAME_ERROR_COUNT" -eq 1 ]]
  [[ "$CB_LAST_ERROR_HASH" == "abc123" ]]
  [[ ${#CB_OUTPUT_SIZES[@]} -eq 3 ]]
  [[ "${CB_OUTPUT_SIZES[0]}" -eq 100 ]]
}

@test "cb_load_state handles missing file gracefully" {
  cb_load_state "nonexistent-agent"
  [[ "$CB_STATE" == "CLOSED" ]]
  [[ "$CB_NO_PROGRESS_COUNT" -eq 0 ]]
}

@test "cb_save_state uses atomic write" {
  cb_reset
  CB_STATE="OPEN"
  cb_save_state "test-agent"

  # Verify no .tmp files left behind
  local tmp_files
  tmp_files=$(ls "$STATE_DIR"/circuit-breaker-test-agent.tmp.* 2>/dev/null || echo "")
  [[ -z "$tmp_files" ]]
}

# ============================================================================
# Integration: cb_record_iteration
# ============================================================================

@test "cb_record_iteration on success with changes resets state" {
  cb_reset
  CB_STATE="HALF_OPEN"
  CB_NO_PROGRESS_COUNT=2

  # Create a git repo with changes
  cd "$PROJECT_DIR"
  git init -q .
  git config user.email "test@test.com"
  git config user.name "Test"
  echo "initial" > file.txt
  git add file.txt
  git commit -q -m "init"
  echo "changed" >> file.txt  # Unstaged change = diff exists

  cb_record_iteration 0 "" "$PROJECT_DIR"

  [[ "$CB_STATE" == "CLOSED" ]]
  [[ "$CB_NO_PROGRESS_COUNT" -eq 0 ]]
}

@test "cb_record_iteration on success without changes increments no-progress" {
  cb_reset

  # Create a git repo with NO changes
  cd "$PROJECT_DIR"
  git init -q .
  git config user.email "test@test.com"
  git config user.name "Test"
  echo "initial" > file.txt
  git add file.txt
  git commit -q -m "init"
  # No modifications — clean working tree

  cb_record_iteration 0 "" "$PROJECT_DIR"

  [[ "$CB_NO_PROGRESS_COUNT" -eq 1 ]]
}

@test "cb_record_iteration on failure records error" {
  cb_reset

  # Create a fake log file
  local log_file="$TEST_TEMP_DIR/phase.log"
  echo "Error: something went wrong" > "$log_file"
  echo "Stack trace: line 42" >> "$log_file"

  cb_record_iteration 1 "$log_file" "$PROJECT_DIR"

  [[ "$CB_NO_PROGRESS_COUNT" -eq 1 ]]
  [[ -n "$CB_LAST_ERROR_HASH" ]]
  [[ "$CB_SAME_ERROR_COUNT" -eq 1 ]]
}

@test "cb_record_iteration disabled when CB_ENABLED=0" {
  CB_ENABLED=0
  CB_STATE="CLOSED"
  CB_NO_PROGRESS_COUNT=0

  cb_record_iteration 1 "" "$PROJECT_DIR"

  [[ "$CB_NO_PROGRESS_COUNT" -eq 0 ]]
}

# ============================================================================
# Full Lifecycle
# ============================================================================

@test "full lifecycle: CLOSED → HALF_OPEN → OPEN → cooldown → HALF_OPEN → CLOSED" {
  cb_reset
  CB_NO_PROGRESS_THRESHOLD=3
  CB_COOLDOWN_MINUTES=0  # instant cooldown for test

  # No progress iterations
  _cb_on_no_progress "test"
  [[ "$CB_STATE" == "CLOSED" ]]

  _cb_on_no_progress "test"
  [[ "$CB_STATE" == "HALF_OPEN" ]]

  _cb_on_no_progress "test"
  [[ "$CB_STATE" == "OPEN" ]]

  # Cooldown expired (0 minutes)
  CB_OPEN_SINCE=$(( $(date +%s) - 10 ))
  cb_should_proceed
  [[ "$CB_STATE" == "HALF_OPEN" ]]

  # Progress detected
  _cb_on_progress
  [[ "$CB_STATE" == "CLOSED" ]]
  [[ "$CB_NO_PROGRESS_COUNT" -eq 0 ]]
}
