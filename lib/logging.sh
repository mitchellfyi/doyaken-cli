#!/usr/bin/env bash
#
# logging.sh - Centralized logging functions for doyaken
#
# This file provides consistent logging across all doyaken components.
# Source this file at the top of any script that needs logging.
#
# Usage:
#   source "$DOYAKEN_HOME/lib/logging.sh"
#   log_info "Starting process..."
#   log_success "Done!"
#   log_warn "Something might be wrong"
#   log_error "Something failed"
#

# Prevent multiple sourcing
[[ -n "${_DOYAKEN_LOGGING_LOADED:-}" ]] && return 0
_DOYAKEN_LOGGING_LOADED=1

# ============================================================================
# Color Definitions
# ============================================================================

# Only set colors if terminal supports them
# Use $'...' (ANSI-C quoting) so variables contain actual escape characters.
# This makes colors work everywhere: echo, echo -e, printf, cat heredocs.
if [[ -t 1 ]] && [[ "${TERM:-}" != "dumb" ]]; then
  RED=$'\033[0;31m'
  GREEN=$'\033[0;32m'
  YELLOW=$'\033[0;33m'
  BLUE=$'\033[0;34m'
  CYAN=$'\033[0;36m'
  BOLD=$'\033[1m'
  DIM=$'\033[2m'
  NC=$'\033[0m'
else
  RED=''
  GREEN=''
  YELLOW=''
  BLUE=''
  CYAN=''
  BOLD=''
  DIM=''
  NC=''
fi

# Export colors for subshells
export RED GREEN YELLOW BLUE CYAN BOLD DIM NC

# ============================================================================
# Logging Functions
# ============================================================================

# Standard logging prefix
DOYAKEN_LOG_PREFIX="${DOYAKEN_LOG_PREFIX:-doyaken}"

# Info message (blue)
log_info() {
  printf '%s\n' "${BLUE}[${DOYAKEN_LOG_PREFIX}]${NC} $1"
}

# Success message (green)
log_success() {
  printf '%s\n' "${GREEN}[${DOYAKEN_LOG_PREFIX}]${NC} $1"
}

# Warning message (yellow)
log_warn() {
  printf '%s\n' "${YELLOW}[${DOYAKEN_LOG_PREFIX}]${NC} $1"
}

# Error message (red, to stderr)
log_error() {
  printf '%s\n' "${RED}[${DOYAKEN_LOG_PREFIX}]${NC} $1" >&2
}

# Step/phase message (cyan, for workflow phases)
log_step() {
  printf '%s\n' "${CYAN}[${DOYAKEN_LOG_PREFIX}]${NC} $1"
}

# Phase header (bold cyan, for major sections)
log_phase() {
  printf '%s\n' "${CYAN}${BOLD}[${DOYAKEN_LOG_PREFIX}]${NC} ${BOLD}$1${NC}"
}

# Debug message (only if DOYAKEN_DEBUG is set)
log_debug() {
  [[ -n "${DOYAKEN_DEBUG:-}" ]] && printf '%s\n' "${BLUE}[debug]${NC} $1" >&2
}

# ============================================================================
# Utility Functions
# ============================================================================

# Set custom log prefix for a component
# Usage: set_log_prefix "upgrade"
set_log_prefix() {
  DOYAKEN_LOG_PREFIX="${1:-doyaken}"
}

# Reset to default prefix
reset_log_prefix() {
  DOYAKEN_LOG_PREFIX="doyaken"
}

# Export functions for subshells
export -f log_info log_success log_warn log_error log_step log_phase log_debug set_log_prefix reset_log_prefix 2>/dev/null || true
