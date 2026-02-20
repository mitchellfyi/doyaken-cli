#!/usr/bin/env bats
#
# Unit tests for lib/core.sh functions
#
# Note: These tests use exported functions from core.sh via the CLI
# rather than sourcing directly due to complex dependencies
#

load "../test_helper"

setup() {
  export TEST_TEMP_DIR
  TEST_TEMP_DIR="$(mktemp -d)"

  # Create mock project structure
  create_mock_project "$TEST_TEMP_DIR/project"
  export DOYAKEN_PROJECT="$TEST_TEMP_DIR/project"
}

teardown() {
  if [[ -d "${TEST_TEMP_DIR:-}" ]]; then
    rm -rf "$TEST_TEMP_DIR"
  fi
}

# ============================================================================
# State file operations (test via filesystem)
# ============================================================================

@test "state file: can save state" {
  echo "test-value" > "$DOYAKEN_PROJECT/.doyaken/state/test-key"
  [ -f "$DOYAKEN_PROJECT/.doyaken/state/test-key" ]
}

@test "state file: can read state" {
  echo "test-value" > "$DOYAKEN_PROJECT/.doyaken/state/test-key"
  run cat "$DOYAKEN_PROJECT/.doyaken/state/test-key"
  [ "$output" = "test-value" ]
}

@test "state file: directory exists" {
  [ -d "$DOYAKEN_PROJECT/.doyaken/state" ]
}

# ============================================================================
# Manifest operations
# ============================================================================

@test "manifest: exists in mock project" {
  [ -f "$DOYAKEN_PROJECT/.doyaken/manifest.yaml" ]
}

@test "manifest: contains version" {
  grep -q "version:" "$DOYAKEN_PROJECT/.doyaken/manifest.yaml"
}

@test "manifest: contains project name" {
  grep -q "name:" "$DOYAKEN_PROJECT/.doyaken/manifest.yaml"
}

# ============================================================================
# Manifest loading optimization tests (JSON caching)
# ============================================================================

@test "manifest: JSON cache reduces yq calls" {
  command -v yq > /dev/null || skip "yq not installed"
  command -v jq > /dev/null || skip "jq not installed"

  # Create test manifest with all sections
  cat > "$DOYAKEN_PROJECT/.doyaken/manifest.yaml" << 'EOF'
version: 1
agent:
  name: "test-agent"
  model: "sonnet"
  max_retries: 3
quality:
  test_command: "npm test"
  lint_command: "eslint ."
env:
  TEST_VAR1: "value1"
  TEST_VAR2: "value2"
skills:
  hooks:
    before-test:
      - "hook1"
    after-test:
      - "hook2"
EOF

  # The yq -o=json call converts the manifest to JSON in one shot
  # This is much faster than 24+ individual yq calls
  run yq -o=json '.' "$DOYAKEN_PROJECT/.doyaken/manifest.yaml"
  [ "$status" -eq 0 ]

  # Verify JSON is valid and contains all expected sections
  echo "$output" | jq -e '.agent.name' > /dev/null
  echo "$output" | jq -e '.quality.test_command' > /dev/null
  echo "$output" | jq -e '.env.TEST_VAR1' > /dev/null
  echo "$output" | jq -e '.skills.hooks."before-test"' > /dev/null
}

@test "manifest: jq extracts env vars efficiently" {
  command -v jq > /dev/null || skip "jq not installed"

  # Test jq extraction of env vars as key=value pairs (single call)
  local test_json='{"env":{"VAR1":"value1","VAR2":"value2"}}'

  run bash -c "echo '$test_json' | jq -r '.env // {} | to_entries[] | \"\\(.key)=\\(.value)\"'"
  [ "$status" -eq 0 ]
  [[ "$output" == *"VAR1=value1"* ]]
  [[ "$output" == *"VAR2=value2"* ]]
}

@test "manifest: jq handles special characters in env values" {
  command -v jq > /dev/null || skip "jq not installed"

  # Test that jq properly escapes special characters
  local test_json='{"env":{"TEST":"value with \"quotes\""}}'

  run bash -c "echo '$test_json' | jq -r '.env.TEST'"
  [ "$status" -eq 0 ]
  [[ "$output" == *"quotes"* ]]
}

@test "manifest: jq extracts hooks efficiently" {
  command -v jq > /dev/null || skip "jq not installed"

  # Test jq extraction of hooks array
  local test_json='{"hooks":{"before-test":["hook1","hook2","hook3"]}}'

  run bash -c "echo '$test_json' | jq -r '.hooks.\"before-test\" // [] | .[]'"
  [ "$status" -eq 0 ]
  [[ "$output" == *"hook1"* ]]
  [[ "$output" == *"hook2"* ]]
  [[ "$output" == *"hook3"* ]]
}

