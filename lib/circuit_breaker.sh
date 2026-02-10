#!/usr/bin/env bash
#
# circuit_breaker.sh - 3-state circuit breaker for stall detection
#
# States:
#   CLOSED    (normal)  — agent is making progress
#   HALF_OPEN (caution) — stagnation detected, allow one more attempt
#   OPEN      (halted)  — threshold breached, stop execution
#
# Stagnation signals:
#   - No file changes after iteration (git diff)
#   - Repeated error patterns (hash comparison)
#   - Output decline (< threshold% of rolling average)
#   - Repeated phase failures
#
# State persisted in $STATE_DIR/circuit-breaker-<agent-id>
#

# Prevent multiple sourcing
[[ -n "${_DOYAKEN_CIRCUIT_BREAKER_LOADED:-}" ]] && return 0
_DOYAKEN_CIRCUIT_BREAKER_LOADED=1

# ============================================================================
# Configuration (defaults, overridable via config priority chain)
# ============================================================================

CB_ENABLED="${CB_ENABLED:-1}"
CB_NO_PROGRESS_THRESHOLD="${CB_NO_PROGRESS_THRESHOLD:-3}"
CB_SAME_ERROR_THRESHOLD="${CB_SAME_ERROR_THRESHOLD:-5}"
CB_OUTPUT_DECLINE_PERCENT="${CB_OUTPUT_DECLINE_PERCENT:-70}"
CB_COOLDOWN_MINUTES="${CB_COOLDOWN_MINUTES:-5}"

# ============================================================================
# State Variables
# ============================================================================

CB_STATE="CLOSED"                # CLOSED | HALF_OPEN | OPEN
CB_NO_PROGRESS_COUNT=0           # Consecutive iterations with no file changes
CB_SAME_ERROR_COUNT=0            # Consecutive identical error hashes
CB_LAST_ERROR_HASH=""            # Hash of last error output
CB_OUTPUT_SIZES=()               # Rolling window of output sizes (last 5)
CB_LAST_TRANSITION=""            # Timestamp of last state transition
CB_OPEN_SINCE=0                  # Timestamp when OPEN state was entered

# ============================================================================
# Load Circuit Breaker Configuration
# ============================================================================

load_circuit_breaker_config() {
  local manifest_file="${1:-}"

  if declare -f _load_config_bool &>/dev/null; then
    _load_config_bool "CB_ENABLED"                "circuit_breaker.enabled"                "true" "$manifest_file"
  fi
  if declare -f _load_config &>/dev/null; then
    _load_config "CB_NO_PROGRESS_THRESHOLD"  "circuit_breaker.no_progress_threshold"  "3"   "$manifest_file"
    _load_config "CB_SAME_ERROR_THRESHOLD"   "circuit_breaker.same_error_threshold"   "5"   "$manifest_file"
    _load_config "CB_OUTPUT_DECLINE_PERCENT" "circuit_breaker.output_decline_percent" "70"  "$manifest_file"
    _load_config "CB_COOLDOWN_MINUTES"       "circuit_breaker.cooldown_minutes"       "5"   "$manifest_file"
  fi
}

# ============================================================================
# State Persistence
# ============================================================================

# Get state file path
_cb_state_file() {
  local agent_id="${1:-${AGENT_ID:-agent}}"
  local state_dir="${STATE_DIR:-/tmp}"
  echo "$state_dir/circuit-breaker-$agent_id"
}

