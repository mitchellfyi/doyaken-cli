#!/usr/bin/env bats
#
# Unit tests for lib/errors.sh - error collection and reporting
#

load "../test_helper"

setup() {
  export TEST_TEMP_DIR
  TEST_TEMP_DIR="$(mktemp -d)"

  # Stub color vars (errors.sh uses RED, GREEN, DIM, NC)
  export RED="" GREEN="" DIM="" NC="" BOLD=""

  # Source errors.sh
  load_lib "errors"
}

teardown() {
  if [[ -d "${TEST_TEMP_DIR:-}" ]]; then
    rm -rf "$TEST_TEMP_DIR"
  fi
}

# ============================================================================
# error_init
# ============================================================================

@test "error_init: resets all error arrays" {
  error_add "msg" "fix" "doc"
  error_init

  run error_has_errors
  [ "$status" -eq 1 ]
}

# ============================================================================
# error_add
# ============================================================================

@test "error_add: stores message and fix" {
  error_init
  error_add "Something broke" "Do this to fix it"

  run error_has_errors
  [ "$status" -eq 0 ]
}

@test "error_add: stores all three parameters" {
  error_init
  error_add "Problem occurred" "Run this command" "https://example.com/docs"

  run error_report
  [[ "$output" == *"Problem occurred"* ]]
  [[ "$output" == *"Run this command"* ]]
  [[ "$output" == *"https://example.com/docs"* ]]
}

@test "error_add: works with empty doc parameter" {
  error_init
  error_add "Problem occurred" "Fix suggestion" ""

  run error_report
  [[ "$output" == *"Problem occurred"* ]]
  [[ "$output" == *"Fix suggestion"* ]]
  # Should NOT contain a "Docs:" line
  [[ "$output" != *"Docs:"* ]]
}

@test "error_add: works with only message parameter" {
  error_init
  error_add "Just the problem"

  run error_report
  [[ "$output" == *"Just the problem"* ]]
  # No fix line when fix is empty
  [[ "$output" != *"Fix:"* ]]
}

@test "error_add: accumulates multiple errors" {
  error_init
  error_add "First error" "Fix one"
  error_add "Second error" "Fix two"
  error_add "Third error" "Fix three"

  run error_report
  [[ "$output" == *"3 error(s)"* ]]
  [[ "$output" == *"First error"* ]]
  [[ "$output" == *"Second error"* ]]
  [[ "$output" == *"Third error"* ]]
}

# ============================================================================
# error_has_errors
# ============================================================================

@test "error_has_errors: returns 1 when no errors" {
  error_init

  run error_has_errors
  [ "$status" -eq 1 ]
}

@test "error_has_errors: returns 0 when errors exist" {
  error_init
  error_add "An error" "A fix"

  run error_has_errors
  [ "$status" -eq 0 ]
}

@test "error_has_errors: returns 1 after init clears errors" {
  error_add "An error" "A fix"
  error_init

  run error_has_errors
  [ "$status" -eq 1 ]
}

# ============================================================================
# error_report
# ============================================================================

@test "error_report: outputs nothing when no errors" {
  error_init

  run error_report
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "error_report: shows numbered errors with Fix lines" {
  error_init
  error_add "Manifest missing" "Run dk init"
  error_add "Bad YAML" "Check syntax"

  run error_report
  [[ "$output" == *"1."*"Manifest missing"* ]]
  [[ "$output" == *"Fix:"*"Run dk init"* ]]
  [[ "$output" == *"2."*"Bad YAML"* ]]
  [[ "$output" == *"Fix:"*"Check syntax"* ]]
}

@test "error_report: shows Docs line when doc URL provided" {
  error_init
  error_add "Problem" "Fix it" "https://docs.example.com"

  run error_report
  [[ "$output" == *"Docs:"*"https://docs.example.com"* ]]
}

@test "error_report: omits Docs line when doc URL empty" {
  error_init
  error_add "Problem" "Fix it" ""

  run error_report
  [[ "$output" != *"Docs:"* ]]
}

@test "error_report: separates problem from fix on different lines" {
  error_init
  error_add "The problem description" "The fix suggestion" "https://docs.example.com"

  run error_report
  # Problem, fix, and docs should each be on their own line
  local problem_line fix_line docs_line
  problem_line=$(echo "$output" | grep "The problem description")
  fix_line=$(echo "$output" | grep "Fix:.*The fix suggestion")
  docs_line=$(echo "$output" | grep "Docs:.*https://docs.example.com")

  [ -n "$problem_line" ]
  [ -n "$fix_line" ]
  [ -n "$docs_line" ]
  # They should be different lines
  [ "$problem_line" != "$fix_line" ]
  [ "$fix_line" != "$docs_line" ]
}

# ============================================================================
# error_report_and_exit
# ============================================================================

@test "error_report_and_exit: exits 1 when errors exist" {
  error_init
  error_add "Fatal error" "Cannot continue"

  run error_report_and_exit
  [ "$status" -eq 1 ]
  [[ "$output" == *"Fatal error"* ]]
}

@test "error_report_and_exit: succeeds silently when no errors" {
  error_init

  run error_report_and_exit
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

# ============================================================================
# Error message quality (regression tests for improved messages)
# ============================================================================

@test "error_report: mixed errors with and without doc URLs render correctly" {
  error_init
  error_add "Error with docs" "Fix with docs" "https://example.com"
  error_add "Error without docs" "Fix without docs"
  error_add "Error with docs too" "Another fix" "https://other.example.com"

  run error_report
  [[ "$output" == *"3 error(s)"* ]]
  # First and third should have Docs lines
  local docs_count
  docs_count=$(echo "$output" | grep -c "Docs:" || true)
  [ "$docs_count" -eq 2 ]
}