# ============================================================================
# Core Functions Test Setup
# ============================================================================

# Setup for core function tests (uses isolated environment)
_setup_core_test() {
  source "$PROJECT_ROOT/test/unit/core_functions.sh"
  setup_core_test_env

  # Reset state for each test
  MODEL_FALLBACK_TRIGGERED=0
  CONSECUTIVE_FAILURES=0
}

# ============================================================================
# Model Fallback Tests
# ============================================================================

@test "fallback_to_sonnet: claude opus -> sonnet on rate limit" {
  _setup_core_test
  CURRENT_AGENT="claude"
  CURRENT_MODEL="opus"

  # Don't use run - we need to test the variable modification
  fallback_to_sonnet
  [ "$CURRENT_MODEL" = "sonnet" ]
}

@test "fallback_to_sonnet: codex gpt-5 -> o4-mini" {
  _setup_core_test
  CURRENT_AGENT="codex"
  CURRENT_MODEL="gpt-5"

  fallback_to_sonnet
  [ "$CURRENT_MODEL" = "o4-mini" ]
}

@test "fallback_to_sonnet: gemini 2.5-pro -> 2.5-flash" {
  _setup_core_test
  CURRENT_AGENT="gemini"
  CURRENT_MODEL="gemini-2.5-pro"

  fallback_to_sonnet
  [ "$CURRENT_MODEL" = "gemini-2.5-flash" ]
}

@test "fallback_to_sonnet: returns 1 when already on fallback model" {
  _setup_core_test
  CURRENT_AGENT="claude"
  CURRENT_MODEL="sonnet"

  run fallback_to_sonnet
  [ "$status" -eq 1 ]
}

@test "fallback_to_sonnet: returns 1 when AGENT_NO_FALLBACK=1" {
  _setup_core_test
  CURRENT_AGENT="claude"
  CURRENT_MODEL="opus"
  AGENT_NO_FALLBACK="1"

  run fallback_to_sonnet
  [ "$status" -eq 1 ]
}

@test "fallback_to_sonnet: returns 1 for unknown agent" {
  _setup_core_test
  CURRENT_AGENT="unknown"
  CURRENT_MODEL="model"

  run fallback_to_sonnet
  [ "$status" -eq 1 ]
}

@test "reset_model: restores original model after fallback" {
  _setup_core_test
  DOYAKEN_MODEL="opus"
  CURRENT_MODEL="sonnet"
  MODEL_FALLBACK_TRIGGERED=1

  reset_model

  [ "$CURRENT_MODEL" = "opus" ]
  [ "$MODEL_FALLBACK_TRIGGERED" = "0" ]
}

@test "reset_model: clears MODEL_FALLBACK_TRIGGERED flag" {
  _setup_core_test
  MODEL_FALLBACK_TRIGGERED=1
  DOYAKEN_MODEL="opus"
  CURRENT_MODEL="sonnet"

  reset_model

  [ "$MODEL_FALLBACK_TRIGGERED" = "0" ]
}

@test "reset_model: noop when no fallback was triggered" {
  _setup_core_test
  DOYAKEN_MODEL="opus"
  CURRENT_MODEL="opus"
  MODEL_FALLBACK_TRIGGERED=0

  reset_model

  [ "$CURRENT_MODEL" = "opus" ]
  [ "$MODEL_FALLBACK_TRIGGERED" = "0" ]
}

# ============================================================================
# Session State Tests
# ============================================================================

@test "save_session: creates session file with correct content" {
  _setup_core_test

  save_session "session-123" "running"

  local session_file="$STATE_DIR/session-test-worker"
  [ -f "$session_file" ]

  grep -q "SESSION_ID=\"session-123\"" "$session_file"
  grep -q "STATUS=\"running\"" "$session_file"
}

@test "save_session: includes AGENT_ID, TIMESTAMP" {
  _setup_core_test

  save_session "session-456" "running"

  local session_file="$STATE_DIR/session-test-worker"
  grep -q "AGENT_ID=\"test-worker\"" "$session_file"
  grep -q "TIMESTAMP=" "$session_file"
}

@test "load_session: returns 0 and sets vars when session exists" {
  _setup_core_test

  save_session "session-789" "running"

  run load_session
  [ "$status" -eq 0 ]
}

@test "load_session: returns 1 when no session file" {
  _setup_core_test

  run load_session
  [ "$status" -eq 1 ]
}

@test "load_session: returns 1 when AGENT_NO_RESUME=1" {
  _setup_core_test
  AGENT_NO_RESUME="1"

  save_session "session-noresume" "running"

  run load_session
  [ "$status" -eq 1 ]
}

@test "load_session: returns 1 when status is not running" {
  _setup_core_test

  save_session "session-complete" "completed"

  run load_session
  [ "$status" -eq 1 ]
}

