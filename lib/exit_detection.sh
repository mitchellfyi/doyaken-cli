#!/usr/bin/env bash
#
# exit_detection.sh - Smart exit detection with dual-condition gate
#
# Analyzes agent output to determine whether work is truly complete.
# Uses a confidence scoring system (0-100) based on:
#   - DOYAKEN_STATUS structured block presence and values
#   - Git file changes
#   - Task file movement to done/
#   - Completion keywords in output
#
# Dual-condition gate: requires BOTH completion indicators AND structured
# signal for high-confidence completion.
#

# Prevent multiple sourcing
[[ -n "${_DOYAKEN_EXIT_DETECTION_LOADED:-}" ]] && return 0
_DOYAKEN_EXIT_DETECTION_LOADED=1

# ============================================================================
# Configuration
# ============================================================================

ED_CONFIDENCE_THRESHOLD="${ED_CONFIDENCE_THRESHOLD:-70}"
ED_LOW_CONFIDENCE_WARN="${ED_LOW_CONFIDENCE_WARN:-3}"  # Warn after N low-confidence "completions"

# Tracking state
ED_LOW_CONFIDENCE_COUNT=0

# ============================================================================
# DOYAKEN_STATUS Block Parsing
# ============================================================================

# Parse DOYAKEN_STATUS block from log file
# Sets global variables: ED_STATUS_FOUND, ED_PHASE_COMPLETE, ED_FILES_MODIFIED,
# ED_TESTS_STATUS, ED_CONFIDENCE_LEVEL, ED_REMAINING_WORK
ed_parse_status_block() {
  local log_file="$1"

  # Reset
  ED_STATUS_FOUND=0
  ED_PHASE_COMPLETE=""
  ED_FILES_MODIFIED=""
  ED_TESTS_STATUS=""
  ED_CONFIDENCE_LEVEL=""
  ED_REMAINING_WORK=""

  if [ ! -f "$log_file" ]; then
    return 1
  fi

  # Extract DOYAKEN_STATUS block — look for the marker and grab key-value pairs after it
  local in_block=0
  while IFS= read -r line; do
    if echo "$line" | grep -q "DOYAKEN_STATUS:" 2>/dev/null; then
      in_block=1
      ED_STATUS_FOUND=1
      continue
    fi

    if [ "$in_block" -eq 1 ]; then
      # Empty line or non-indented line ends the block
      if [ -z "$line" ] || [[ ! "$line" =~ ^[[:space:]] ]]; then
        break
      fi

      # Parse key-value pairs
      local key value
      key=$(echo "$line" | sed 's/^[[:space:]]*//' | cut -d: -f1 | tr -d ' ')
      value=$(echo "$line" | cut -d: -f2- | sed 's/^[[:space:]]*//')

      case "$key" in
        PHASE_COMPLETE) ED_PHASE_COMPLETE="$value" ;;
        FILES_MODIFIED) ED_FILES_MODIFIED="$value" ;;
        TESTS_STATUS)   ED_TESTS_STATUS="$value" ;;
        CONFIDENCE)     ED_CONFIDENCE_LEVEL="$value" ;;
        REMAINING_WORK) ED_REMAINING_WORK="$value" ;;
      esac
    fi
  done < "$log_file"

  if [ "$ED_STATUS_FOUND" -eq 1 ]; then
    return 0
  fi
  return 1
}

# ============================================================================
# Completion Keyword Detection
# ============================================================================

# Check if log file contains completion keywords
# Returns 0 if keywords found, 1 if not
ed_has_completion_keywords() {
  local log_file="$1"

  if [ ! -f "$log_file" ]; then
    return 1
  fi

  if grep -qiE "(all.*complete|implementation.*finished|task.*done|tests.*pass(ing|ed)|successfully.*complet)" "$log_file" 2>/dev/null; then
    return 0
  fi
  return 1
}

# ============================================================================
# Confidence Scoring
# ============================================================================

