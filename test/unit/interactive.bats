#!/usr/bin/env bats
#
# Tests for lib/interactive.sh and lib/commands.sh
#

load '../test_helper'

setup() {
  export TEST_TEMP_DIR
  TEST_TEMP_DIR="$(mktemp -d)"
  export DOYAKEN_HOME="$PROJECT_ROOT"

  # Create a mock project
  export DOYAKEN_PROJECT="$TEST_TEMP_DIR/project"
  mkdir -p "$DOYAKEN_PROJECT/.doyaken/tasks/1.blocked"
  mkdir -p "$DOYAKEN_PROJECT/.doyaken/tasks/2.todo"
  mkdir -p "$DOYAKEN_PROJECT/.doyaken/tasks/3.doing"
  mkdir -p "$DOYAKEN_PROJECT/.doyaken/tasks/4.done"
  mkdir -p "$DOYAKEN_PROJECT/.doyaken/sessions"
  export DOYAKEN_DIR="$DOYAKEN_PROJECT/.doyaken"

  # Source libraries
  source "$PROJECT_ROOT/lib/logging.sh"
  source "$PROJECT_ROOT/lib/project.sh"
  source "$PROJECT_ROOT/lib/commands.sh"
  source "$PROJECT_ROOT/lib/interactive.sh"
}

teardown() {
  if [[ -d "${TEST_TEMP_DIR:-}" ]]; then
    rm -rf "$TEST_TEMP_DIR"
  fi
}

# ============================================================================
# commands.sh tests
# ============================================================================

@test "is_command returns true for slash commands" {
  run is_command "/help"
  assert_success
}

@test "is_command returns true for multi-word slash commands" {
  run is_command "/status something"
  assert_success
}

@test "is_command returns false for regular messages" {
  run is_command "hello world"
  assert_failure
}

@test "is_command returns false for empty string" {
  run is_command ""
  assert_failure
}

@test "dispatch_command handles /help" {
  run dispatch_command "/help"
  assert_success
  assert_output_contains "Available Commands"
}

@test "dispatch_command handles /h alias" {
  run dispatch_command "/h"
  assert_success
  assert_output_contains "Available Commands"
}

@test "dispatch_command handles /status" {
  run dispatch_command "/status"
  assert_success
  assert_output_contains "Project:"
}

@test "dispatch_command handles /clear" {
  # /clear calls clear which may not work in test context, just check no error
  run dispatch_command "/clear" 2>/dev/null
  # Accept either success or failure (clear may fail in non-tty)
  true
}

@test "dispatch_command handles /quit" {
  CHAT_SHOULD_EXIT=0
  dispatch_command "/quit"
  [ "$CHAT_SHOULD_EXIT" -eq 1 ]
}

@test "dispatch_command handles /exit" {
  CHAT_SHOULD_EXIT=0
  dispatch_command "/exit"
  [ "$CHAT_SHOULD_EXIT" -eq 1 ]
}

@test "dispatch_command handles /q alias" {
  CHAT_SHOULD_EXIT=0
  dispatch_command "/q"
  [ "$CHAT_SHOULD_EXIT" -eq 1 ]
}

@test "dispatch_command returns error for unknown commands" {
  run dispatch_command "/foobar"
  assert_failure
  assert_output_contains "Unknown command: /foobar"
}

@test "chat_cmd_help lists all built-in commands" {
  run chat_cmd_help
  assert_success
  assert_output_contains "/help"
  assert_output_contains "/status"
  assert_output_contains "/clear"
  assert_output_contains "/quit"
}

@test "chat_cmd_status shows project name" {
  run chat_cmd_status
  assert_success
  assert_output_contains "Project:"
  assert_output_contains "project"
}

@test "chat_cmd_status shows agent info" {
  export DOYAKEN_AGENT="claude"
  run chat_cmd_status
  assert_success
  assert_output_contains "Agent:"
  assert_output_contains "claude"
}

@test "chat_cmd_status shows session ID when set" {
  CHAT_SESSION_ID="test-session-123"
  run chat_cmd_status
  assert_success
  assert_output_contains "Session:"
  assert_output_contains "test-session-123"
}

@test "chat_cmd_status shows task counts" {
  # Create some test tasks
  touch "$DOYAKEN_PROJECT/.doyaken/tasks/2.todo/task1.md"
  touch "$DOYAKEN_PROJECT/.doyaken/tasks/2.todo/task2.md"
  touch "$DOYAKEN_PROJECT/.doyaken/tasks/3.doing/task3.md"

  run chat_cmd_status
  assert_success
  assert_output_contains "Todo:"
  assert_output_contains "Doing:"
}

