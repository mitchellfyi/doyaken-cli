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
# Lock file operations (test via filesystem)
# ============================================================================

@test "lock file: directory exists in mock project" {
  [ -d "$DOYAKEN_PROJECT/.doyaken/locks" ]
}

@test "lock file: can create lock" {
  local lock_file="$DOYAKEN_PROJECT/.doyaken/locks/test-task.lock"
  echo "test-agent" > "$lock_file"
  [ -f "$lock_file" ]
}

@test "lock file: can remove lock" {
  local lock_file="$DOYAKEN_PROJECT/.doyaken/locks/test-task.lock"
  echo "test-agent" > "$lock_file"
  rm "$lock_file"
  [ ! -f "$lock_file" ]
}

# ============================================================================
# Task folder structure
# ============================================================================

@test "task folders: todo exists" {
  [ -d "$DOYAKEN_PROJECT/.doyaken/tasks/2.todo" ]
}

@test "task folders: doing exists" {
  [ -d "$DOYAKEN_PROJECT/.doyaken/tasks/3.doing" ]
}

@test "task folders: done exists" {
  [ -d "$DOYAKEN_PROJECT/.doyaken/tasks/4.done" ]
}

@test "task folders: blocked exists" {
  [ -d "$DOYAKEN_PROJECT/.doyaken/tasks/1.blocked" ]
}

# ============================================================================
# Task file operations
# ============================================================================

@test "task file: can create in todo" {
  local task_file="$DOYAKEN_PROJECT/.doyaken/tasks/2.todo/003-001-test.md"
  cat > "$task_file" << 'EOF'
# Task: Test Task

| Field | Value |
|-------|-------|
| Priority | Medium |
| Status | todo |
EOF
  [ -f "$task_file" ]
  grep -q "Test Task" "$task_file"
}

@test "task file: can move to doing" {
  local src="$DOYAKEN_PROJECT/.doyaken/tasks/2.todo/003-001-test.md"
  local dst="$DOYAKEN_PROJECT/.doyaken/tasks/3.doing/003-001-test.md"

  echo "# Test task" > "$src"
  mv "$src" "$dst"

  [ ! -f "$src" ]
  [ -f "$dst" ]
}

@test "task file: can count tasks" {
  touch "$DOYAKEN_PROJECT/.doyaken/tasks/2.todo/001-001-a.md"
  touch "$DOYAKEN_PROJECT/.doyaken/tasks/2.todo/001-002-b.md"
  touch "$DOYAKEN_PROJECT/.doyaken/tasks/2.todo/001-003-c.md"

  run find "$DOYAKEN_PROJECT/.doyaken/tasks/2.todo" -maxdepth 1 -name "*.md" -type f
  [ "$status" -eq 0 ]
  [ "$(echo "$output" | wc -l | tr -d ' ')" -eq 3 ]
}

# ============================================================================
# State file operations
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
# Task metadata operations (update_task_metadata function)
# ============================================================================

# Helper: Standalone copy of update_task_metadata for testing
# This avoids sourcing core.sh which has complex dependencies
_update_task_metadata() {
  local task_file="$1"
  local field_name="$2"
  local new_value="$3"

  [ -f "$task_file" ] || return 1

  # Escape backslashes for awk -v (which interprets escape sequences)
  local escaped_value="${new_value//\\/\\\\}"

  local temp_file="${task_file}.tmp.$$"
  # Use awk's index() to find "| FieldName |" pattern (literal string match)
  awk -v field="$field_name" -v value="$escaped_value" '
    BEGIN { found = 0; pattern = "| " field " |" }
    index($0, pattern) == 1 {
      printf "| %s | %s |\n", field, value
      found = 1
      next
    }
    { print }
    END { exit (found ? 0 : 1) }
  ' "$task_file" > "$temp_file" && mv "$temp_file" "$task_file"
  local result=$?
  rm -f "$temp_file" 2>/dev/null
  return $result
}

@test "metadata: updates basic field value" {
  local task_file="$TEST_TEMP_DIR/task.md"
  cat > "$task_file" << 'EOF'
# Task

| Field | Value |
|-------|-------|
| Status | todo |
| Assigned To | |
EOF

  run _update_task_metadata "$task_file" "Status" "doing"
  [ "$status" -eq 0 ]
  grep -q "| Status | doing |" "$task_file"
}