# Calculate completion confidence score (0-100)
# Args:
#   $1 = log_file (phase log to analyze)
#   $2 = task_id
#   $3 = project_dir (for git diff check)
#   $4 = tasks_dir (to check done/ for task file)
#
# Outputs: score (integer 0-100)
# Also sets ED_SCORE_REASONS (array of reason strings)
ed_calculate_confidence() {
  local log_file="${1:-}"
  local task_id="${2:-}"
  local project_dir="${3:-${PROJECT_DIR:-.}}"
  local tasks_dir="${4:-}"

  local score=0
  ED_SCORE_REASONS=()

  # 1. Structured status block present (+30)
  if [ -n "$log_file" ] && ed_parse_status_block "$log_file"; then
    score=$((score + 30))
    ED_SCORE_REASONS+=("status_block:+30")

    # 2. PHASE_COMPLETE: true (+20)
    if [ "$ED_PHASE_COMPLETE" = "true" ]; then
      score=$((score + 20))
      ED_SCORE_REASONS+=("phase_complete:+20")
    fi

    # 6. TESTS_STATUS: pass (+5)
    if [ "$ED_TESTS_STATUS" = "pass" ]; then
      score=$((score + 5))
      ED_SCORE_REASONS+=("tests_pass:+5")
    fi
  fi

  # 3. Files actually modified via git diff (+15)
  if [ -n "$project_dir" ] && command -v git &>/dev/null; then
    local diff_stat
    diff_stat=$(git -C "$project_dir" diff --stat HEAD 2>/dev/null || echo "")
    if [ -n "$diff_stat" ]; then
      score=$((score + 15))
      ED_SCORE_REASONS+=("files_modified:+15")
    fi
  fi

  # 4. Task file in done/ (+20)
  if [ -n "$task_id" ] && [ -n "$tasks_dir" ]; then
    if ls "$tasks_dir/4.done/"*"$task_id"* &>/dev/null 2>&1; then
      score=$((score + 20))
      ED_SCORE_REASONS+=("task_in_done:+20")
    fi
  fi

  # 5. Completion keywords in output (+10)
  if [ -n "$log_file" ] && ed_has_completion_keywords "$log_file"; then
    score=$((score + 10))
    ED_SCORE_REASONS+=("keywords:+10")
  fi

  echo "$score"
}

# ============================================================================
# Exit Decision
# ============================================================================

# Evaluate whether an iteration is truly complete
# Args:
#   $1 = log_file
#   $2 = task_id
#   $3 = project_dir
#   $4 = tasks_dir
#
# Returns:
#   0 = high confidence completion (score >= threshold)
#   1 = low confidence, should continue
#   2 = repeated low-confidence warnings (manual review needed)
ed_evaluate_completion() {
  local log_file="${1:-}"
  local task_id="${2:-}"
  local project_dir="${3:-${PROJECT_DIR:-.}}"
  local tasks_dir="${4:-}"

  local score
  score=$(ed_calculate_confidence "$log_file" "$task_id" "$project_dir" "$tasks_dir")

  # Log the score
  if declare -f log_info &>/dev/null; then
    local reasons_str=""
    if [ ${#ED_SCORE_REASONS[@]} -gt 0 ]; then
      reasons_str=$(IFS=', '; echo "${ED_SCORE_REASONS[*]}")
    fi
    log_info "Exit detection: confidence=$score/$ED_CONFIDENCE_THRESHOLD ($reasons_str)"
  fi

  # Write to confidence log if available
  if [ -n "${RUN_LOG_DIR:-}" ] && [ -d "${RUN_LOG_DIR:-}" ]; then
    echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) task=$task_id score=$score reasons=${ED_SCORE_REASONS[*]}" >> "$RUN_LOG_DIR/confidence.log" 2>/dev/null || true
  fi

  if [ "$score" -ge "$ED_CONFIDENCE_THRESHOLD" ]; then
    ED_LOW_CONFIDENCE_COUNT=0
    return 0  # High confidence
  fi

  # Low confidence
  ((ED_LOW_CONFIDENCE_COUNT++))

  if [ "$ED_LOW_CONFIDENCE_COUNT" -ge "$ED_LOW_CONFIDENCE_WARN" ]; then
    if declare -f log_warn &>/dev/null; then
      log_warn "Exit detection: $ED_LOW_CONFIDENCE_COUNT consecutive low-confidence completions"
      log_warn "Agent may be claiming completion prematurely — consider manual review"
    fi
    return 2  # Repeated low confidence
  fi

  return 1  # Low confidence, continue
}

# Reset low-confidence counter (call when starting a new task)
ed_reset() {
  ED_LOW_CONFIDENCE_COUNT=0
  ED_SCORE_REASONS=()
}
