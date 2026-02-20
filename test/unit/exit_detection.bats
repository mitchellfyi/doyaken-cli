#!/usr/bin/env bats
#
# Tests for lib/exit_detection.sh
#

load '../test_helper'

setup() {
  export TEST_TEMP_DIR
  TEST_TEMP_DIR="$(mktemp -d)"
  export DOYAKEN_HOME="$PROJECT_ROOT"
  export STATE_DIR="$TEST_TEMP_DIR/state"
  export PROJECT_DIR="$TEST_TEMP_DIR/project"
  export TASKS_DIR="$TEST_TEMP_DIR/tasks"
  export RUN_LOG_DIR="$TEST_TEMP_DIR/logs"

  mkdir -p "$STATE_DIR" "$PROJECT_DIR" "$TASKS_DIR/4.done" "$RUN_LOG_DIR"

  # Source dependencies
  source "$PROJECT_ROOT/lib/logging.sh"
  source "$PROJECT_ROOT/lib/exit_detection.sh"
}

teardown() {
  if [[ -d "${TEST_TEMP_DIR:-}" ]]; then
    rm -rf "$TEST_TEMP_DIR"
  fi
}

# ============================================================================
# Loading
# ============================================================================

@test "exit_detection.sh loads without error" {
  [[ -n "$_DOYAKEN_EXIT_DETECTION_LOADED" ]]
}

@test "default configuration" {
  [[ "$ED_CONFIDENCE_THRESHOLD" -eq 70 ]]
  [[ "$ED_LOW_CONFIDENCE_WARN" -eq 3 ]]
}

# ============================================================================
# DOYAKEN_STATUS Block Parsing
# ============================================================================

@test "ed_parse_status_block finds complete block" {
  local log="$TEST_TEMP_DIR/phase.log"
  cat > "$log" << 'EOF'
Some agent output here
DOYAKEN_STATUS:
  PHASE_COMPLETE: true
  FILES_MODIFIED: 5
  TESTS_STATUS: pass
  CONFIDENCE: high
  REMAINING_WORK: none

More output
EOF

  ed_parse_status_block "$log"
  [[ "$ED_STATUS_FOUND" -eq 1 ]]
  [[ "$ED_PHASE_COMPLETE" == "true" ]]
  [[ "$ED_FILES_MODIFIED" == "5" ]]
  [[ "$ED_TESTS_STATUS" == "pass" ]]
  [[ "$ED_CONFIDENCE_LEVEL" == "high" ]]
  [[ "$ED_REMAINING_WORK" == "none" ]]
}

@test "ed_parse_status_block finds partial block" {
  local log="$TEST_TEMP_DIR/phase.log"
  cat > "$log" << 'EOF'
Agent output
DOYAKEN_STATUS:
  PHASE_COMPLETE: false
  REMAINING_WORK: fix tests
EOF

  ed_parse_status_block "$log"
  [[ "$ED_STATUS_FOUND" -eq 1 ]]
  [[ "$ED_PHASE_COMPLETE" == "false" ]]
  [[ "$ED_REMAINING_WORK" == "fix tests" ]]
}

@test "ed_parse_status_block returns 1 when no block" {
  local log="$TEST_TEMP_DIR/phase.log"
  echo "Just regular output" > "$log"

  local result=0
  ed_parse_status_block "$log" || result=$?
  [[ "$result" -eq 1 ]]
  [[ "$ED_STATUS_FOUND" -eq 0 ]]
}

@test "ed_parse_status_block returns 1 for missing file" {
  local result=0
  ed_parse_status_block "/nonexistent/file" || result=$?
  [[ "$result" -eq 1 ]]
}

