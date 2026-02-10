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

@test "rename_task_priority: preserves all non-priority file content" {
  _create_test_task "$TEST_TEMP_DIR" "003-001-my-task.md" "003" "Medium"
  # Add extra content after the metadata
  cat >> "$TEST_TEMP_DIR/003-001-my-task.md" << 'EXTRA'

## Work Log

### 2026-01-01 - Created

- Task created via CLI
EXTRA

  run rename_task_priority "$TEST_TEMP_DIR/003-001-my-task.md" "002"
  [ "$status" -eq 0 ]

  # All non-priority content should be preserved
  grep -q '`003-001-my-task`' "$TEST_TEMP_DIR/002-001-my-task.md"
  grep -q '`todo`' "$TEST_TEMP_DIR/002-001-my-task.md"
  grep -q '## Work Log' "$TEST_TEMP_DIR/002-001-my-task.md"
  grep -q 'Task created via CLI' "$TEST_TEMP_DIR/002-001-my-task.md"
}

@test "rename_task_priority: handles file without Priority metadata row" {
  mkdir -p "$TEST_TEMP_DIR"
  cat > "$TEST_TEMP_DIR/003-001-minimal.md" << 'EOF'
# Task: Minimal Task

No metadata table here.
EOF

  run rename_task_priority "$TEST_TEMP_DIR/003-001-minimal.md" "001"
  [ "$status" -eq 0 ]
  [ "$output" = "$TEST_TEMP_DIR/001-001-minimal.md" ]

  # File should be renamed
  [ -f "$TEST_TEMP_DIR/001-001-minimal.md" ]
  [ ! -f "$TEST_TEMP_DIR/003-001-minimal.md" ]
  # Content should be preserved (no Priority line to update)
  grep -q 'No metadata table here' "$TEST_TEMP_DIR/001-001-minimal.md"
}

@test "rename_task_priority: returns error for empty priority" {
  _create_test_task "$TEST_TEMP_DIR" "003-001-my-task.md" "003" "Medium"

  run rename_task_priority "$TEST_TEMP_DIR/003-001-my-task.md" ""
  [ "$status" -eq 1 ]
  [[ "$output" == *"invalid priority format"* ]]
}

@test "rename_task_priority: works with filename that has no sequence number" {
  # Filename like 003-my-simple-task.md (no SSS part, just PPP-rest)
  mkdir -p "$TEST_TEMP_DIR"
  cat > "$TEST_TEMP_DIR/003-my-simple-task.md" << 'EOF'
# Task: Simple
| Priority    | `003` Medium                                   |
EOF

  run rename_task_priority "$TEST_TEMP_DIR/003-my-simple-task.md" "001"
  [ "$status" -eq 0 ]
  [ "$output" = "$TEST_TEMP_DIR/001-my-simple-task.md" ]
  [ -f "$TEST_TEMP_DIR/001-my-simple-task.md" ]
  grep -q '`001` Critical' "$TEST_TEMP_DIR/001-my-simple-task.md"
}

@test "get_priority_label: empty input returns Unknown" {
  run get_priority_label ""
  [ "$status" -eq 0 ]
  [ "$output" = "Unknown" ]
}

# ============================================================================
# create_task_file() tests
# ============================================================================

@test "create_task_file: creates file at expected path" {
  mkdir -p "$TEST_TEMP_DIR/todo"

  run create_task_file "003-001-test-task" "Test Task" "003" "Medium" "$TEST_TEMP_DIR/todo"
  [ "$status" -eq 0 ]
  [ "$output" = "$TEST_TEMP_DIR/todo/003-001-test-task.md" ]
  [ -f "$TEST_TEMP_DIR/todo/003-001-test-task.md" ]
}

@test "create_task_file: output contains Metadata section with correct values" {
  mkdir -p "$TEST_TEMP_DIR/todo"

  create_task_file "003-001-test-task" "Test Task" "003" "Medium" "$TEST_TEMP_DIR/todo" > /dev/null
  local content
  content=$(cat "$TEST_TEMP_DIR/todo/003-001-test-task.md")

  [[ "$content" == *"# Task: Test Task"* ]]
  [[ "$content" == *"## Metadata"* ]]
  [[ "$content" == *'`003-001-test-task`'* ]]
  [[ "$content" == *'`todo`'* ]]
  [[ "$content" == *'`003` Medium'* ]]
}

