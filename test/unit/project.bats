#!/usr/bin/env bats
#
# Unit tests for lib/project.sh
#
# Tests: count_files(), count_task_files(), count_files_excluding_gitkeep(),
#        get_priority_label(), rename_task_priority()
#

load "../test_helper"

setup() {
  export TEST_TEMP_DIR
  TEST_TEMP_DIR="$(mktemp -d)"

  # Source project.sh (need logging stubs since it doesn't source them)
  log_error() { :; }
  log_info() { :; }
  export -f log_error log_info

  source "$PROJECT_ROOT/lib/project.sh"
}

teardown() {
  if [[ -d "${TEST_TEMP_DIR:-}" ]]; then
    rm -rf "$TEST_TEMP_DIR"
  fi
}

# ============================================================================
# count_files() tests
# ============================================================================

@test "count_files: empty directory returns 0" {
  mkdir -p "$TEST_TEMP_DIR/empty"

  run count_files "$TEST_TEMP_DIR/empty"
  [ "$status" -eq 0 ]
  [ "$output" = "0" ]
}

@test "count_files: missing directory returns 0" {
  run count_files "$TEST_TEMP_DIR/nonexistent"
  [ "$status" -eq 0 ]
  [ "$output" = "0" ]
}

@test "count_files: counts all files when no pattern specified" {
  mkdir -p "$TEST_TEMP_DIR/files"
  touch "$TEST_TEMP_DIR/files/a.txt"
  touch "$TEST_TEMP_DIR/files/b.md"
  touch "$TEST_TEMP_DIR/files/c.sh"

  run count_files "$TEST_TEMP_DIR/files"
  [ "$status" -eq 0 ]
  [ "$output" = "3" ]
}

@test "count_files: respects pattern parameter" {
  mkdir -p "$TEST_TEMP_DIR/files"
  touch "$TEST_TEMP_DIR/files/a.txt"
  touch "$TEST_TEMP_DIR/files/b.txt"
  touch "$TEST_TEMP_DIR/files/c.md"

  run count_files "$TEST_TEMP_DIR/files" "*.txt"
  [ "$status" -eq 0 ]
  [ "$output" = "2" ]
}

@test "count_files: ignores subdirectories" {
  mkdir -p "$TEST_TEMP_DIR/files/subdir"
  touch "$TEST_TEMP_DIR/files/a.txt"
  touch "$TEST_TEMP_DIR/files/subdir/b.txt"

  run count_files "$TEST_TEMP_DIR/files" "*.txt"
  [ "$status" -eq 0 ]
  [ "$output" = "1" ]
}

@test "count_files: ignores directories matching pattern" {
  mkdir -p "$TEST_TEMP_DIR/files"
  mkdir -p "$TEST_TEMP_DIR/files/test.txt"  # directory, not file
  touch "$TEST_TEMP_DIR/files/real.txt"

  run count_files "$TEST_TEMP_DIR/files" "*.txt"
  [ "$status" -eq 0 ]
  [ "$output" = "1" ]
}

@test "count_files: handles files with spaces in names" {
  mkdir -p "$TEST_TEMP_DIR/files"
  touch "$TEST_TEMP_DIR/files/file with spaces.txt"
  touch "$TEST_TEMP_DIR/files/another file.txt"

  run count_files "$TEST_TEMP_DIR/files" "*.txt"
  [ "$status" -eq 0 ]
  [ "$output" = "2" ]
}

# ============================================================================
# count_task_files() tests
# ============================================================================

@test "count_task_files: counts only .md files" {
  mkdir -p "$TEST_TEMP_DIR/tasks"
  touch "$TEST_TEMP_DIR/tasks/001-task.md"
  touch "$TEST_TEMP_DIR/tasks/002-task.md"
  touch "$TEST_TEMP_DIR/tasks/readme.txt"
  touch "$TEST_TEMP_DIR/tasks/.gitkeep"

  run count_task_files "$TEST_TEMP_DIR/tasks"
  [ "$status" -eq 0 ]
  [ "$output" = "2" ]
}

