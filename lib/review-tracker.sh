#!/usr/bin/env bash
#
# doyaken Review Tracker Library
#
# Tracks task completions and triggers periodic reviews when threshold is reached.
# State is stored in a simple integer counter file.
#

# ============================================================================
# Configuration
# ============================================================================

DOYAKEN_HOME="${DOYAKEN_HOME:-$HOME/.doyaken}"
REVIEW_STATE_DIR="${DOYAKEN_HOME}/state"
REVIEW_COUNTER_FILE="${REVIEW_STATE_DIR}/task-completion-counter"

# Default threshold (can be overridden by config)
REVIEW_THRESHOLD="${REVIEW_THRESHOLD:-3}"

# ============================================================================
# State Management
# ============================================================================

# Initialize state directory if needed
_review_init_state() {
  mkdir -p "$REVIEW_STATE_DIR"
  if [ ! -f "$REVIEW_COUNTER_FILE" ]; then
    echo "0" > "$REVIEW_COUNTER_FILE"
  fi
}

# Get current completion count
# Returns: integer count
review_tracker_get_count() {
  _review_init_state
  cat "$REVIEW_COUNTER_FILE" 2>/dev/null || echo "0"
}

# Increment the completion counter
# Usage: review_tracker_increment
review_tracker_increment() {
  _review_init_state
  local current
  current=$(review_tracker_get_count)
  local new=$((current + 1))
  echo "$new" > "$REVIEW_COUNTER_FILE"
  echo "$new"
}

# Reset the counter (after a review is completed)
# Usage: review_tracker_reset
review_tracker_reset() {
  _review_init_state
  echo "0" > "$REVIEW_COUNTER_FILE"
}

# Check if threshold is reached
# Returns: 0 if review should trigger, 1 otherwise
review_tracker_should_trigger() {
  local count
  count=$(review_tracker_get_count)

  # Load threshold from config if available
  local threshold="${REVIEW_THRESHOLD:-3}"

  if [ "$count" -ge "$threshold" ]; then
    return 0
  else
    return 1
  fi
}

# Get the current threshold
# Returns: threshold number
review_tracker_get_threshold() {
  echo "${REVIEW_THRESHOLD:-3}"
}

# Get status string for display
# Returns: "X/Y tasks completed"
review_tracker_status() {
  local count
  count=$(review_tracker_get_count)
  local threshold
  threshold=$(review_tracker_get_threshold)
  echo "$count/$threshold tasks until next review"
}

# ============================================================================
# Utility
# ============================================================================

# Check if periodic reviews are enabled
# Returns: 0 if enabled, 1 if disabled
review_tracker_is_enabled() {
  if [ "${REVIEW_ENABLED:-1}" = "1" ] || [ "${REVIEW_ENABLED:-true}" = "true" ]; then
    return 0
  else
    return 1
  fi
}

# ============================================================================
# Main Entry Point (for direct execution)
# ============================================================================

if [[ "${BASH_SOURCE[0]:-}" == "${0:-}" ]] && [[ -n "${0:-}" ]]; then
  echo "This is a library file. Source it from another script:"
  echo "  source lib/review-tracker.sh"
  exit 1
fi