@test "create_task_file: output contains Context section" {
  mkdir -p "$TEST_TEMP_DIR/todo"

  create_task_file "003-001-test-task" "Test Task" "003" "Medium" "$TEST_TEMP_DIR/todo" > /dev/null
  local content
  content=$(cat "$TEST_TEMP_DIR/todo/003-001-test-task.md")

  [[ "$content" == *"## Context"* ]]
}

@test "create_task_file: output contains custom context" {
  mkdir -p "$TEST_TEMP_DIR/todo"

  create_task_file "003-001-test-task" "Test Task" "003" "Medium" "$TEST_TEMP_DIR/todo" "Custom context here" > /dev/null
  local content
  content=$(cat "$TEST_TEMP_DIR/todo/003-001-test-task.md")

  [[ "$content" == *"Custom context here"* ]]
}

@test "create_task_file: output contains default context when none provided" {
  mkdir -p "$TEST_TEMP_DIR/todo"

  create_task_file "003-001-test-task" "Test Task" "003" "Medium" "$TEST_TEMP_DIR/todo" > /dev/null
  local content
  content=$(cat "$TEST_TEMP_DIR/todo/003-001-test-task.md")

  [[ "$content" == *"Why does this task exist?"* ]]
}

@test "create_task_file: output contains Acceptance Criteria section" {
  mkdir -p "$TEST_TEMP_DIR/todo"

  create_task_file "003-001-test-task" "Test Task" "003" "Medium" "$TEST_TEMP_DIR/todo" > /dev/null
  local content
  content=$(cat "$TEST_TEMP_DIR/todo/003-001-test-task.md")

  [[ "$content" == *"## Acceptance Criteria"* ]]
}

@test "create_task_file: output contains Specification section" {
  mkdir -p "$TEST_TEMP_DIR/todo"

  create_task_file "003-001-test-task" "Test Task" "003" "Medium" "$TEST_TEMP_DIR/todo" > /dev/null
  local content
  content=$(cat "$TEST_TEMP_DIR/todo/003-001-test-task.md")

  [[ "$content" == *"## Specification"* ]]
}

@test "create_task_file: Specification contains User Stories subsection" {
  mkdir -p "$TEST_TEMP_DIR/todo"

  create_task_file "003-001-test-task" "Test Task" "003" "Medium" "$TEST_TEMP_DIR/todo" > /dev/null
  local content
  content=$(cat "$TEST_TEMP_DIR/todo/003-001-test-task.md")

  [[ "$content" == *"### User Stories"* ]]
}

@test "create_task_file: Specification contains Acceptance Scenarios subsection" {
  mkdir -p "$TEST_TEMP_DIR/todo"

  create_task_file "003-001-test-task" "Test Task" "003" "Medium" "$TEST_TEMP_DIR/todo" > /dev/null
  local content
  content=$(cat "$TEST_TEMP_DIR/todo/003-001-test-task.md")

  [[ "$content" == *"### Acceptance Scenarios"* ]]
}

@test "create_task_file: Specification contains Success Metrics subsection" {
  mkdir -p "$TEST_TEMP_DIR/todo"

  create_task_file "003-001-test-task" "Test Task" "003" "Medium" "$TEST_TEMP_DIR/todo" > /dev/null
  local content
  content=$(cat "$TEST_TEMP_DIR/todo/003-001-test-task.md")

  [[ "$content" == *"### Success Metrics"* ]]
}

@test "create_task_file: Specification contains Scope subsection" {
  mkdir -p "$TEST_TEMP_DIR/todo"

  create_task_file "003-001-test-task" "Test Task" "003" "Medium" "$TEST_TEMP_DIR/todo" > /dev/null
  local content
  content=$(cat "$TEST_TEMP_DIR/todo/003-001-test-task.md")

  [[ "$content" == *"### Scope"* ]]
}

