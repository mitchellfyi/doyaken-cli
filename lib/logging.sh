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
if [[ -t 1 ]] && [[ "${TERM:-}" != "dumb" ]]; then
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  YELLOW='\033[0;33m'
  BLUE='\033[0;34m'
  CYAN='\033[0;36m'
  BOLD='\033[1m'
  NC='\033[0m'  # No Color
else
  RED=''
  GREEN=''
  YELLOW=''
  BLUE=''
  CYAN=''
  BOLD=''
  NC=''
fi

# Export colors for subshells
export RED GREEN YELLOW BLUE CYAN BOLD NC

# ============================================================================
# Logging Functions
# ============================================================================

# Standard logging prefix
DOYAKEN_LOG_PREFIX="${DOYAKEN_LOG_PREFIX:-doyaken}"

# Info message (blue)
log_info() {
  echo -e "${BLUE}[${DOYAKEN_LOG_PREFIX}]${NC} $1"
}

# Success message (green)
log_success() {
  echo -e "${GREEN}[${DOYAKEN_LOG_PREFIX}]${NC} $1"
}

# Warning message (yellow)
log_warn() {
  echo -e "${YELLOW}[${DOYAKEN_LOG_PREFIX}]${NC} $1"
}

# Error message (red, to stderr)
log_error() {
  echo -e "${RED}[${DOYAKEN_LOG_PREFIX}]${NC} $1" >&2
}

# Step/phase message (cyan, for workflow phases)
log_step() {
  echo -e "${CYAN}[${DOYAKEN_LOG_PREFIX}]${NC} $1"
}

# Phase header (bold cyan, for major sections)
log_phase() {
  echo -e "${CYAN}${BOLD}[${DOYAKEN_LOG_PREFIX}]${NC} ${BOLD}$1${NC}"
}

# Debug message (only if DOYAKEN_DEBUG is set)
log_debug() {
  [[ -n "${DOYAKEN_DEBUG:-}" ]] && echo -e "${BLUE}[debug]${NC} $1" >&2
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