@test "count_task_files: returns 0 for empty directory" {
  mkdir -p "$TEST_TEMP_DIR/tasks"

  run count_task_files "$TEST_TEMP_DIR/tasks"
  [ "$status" -eq 0 ]
  [ "$output" = "0" ]
}

@test "count_task_files: returns 0 for missing directory" {
  run count_task_files "$TEST_TEMP_DIR/nonexistent"
  [ "$status" -eq 0 ]
  [ "$output" = "0" ]
}

@test "count_task_files: does not count nested md files" {
  mkdir -p "$TEST_TEMP_DIR/tasks/archive"
  touch "$TEST_TEMP_DIR/tasks/001-task.md"
  touch "$TEST_TEMP_DIR/tasks/archive/old-task.md"

  run count_task_files "$TEST_TEMP_DIR/tasks"
  [ "$status" -eq 0 ]
  [ "$output" = "1" ]
}

# ============================================================================
# count_files_excluding_gitkeep() tests
# ============================================================================

@test "count_files_excluding_gitkeep: excludes .gitkeep" {
  mkdir -p "$TEST_TEMP_DIR/dir"
  touch "$TEST_TEMP_DIR/dir/.gitkeep"
  touch "$TEST_TEMP_DIR/dir/file1.txt"
  touch "$TEST_TEMP_DIR/dir/file2.txt"

  run count_files_excluding_gitkeep "$TEST_TEMP_DIR/dir"
  [ "$status" -eq 0 ]
  [ "$output" = "2" ]
}

@test "count_files_excluding_gitkeep: returns 0 for directory with only .gitkeep" {
  mkdir -p "$TEST_TEMP_DIR/dir"
  touch "$TEST_TEMP_DIR/dir/.gitkeep"

  run count_files_excluding_gitkeep "$TEST_TEMP_DIR/dir"
  [ "$status" -eq 0 ]
  [ "$output" = "0" ]
}

@test "count_files_excluding_gitkeep: returns 0 for empty directory" {
  mkdir -p "$TEST_TEMP_DIR/dir"

  run count_files_excluding_gitkeep "$TEST_TEMP_DIR/dir"
  [ "$status" -eq 0 ]
  [ "$output" = "0" ]
}

@test "count_files_excluding_gitkeep: returns 0 for missing directory" {
  run count_files_excluding_gitkeep "$TEST_TEMP_DIR/nonexistent"
  [ "$status" -eq 0 ]
  [ "$output" = "0" ]
}

@test "count_files_excluding_gitkeep: counts hidden files except .gitkeep" {
  mkdir -p "$TEST_TEMP_DIR/dir"
  touch "$TEST_TEMP_DIR/dir/.gitkeep"
  touch "$TEST_TEMP_DIR/dir/.hidden"
  touch "$TEST_TEMP_DIR/dir/visible.txt"

  run count_files_excluding_gitkeep "$TEST_TEMP_DIR/dir"
  [ "$status" -eq 0 ]
  [ "$output" = "2" ]
}

@test "count_files_excluding_gitkeep: ignores subdirectories" {
  mkdir -p "$TEST_TEMP_DIR/dir/subdir"
  touch "$TEST_TEMP_DIR/dir/file.txt"
  touch "$TEST_TEMP_DIR/dir/subdir/nested.txt"

  run count_files_excluding_gitkeep "$TEST_TEMP_DIR/dir"
  [ "$status" -eq 0 ]
  [ "$output" = "1" ]
}

# ============================================================================
# get_priority_label() tests
# ============================================================================

@test "get_priority_label: 001 returns Critical" {
  run get_priority_label "001"
  [ "$status" -eq 0 ]
  [ "$output" = "Critical" ]
}

@test "get_priority_label: 002 returns High" {
  run get_priority_label "002"
  [ "$status" -eq 0 ]
  [ "$output" = "High" ]
}

@test "get_priority_label: 003 returns Medium" {
  run get_priority_label "003"
  [ "$status" -eq 0 ]
  [ "$output" = "Medium" ]
}

@test "get_priority_label: 004 returns Low" {
  run get_priority_label "004"
  [ "$status" -eq 0 ]
  [ "$output" = "Low" ]
}

