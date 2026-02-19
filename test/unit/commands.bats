#!/usr/bin/env bats
#
# Unit tests for lib/commands.sh
#

load "../test_helper"

setup() {
  export TEST_TEMP_DIR
  TEST_TEMP_DIR="$(mktemp -d)"

  # Mock environment
  export DOYAKEN_PROJECT="$TEST_TEMP_DIR/project"
  export DOYAKEN_HOME="$TEST_TEMP_DIR/home"
  mkdir -p "$DOYAKEN_PROJECT/.doyaken"
  mkdir -p "$DOYAKEN_HOME"

  # Source dependencies
  load_lib "logging"
  load_lib "config"
  load_lib "utils"

  # Source commands.sh
  source "$PROJECT_ROOT/lib/commands.sh"

  # Reset command registry
  REGISTERED_CMD_NAMES=()
  REGISTERED_CMD_DESCS=()
  REGISTERED_CMD_TYPES=()
}

teardown() {
  if [[ -d "${TEST_TEMP_DIR:-}" ]]; then
    rm -rf "$TEST_TEMP_DIR"
  fi
}

# ============================================================================
# Command Registry Tests
# ============================================================================

@test "register_command: adds command to registry" {
  register_command "test" "Test command" "builtin"

  [ "${#REGISTERED_CMD_NAMES[@]}" -eq 1 ]
  [ "${REGISTERED_CMD_NAMES[0]}" = "test" ]
  [ "${REGISTERED_CMD_DESCS[0]}" = "Test command" ]
  [ "${REGISTERED_CMD_TYPES[0]}" = "builtin" ]
}

@test "register_command: defaults to builtin type" {
  register_command "test" "Test command"

  [ "${REGISTERED_CMD_TYPES[0]}" = "builtin" ]
}

@test "register_command: can register multiple commands" {
  register_command "test1" "First test" "builtin"
  register_command "test2" "Second test" "skill"
  register_command "test3" "Third test"

  [ "${#REGISTERED_CMD_NAMES[@]}" -eq 3 ]
  [ "${REGISTERED_CMD_NAMES[1]}" = "test2" ]
  [ "${REGISTERED_CMD_TYPES[1]}" = "skill" ]
}

# ============================================================================
# Command Detection Tests
# ============================================================================

@test "is_command: detects slash commands" {
  run is_command "/help"
  [ "$status" -eq 0 ]

  run is_command "/tasks list"
  [ "$status" -eq 0 ]

  run is_command "/a"
  [ "$status" -eq 0 ]
}

@test "is_command: rejects non-commands" {
  # is_command returns shell success/failure directly
  ! is_command "help"
  ! is_command "not a command"
  ! is_command ""
}

@test "is_command: accepts single slash" {
  # Actually "/" is technically a command (empty command name)
  is_command "/"
}

# ============================================================================
# Command Dispatch Tests
# ============================================================================

@test "dispatch_command: strips slash and extracts args" {
  # Mock chat_cmd_help function to verify args
  chat_cmd_help() {
    echo "help called with: '$1'"
  }

  run dispatch_command "/help commands"
  [ "$status" -eq 0 ]
  [[ "$output" == "help called with: 'commands'" ]]
}

@test "dispatch_command: handles commands without args" {
  # Mock chat_cmd_status function
  chat_cmd_status() {
    echo "status called"
  }

  run dispatch_command "/status"
  [ "$status" -eq 0 ]
  [[ "$output" == "status called" ]]
}

@test "dispatch_command: handles command aliases" {
  # Mock functions
  chat_cmd_help() { echo "help"; }
  chat_cmd_quit() { echo "quit"; }

  run dispatch_command "/h"
  [ "$status" -eq 0 ]
  [[ "$output" == "help" ]]

  run dispatch_command "/q"
  [ "$status" -eq 0 ]
  [[ "$output" == "quit" ]]
}

@test "dispatch_command: returns error for unknown command" {
  # Mock fuzzy match to return nothing
  fuzzy_match_slash_command() { echo ""; }

  run dispatch_command "/unknown"
  [ "$status" -eq 1 ]
  [[ "$output" == *"Unknown command"* ]]
  [[ "$output" == *"/unknown"* ]]
}

@test "dispatch_command: suggests fuzzy match" {
  # Mock fuzzy match
  fuzzy_match_slash_command() {
    if [[ "$1" == "hel" ]]; then
      echo "help"
    fi
  }

  run dispatch_command "/hel"
  [ "$status" -eq 1 ]
  [[ "$output" == *"Did you mean"* ]]
  [[ "$output" == *"/help"* ]]
}

# ============================================================================
# Edge Cases
# ============================================================================

@test "dispatch_command: handles empty command" {
  run dispatch_command "/"
  [ "$status" -eq 1 ]
  [[ "$output" == *"Unknown command"* ]]
}

@test "dispatch_command: handles command with multiple spaces" {
  chat_cmd_tasks() {
    echo "tasks called with: '$1'"
  }

  run dispatch_command "/tasks   list   all"
  [ "$status" -eq 0 ]
  # Args should preserve spacing after first space (${input#* } removes first word and one space)
  [[ "$output" == "tasks called with: '  list   all'" ]]
}

@test "register_command: handles empty description" {
  register_command "test" ""

  [ "${REGISTERED_CMD_DESCS[0]}" = "" ]
}

@test "register_command: handles special characters in name" {
  register_command "test-cmd" "Test with dash"
  register_command "test_cmd" "Test with underscore"

  [ "${#REGISTERED_CMD_NAMES[@]}" -eq 2 ]
  [ "${REGISTERED_CMD_NAMES[0]}" = "test-cmd" ]
  [ "${REGISTERED_CMD_NAMES[1]}" = "test_cmd" ]
}

@test "dispatch_command: handles very long command names" {
  local long_cmd="verylongcommandnamethatdoesnotexist"
  fuzzy_match_slash_command() { echo ""; }

  run dispatch_command "/$long_cmd"
  [ "$status" -eq 1 ]
  [[ "$output" == *"Unknown command"* ]]
}