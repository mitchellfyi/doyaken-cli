#!/usr/bin/env bats
#
# Tests for lib/rate_limiter.sh
#

load '../test_helper'

setup() {
  export TEST_TEMP_DIR
  TEST_TEMP_DIR="$(mktemp -d)"
  export DOYAKEN_HOME="$PROJECT_ROOT"
  export STATE_DIR="$TEST_TEMP_DIR/state"

  mkdir -p "$STATE_DIR"

  # Source dependencies
  source "$PROJECT_ROOT/lib/logging.sh"
  source "$PROJECT_ROOT/lib/config.sh"
  source "$PROJECT_ROOT/lib/rate_limiter.sh"
}

teardown() {
  if [[ -d "${TEST_TEMP_DIR:-}" ]]; then
    rm -rf "$TEST_TEMP_DIR"
  fi
}

# ============================================================================
# Loading and Configuration
# ============================================================================

@test "rate_limiter.sh loads without error" {
  [[ -n "$_DOYAKEN_RATE_LIMITER_LOADED" ]]
}

@test "default config values are set" {
  [[ "$RL_ENABLED" == "1" ]]
  [[ "$RL_CALLS_PER_HOUR" == "80" ]]
  [[ "$RL_WARNING_THRESHOLD" == "80" ]]
}

@test "load_rate_limiter_config loads defaults" {
  unset RL_ENABLED RL_CALLS_PER_HOUR RL_WARNING_THRESHOLD
  export RL_ENABLED="" RL_CALLS_PER_HOUR="" RL_WARNING_THRESHOLD=""

  load_rate_limiter_config ""

  [[ "$RL_ENABLED" == "1" ]]
  [[ "$RL_CALLS_PER_HOUR" == "80" ]]
  [[ "$RL_WARNING_THRESHOLD" == "80" ]]
}

# ============================================================================
# Rate Limit Log File
# ============================================================================

@test "_rl_log_file returns path in STATE_DIR" {
  local path
  path=$(_rl_log_file)
  [[ "$path" == "$STATE_DIR/rate_limit.log" ]]
}

@test "_rl_prune_and_count returns 0 for no log file" {
  local count
  count=$(_rl_prune_and_count)
  [[ "$count" -eq 0 ]]
}

@test "_rl_prune_and_count counts recent entries" {
  local log_file
  log_file=$(_rl_log_file)
  local now
  now=$(date +%s)

  # Write 3 recent timestamps
  echo "$now" > "$log_file"
  echo "$((now - 100))" >> "$log_file"
  echo "$((now - 200))" >> "$log_file"

  local count
  count=$(_rl_prune_and_count)
  [[ "$count" -eq 3 ]]
}

@test "_rl_prune_and_count removes old entries" {
  local log_file
  log_file=$(_rl_log_file)
  local now
  now=$(date +%s)

  # Write 2 recent and 2 old timestamps
  echo "$now" > "$log_file"
  echo "$((now - 100))" >> "$log_file"
  echo "$((now - 4000))" >> "$log_file"  # > 1 hour ago
  echo "$((now - 5000))" >> "$log_file"  # > 1 hour ago

  local count
  count=$(_rl_prune_and_count)
  [[ "$count" -eq 2 ]]

  # Verify old entries were pruned from file
  local remaining
  remaining=$(wc -l < "$log_file" | tr -d ' ')
  [[ "$remaining" -eq 2 ]]
}

@test "_rl_earliest_expiry returns correct time" {
  local log_file
  log_file=$(_rl_log_file)
  local now
  now=$(date +%s)
  local oldest=$((now - 3500))  # 3500s ago (within 1-hour window)

  echo "$oldest" > "$log_file"
  echo "$((now - 100))" >> "$log_file"

  local expiry
  expiry=$(_rl_earliest_expiry)
  [[ "$expiry" -eq $((oldest + 3600)) ]]
}

@test "_rl_earliest_expiry returns 0 for empty log" {
  local expiry
  expiry=$(_rl_earliest_expiry)
  [[ "$expiry" -eq 0 ]]
}

# ============================================================================
# Rate Limit Recording
# ============================================================================

@test "rate_limit_record appends timestamp" {
  rate_limit_record

  local log_file
  log_file=$(_rl_log_file)
  [[ -f "$log_file" ]]

  local count
  count=$(wc -l < "$log_file" | tr -d ' ')
  [[ "$count" -eq 1 ]]
}