@test "ed_parse_status_block resets state between calls" {
  local log="$TEST_TEMP_DIR/phase.log"
  cat > "$log" << 'EOF'
DOYAKEN_STATUS:
  PHASE_COMPLETE: true
  TESTS_STATUS: pass
EOF
  ed_parse_status_block "$log"
  [[ "$ED_PHASE_COMPLETE" == "true" ]]

  # Second call with no block
  echo "no block" > "$log"
  ed_parse_status_block "$log" || true
  [[ "$ED_STATUS_FOUND" -eq 0 ]]
  [[ -z "$ED_PHASE_COMPLETE" ]]
}

# ============================================================================
# Completion Keywords
# ============================================================================

@test "ed_has_completion_keywords detects 'all tasks complete'" {
  local log="$TEST_TEMP_DIR/phase.log"
  echo "All tasks complete, moving on" > "$log"
  ed_has_completion_keywords "$log"
}

@test "ed_has_completion_keywords detects 'implementation finished'" {
  local log="$TEST_TEMP_DIR/phase.log"
  echo "The implementation finished successfully" > "$log"
  ed_has_completion_keywords "$log"
}

@test "ed_has_completion_keywords detects 'tests passing'" {
  local log="$TEST_TEMP_DIR/phase.log"
  echo "All tests passing now" > "$log"
  ed_has_completion_keywords "$log"
}

@test "ed_has_completion_keywords returns 1 for no keywords" {
  local log="$TEST_TEMP_DIR/phase.log"
  echo "Still working on things" > "$log"

  local result=0
  ed_has_completion_keywords "$log" || result=$?
  [[ "$result" -eq 1 ]]
}

@test "ed_has_completion_keywords returns 1 for missing file" {
  local result=0
  ed_has_completion_keywords "/nonexistent" || result=$?
  [[ "$result" -eq 1 ]]
}

# ============================================================================
# Confidence Scoring
# ============================================================================

@test "ed_calculate_confidence returns 0 for empty log" {
  local score
  score=$(ed_calculate_confidence "" "" "" "")
  [[ "$score" -eq 0 ]]
}

@test "ed_calculate_confidence scores status block (+30)" {
  local log="$TEST_TEMP_DIR/phase.log"
  cat > "$log" << 'EOF'
DOYAKEN_STATUS:
  PHASE_COMPLETE: false
  TESTS_STATUS: unknown
EOF

  local score
  score=$(ed_calculate_confidence "$log" "" "" "")
  [[ "$score" -ge 30 ]]
}

@test "ed_calculate_confidence scores phase_complete (+50)" {
  local log="$TEST_TEMP_DIR/phase.log"
  cat > "$log" << 'EOF'
DOYAKEN_STATUS:
  PHASE_COMPLETE: true
EOF

  local score
  score=$(ed_calculate_confidence "$log" "" "" "")
  [[ "$score" -ge 50 ]]
}

@test "ed_calculate_confidence scores tests_pass (+55)" {
  local log="$TEST_TEMP_DIR/phase.log"
  cat > "$log" << 'EOF'
DOYAKEN_STATUS:
  PHASE_COMPLETE: true
  TESTS_STATUS: pass
EOF

  local score
  score=$(ed_calculate_confidence "$log" "" "" "")
  [[ "$score" -ge 55 ]]
}

@test "ed_calculate_confidence scores completion keywords (+10)" {
  local log="$TEST_TEMP_DIR/phase.log"
  echo "All tasks complete and implementation finished" > "$log"

  local score
  score=$(ed_calculate_confidence "$log" "" "" "")
  [[ "$score" -ge 10 ]]
}

@test "ed_calculate_confidence scores git changes (+15)" {
  # Set up a git repo with changes
  cd "$PROJECT_DIR"
  git init -q .
  git config user.email "test@test.com"
  git config user.name "Test"
  echo "initial" > file.txt
  git add file.txt
  git commit -q -m "init"
  echo "changed" >> file.txt

  local log="$TEST_TEMP_DIR/phase.log"
  echo "output" > "$log"

  local score
  score=$(ed_calculate_confidence "$log" "" "$PROJECT_DIR" "")
  [[ "$score" -ge 15 ]]
}

