#!/usr/bin/env bats
#
# Unit tests for lib/utils.sh
#

load "../test_helper"

setup() {
  export TEST_TEMP_DIR
  TEST_TEMP_DIR="$(mktemp -d)"

  # Source dependencies
  source "$PROJECT_ROOT/lib/logging.sh"
  source "$PROJECT_ROOT/lib/utils.sh"

  # Reset any environment variables
  unset DOYAKEN_AUTO_TIMEOUT
}

teardown() {
  if [[ -d "${TEST_TEMP_DIR:-}" ]]; then
    rm -rf "$TEST_TEMP_DIR"
  fi
}

# ============================================================================
# read_with_timeout tests
# ============================================================================

@test "read_with_timeout: sets variable with user input" {
  # Simulate user input
  run bash -c 'source "$PROJECT_ROOT/lib/logging.sh"; source "$PROJECT_ROOT/lib/utils.sh"; echo "2" | read_with_timeout choice "Enter [1-3]: " 1 2 3; echo "$choice"'
  [ "$status" -eq 0 ]
  [[ "${lines[-1]}" == "2" ]]
}

@test "read_with_timeout: works with no timeout when DOYAKEN_AUTO_TIMEOUT is 0" {
  export DOYAKEN_AUTO_TIMEOUT=0
  run bash -c 'source "$PROJECT_ROOT/lib/logging.sh"; source "$PROJECT_ROOT/lib/utils.sh"; echo "test" | read_with_timeout result "Enter: "; echo "$result"'
  [ "$status" -eq 0 ]
  [[ "${lines[-1]}" == "test" ]]
}

@test "read_with_timeout: handles empty input" {
  run bash -c 'source "$PROJECT_ROOT/lib/logging.sh"; source "$PROJECT_ROOT/lib/utils.sh"; echo "" | read_with_timeout result "Enter: " a b c; echo "result=$result"'
  [ "$status" -eq 0 ]
  [[ "$output" == *"result="* ]]
}

# ============================================================================
# fuzzy_match_command tests
# ============================================================================

@test "fuzzy_match_command: returns empty for input too short" {
  run fuzzy_match_command "r"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "fuzzy_match_command: exact prefix match for 3+ chars" {
  run fuzzy_match_command "tas"
  [ "$status" -eq 0 ]
  [ "$output" = "tasks" ]

  run fuzzy_match_command "sta"
  [ "$status" -eq 0 ]
  [ "$output" = "status" ]
}

@test "fuzzy_match_command: handles missing character" {
  run fuzzy_match_command "taks"
  [ "$status" -eq 0 ]
  [ "$output" = "tasks" ]

  run fuzzy_match_command "statu"
  [ "$status" -eq 0 ]
  [ "$output" = "status" ]
}

@test "fuzzy_match_command: handles extra character" {
  run fuzzy_match_command "taskss"
  [ "$status" -eq 0 ]
  [ "$output" = "tasks" ]

  run fuzzy_match_command "statuss"
  [ "$status" -eq 0 ]
  [ "$output" = "status" ]
}

@test "fuzzy_match_command: handles adjacent character swap" {
  run fuzzy_match_command "tsaks"
  [ "$status" -eq 0 ]
  [ "$output" = "tasks" ]

  run fuzzy_match_command "stauts"
  [ "$status" -eq 0 ]
  [ "$output" = "status" ]
}

@test "fuzzy_match_command: returns empty for no match" {
  run fuzzy_match_command "xyz"
  [ "$status" -eq 0 ]
  [ -z "$output" ]

  run fuzzy_match_command "completely-wrong"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "fuzzy_match_command: handles partial matches correctly" {
  # Should match "config"
  run fuzzy_match_command "conf"
  [ "$status" -eq 0 ]
  [ "$output" = "config" ]

  # Should match "upgrade"
  run fuzzy_match_command "upgr"
  [ "$status" -eq 0 ]
  [ "$output" = "upgrade" ]
}

@test "fuzzy_match_command: prioritizes exact prefix over typos" {
  # "reg" should match "register" not "unregister"
  run fuzzy_match_command "reg"
  [ "$status" -eq 0 ]
  [ "$output" = "register" ]
}

# ============================================================================
# Edge Cases
# ============================================================================

@test "fuzzy_match_command: handles empty input" {
  run fuzzy_match_command ""
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "fuzzy_match_command: handles single character input" {
  run fuzzy_match_command "s"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "fuzzy_match_command: handles very long input" {
  run fuzzy_match_command "verylonginputthatwontmatchanything"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "fuzzy_match_command: handles special characters" {
  run fuzzy_match_command "ta-sk"
  [ "$status" -eq 0 ]
  # Should not match anything with special char in middle
  [ -z "$output" ]
}

@test "read_with_timeout: handles multiple word input" {
  run bash -c 'source "$PROJECT_ROOT/lib/logging.sh"; source "$PROJECT_ROOT/lib/utils.sh"; echo "hello world" | read_with_timeout result "Enter: "; echo "$result"'
  [ "$status" -eq 0 ]
  [[ "${lines[-1]}" == "hello world" ]]
}

@test "read_with_timeout: preserves special characters in input" {
  run bash -c 'source "$PROJECT_ROOT/lib/logging.sh"; source "$PROJECT_ROOT/lib/utils.sh"; echo "test@123!" | read_with_timeout result "Enter: "; echo "$result"'
  [ "$status" -eq 0 ]
  [[ "${lines[-1]}" == "test@123!" ]]
}