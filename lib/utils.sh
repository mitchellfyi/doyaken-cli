#!/usr/bin/env bash
#
# utils.sh - Common utilities for doyaken CLI
#
# Provides: auto-timeout, fuzzy matching
#

# Source centralized logging
SCRIPT_DIR_UTILS="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR_UTILS/logging.sh"

# ============================================================================
# Auto-timeout for autonomous mode
# ============================================================================

# Read user input with optional timeout and random fallback
# Usage: read_with_timeout <var_name> <prompt> <valid_options...>
# Returns: Sets the variable to user input or random choice on timeout
# Example: read_with_timeout choice "Enter [1-3]: " 1 2 3
read_with_timeout() {
  local var_name="$1"
  local prompt="$2"
  shift 2
  local -a options=("$@")
  local timeout="${DOYAKEN_AUTO_TIMEOUT:-60}"
  local result=""
  local num_options="${#options[@]}"

  if [ "$timeout" -gt 0 ] && [ "$num_options" -gt 0 ]; then
    # Show timeout indicator
    echo -e "  ${YELLOW}(auto-select in ${timeout}s)${NC}"
    echo ""

    # Read with timeout - use printf for prompt to avoid -p issues
    printf "%s" "$prompt"
    if read -r -t "$timeout" result 2>/dev/null; then
      # User provided input - use printf -v for safe variable assignment
      printf -v "$var_name" '%s' "$result"
    else
      # Timeout - pick random option
      echo ""
      local random_idx=$((RANDOM % num_options))
      result="${options[$random_idx]}"
      log_info "Auto-selected option: $result"
      printf -v "$var_name" '%s' "$result"
    fi
  else
    # No timeout - normal read
    read -rp "$prompt" result
    printf -v "$var_name" '%s' "$result"
  fi
}

# ============================================================================
# Fuzzy Command Matching
# ============================================================================

# List of valid commands for fuzzy matching
DOYAKEN_COMMANDS="run chat init register unregister list status manifest doctor skills skill config upgrade review mcp hooks sync commands sessions validate stats audit generate version help"

# Find similar command for typo suggestions
# Returns closest match or empty string
fuzzy_match_command() {
  local input="$1"
  local input_len=${#input}

  # Too short to match
  (( input_len < 2 )) && return

  for cmd in $DOYAKEN_COMMANDS; do
    local cmd_len=${#cmd}

    # Exact prefix match (user typed partial command)
    if [[ "$cmd" == "$input"* ]] && (( input_len >= 3 )); then
      echo "$cmd"
      return
    fi

    # One character missing (taks -> tasks)
    if (( cmd_len == input_len + 1 )); then
      for (( i=0; i<=cmd_len; i++ )); do
        local without="${cmd:0:$i}${cmd:$((i+1))}"
        if [[ "$without" == "$input" ]]; then
          echo "$cmd"
          return
        fi
      done
    fi

    # One character extra (statuss -> status)
    if (( cmd_len == input_len - 1 )); then
      for (( i=0; i<=input_len; i++ )); do
        local without="${input:0:$i}${input:$((i+1))}"
        if [[ "$without" == "$cmd" ]]; then
          echo "$cmd"
          return
        fi
      done
    fi

    # Adjacent swap (stauts -> status)
    if (( cmd_len == input_len )); then
      for (( i=0; i<input_len-1; i++ )); do
        local swapped="${input:0:$i}${input:$((i+1)):1}${input:$i:1}${input:$((i+2))}"
        if [[ "$swapped" == "$cmd" ]]; then
          echo "$cmd"
          return
        fi
      done
    fi
  done
}
