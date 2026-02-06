#!/usr/bin/env bats
#
# Tests for task 004-001-test-create-hello-file
# Verifies the test-output/hello.txt file meets acceptance criteria
#

load "../test_helper"

# ============================================================================
# Acceptance criteria verification
# ============================================================================

@test "hello output: test-output directory exists" {
  [ -d "$PROJECT_ROOT/test-output" ]
}

@test "hello output: hello.txt file exists" {
  [ -f "$PROJECT_ROOT/test-output/hello.txt" ]
}

@test "hello output: content is exactly 'Hello from doyaken!'" {
  local expected="Hello from doyaken!"
  local actual
  actual=$(cat "$PROJECT_ROOT/test-output/hello.txt")
  [ "$actual" = "$expected" ]
}

@test "hello output: file is 19 bytes (no trailing newline)" {
  local size
  size=$(wc -c < "$PROJECT_ROOT/test-output/hello.txt" | tr -d ' ')
  [ "$size" -eq 19 ]
}
