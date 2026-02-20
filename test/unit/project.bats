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