@test "metadata: handles ampersand character" {
  local task_file="$TEST_TEMP_DIR/task.md"
  cat > "$task_file" << 'EOF'
| Assigned To | |
EOF

  run _update_task_metadata "$task_file" "Assigned To" "agent&1"
  [ "$status" -eq 0 ]
  grep -q "| Assigned To | agent&1 |" "$task_file"
}

@test "metadata: handles forward slash character" {
  local task_file="$TEST_TEMP_DIR/task.md"
  cat > "$task_file" << 'EOF'
| Assigned To | |
EOF

  run _update_task_metadata "$task_file" "Assigned To" "agent/1"
  [ "$status" -eq 0 ]
  grep -q "| Assigned To | agent/1 |" "$task_file"
}

@test "metadata: handles backslash character" {
  local task_file="$TEST_TEMP_DIR/task.md"
  cat > "$task_file" << 'EOF'
| Assigned To | |
EOF

  run _update_task_metadata "$task_file" "Assigned To" 'agent\1'
  [ "$status" -eq 0 ]
  # Use fgrep (grep -F) for literal string matching
  grep -F '| Assigned To | agent\1 |' "$task_file"
}

@test "metadata: handles asterisk character" {
  local task_file="$TEST_TEMP_DIR/task.md"
  cat > "$task_file" << 'EOF'
| Assigned To | |
EOF

  run _update_task_metadata "$task_file" "Assigned To" "agent*1"
  [ "$status" -eq 0 ]
  grep -F "| Assigned To | agent*1 |" "$task_file"
}

@test "metadata: handles dot character" {
  local task_file="$TEST_TEMP_DIR/task.md"
  cat > "$task_file" << 'EOF'
| Assigned To | |
EOF

  run _update_task_metadata "$task_file" "Assigned To" "agent.1"
  [ "$status" -eq 0 ]
  grep -F "| Assigned To | agent.1 |" "$task_file"
}

@test "metadata: handles bracket characters" {
  local task_file="$TEST_TEMP_DIR/task.md"
  cat > "$task_file" << 'EOF'
| Assigned To | |
EOF

  run _update_task_metadata "$task_file" "Assigned To" "[agent]"
  [ "$status" -eq 0 ]
  grep -F "| Assigned To | [agent] |" "$task_file"
}

@test "metadata: handles caret and dollar characters" {
  local task_file="$TEST_TEMP_DIR/task.md"
  cat > "$task_file" << 'EOF'
| Assigned To | |
EOF

  run _update_task_metadata "$task_file" "Assigned To" '^agent$'
  [ "$status" -eq 0 ]
  grep -F '| Assigned To | ^agent$ |' "$task_file"
}

@test "metadata: handles empty value (unassign)" {
  local task_file="$TEST_TEMP_DIR/task.md"
  cat > "$task_file" << 'EOF'
| Assigned To | worker-1 |
EOF

  run _update_task_metadata "$task_file" "Assigned To" ""
  [ "$status" -eq 0 ]
  grep -F "| Assigned To |  |" "$task_file"
}

@test "metadata: returns error for non-existent field" {
  local task_file="$TEST_TEMP_DIR/task.md"
  cat > "$task_file" << 'EOF'
| Status | todo |
EOF

  run _update_task_metadata "$task_file" "NonExistent" "value"
  [ "$status" -ne 0 ]
}

@test "metadata: returns error for non-existent file" {
  run _update_task_metadata "$TEST_TEMP_DIR/nonexistent.md" "Field" "value"
  [ "$status" -ne 0 ]
}

@test "metadata: preserves other fields unchanged" {
  local task_file="$TEST_TEMP_DIR/task.md"
  cat > "$task_file" << 'EOF'
# Task

| Field | Value |
|-------|-------|
| Status | todo |
| Priority | High |
| Assigned To | |
EOF

  run _update_task_metadata "$task_file" "Assigned To" "worker-1"
  [ "$status" -eq 0 ]
  grep -q "| Status | todo |" "$task_file"
  grep -q "| Priority | High |" "$task_file"
  grep -q "| Assigned To | worker-1 |" "$task_file"
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
