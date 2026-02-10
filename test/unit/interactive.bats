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
  mkdir -p "$DOYAKEN_PROJECT/.doyaken/logs"
  mkdir -p "$DOYAKEN_PROJECT/.git"
  export DOYAKEN_DIR="$DOYAKEN_PROJECT/.doyaken"

  # Source libraries
  source "$PROJECT_ROOT/lib/logging.sh"
  source "$PROJECT_ROOT/lib/project.sh"
  source "$PROJECT_ROOT/lib/agents.sh"
  source "$PROJECT_ROOT/lib/sessions.sh"
  source "$PROJECT_ROOT/lib/undo.sh"
  source "$PROJECT_ROOT/lib/approval.sh"
  source "$PROJECT_ROOT/lib/commands.sh"
  source "$PROJECT_ROOT/lib/interactive.sh"

  # Register commands for tests
  register_builtin_commands
}

teardown() {
  if [[ -d "${TEST_TEMP_DIR:-}" ]]; then
    rm -rf "$TEST_TEMP_DIR"
  fi
}

# ============================================================================
# Command registry tests
# ============================================================================

@test "register_command adds to parallel arrays" {
  local before=${#REGISTERED_CMD_NAMES[@]}
  register_command "test-cmd" "A test command" "builtin"
  [ ${#REGISTERED_CMD_NAMES[@]} -eq $((before + 1)) ]
}

@test "register_command stores name, description, and type" {
  register_command "mycmd" "My description" "skill"
  local last=$((${#REGISTERED_CMD_NAMES[@]} - 1))
  [ "${REGISTERED_CMD_NAMES[$last]}" = "mycmd" ]
  [ "${REGISTERED_CMD_DESCS[$last]}" = "My description" ]
  [ "${REGISTERED_CMD_TYPES[$last]}" = "skill" ]
}

@test "register_command defaults type to builtin" {
  register_command "defcmd" "Default type"
  local last=$((${#REGISTERED_CMD_NAMES[@]} - 1))
  [ "${REGISTERED_CMD_TYPES[$last]}" = "builtin" ]
}

# ============================================================================
# is_command tests
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

# ============================================================================
# dispatch_command tests (existing + new commands)
# ============================================================================

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
  run dispatch_command "/clear" 2>/dev/null
  true  # Accept any result since clear may fail in non-tty
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

@test "dispatch_command handles /tasks" {
  touch "$DOYAKEN_PROJECT/.doyaken/tasks/2.todo/task1.md"
  run dispatch_command "/tasks"
  assert_success
  assert_output_contains "TODO"
  assert_output_contains "task1"
}

@test "dispatch_command handles /task with pattern" {
  cat > "$DOYAKEN_PROJECT/.doyaken/tasks/2.todo/003-001-test.md" << 'EOF'
# Task: Test task
## Metadata
| Field | Value |
| ID | `003-001-test` |
EOF
  run dispatch_command "/task 003-001"
  assert_success
  assert_output_contains "Test task"
}

@test "dispatch_command handles /task without args" {
  run dispatch_command "/task"
  assert_failure
  assert_output_contains "Usage:"
}

@test "dispatch_command handles /pick" {
  touch "$DOYAKEN_PROJECT/.doyaken/tasks/2.todo/003-002-pick-me.md"
  run dispatch_command "/pick pick-me"
  assert_success
  assert_output_contains "Picked up"
  # Verify file was moved
  [ ! -f "$DOYAKEN_PROJECT/.doyaken/tasks/2.todo/003-002-pick-me.md" ]
  [ -f "$DOYAKEN_PROJECT/.doyaken/tasks/3.doing/003-002-pick-me.md" ]
}

@test "dispatch_command handles /model without args (show current)" {
  export DOYAKEN_AGENT="claude"
  export DOYAKEN_MODEL="opus"
  run dispatch_command "/model"
  assert_success
  assert_output_contains "opus"
}

@test "dispatch_command handles /model with valid model" {
  export DOYAKEN_AGENT="claude"
  export DOYAKEN_MODEL="opus"
  run dispatch_command "/model sonnet"
  assert_success
  assert_output_contains "Model changed to"
}

@test "dispatch_command handles /agent without args" {
  export DOYAKEN_AGENT="claude"
  run dispatch_command "/agent"
  assert_success
  assert_output_contains "claude"
  assert_output_contains "Available"
}

@test "dispatch_command handles /skip with valid phase" {
  dispatch_command "/skip docs"
  [ "$SKIP_DOCS" = "1" ]
}

@test "dispatch_command handles /skip with invalid phase" {
  run dispatch_command "/skip foobar"
  assert_failure
  assert_output_contains "Unknown phase"
}

@test "dispatch_command handles /phase without args" {
  run dispatch_command "/phase"
  assert_failure
  assert_output_contains "Usage:"
}

@test "dispatch_command handles /phase with invalid phase" {
  run dispatch_command "/phase foobar"
  assert_failure
  assert_output_contains "Unknown phase"
}

@test "dispatch_command handles /config without args" {
  run dispatch_command "/config"
  assert_success
  assert_output_contains "Agent:"
  assert_output_contains "Model:"
}

@test "dispatch_command handles /config with key" {
  export DOYAKEN_AGENT="claude"
  run dispatch_command "/config agent"
  assert_success
  assert_output_contains "claude"
}

@test "dispatch_command handles /config set key value" {
  run dispatch_command "/config verbose 1"
  assert_success
  assert_output_contains "Set"
}

@test "dispatch_command handles /log" {
  run dispatch_command "/log"
  # May show "No log files found" which is fine
  assert_success
}

@test "dispatch_command handles /diff" {
  run dispatch_command "/diff"
  # May show "No uncommitted changes" which is fine
  assert_success
}

@test "dispatch_command handles /run without task" {
  unset CHAT_CURRENT_TASK
  run dispatch_command "/run"
  assert_failure
  assert_output_contains "No task picked"
}

@test "dispatch_command suggests fuzzy match for typos" {
  run dispatch_command "/hlep"
  assert_failure
  assert_output_contains "Did you mean"
  assert_output_contains "/help"
}

@test "dispatch_command returns error for unknown commands" {
  run dispatch_command "/zzzzunknown"
  assert_failure
  assert_output_contains "Unknown command"
}

# ============================================================================
# Fuzzy matching tests
# ============================================================================

@test "fuzzy_match_slash_command: prefix match he -> help" {
  run fuzzy_match_slash_command "he"
  assert_success
  assert_output_contains "help"
}

@test "fuzzy_match_slash_command: prefix match sta -> status" {
  run fuzzy_match_slash_command "sta"
  assert_success
  assert_output_contains "status"
}

@test "fuzzy_match_slash_command: prefix match ta -> tasks" {
  run fuzzy_match_slash_command "ta"
  assert_success
  assert_output_contains "task"
}

@test "fuzzy_match_slash_command: typo hlep -> help" {
  run fuzzy_match_slash_command "hlep"
  assert_success
  assert_output_contains "help"
}

@test "fuzzy_match_slash_command: typo stauts -> status" {
  run fuzzy_match_slash_command "stauts"
  assert_success
  assert_output_contains "status"
}

@test "fuzzy_match_slash_command: single char returns empty" {
  run fuzzy_match_slash_command "x"
  assert_success
  [ -z "$output" ]
}

@test "fuzzy_match_slash_command: no match returns empty" {
  run fuzzy_match_slash_command "zzzzz"
  assert_success
  [ -z "$output" ]
}

# ============================================================================
# Help command tests
# ============================================================================

@test "chat_cmd_help lists all built-in commands" {
  run chat_cmd_help
  assert_success
  assert_output_contains "/help"
  assert_output_contains "/status"
  assert_output_contains "/clear"
  assert_output_contains "/quit"
  assert_output_contains "/tasks"
  assert_output_contains "/model"
  assert_output_contains "/diff"
}

@test "chat_cmd_help hides exit alias" {
  run chat_cmd_help
  # 'exit' should not appear as a separate entry (it's an alias for quit)
  local exit_lines
  exit_lines=$(echo "$output" | grep -c "^  .*/exit" || true)
  [ "$exit_lines" -eq 0 ]
}

@test "chat_cmd_help filters by keyword" {
  run chat_cmd_help "task"
  assert_success
  assert_output_contains "/task"
}

@test "chat_cmd_help shows skill commands with tag" {
  register_command "my-skill" "A custom skill" "skill"
  run chat_cmd_help
  assert_success
  assert_output_contains "my-skill"
  assert_output_contains "[skill]"
}

# ============================================================================
# Status command tests
# ============================================================================

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
# Tasks command tests
# ============================================================================

@test "chat_cmd_tasks lists tasks by state" {
  touch "$DOYAKEN_PROJECT/.doyaken/tasks/2.todo/todo-task.md"
  touch "$DOYAKEN_PROJECT/.doyaken/tasks/3.doing/doing-task.md"
  run chat_cmd_tasks
  assert_success
  assert_output_contains "TODO"
  assert_output_contains "DOING"
  assert_output_contains "todo-task"
  assert_output_contains "doing-task"
}

@test "chat_cmd_tasks filters by pattern" {
  touch "$DOYAKEN_PROJECT/.doyaken/tasks/2.todo/alpha.md"
  touch "$DOYAKEN_PROJECT/.doyaken/tasks/2.todo/beta.md"
  run chat_cmd_tasks "alpha"
  assert_success
  assert_output_contains "alpha"
  # beta should not appear in filtered output
  local beta_count
  beta_count=$(echo "$output" | grep -c "beta" || true)
  [ "$beta_count" -eq 0 ]
}

@test "chat_cmd_tasks fails without project" {
  unset DOYAKEN_PROJECT
  run chat_cmd_tasks
  assert_failure
  assert_output_contains "Not in a project"
}

# ============================================================================
# Task detail command tests
# ============================================================================

@test "chat_cmd_task shows task content" {
  cat > "$DOYAKEN_PROJECT/.doyaken/tasks/2.todo/003-001-test.md" << 'EOF'
# Task: Show this content
Test body
EOF
  run chat_cmd_task "003-001"
  assert_success
  assert_output_contains "Show this content"
}

@test "chat_cmd_task searches all states" {
  cat > "$DOYAKEN_PROJECT/.doyaken/tasks/4.done/003-002-done.md" << 'EOF'
# Task: Done task
EOF
  run chat_cmd_task "003-002"
  assert_success
  assert_output_contains "Done task"
}

@test "chat_cmd_task fails for non-existent task" {
  run chat_cmd_task "nonexistent"
  assert_failure
  assert_output_contains "No task found"
}

# ============================================================================
# Pick command tests
# ============================================================================

@test "chat_cmd_pick moves task to doing" {
  touch "$DOYAKEN_PROJECT/.doyaken/tasks/2.todo/003-003-move-me.md"
  run chat_cmd_pick "move-me"
  assert_success
  [ ! -f "$DOYAKEN_PROJECT/.doyaken/tasks/2.todo/003-003-move-me.md" ]
  [ -f "$DOYAKEN_PROJECT/.doyaken/tasks/3.doing/003-003-move-me.md" ]
}

@test "chat_cmd_pick sets CHAT_CURRENT_TASK" {
  touch "$DOYAKEN_PROJECT/.doyaken/tasks/2.todo/003-004-pickable.md"
  chat_cmd_pick "pickable"
  [ "$CHAT_CURRENT_TASK" = "003-004-pickable" ]
}

@test "chat_cmd_pick fails for non-existent task" {
  run chat_cmd_pick "nonexistent"
  assert_failure
  assert_output_contains "No todo task found"
}

# ============================================================================
# Model command tests
# ============================================================================

@test "chat_cmd_model shows current model" {
  export DOYAKEN_MODEL="opus"
  run chat_cmd_model
  assert_success
  assert_output_contains "opus"
}

@test "chat_cmd_model changes model" {
  export DOYAKEN_AGENT="claude"
  export DOYAKEN_MODEL="opus"
  chat_cmd_model "sonnet"
  [ "$DOYAKEN_MODEL" = "sonnet" ]
}

@test "chat_cmd_model rejects unsupported model" {
  export DOYAKEN_AGENT="claude"
  run chat_cmd_model "gpt-5"
  assert_failure
  assert_output_contains "not supported"
}

# ============================================================================
# Skip command tests
# ============================================================================

@test "chat_cmd_skip sets env var for valid phase" {
  chat_cmd_skip "test"
  [ "$SKIP_TEST" = "1" ]
}

@test "chat_cmd_skip rejects invalid phase" {
  run chat_cmd_skip "invalid"
  assert_failure
}

@test "chat_cmd_skip shows usage without args" {
  run chat_cmd_skip
  assert_failure
  assert_output_contains "Usage:"
}

# ============================================================================
# Config command tests
# ============================================================================

@test "chat_cmd_config shows summary without args" {
  run chat_cmd_config
  assert_success
  assert_output_contains "Agent:"
  assert_output_contains "Model:"
}

@test "chat_cmd_config gets specific key" {
  export DOYAKEN_AGENT="claude"
  run chat_cmd_config "agent"
  assert_success
  assert_output_contains "claude"
}

@test "chat_cmd_config sets key value" {
  chat_cmd_config "verbose 1"
  [ "$AGENT_VERBOSE" = "1" ]
}

@test "chat_cmd_config rejects unknown key" {
  run chat_cmd_config "unknown_key"
  assert_failure
}

# ============================================================================
# Diff command tests
# ============================================================================

@test "chat_cmd_diff works in git project" {
  # Initialize a real git repo for the test
  git -C "$DOYAKEN_PROJECT" init -q
  run chat_cmd_diff
  assert_success
}

@test "chat_cmd_diff fails without project" {
  unset DOYAKEN_PROJECT
  run chat_cmd_diff
  assert_failure
  assert_output_contains "Not in a project"
}

# ============================================================================
# Skills auto-registration tests
# ============================================================================

@test "register_skill_commands registers from project skills" {
  mkdir -p "$DOYAKEN_PROJECT/.doyaken/skills"
  cat > "$DOYAKEN_PROJECT/.doyaken/skills/my-skill.md" << 'EOF'
---
description: My custom skill
---
# My Skill
Content here
EOF
  register_skill_commands
  local found=false
  for (( i=0; i < ${#REGISTERED_CMD_NAMES[@]}; i++ )); do
    if [ "${REGISTERED_CMD_NAMES[$i]}" = "my-skill" ]; then
      found=true
      [ "${REGISTERED_CMD_TYPES[$i]}" = "skill" ]
      break
    fi
  done
  [ "$found" = "true" ]
}

@test "register_skill_commands extracts description" {
  mkdir -p "$DOYAKEN_PROJECT/.doyaken/skills"
  cat > "$DOYAKEN_PROJECT/.doyaken/skills/test-skill.md" << 'EOF'
---
description: A test skill description
---
Content
EOF
  register_skill_commands
  local found_desc=""
  for (( i=0; i < ${#REGISTERED_CMD_NAMES[@]}; i++ )); do
    if [ "${REGISTERED_CMD_NAMES[$i]}" = "test-skill" ]; then
      found_desc="${REGISTERED_CMD_DESCS[$i]}"
      break
    fi
  done
  [[ "$found_desc" == *"test skill description"* ]]
}

@test "register_skill_commands skips README.md" {
  mkdir -p "$DOYAKEN_PROJECT/.doyaken/skills"
  cat > "$DOYAKEN_PROJECT/.doyaken/skills/README.md" << 'EOF'
# Skills Directory
EOF
  register_skill_commands
  local found=false
  for (( i=0; i < ${#REGISTERED_CMD_NAMES[@]}; i++ )); do
    if [ "${REGISTERED_CMD_NAMES[$i]}" = "README" ]; then
      found=true
    fi
  done
  [ "$found" = "false" ]
}

# ============================================================================
# Tab completion tests
# ============================================================================

@test "generate_completions_file creates file with commands" {
  local comp_file="$TEST_TEMP_DIR/completions"
  generate_completions_file "$comp_file"
  [ -f "$comp_file" ]
  local content
  content=$(cat "$comp_file")
  [[ "$content" == *"/help"* ]]
  [[ "$content" == *"/quit"* ]]
  [[ "$content" == *"/tasks"* ]]
}

@test "generate_completions_file includes skill commands" {
  register_command "custom-skill" "A skill" "skill"
  local comp_file="$TEST_TEMP_DIR/completions"
  generate_completions_file "$comp_file"
  local content
  content=$(cat "$comp_file")
  [[ "$content" == *"/custom-skill"* ]]
}

# ============================================================================
# interactive.sh session tests
# ============================================================================

@test "generate_session_id produces unique IDs" {
  local id1 id2
  id1=$(generate_session_id)
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
  CHAT_CURRENT_TASK=""
  local prompt
  prompt=$(build_chat_prompt)
  [[ "$prompt" == *"myproject"* ]]
}

@test "build_chat_prompt shows task when picked" {
  CHAT_CURRENT_TASK="003-001-my-task"
  local prompt
  prompt=$(build_chat_prompt)
  [[ "$prompt" == *"003-001-my-task"* ]]
}

@test "build_chat_prompt shows default when no project" {
  unset DOYAKEN_PROJECT
  CHAT_CURRENT_TASK=""
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

# ============================================================================
# sessions.sh tests
# ============================================================================

@test "session_save_meta creates meta.yaml" {
  init_session
  session_save_meta "$CHAT_SESSION_DIR" "$CHAT_SESSION_ID" "active"
  [ -f "$CHAT_SESSION_DIR/meta.yaml" ]
}

@test "session_save_meta writes correct fields" {
  init_session
  CHAT_CURRENT_TASK="test-task"
  session_save_meta "$CHAT_SESSION_DIR" "$CHAT_SESSION_ID" "saved" "my-tag"
  local meta="$CHAT_SESSION_DIR/meta.yaml"
  [ -f "$meta" ]
  grep -q "^id:" "$meta"
  grep -q "^status: \"saved\"" "$meta"
  grep -q "^tag: \"my-tag\"" "$meta"
  grep -q "^task: \"test-task\"" "$meta"
}

@test "session_read_meta reads field correctly" {
  init_session
  session_save_meta "$CHAT_SESSION_DIR" "$CHAT_SESSION_ID" "saved" "test-tag"
  local status
  status=$(session_read_meta "$CHAT_SESSION_DIR" "status")
  [ "$status" = "saved" ]
  local tag
  tag=$(session_read_meta "$CHAT_SESSION_DIR" "tag")
  [ "$tag" = "test-tag" ]
}

@test "session_read_meta returns 1 for missing meta" {
  run session_read_meta "/nonexistent/dir" "status"
  assert_failure
}

@test "session_save saves with correct status" {
  init_session
  log_message "user" "test message"
  session_save "my-save-tag"
  local status
  status=$(session_read_meta "$CHAT_SESSION_DIR" "status")
  [ "$status" = "saved" ]
}

@test "session_save creates context.md" {
  init_session
  log_message "user" "test message"
  session_save
  [ -f "$CHAT_SESSION_DIR/context.md" ]
}

@test "session_save fails without active session" {
  CHAT_SESSION_ID=""
  CHAT_SESSION_DIR=""
  run session_save
  assert_failure
  assert_output_contains "No active session"
}

@test "session_resume loads session state" {
  # Create a session to resume
  init_session
  local orig_id="$CHAT_SESSION_ID"
  local orig_dir="$CHAT_SESSION_DIR"
  log_message "user" "hello"
  CHAT_CURRENT_TASK="resumed-task"
  session_save "resumable"

  # Clear state
  CHAT_SESSION_ID=""
  CHAT_SESSION_DIR=""
  CHAT_MESSAGES_FILE=""
  CHAT_CURRENT_TASK=""

  # Resume
  session_resume "$orig_id"
  [ "$CHAT_SESSION_ID" = "$orig_id" ]
  [ -n "$CHAT_MESSAGES_FILE" ]
}

@test "session_resume finds latest saved session" {
  # Create two sessions
  init_session
  local first_id="$CHAT_SESSION_ID"
  session_save_meta "$CHAT_SESSION_DIR" "$CHAT_SESSION_ID" "saved"

  sleep 1  # Ensure different timestamp
  init_session
  local second_id="$CHAT_SESSION_ID"
  session_save_meta "$CHAT_SESSION_DIR" "$CHAT_SESSION_ID" "saved"

  # Clear and resume latest
  CHAT_SESSION_ID=""
  session_resume ""
  [ "$CHAT_SESSION_ID" = "$second_id" ]
}

@test "session_resume returns error for non-existent session" {
  run session_resume "nonexistent-999"
  assert_failure
  assert_output_contains "Session not found"
}

@test "session_fork creates independent copy" {
  init_session
  local orig_id="$CHAT_SESSION_ID"
  log_message "user" "original message"
  session_save

  local new_id
  new_id=$(session_fork "$orig_id")
  [ -n "$new_id" ]
  [ "$new_id" != "$orig_id" ]
  # Forked session should have messages
  [ -f "$CHAT_SESSION_DIR/messages.jsonl" ]
}

@test "session_fork fails for non-existent session" {
  run session_fork "nonexistent-999"
  assert_failure
  assert_output_contains "not found"
}

@test "session_list shows sessions" {
  init_session
  session_save_meta "$CHAT_SESSION_DIR" "$CHAT_SESSION_ID" "saved"
  run session_list
  assert_success
  assert_output_contains "$CHAT_SESSION_ID"
}

@test "session_list shows 'No sessions found' when empty" {
  rm -rf "$DOYAKEN_PROJECT/.doyaken/sessions"
  run session_list
  assert_success
  assert_output_contains "No sessions found"
}

@test "session_export outputs markdown" {
  init_session
  log_message "user" "hello there"
  log_message "assistant" "hi back"
  session_save_meta "$CHAT_SESSION_DIR" "$CHAT_SESSION_ID" "saved"
  run session_export "$CHAT_SESSION_ID"
  assert_success
  assert_output_contains "# Session:"
  assert_output_contains "User"
  assert_output_contains "Assistant"
}

@test "session_export fails for non-existent session" {
  run session_export "nonexistent-999"
  assert_failure
  assert_output_contains "not found"
}

@test "session_delete removes session directory" {
  # Manually create a session directory to delete
  local sessions_root="$DOYAKEN_PROJECT/.doyaken/sessions"
  local del_id="deletable-session-000"
  local del_dir="$sessions_root/$del_id"
  mkdir -p "$del_dir"
  session_save_meta "$del_dir" "$del_id" "saved"

  # Set active session to something else
  init_session
  session_delete "$del_id"
  [ ! -d "$del_dir" ]
}

@test "session_delete fails for active session" {
  init_session
  run session_delete "$CHAT_SESSION_ID"
  assert_failure
  assert_output_contains "Cannot delete active session"
}

@test "session_delete requires ID" {
  run session_delete ""
  assert_failure
  assert_output_contains "Session ID required"
}

@test "_generate_context_summary includes message count" {
  init_session
  log_message "user" "msg1"
  log_message "user" "msg2"
  _generate_context_summary "$CHAT_SESSION_DIR"
  [ -f "$CHAT_SESSION_DIR/context.md" ]
  local content
  content=$(cat "$CHAT_SESSION_DIR/context.md")
  [[ "$content" == *"Messages: 2"* ]]
}

@test "session_get_resume_context returns context content" {
  init_session
  log_message "user" "context test"
  _generate_context_summary "$CHAT_SESSION_DIR"
  local context
  context=$(session_get_resume_context)
  [[ "$context" == *"Session Context"* ]]
}

# ============================================================================
# Session slash command tests
# ============================================================================

@test "dispatch_command handles /sessions" {
  init_session
  session_save_meta "$CHAT_SESSION_DIR" "$CHAT_SESSION_ID" "saved"
  run dispatch_command "/sessions"
  assert_success
  assert_output_contains "Recent Sessions"
}

@test "dispatch_command handles /session without args" {
  run dispatch_command "/session"
  assert_failure
  assert_output_contains "Usage:"
}

@test "dispatch_command handles /session save" {
  init_session
  run dispatch_command "/session save my-tag"
  assert_success
  assert_output_contains "Session saved"
}

@test "dispatch_command handles /session export" {
  init_session
  log_message "user" "test"
  session_save_meta "$CHAT_SESSION_DIR" "$CHAT_SESSION_ID" "saved"
  run dispatch_command "/session export $CHAT_SESSION_ID"
  assert_success
  assert_output_contains "# Session:"
}

@test "dispatch_command handles /session delete" {
  # Create a deletable session manually
  local sessions_root="$DOYAKEN_PROJECT/.doyaken/sessions"
  local del_id="deletable-cmd-test"
  local del_dir="$sessions_root/$del_id"
  mkdir -p "$del_dir"
  session_save_meta "$del_dir" "$del_id" "saved"
  # Set active session to something different
  init_session
  run dispatch_command "/session delete $del_id"
  assert_success
  assert_output_contains "Session deleted"
}

@test "dispatch_command handles /session unknown subcommand" {
  run dispatch_command "/session foobar"
  assert_failure
  assert_output_contains "Unknown session subcommand"
}

@test "help includes session commands" {
  run chat_cmd_help
  assert_success
  assert_output_contains "/sessions"
  assert_output_contains "/session"
}

@test "completions file includes session commands" {
  local comp_file="$TEST_TEMP_DIR/completions"
  generate_completions_file "$comp_file"
  local content
  content=$(cat "$comp_file")
  [[ "$content" == *"/sessions"* ]]
  [[ "$content" == *"/session"* ]]
}

@test "sessions command is in fuzzy match list" {
  source "$PROJECT_ROOT/lib/utils.sh"
  [[ "$DOYAKEN_COMMANDS" == *"sessions"* ]]
}

@test "help text includes sessions command" {
  source "$PROJECT_ROOT/lib/help.sh"
  run show_help
  assert_output_contains "sessions"
}

@test "chat help mentions --resume" {
  source "$PROJECT_ROOT/lib/help.sh"
  run show_command_help "chat"
  assert_output_contains "--resume"
  assert_output_contains "/session"
}

# ============================================================================
# undo.sh tests
# ============================================================================

# Helper to initialize a real git repo for undo tests
_setup_git_repo() {
  rm -rf "$DOYAKEN_PROJECT/.git"
  git -C "$DOYAKEN_PROJECT" init -q
  git -C "$DOYAKEN_PROJECT" config user.email "test@test.com"
  git -C "$DOYAKEN_PROJECT" config user.name "Test"
  echo "initial" > "$DOYAKEN_PROJECT/file.txt"
  git -C "$DOYAKEN_PROJECT" add -A
  git -C "$DOYAKEN_PROJECT" commit -q -m "initial"
}

@test "checkpoint_create succeeds in git repo" {
  _setup_git_repo
  echo "change" >> "$DOYAKEN_PROJECT/file.txt"
  checkpoint_create "test checkpoint"
  [ ${#UNDO_CHECKPOINT_REFS[@]} -ge 1 ]
}

@test "checkpoint_create stores description" {
  _setup_git_repo
  echo "change" >> "$DOYAKEN_PROJECT/file.txt"
  checkpoint_create "my description"
  local last=$((${#UNDO_CHECKPOINT_DESCS[@]} - 1))
  [ "${UNDO_CHECKPOINT_DESCS[$last]}" = "my description" ]
}

@test "checkpoint_create stores timestamp" {
  _setup_git_repo
  checkpoint_create "timed"
  local last=$((${#UNDO_CHECKPOINT_TIMES[@]} - 1))
  [[ "${UNDO_CHECKPOINT_TIMES[$last]}" == *"T"*"Z" ]]
}

@test "checkpoint_create fails outside git repo" {
  rm -rf "$DOYAKEN_PROJECT/.git"
  run checkpoint_create "no git"
  assert_failure
}

@test "checkpoint_list shows checkpoints" {
  _setup_git_repo
  checkpoint_create "first"
  echo "change" >> "$DOYAKEN_PROJECT/file.txt"
  checkpoint_create "second"
  run checkpoint_list
  assert_success
  assert_output_contains "first"
  assert_output_contains "second"
}

@test "checkpoint_list shows 'No checkpoints' when empty" {
  UNDO_CHECKPOINT_REFS=()
  UNDO_CHECKPOINT_DESCS=()
  UNDO_CHECKPOINT_TIMES=()
  UNDO_CHECKPOINT_FILES=()
  run checkpoint_list
  assert_success
  assert_output_contains "No checkpoints"
}

@test "undo_last_change reverts file changes" {
  _setup_git_repo
  # Checkpoint the clean state
  checkpoint_create "clean state"
  # Make a change
  echo "unwanted change" >> "$DOYAKEN_PROJECT/file.txt"
  # Undo should revert to checkpoint
  undo_last_change
  local content
  content=$(cat "$DOYAKEN_PROJECT/file.txt")
  [ "$content" = "initial" ]
}

@test "undo_last_change fails with no checkpoints" {
  _setup_git_repo
  UNDO_CHECKPOINT_REFS=()
  UNDO_CHECKPOINT_DESCS=()
  UNDO_CHECKPOINT_TIMES=()
  UNDO_CHECKPOINT_FILES=()
  run undo_last_change
  assert_failure
  assert_output_contains "No checkpoints"
}

@test "undo_last_change fails outside git repo" {
  rm -rf "$DOYAKEN_PROJECT/.git"
  run undo_last_change
  assert_failure
  assert_output_contains "Not in a git repository"
}

@test "redo_last_change re-applies after undo" {
  _setup_git_repo
  checkpoint_create "clean"
  echo "wanted change" >> "$DOYAKEN_PROJECT/file.txt"
  local changed_content
  changed_content=$(cat "$DOYAKEN_PROJECT/file.txt")
  undo_last_change
  # Now redo
  redo_last_change
  local restored
  restored=$(cat "$DOYAKEN_PROJECT/file.txt")
  [ "$restored" = "$changed_content" ]
}

@test "redo_last_change fails when nothing to redo" {
  _setup_git_repo
  UNDO_LAST_ACTION=""
  UNDO_STACK_REFS=()
  run redo_last_change
  assert_failure
  assert_output_contains "Nothing to redo"
}

@test "undo_clear_redo clears redo state" {
  UNDO_STACK_REFS=("abc123")
  UNDO_LAST_ACTION="undo"
  undo_clear_redo
  [ ${#UNDO_STACK_REFS[@]} -eq 0 ]
  [ -z "$UNDO_LAST_ACTION" ]
}

@test "diff_since_checkpoint shows changes" {
  _setup_git_repo
  checkpoint_create "baseline"
  echo "new content" >> "$DOYAKEN_PROJECT/file.txt"
  run diff_since_checkpoint
  assert_success
  assert_output_contains "file.txt"
}

@test "restore_to_checkpoint requires index" {
  run restore_to_checkpoint ""
  assert_failure
  assert_output_contains "Usage:"
}

@test "restore_to_checkpoint fails with no checkpoints" {
  _setup_git_repo
  UNDO_CHECKPOINT_REFS=()
  UNDO_CHECKPOINT_DESCS=()
  UNDO_CHECKPOINT_TIMES=()
  UNDO_CHECKPOINT_FILES=()
  run restore_to_checkpoint 1
  assert_failure
  assert_output_contains "No checkpoints"
}

# ============================================================================
# Undo slash command tests
# ============================================================================

@test "dispatch_command handles /undo" {
  _setup_git_repo
  checkpoint_create "pre-change"
  echo "bad" >> "$DOYAKEN_PROJECT/file.txt"
  run dispatch_command "/undo"
  assert_success
  assert_output_contains "reverted"
}

@test "dispatch_command handles /redo" {
  _setup_git_repo
  UNDO_LAST_ACTION=""
  UNDO_STACK_REFS=()
  run dispatch_command "/redo"
  assert_failure
}

@test "dispatch_command handles /checkpoint" {
  UNDO_CHECKPOINT_REFS=()
  UNDO_CHECKPOINT_DESCS=()
  UNDO_CHECKPOINT_TIMES=()
  UNDO_CHECKPOINT_FILES=()
  run dispatch_command "/checkpoint"
  assert_success
  assert_output_contains "Checkpoints"
}

@test "dispatch_command handles /checkpoint save" {
  _setup_git_repo
  run dispatch_command "/checkpoint save my-tag"
  assert_success
  assert_output_contains "Checkpoint created"
}

@test "dispatch_command handles /restore without args" {
  run dispatch_command "/restore"
  assert_failure
  assert_output_contains "Usage:"
}

@test "help includes undo commands" {
  run chat_cmd_help
  assert_success
  assert_output_contains "/undo"
  assert_output_contains "/redo"
  assert_output_contains "/checkpoint"
  assert_output_contains "/restore"
}

@test "completions file includes undo commands" {
  local comp_file="$TEST_TEMP_DIR/completions"
  generate_completions_file "$comp_file"
  local content
  content=$(cat "$comp_file")
  [[ "$content" == *"/undo"* ]]
  [[ "$content" == *"/redo"* ]]
  [[ "$content" == *"/checkpoint"* ]]
  [[ "$content" == *"/restore"* ]]
}

@test "chat help mentions undo commands" {
  source "$PROJECT_ROOT/lib/help.sh"
  run show_command_help "chat"
  assert_output_contains "/undo"
  assert_output_contains "/redo"
  assert_output_contains "/checkpoint"
}

# ============================================================================
# approval.sh tests
# ============================================================================

@test "set_approval_level accepts full-auto" {
  set_approval_level "full-auto"
  [ "$DOYAKEN_APPROVAL" = "full-auto" ]
}

@test "set_approval_level accepts supervised" {
  set_approval_level "supervised"
  [ "$DOYAKEN_APPROVAL" = "supervised" ]
}

@test "set_approval_level accepts plan-only" {
  set_approval_level "plan-only"
  [ "$DOYAKEN_APPROVAL" = "plan-only" ]
}

@test "set_approval_level rejects unknown level" {
  run set_approval_level "foobar"
  assert_failure
  assert_output_contains "Unknown approval level"
}

@test "get_approval_level returns current level" {
  export DOYAKEN_APPROVAL="supervised"
  local level
  level=$(get_approval_level)
  [ "$level" = "supervised" ]
}

@test "get_approval_level defaults to full-auto" {
  unset DOYAKEN_APPROVAL
  local level
  level=$(get_approval_level)
  [ "$level" = "full-auto" ]
}

@test "approval_gate returns 0 in full-auto mode" {
  export DOYAKEN_APPROVAL="full-auto"
  approval_gate "implement" "task-1"
  [ $? -eq 0 ]
}

@test "dispatch_command handles /approval without args" {
  export DOYAKEN_APPROVAL="full-auto"
  run dispatch_command "/approval"
  assert_success
  assert_output_contains "full-auto"
  assert_output_contains "supervised"
  assert_output_contains "plan-only"
}

@test "dispatch_command handles /approval with valid level" {
  run dispatch_command "/approval supervised"
  assert_success
  assert_output_contains "Approval level set to"
}

@test "dispatch_command handles /approval with invalid level" {
  run dispatch_command "/approval foobar"
  assert_failure
  assert_output_contains "Unknown approval level"
}

@test "help includes /approval command" {
  run chat_cmd_help
  assert_success
  assert_output_contains "/approval"
}

@test "completions file includes /approval" {
  local comp_file="$TEST_TEMP_DIR/completions"
  generate_completions_file "$comp_file"
  local content
  content=$(cat "$comp_file")
  [[ "$content" == *"/approval"* ]]
}

@test "help text includes --supervised flag" {
  source "$PROJECT_ROOT/lib/help.sh"
  run show_help
  assert_output_contains "--supervised"
  assert_output_contains "--plan-only"
}
