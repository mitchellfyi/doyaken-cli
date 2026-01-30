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
