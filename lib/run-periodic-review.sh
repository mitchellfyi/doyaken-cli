#!/usr/bin/env bash
#
# run-periodic-review.sh - Execute periodic review workflow
#
# This script runs the periodic-review skill and handles:
# - Configuration loading
# - Error handling (graceful degradation)
# - Logging
# - Counter reset on completion
#
# Usage:
#   ./run-periodic-review.sh [--fix] [--no-tasks] [--scope=SCOPE]
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOYAKEN_HOME="${DOYAKEN_HOME:-$HOME/.doyaken}"

# Source centralized logging
if [[ -f "$SCRIPT_DIR/logging.sh" ]]; then
  source "$SCRIPT_DIR/logging.sh"
  set_log_prefix "review"
else
  # Fallback
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  YELLOW='\033[0;33m'
  BLUE='\033[0;34m'
  NC='\033[0m'
  log_info() { echo -e "${BLUE}[review]${NC} $1"; }
  log_success() { echo -e "${GREEN}[review]${NC} $1"; }
  log_warn() { echo -e "${YELLOW}[review]${NC} $1"; }
  log_error() { echo -e "${RED}[review]${NC} $1" >&2; }
fi

# Source libraries
source "$SCRIPT_DIR/review-tracker.sh" 2>/dev/null || {
  log_error "Failed to load review-tracker.sh"
  exit 1
}

# ============================================================================
# Argument Parsing
# ============================================================================

FIX_MODE="true"
CREATE_TASKS="true"
SCOPE="all"
BACKGROUND="false"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --fix|-f)
      FIX_MODE="true"
      shift
      ;;
    --no-tasks)
      CREATE_TASKS="false"
      shift
      ;;
    --scope=*)
      SCOPE="${1#*=}"
      shift
      ;;
    --scope)
      SCOPE="$2"
      shift 2
      ;;
    --background|-b)
      BACKGROUND="true"
      shift
      ;;
    --help|-h)
      cat << 'EOF'
run-periodic-review.sh - Execute periodic codebase review

Usage:
  ./run-periodic-review.sh [OPTIONS]

Options:
  --fix, -f       Enable auto-fix mode (fix issues automatically where possible)
  --no-tasks      Don't create task files (only fix or report)
  --scope=SCOPE   Review scope: all, quality, security, performance, debt, ux, docs
  --background    Run in background (non-blocking)
  --help, -h      Show this help

Examples:
  ./run-periodic-review.sh                    # Full review, create tasks
  ./run-periodic-review.sh --fix              # Full review with auto-fix
  ./run-periodic-review.sh --scope=security   # Security-only review
EOF
      exit 0
      ;;
    *)
      shift
      ;;
  esac
done

# ============================================================================
# Main
# ============================================================================

main() {
  log_info "Starting periodic review..."
  log_info "Scope: $SCOPE | Fix: $FIX_MODE | Tasks: $CREATE_TASKS"

  # Check if enabled
  if ! review_tracker_is_enabled; then
    log_warn "Periodic reviews are disabled in configuration"
    exit 0
  fi

  # Find project directory (look for .doyaken folder)
  local project_dir=""
  local current="$PWD"
  while [ "$current" != "/" ]; do
    if [ -d "$current/.doyaken" ]; then
      project_dir="$current"
      break
    fi
    current="$(dirname "$current")"
  done

  if [ -z "$project_dir" ]; then
    log_warn "Not in a doyaken project (no .doyaken directory found)"
    project_dir="$PWD"
  fi

  cd "$project_dir"

  # Build skill arguments
  local skill_args="fix=$FIX_MODE create-tasks=$CREATE_TASKS scope=$SCOPE"

  # Check if we have claude CLI
  if ! command -v claude &>/dev/null; then
    log_error "Claude CLI not found. Please install from: https://claude.ai/cli"
    exit 1
  fi

  # Prepare log file
  local log_dir="$DOYAKEN_HOME/logs"
  mkdir -p "$log_dir"
  local log_file="$log_dir/review-$(date '+%Y%m%d-%H%M%S').log"

  log_info "Log file: $log_file"

  # Build prompt with skill
  local skill_file="$DOYAKEN_HOME/skills/periodic-review.md"
  if [ ! -f "$skill_file" ]; then
    log_error "Skill file not found: $skill_file"
    exit 1
  fi

  # Run the review via claude
  local exit_code=0

  if [ "$BACKGROUND" = "true" ]; then
    log_info "Running in background..."
    nohup bash -c "
      cd '$project_dir'
      claude --print 'Run the periodic-review skill with args: $skill_args. Follow the methodology exactly.' 2>&1 | tee -a '$log_file'
    " > /dev/null 2>&1 &
    log_success "Review started in background (PID: $!)"
    log_info "Check log: tail -f $log_file"
  else
    # Run interactively
    claude --print "Run the periodic-review skill with args: $skill_args. Follow the methodology exactly." 2>&1 | tee -a "$log_file" || exit_code=$?
  fi

  if [ "$exit_code" -eq 0 ]; then
    # Reset the counter on success
    review_tracker_reset
    log_success "Periodic review complete. Counter reset."
  else
    log_warn "Review completed with warnings (exit code: $exit_code)"
    log_warn "Counter NOT reset - review may have encountered issues"
  fi

  return $exit_code
}

# Run main
main "$@"