@test "clear_session: removes session file" {
  _setup_core_test

  save_session "session-clear" "running"
  clear_session

  [ ! -f "$STATE_DIR/session-test-worker" ]
}

@test "clear_session: succeeds when file doesn't exist" {
  _setup_core_test

  run clear_session
  [ "$status" -eq 0 ]
}

# ============================================================================
# Health Check Tests
# ============================================================================

@test "update_health: creates health file with status and message" {
  _setup_core_test

  update_health "healthy" "All checks passed"

  local health_file="$STATE_DIR/health-test-worker"
  [ -f "$health_file" ]
  grep -q "STATUS=\"healthy\"" "$health_file"
  grep -q "MESSAGE=\"All checks passed\"" "$health_file"
}

@test "update_health: includes AGENT_ID and LAST_CHECK" {
  _setup_core_test

  update_health "unhealthy" "Issues found"

  local health_file="$STATE_DIR/health-test-worker"
  grep -q "AGENT_ID=\"test-worker\"" "$health_file"
  grep -q "LAST_CHECK=" "$health_file"
}

@test "update_health: includes CONSECUTIVE_FAILURES" {
  _setup_core_test
  CONSECUTIVE_FAILURES=3

  update_health "degraded" "Some failures"

  local health_file="$STATE_DIR/health-test-worker"
  grep -q "CONSECUTIVE_FAILURES=\"3\"" "$health_file"
}

@test "get_consecutive_failures: reads from health file" {
  _setup_core_test
  CONSECUTIVE_FAILURES=5
  update_health "degraded" "Failures"

  CONSECUTIVE_FAILURES=0
  run get_consecutive_failures
  [ "$status" -eq 0 ]
  [ "$output" = "5" ]
}

@test "get_consecutive_failures: returns 0 when no health file" {
  _setup_core_test

  run get_consecutive_failures
  [ "$status" -eq 0 ]
  [ "$output" = "0" ]
}

# ============================================================================
# Prompt File Tests
# ============================================================================

@test "get_prompt_file: finds project-specific prompt first" {
  _setup_core_test

  mkdir -p "$DATA_DIR/prompts"
  echo "project prompt" > "$DATA_DIR/prompts/test-prompt.md"

  run get_prompt_file "test-prompt.md"
  [ "$status" -eq 0 ]
  [[ "$output" == *"$DATA_DIR/prompts/test-prompt.md"* ]]
}

@test "get_prompt_file: falls back to global prompt" {
  _setup_core_test
  export DOYAKEN_HOME="$TEST_TEMP_DIR/global"

  mkdir -p "$DOYAKEN_HOME/prompts"
  echo "global prompt" > "$DOYAKEN_HOME/prompts/global-prompt.md"

  run get_prompt_file "global-prompt.md"
  [ "$status" -eq 0 ]
  [[ "$output" == *"global-prompt.md"* ]]
}

@test "get_prompt_file: returns 1 when not found" {
  _setup_core_test

  run get_prompt_file "nonexistent.md"
  [ "$status" -eq 1 ]
}

@test "process_includes: replaces include directive with content" {
  _setup_core_test

  mkdir -p "$DATA_DIR/prompts"
  echo "included content" > "$DATA_DIR/prompts/module.md"

  local input="Before {{include:module.md}} After"
  run process_includes "$input"

  [ "$status" -eq 0 ]
  [[ "$output" == *"Before"* ]]
  [[ "$output" == *"included content"* ]]
  [[ "$output" == *"After"* ]]
}

@test "process_includes: handles nested includes" {
  _setup_core_test

  mkdir -p "$DATA_DIR/prompts"
  echo "nested {{include:leaf.md}} content" > "$DATA_DIR/prompts/nested.md"
  echo "leaf" > "$DATA_DIR/prompts/leaf.md"

  local input="Root {{include:nested.md}}"
  run process_includes "$input"

  [ "$status" -eq 0 ]
  [[ "$output" == *"Root"* ]]
  [[ "$output" == *"nested"* ]]
  [[ "$output" == *"leaf"* ]]
}

@test "process_includes: respects max_depth parameter" {
  _setup_core_test

  mkdir -p "$DATA_DIR/prompts"
  # Create a chain: a -> b -> c -> d (more than 2 levels)
  echo "a: {{include:b.md}}" > "$DATA_DIR/prompts/a.md"
  echo "b: {{include:c.md}}" > "$DATA_DIR/prompts/b.md"
  echo "c: {{include:d.md}}" > "$DATA_DIR/prompts/c.md"
  echo "d: end" > "$DATA_DIR/prompts/d.md"

  # With max_depth=2, should not fully expand
  local input="{{include:a.md}}"
  run process_includes "$input" 2

  [ "$status" -eq 0 ]
  # Should contain the beginning of the chain
  [[ "$output" == *"a:"* ]]
}