@test "create_task_file: Specification contains Dependencies subsection" {
  mkdir -p "$TEST_TEMP_DIR/todo"

  create_task_file "003-001-test-task" "Test Task" "003" "Medium" "$TEST_TEMP_DIR/todo" > /dev/null
  local content
  content=$(cat "$TEST_TEMP_DIR/todo/003-001-test-task.md")

  [[ "$content" == *"### Dependencies"* ]]
}

@test "create_task_file: Specification subsections have placeholder text" {
  mkdir -p "$TEST_TEMP_DIR/todo"

  create_task_file "003-001-test-task" "Test Task" "003" "Medium" "$TEST_TEMP_DIR/todo" > /dev/null
  local content
  content=$(cat "$TEST_TEMP_DIR/todo/003-001-test-task.md")

  [[ "$content" == *"(To be filled in during EXPAND phase)"* ]]
}

@test "create_task_file: output contains Plan section" {
  mkdir -p "$TEST_TEMP_DIR/todo"

  create_task_file "003-001-test-task" "Test Task" "003" "Medium" "$TEST_TEMP_DIR/todo" > /dev/null
  local content
  content=$(cat "$TEST_TEMP_DIR/todo/003-001-test-task.md")

  [[ "$content" == *"## Plan"* ]]
}

@test "create_task_file: output contains Work Log section" {
  mkdir -p "$TEST_TEMP_DIR/todo"

  create_task_file "003-001-test-task" "Test Task" "003" "Medium" "$TEST_TEMP_DIR/todo" > /dev/null
  local content
  content=$(cat "$TEST_TEMP_DIR/todo/003-001-test-task.md")

  [[ "$content" == *"## Work Log"* ]]
}

@test "create_task_file: output contains Notes section" {
  mkdir -p "$TEST_TEMP_DIR/todo"

  create_task_file "003-001-test-task" "Test Task" "003" "Medium" "$TEST_TEMP_DIR/todo" > /dev/null
  local content
  content=$(cat "$TEST_TEMP_DIR/todo/003-001-test-task.md")

  [[ "$content" == *"## Notes"* ]]
}

@test "create_task_file: output contains Links section" {
  mkdir -p "$TEST_TEMP_DIR/todo"

  create_task_file "003-001-test-task" "Test Task" "003" "Medium" "$TEST_TEMP_DIR/todo" > /dev/null
  local content
  content=$(cat "$TEST_TEMP_DIR/todo/003-001-test-task.md")

  [[ "$content" == *"## Links"* ]]
}

@test "create_task_file: sections appear in correct order" {
  mkdir -p "$TEST_TEMP_DIR/todo"

  create_task_file "003-001-test-task" "Test Task" "003" "Medium" "$TEST_TEMP_DIR/todo" > /dev/null
  local file="$TEST_TEMP_DIR/todo/003-001-test-task.md"

  # Extract line numbers of each section header
  local metadata_line context_line ac_line spec_line plan_line worklog_line notes_line links_line
  metadata_line=$(grep -n "## Metadata" "$file" | head -1 | cut -d: -f1)
  context_line=$(grep -n "## Context" "$file" | head -1 | cut -d: -f1)
  ac_line=$(grep -n "## Acceptance Criteria" "$file" | head -1 | cut -d: -f1)
  spec_line=$(grep -n "## Specification" "$file" | head -1 | cut -d: -f1)
  plan_line=$(grep -n "## Plan" "$file" | head -1 | cut -d: -f1)
  worklog_line=$(grep -n "## Work Log" "$file" | head -1 | cut -d: -f1)
  notes_line=$(grep -n "## Notes" "$file" | head -1 | cut -d: -f1)
  links_line=$(grep -n "## Links" "$file" | head -1 | cut -d: -f1)

  # Verify order: Metadata < Context < AC < Specification < Plan < Work Log < Notes < Links
  [ "$metadata_line" -lt "$context_line" ]
  [ "$context_line" -lt "$ac_line" ]
  [ "$ac_line" -lt "$spec_line" ]
  [ "$spec_line" -lt "$plan_line" ]
  [ "$plan_line" -lt "$worklog_line" ]
  [ "$worklog_line" -lt "$notes_line" ]
  [ "$notes_line" -lt "$links_line" ]
}