@test "ed_calculate_confidence full score scenario" {
  # Set up git with changes
  cd "$PROJECT_DIR"
  git init -q .
  git config user.email "test@test.com"
  git config user.name "Test"
  echo "initial" > file.txt
  git add file.txt
  git commit -q -m "init"
  echo "changed" >> file.txt

  # Create log with status block and keywords
  local log="$TEST_TEMP_DIR/phase.log"
  cat > "$log" << 'EOF'
All tasks complete, implementation finished
DOYAKEN_STATUS:
  PHASE_COMPLETE: true
  FILES_MODIFIED: 3
  TESTS_STATUS: pass
  CONFIDENCE: high
  REMAINING_WORK: none
EOF

  local score
  score=$(ed_calculate_confidence "$log" "" "$PROJECT_DIR")
  # 30 (block) + 20 (phase_complete) + 5 (tests) + 15 (git) + 10 (keywords) = 80
  [[ "$score" -eq 80 ]]
}

@test "ED_SCORE_REASONS populated" {
  local log="$TEST_TEMP_DIR/phase.log"
  cat > "$log" << 'EOF'
DOYAKEN_STATUS:
  PHASE_COMPLETE: true
EOF

  ed_calculate_confidence "$log" "" "" ""
  [[ ${#ED_SCORE_REASONS[@]} -ge 2 ]]
  [[ "${ED_SCORE_REASONS[0]}" == *"status_block"* ]]
}

# ============================================================================
# Exit Evaluation
# ============================================================================

@test "ed_evaluate_completion returns 0 for high confidence" {
  ED_CONFIDENCE_THRESHOLD=50

  # Set up a log with enough signals
  local log="$TEST_TEMP_DIR/phase.log"
  cat > "$log" << 'EOF'
All tasks complete
DOYAKEN_STATUS:
  PHASE_COMPLETE: true
  TESTS_STATUS: pass
EOF

  # 30 + 20 + 5 + 10 = 65, above 50 threshold
  ed_evaluate_completion "$log" "" "" ""
}

@test "ed_evaluate_completion returns 1 for low confidence" {
  ED_CONFIDENCE_THRESHOLD=70
  ED_LOW_CONFIDENCE_COUNT=0

  local log="$TEST_TEMP_DIR/phase.log"
  echo "still working" > "$log"

  local result=0
  ed_evaluate_completion "$log" "" "" "" || result=$?
  [[ "$result" -eq 1 ]]
}

@test "ed_evaluate_completion returns 2 after repeated low confidence" {
  ED_CONFIDENCE_THRESHOLD=70
  ED_LOW_CONFIDENCE_WARN=3
  ED_LOW_CONFIDENCE_COUNT=2  # Already 2 low-confidence

  local log="$TEST_TEMP_DIR/phase.log"
  echo "still working" > "$log"

  local result=0
  ed_evaluate_completion "$log" "" "" "" || result=$?
  [[ "$result" -eq 2 ]]
  [[ "$ED_LOW_CONFIDENCE_COUNT" -eq 3 ]]
}

@test "ed_evaluate_completion writes confidence log" {
  ED_CONFIDENCE_THRESHOLD=50

  local log="$TEST_TEMP_DIR/phase.log"
  cat > "$log" << 'EOF'
DOYAKEN_STATUS:
  PHASE_COMPLETE: true
EOF

  ed_evaluate_completion "$log" "" ""

  [[ -f "$RUN_LOG_DIR/confidence.log" ]]
  local content
  content=$(cat "$RUN_LOG_DIR/confidence.log")
  [[ "$content" == *"score="* ]]
}

# ============================================================================
# Reset
# ============================================================================

@test "ed_reset clears counters" {
  ED_LOW_CONFIDENCE_COUNT=5
  ED_SCORE_REASONS=("a" "b" "c")

  ed_reset

  [[ "$ED_LOW_CONFIDENCE_COUNT" -eq 0 ]]
  [[ ${#ED_SCORE_REASONS[@]} -eq 0 ]]
}
