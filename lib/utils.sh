#!/usr/bin/env bash
#
# utils.sh - Common utilities for doyaken CLI
#
# Provides: colors, logging, auto-timeout, fuzzy matching
#

# ============================================================================
# Colors
# ============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# ============================================================================
# Logging
# ============================================================================

log_info() { echo -e "${BLUE}[doyaken]${NC} $1"; }
log_success() { echo -e "${GREEN}[doyaken]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[doyaken]${NC} $1"; }
log_error() { echo -e "${RED}[doyaken]${NC} $1" >&2; }

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
      # User provided input
      eval "$var_name=\"\$result\""
    else
      # Timeout - pick random option
      echo ""
      local random_idx=$((RANDOM % num_options))
      result="${options[$random_idx]}"
      log_info "Auto-selected option: $result"
      eval "$var_name=\"\$result\""
    fi
  else
    # No timeout - normal read
    read -rp "$prompt" result
    eval "$var_name=\"\$result\""
  fi
}

# ============================================================================
# Fuzzy Command Matching
# ============================================================================

# List of valid commands for fuzzy matching
DOYAKEN_COMMANDS="run init register unregister list tasks task add status manifest doctor skills skill config upgrade review mcp hooks sync commands version help"

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