@test "get_priority_label: unknown code returns Unknown" {
  run get_priority_label "999"
  [ "$status" -eq 0 ]
  [ "$output" = "Unknown" ]
}

# ============================================================================
# rename_task_priority() tests
# ============================================================================

# Helper to create a task file with standard metadata
_create_test_task() {
  local dir="$1"
  local filename="$2"
  local priority="$3"
  local label="$4"
  mkdir -p "$dir"
  cat > "$dir/$filename" << EOF
# Task: Test Task

## Metadata

| Field       | Value                                                  |
| ----------- | ------------------------------------------------------ |
| ID          | \`${filename%.md}\`                                    |
| Status      | \`todo\`                                               |
| Priority    | \`$priority\` $label                                   |
| Created     | \`2026-01-01 00:00\`                                   |
EOF
}

@test "rename_task_priority: successful rename changes file and metadata" {
  _create_test_task "$TEST_TEMP_DIR" "003-001-my-task.md" "003" "Medium"

  run rename_task_priority "$TEST_TEMP_DIR/003-001-my-task.md" "001"
  [ "$status" -eq 0 ]
  [ "$output" = "$TEST_TEMP_DIR/001-001-my-task.md" ]

  # Old file should be gone
  [ ! -f "$TEST_TEMP_DIR/003-001-my-task.md" ]
  # New file should exist
  [ -f "$TEST_TEMP_DIR/001-001-my-task.md" ]
  # Metadata should be updated
  grep -q '`001` Critical' "$TEST_TEMP_DIR/001-001-my-task.md"
}

@test "rename_task_priority: no-op when priority unchanged" {
  _create_test_task "$TEST_TEMP_DIR" "003-001-my-task.md" "003" "Medium"

  run rename_task_priority "$TEST_TEMP_DIR/003-001-my-task.md" "003"
  [ "$status" -eq 0 ]
  [ "$output" = "$TEST_TEMP_DIR/003-001-my-task.md" ]

  # File should still exist at original path
  [ -f "$TEST_TEMP_DIR/003-001-my-task.md" ]
}

@test "rename_task_priority: returns error for missing file" {
  run rename_task_priority "$TEST_TEMP_DIR/nonexistent.md" "001"
  [ "$status" -eq 1 ]
  [[ "$output" == *"file not found"* ]]
}

@test "rename_task_priority: returns error when target exists (collision)" {
  _create_test_task "$TEST_TEMP_DIR" "003-001-my-task.md" "003" "Medium"
  _create_test_task "$TEST_TEMP_DIR" "001-001-my-task.md" "001" "Critical"

  run rename_task_priority "$TEST_TEMP_DIR/003-001-my-task.md" "001"
  [ "$status" -eq 1 ]
  [[ "$output" == *"already exists"* ]]

  # Original should still exist
  [ -f "$TEST_TEMP_DIR/003-001-my-task.md" ]
}

@test "rename_task_priority: returns error for invalid priority format" {
  _create_test_task "$TEST_TEMP_DIR" "003-001-my-task.md" "003" "Medium"

  # Too short
  run rename_task_priority "$TEST_TEMP_DIR/003-001-my-task.md" "01"
  [ "$status" -eq 1 ]
  [[ "$output" == *"invalid priority format"* ]]

  # Too long
  run rename_task_priority "$TEST_TEMP_DIR/003-001-my-task.md" "0001"
  [ "$status" -eq 1 ]
  [[ "$output" == *"invalid priority format"* ]]

  # Non-numeric
  run rename_task_priority "$TEST_TEMP_DIR/003-001-my-task.md" "abc"
  [ "$status" -eq 1 ]
  [[ "$output" == *"invalid priority format"* ]]
}

@test "rename_task_priority: returns error for non-standard filename" {
  mkdir -p "$TEST_TEMP_DIR"
  echo "# Task" > "$TEST_TEMP_DIR/my-custom-task.md"

  run rename_task_priority "$TEST_TEMP_DIR/my-custom-task.md" "001"
  [ "$status" -eq 1 ]
  [[ "$output" == *"does not match"* ]]
}