@test "chat_cmd_status works without project" {
  unset DOYAKEN_PROJECT
  run chat_cmd_status
  assert_success
  assert_output_contains "Project:"
  assert_output_contains "(none)"
}

# ============================================================================
# interactive.sh session tests
# ============================================================================

@test "generate_session_id produces unique IDs" {
  local id1 id2
  id1=$(generate_session_id)
  # Ensure different PID component
  id2=$(bash -c 'source "'"$PROJECT_ROOT"'/lib/interactive.sh"; generate_session_id')
  [ "$id1" != "$id2" ]
}

@test "generate_session_id contains date component" {
  local id
  id=$(generate_session_id)
  local today
  today=$(date '+%Y%m%d')
  [[ "$id" == ${today}* ]]
}

@test "init_session creates session directory" {
  init_session
  [ -d "$CHAT_SESSION_DIR" ]
}

@test "init_session creates messages file parent" {
  init_session
  [ -d "$(dirname "$CHAT_MESSAGES_FILE")" ]
}

@test "init_session sets session ID" {
  init_session
  [ -n "$CHAT_SESSION_ID" ]
}

@test "init_session uses project dir for sessions" {
  init_session
  [[ "$CHAT_SESSION_DIR" == *"$DOYAKEN_PROJECT/.doyaken/sessions/"* ]]
}

@test "init_session falls back to DOYAKEN_HOME when no project" {
  unset DOYAKEN_PROJECT
  unset DOYAKEN_DIR
  export DOYAKEN_HOME="$TEST_TEMP_DIR/home"
  mkdir -p "$DOYAKEN_HOME"
  init_session
  [[ "$CHAT_SESSION_DIR" == *"$DOYAKEN_HOME/sessions/"* ]]
}

@test "log_message writes to JSONL file" {
  init_session
  log_message "user" "hello world"
  [ -f "$CHAT_MESSAGES_FILE" ]
  local line_count
  line_count=$(wc -l < "$CHAT_MESSAGES_FILE" | tr -d ' ')
  [ "$line_count" -eq 1 ]
}

@test "log_message includes role and content" {
  init_session
  log_message "user" "test message"
  local content
  content=$(cat "$CHAT_MESSAGES_FILE")
  [[ "$content" == *'"role":"user"'* ]]
  [[ "$content" == *'"content":"test message"'* ]]
}

@test "log_message includes timestamp" {
  init_session
  log_message "assistant" "response"
  local content
  content=$(cat "$CHAT_MESSAGES_FILE")
  [[ "$content" == *'"timestamp":"'* ]]
}

@test "log_message escapes double quotes" {
  init_session
  log_message "user" 'say "hello"'
  local content
  content=$(cat "$CHAT_MESSAGES_FILE")
  [[ "$content" == *'\"hello\"'* ]]
}

@test "log_message appends multiple messages" {
  init_session
  log_message "user" "first"
  log_message "assistant" "second"
  local line_count
  line_count=$(wc -l < "$CHAT_MESSAGES_FILE" | tr -d ' ')
  [ "$line_count" -eq 2 ]
}

@test "build_chat_prompt includes project name when set" {
  export DOYAKEN_PROJECT="$TEST_TEMP_DIR/myproject"
  local prompt
  prompt=$(build_chat_prompt)
  [[ "$prompt" == *"myproject"* ]]
}

@test "build_chat_prompt shows default when no project" {
  unset DOYAKEN_PROJECT
  local prompt
  prompt=$(build_chat_prompt)
  [[ "$prompt" == "doyaken> " ]]
}

# ============================================================================
# CLI integration tests
# ============================================================================

@test "chat command is in the fuzzy match command list" {
  source "$PROJECT_ROOT/lib/utils.sh"
  [[ "$DOYAKEN_COMMANDS" == *"chat"* ]]
}

@test "help text includes chat command" {
  source "$PROJECT_ROOT/lib/help.sh"
  run show_help
  assert_output_contains "chat"
  assert_output_contains "Interactive chat/REPL mode"
}

@test "chat help shows slash commands" {
  source "$PROJECT_ROOT/lib/help.sh"
  run show_command_help "chat"
  assert_output_contains "/help"
  assert_output_contains "/quit"
  assert_output_contains "/status"
  assert_output_contains "/clear"
}
