#!/usr/bin/env bash
#
# rate_limiter.sh - Proactive API rate limiting with hourly quotas
#
# Tracks agent CLI invocations per rolling 1-hour window and pauses
# execution when approaching the quota. Prevents 429 errors rather
# than reacting to them.
#
# Usage:
#   rate_limit_check "IMPLEMENT"   # Check before phase invocation
#   rate_limit_record              # Record an invocation after it starts
#
# Configuration (via config priority chain):
#   rate_limit.calls_per_hour: 80
#   rate_limit.enabled: true
#   rate_limit.warning_threshold: 0.8
#

# Prevent multiple sourcing
[[ -n "${_DOYAKEN_RATE_LIMITER_LOADED:-}" ]] && return 0
_DOYAKEN_RATE_LIMITER_LOADED=1

# ============================================================================
# Configuration
# ============================================================================

RL_ENABLED="${RL_ENABLED:-1}"
RL_CALLS_PER_HOUR="${RL_CALLS_PER_HOUR:-80}"
RL_WARNING_THRESHOLD="${RL_WARNING_THRESHOLD:-80}"  # Stored as percentage (80 = 80%)

# ============================================================================
# Load Configuration
# ============================================================================

load_rate_limiter_config() {
  local manifest_file="${1:-}"

  if declare -f _load_config_bool &>/dev/null; then
    _load_config_bool "RL_ENABLED" "rate_limit.enabled" "true" "$manifest_file"
  fi
  if declare -f _load_config &>/dev/null; then
    _load_config "RL_CALLS_PER_HOUR"      "rate_limit.calls_per_hour"     "80" "$manifest_file"
    _load_config "RL_WARNING_THRESHOLD"    "rate_limit.warning_threshold"  "80" "$manifest_file"
  fi
}

# ============================================================================
# Rate Limit Log File
# ============================================================================

# Get the rate limit log file path
_rl_log_file() {
  local state_dir="${STATE_DIR:-/tmp}"
  echo "$state_dir/rate_limit.log"
}

# Prune entries older than 1 hour and return current count
# Outputs: count of remaining entries
_rl_prune_and_count() {
  local log_file
  log_file=$(_rl_log_file)

  if [ ! -f "$log_file" ]; then
    echo "0"
    return 0
  fi

  local cutoff
  cutoff=$(( $(date +%s) - 3600 ))
  local tmp_file="${log_file}.tmp.$$"
  local count=0

  # Filter entries newer than cutoff
  while IFS= read -r ts; do
    if [ -n "$ts" ] && [ "$ts" -gt "$cutoff" ] 2>/dev/null; then
      echo "$ts" >> "$tmp_file"
      ((++count))
    fi
  done < "$log_file"

  # Atomic replace
  if [ -f "$tmp_file" ]; then
    mv "$tmp_file" "$log_file"
  else
    rm -f "$log_file"
  fi

  echo "$count"
}

# Get the earliest timestamp that will expire (oldest entry still in window)
_rl_earliest_expiry() {
  local log_file
  log_file=$(_rl_log_file)

  if [ ! -f "$log_file" ]; then
    echo "0"
    return
  fi

  local cutoff
  cutoff=$(( $(date +%s) - 3600 ))

  # Find oldest entry still in window
  while IFS= read -r ts; do
    if [ -n "$ts" ] && [ "$ts" -gt "$cutoff" ] 2>/dev/null; then
      # This entry expires at ts + 3600
      echo $(( ts + 3600 ))
      return
    fi
  done < "$log_file"

  echo "0"
}

# ============================================================================
# Core Functions
# ============================================================================

# Record an agent invocation
rate_limit_record() {
  [ "$RL_ENABLED" != "1" ] && return 0

  local log_file
  log_file=$(_rl_log_file)

  # Ensure directory exists
  mkdir -p "$(dirname "$log_file")" 2>/dev/null || true

  # Append current timestamp
  date +%s >> "$log_file"
}

# Check rate limit before an invocation
# Returns:
#   0 = proceed (under quota)
#   1 = blocked (at/over quota, waited but interrupted)
#
# If at quota, displays countdown and waits for a slot to open.
rate_limit_check() {
  [ "$RL_ENABLED" != "1" ] && return 0

  local phase_name="${1:-}"
  local count
  count=$(_rl_prune_and_count)

  # Check warning threshold
  local warn_at=$(( RL_CALLS_PER_HOUR * RL_WARNING_THRESHOLD / 100 ))
  if [ "$count" -ge "$warn_at" ] && [ "$count" -lt "$RL_CALLS_PER_HOUR" ]; then
    local remaining=$(( RL_CALLS_PER_HOUR - count ))
    if declare -f log_warn &>/dev/null; then
      log_warn "Rate limit: $count/$RL_CALLS_PER_HOUR calls used ($remaining remaining)"
    fi
  fi

  # Under quota — proceed
  if [ "$count" -lt "$RL_CALLS_PER_HOUR" ]; then
    return 0
  fi

  # At quota — need to wait
  if declare -f log_warn &>/dev/null; then
    log_warn "Rate limit reached: $count/$RL_CALLS_PER_HOUR calls in last hour"
    if [ -n "$phase_name" ]; then
      log_warn "Phase $phase_name is waiting for a rate limit slot..."
    fi
  fi

  # Find when the next slot opens
  local next_slot
  next_slot=$(_rl_earliest_expiry)

  if [ "$next_slot" -eq 0 ]; then
    # Shouldn't happen, but just wait a minute
    next_slot=$(( $(date +%s) + 60 ))
  fi

  # Wait with countdown (interruptible)
  _rl_wait_countdown "$next_slot" "$phase_name" || return 1

  return 0
}

# Display countdown and wait until a slot opens
# Returns 0 on successful wait, 1 if interrupted
_rl_wait_countdown() {
  local target_time="$1"
  local phase_name="${2:-}"

  while true; do
    local now
    now=$(date +%s)
    local remaining=$(( target_time - now ))

    if [ "$remaining" -le 0 ]; then
      # Slot opened
      if declare -f log_info &>/dev/null; then
        log_info "Rate limit cooldown complete — resuming${phase_name:+ $phase_name}"
      fi
      return 0
    fi

    local mins=$(( remaining / 60 ))
    local secs=$(( remaining % 60 ))

    # Overwrite same line for clean countdown display
    if [[ -t 1 ]] && [[ "${TERM:-}" != "dumb" ]]; then
      printf "\r  ⏳ Waiting for rate limit slot: %02d:%02d remaining " "$mins" "$secs"
    fi

    # Interruptible sleep
    sleep 1 &
    wait $! 2>/dev/null || return 1
  done
}

# Get current usage info (for status display)
rate_limit_status() {
  local count
  count=$(_rl_prune_and_count)
  echo "$count/$RL_CALLS_PER_HOUR"
}