@test "rate_limit_record appends multiple timestamps" {
  rate_limit_record
  rate_limit_record
  rate_limit_record

  local log_file
  log_file=$(_rl_log_file)
  local count
  count=$(wc -l < "$log_file" | tr -d ' ')
  [[ "$count" -eq 3 ]]
}

@test "rate_limit_record skipped when disabled" {
  RL_ENABLED=0
  rate_limit_record

  local log_file
  log_file=$(_rl_log_file)
  [[ ! -f "$log_file" ]]
}

# ============================================================================
# Rate Limit Check
# ============================================================================

@test "rate_limit_check returns 0 under quota" {
  RL_CALLS_PER_HOUR=10
  # Record 5 calls (under quota of 10)
  for i in $(seq 1 5); do
    rate_limit_record
  done

  rate_limit_check "TEST"
}

@test "rate_limit_check returns 0 when disabled" {
  RL_ENABLED=0
  RL_CALLS_PER_HOUR=1

  # Record 10 calls (would be over quota)
  local log_file
  log_file=$(_rl_log_file)
  local now
  now=$(date +%s)
  for i in $(seq 1 10); do
    echo "$now" >> "$log_file"
  done

  RL_ENABLED=0
  rate_limit_check "TEST"
}

@test "rate_limit_check warns at threshold" {
  RL_CALLS_PER_HOUR=10
  RL_WARNING_THRESHOLD=50  # Warn at 50%

  # Record 6 calls (60%, above 50% threshold)
  local log_file
  log_file=$(_rl_log_file)
  local now
  now=$(date +%s)
  for i in $(seq 1 6); do
    echo "$now" >> "$log_file"
  done

  run rate_limit_check "TEST"
  [[ "$status" -eq 0 ]]
  [[ "$output" == *"6/10"* ]]
}

@test "rate_limit_status returns current usage" {
  RL_CALLS_PER_HOUR=10
  rate_limit_record
  rate_limit_record

  local status_str
  status_str=$(rate_limit_status)
  [[ "$status_str" == "2/10" ]]
}

@test "rate_limit_status returns 0 for empty" {
  RL_CALLS_PER_HOUR=10
  local status_str
  status_str=$(rate_limit_status)
  [[ "$status_str" == "0/10" ]]
}

# ============================================================================
# Edge Cases
# ============================================================================

@test "_rl_prune_and_count handles malformed timestamps" {
  local log_file
  log_file=$(_rl_log_file)
  local now
  now=$(date +%s)

  # Mix valid and invalid timestamps
  echo "$now" > "$log_file"
  echo "not-a-timestamp" >> "$log_file"
  echo "$((now - 100))" >> "$log_file"
  echo "" >> "$log_file"  # empty line
  echo "123abc" >> "$log_file"

  local count
  count=$(_rl_prune_and_count)
  # Should only count valid timestamps within window
  [[ "$count" -eq 2 ]]
}

@test "_rl_earliest_expiry handles corrupted log file" {
  local log_file
  log_file=$(_rl_log_file)

  # Write invalid data
  echo "invalid" > "$log_file"
  echo "" >> "$log_file"
  echo "abc123" >> "$log_file"

  local expiry
  expiry=$(_rl_earliest_expiry)
  # Should return 0 when no valid timestamps found
  [[ "$expiry" -eq 0 ]]
}

@test "rate_limit_check handles boundary values" {
  # Test exactly at quota
  RL_CALLS_PER_HOUR=5
  for i in $(seq 1 5); do
    rate_limit_record
  done

  # Should still pass (not over quota yet)
  rate_limit_check "TEST"
}

@test "rate_limit_record handles concurrent writes" {
  # Simulate concurrent writes by appending in background
  local log_file
  log_file=$(_rl_log_file)

  # Start multiple background writers
  for i in $(seq 1 5); do
    (rate_limit_record) &
  done

  # Wait for all to complete
  wait

  # Log file should exist and have entries
  [[ -f "$log_file" ]]
  local count
  count=$(wc -l < "$log_file" | tr -d ' ')
  [[ "$count" -ge 1 ]]  # At least one write succeeded
}

@test "_rl_prune_and_count handles large log files" {
  local log_file
  log_file=$(_rl_log_file)
  local now
  now=$(date +%s)

  # Create large log with mix of old and new entries
  for i in $(seq 1 1000); do
    if (( i % 2 == 0 )); then
      echo "$((now - 5000))" >> "$log_file"  # Old entry
    else
      echo "$((now - i))" >> "$log_file"     # Recent entry
    fi
  done

  local count
  count=$(_rl_prune_and_count)
  # Should have pruned old entries and count only recent ones
  [[ "$count" -eq 500 ]]
}
