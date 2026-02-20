#!/usr/bin/env bash
#
# errors.sh - Actionable error collection and batch reporting
#
# Collects errors with fix suggestions during validation/doctor runs,
# then reports them all at once with numbered suggestions.
#
# Uses parallel arrays for Bash 3.x compatibility (no associative arrays).
#

# Prevent multiple sourcing
[[ -n "${_DOYAKEN_ERRORS_LOADED:-}" ]] && return 0
_DOYAKEN_ERRORS_LOADED=1

# Parallel arrays for error collection
_ERROR_MESSAGES=()
_ERROR_FIXES=()
_ERROR_DOCS=()

# Reset error collection
error_init() {
  _ERROR_MESSAGES=()
  _ERROR_FIXES=()
  _ERROR_DOCS=()
}

# Add an error with actionable fix suggestion
# Usage: error_add "message" "fix suggestion" ["doc_url"]
error_add() {
  local msg="$1"
  local fix="${2:-}"
  local doc="${3:-}"
  _ERROR_MESSAGES+=("$msg")
  _ERROR_FIXES+=("$fix")
  _ERROR_DOCS+=("$doc")
}

# Check if any errors have been collected
# Returns 0 if errors exist, 1 if none
error_has_errors() {
  [ ${#_ERROR_MESSAGES[@]} -gt 0 ]
}

# Print all collected errors as a numbered list with fix suggestions
error_report() {
  if ! error_has_errors; then
    return 0
  fi

  local count=${#_ERROR_MESSAGES[@]}
  echo ""
  echo -e "${RED:-}Found $count error(s):${NC:-}"
  echo ""

  local i
  for (( i=0; i < count; i++ )); do
    local num=$((i + 1))
    echo -e "  ${RED:-}$num.${NC:-} ${_ERROR_MESSAGES[$i]}"
    if [ -n "${_ERROR_FIXES[$i]:-}" ]; then
      echo -e "     ${GREEN:-}Fix:${NC:-} ${_ERROR_FIXES[$i]}"
    fi
    if [ -n "${_ERROR_DOCS[$i]:-}" ]; then
      echo -e "     ${DIM:-}Docs:${NC:-} ${_ERROR_DOCS[$i]}"
    fi
  done
  echo ""
}

# Report errors and exit 1 if any exist
error_report_and_exit() {
  if error_has_errors; then
    error_report
    exit 1
  fi
}