# Save circuit breaker state to disk (atomic write)
cb_save_state() {
  local agent_id="${1:-${AGENT_ID:-agent}}"
  local state_file
  state_file=$(_cb_state_file "$agent_id")
  local tmp_file="${state_file}.tmp.$$"

  local output_sizes_str=""
  if [ ${#CB_OUTPUT_SIZES[@]} -gt 0 ]; then
    output_sizes_str=$(IFS=,; echo "${CB_OUTPUT_SIZES[*]}")
  fi

  cat > "$tmp_file" << EOF
CB_STATE="$CB_STATE"
CB_NO_PROGRESS_COUNT="$CB_NO_PROGRESS_COUNT"
CB_SAME_ERROR_COUNT="$CB_SAME_ERROR_COUNT"
CB_LAST_ERROR_HASH="$CB_LAST_ERROR_HASH"
CB_OUTPUT_SIZES="$output_sizes_str"
CB_LAST_TRANSITION="$CB_LAST_TRANSITION"
CB_OPEN_SINCE="$CB_OPEN_SINCE"
EOF
  mv "$tmp_file" "$state_file"
}

# Load circuit breaker state from disk
cb_load_state() {
  local agent_id="${1:-${AGENT_ID:-agent}}"
  local state_file
  state_file=$(_cb_state_file "$agent_id")

  if [ ! -f "$state_file" ]; then
    cb_reset
    return 0
  fi

  # Parse safely with grep (no source)
  CB_STATE=$(grep '^CB_STATE=' "$state_file" 2>/dev/null | head -1 | cut -d= -f2- | tr -d '"')
  CB_NO_PROGRESS_COUNT=$(grep '^CB_NO_PROGRESS_COUNT=' "$state_file" 2>/dev/null | head -1 | cut -d= -f2- | tr -d '"')
  CB_SAME_ERROR_COUNT=$(grep '^CB_SAME_ERROR_COUNT=' "$state_file" 2>/dev/null | head -1 | cut -d= -f2- | tr -d '"')
  CB_LAST_ERROR_HASH=$(grep '^CB_LAST_ERROR_HASH=' "$state_file" 2>/dev/null | head -1 | cut -d= -f2- | tr -d '"')
  CB_LAST_TRANSITION=$(grep '^CB_LAST_TRANSITION=' "$state_file" 2>/dev/null | head -1 | cut -d= -f2- | tr -d '"')
  CB_OPEN_SINCE=$(grep '^CB_OPEN_SINCE=' "$state_file" 2>/dev/null | head -1 | cut -d= -f2- | tr -d '"')

  # Parse output sizes array
  local sizes_str
  sizes_str=$(grep '^CB_OUTPUT_SIZES=' "$state_file" 2>/dev/null | head -1 | cut -d= -f2- | tr -d '"')
  CB_OUTPUT_SIZES=()
  if [ -n "$sizes_str" ]; then
    IFS=',' read -r -a CB_OUTPUT_SIZES <<< "$sizes_str"
  fi

  # Defaults for missing values
  CB_STATE="${CB_STATE:-CLOSED}"
  CB_NO_PROGRESS_COUNT="${CB_NO_PROGRESS_COUNT:-0}"
  CB_SAME_ERROR_COUNT="${CB_SAME_ERROR_COUNT:-0}"
  CB_OPEN_SINCE="${CB_OPEN_SINCE:-0}"
}

# Reset circuit breaker to initial state
cb_reset() {
  CB_STATE="CLOSED"
  CB_NO_PROGRESS_COUNT=0
  CB_SAME_ERROR_COUNT=0
  CB_LAST_ERROR_HASH=""
  CB_OUTPUT_SIZES=()
  CB_LAST_TRANSITION=""
  CB_OPEN_SINCE=0
}

# ============================================================================
# State Transitions
# ============================================================================

# Transition to a new state
_cb_transition() {
  local new_state="$1"
  local reason="${2:-}"

  if [ "$CB_STATE" = "$new_state" ]; then
    return 0
  fi

  local old_state="$CB_STATE"
  CB_STATE="$new_state"
  CB_LAST_TRANSITION=$(date +%s)

  if [ "$new_state" = "OPEN" ]; then
    CB_OPEN_SINCE=$(date +%s)
  fi

  if declare -f log_heal &>/dev/null; then
    log_heal "Circuit breaker: $old_state → $new_state${reason:+ ($reason)}"
  fi
}

# ============================================================================
# Stagnation Detection
# ============================================================================

# Check if any files changed since a given git ref or time
# Returns 0 if changes detected, 1 if no changes
cb_check_file_changes() {
  local project_dir="${1:-${PROJECT_DIR:-.}}"

  if ! command -v git &>/dev/null; then
    return 0  # Can't check, assume progress
  fi

  local diff_stat
  diff_stat=$(git -C "$project_dir" diff --stat HEAD 2>/dev/null || echo "")

  if [ -z "$diff_stat" ]; then
    return 1  # No changes
  fi
  return 0  # Changes detected
}

# Hash error output for deduplication
# Usage: cb_hash_error "error text"
cb_hash_error() {
  local error_text="$1"
  if [ -z "$error_text" ]; then
    echo ""
    return
  fi
  # Use cksum for portability (available everywhere, no md5 dependency)
  echo "$error_text" | cksum | cut -d' ' -f1
}

# Check if output size indicates decline
# Returns 0 if output is healthy, 1 if declining
cb_check_output_decline() {
  local current_size="$1"

  if [ ${#CB_OUTPUT_SIZES[@]} -lt 2 ]; then
    return 0  # Not enough data
  fi

  # Calculate rolling average
  local total=0
  for size in "${CB_OUTPUT_SIZES[@]}"; do
    total=$((total + size))
  done
  local avg=$((total / ${#CB_OUTPUT_SIZES[@]}))

  if [ "$avg" -eq 0 ]; then
    return 0  # Avoid division by zero
  fi

  # Check if current output is below threshold% of average
  local threshold_size=$(( avg * CB_OUTPUT_DECLINE_PERCENT / 100 ))
  if [ "$current_size" -lt "$threshold_size" ]; then
    return 1  # Declining
  fi
  return 0
}

# Record output size in rolling window (keep last 5)
cb_record_output_size() {
  local size="$1"
  CB_OUTPUT_SIZES+=("$size")

  # Keep only last 5
  while [ ${#CB_OUTPUT_SIZES[@]} -gt 5 ]; do
    CB_OUTPUT_SIZES=("${CB_OUTPUT_SIZES[@]:1}")
  done
}

# ============================================================================
# Main Check Functions
# ============================================================================

# Check if execution should proceed
# Returns:
#   0 = proceed (CLOSED or HALF_OPEN allowing one attempt)
#   1 = halt (OPEN, not yet cooled down)
#   2 = halt with cooldown expired (OPEN → HALF_OPEN transition possible)
cb_should_proceed() {
  [ "$CB_ENABLED" != "1" ] && return 0

  case "$CB_STATE" in
    CLOSED)
      return 0
      ;;
    HALF_OPEN)
      return 0
      ;;
    OPEN)
      # Check cooldown
      local now
      now=$(date +%s)
      local cooldown_secs=$(( CB_COOLDOWN_MINUTES * 60 ))
      local elapsed=$(( now - CB_OPEN_SINCE ))

      if [ "$elapsed" -ge "$cooldown_secs" ]; then
        _cb_transition "HALF_OPEN" "cooldown expired"
        return 0
      fi

      if declare -f log_heal &>/dev/null; then
        local remaining=$(( cooldown_secs - elapsed ))
        log_heal "Circuit breaker OPEN — ${remaining}s until cooldown expires"
      fi
      return 1
      ;;
  esac
}

# Record iteration result and update state
# Call this after each iteration completes (success or failure)
# Args:
#   $1 = exit_code (0=success, non-zero=failure)
#   $2 = log_file (optional, path to phase log for error analysis)
#   $3 = project_dir (optional, for git diff)
cb_record_iteration() {
  [ "$CB_ENABLED" != "1" ] && return 0

  local exit_code="${1:-0}"
  local log_file="${2:-}"
  local project_dir="${3:-${PROJECT_DIR:-.}}"

  if [ "$exit_code" -eq 0 ]; then
    # Success — check for actual file changes
    if cb_check_file_changes "$project_dir"; then
      # Real progress
      _cb_on_progress
    else
      # Success but no file changes
      _cb_on_no_progress "no file changes"
    fi
  else
    # Failure — check for repeated errors
    local error_hash=""
    if [ -n "$log_file" ] && [ -f "$log_file" ]; then
      local error_tail
      error_tail=$(tail -20 "$log_file" 2>/dev/null || echo "")
      error_hash=$(cb_hash_error "$error_tail")

      # Record output size
      local output_size
      output_size=$(wc -c < "$log_file" 2>/dev/null || echo "0")
      cb_record_output_size "$output_size"

      # Check for output decline
      if ! cb_check_output_decline "$output_size"; then
        _cb_on_no_progress "output declining"
      fi
    fi

    # Check for repeated errors
    if [ -n "$error_hash" ] && [ "$error_hash" = "$CB_LAST_ERROR_HASH" ]; then
      ((CB_SAME_ERROR_COUNT++))
      if [ "$CB_SAME_ERROR_COUNT" -ge "$CB_SAME_ERROR_THRESHOLD" ]; then
        _cb_transition "OPEN" "same error repeated $CB_SAME_ERROR_COUNT times"
      fi
    else
      CB_SAME_ERROR_COUNT=1
      CB_LAST_ERROR_HASH="$error_hash"
    fi

    _cb_on_no_progress "iteration failed"
  fi
}

# ============================================================================
# Internal State Handlers
# ============================================================================

_cb_on_progress() {
  CB_NO_PROGRESS_COUNT=0
  CB_SAME_ERROR_COUNT=0

  case "$CB_STATE" in
    HALF_OPEN)
      _cb_transition "CLOSED" "progress detected"
      ;;
    OPEN)
      _cb_transition "CLOSED" "progress detected"
      ;;
  esac
}

_cb_on_no_progress() {
  local reason="${1:-unknown}"
  ((CB_NO_PROGRESS_COUNT++))

  case "$CB_STATE" in
    CLOSED)
      if [ "$CB_NO_PROGRESS_COUNT" -ge 2 ]; then
        _cb_transition "HALF_OPEN" "$reason"
      fi
      ;;
    HALF_OPEN)
      if [ "$CB_NO_PROGRESS_COUNT" -ge "$CB_NO_PROGRESS_THRESHOLD" ]; then
        _cb_transition "OPEN" "$reason — $CB_NO_PROGRESS_COUNT consecutive no-progress iterations"
        if declare -f log_error &>/dev/null; then
          log_error "Circuit breaker OPEN: Agent appears stuck after $CB_NO_PROGRESS_COUNT iterations"
          log_error "Suggested actions:"
          log_error "  - Check task complexity and break into smaller tasks"
          log_error "  - Review recent logs for patterns"
          log_error "  - Wait ${CB_COOLDOWN_MINUTES}m for auto-retry or restart manually"
        fi
      fi
      ;;
  esac
}

# ============================================================================
# Status/Info
# ============================================================================

# Get current circuit breaker state as human-readable string
cb_status() {
  echo "state=$CB_STATE no_progress=$CB_NO_PROGRESS_COUNT errors=$CB_SAME_ERROR_COUNT"
}

# Get state for integration (just the state string)
cb_get_state() {
  echo "$CB_STATE"
}
