#!/usr/bin/env bash
#
# run-bats.sh - Run bats unit and integration tests
#
# Usage:
#   ./test/run-bats.sh           # Run all bats tests
#   ./test/run-bats.sh unit      # Run only unit tests
#   ./test/run-bats.sh integration  # Run only integration tests
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[bats]${NC} $1"; }
log_success() { echo -e "${GREEN}[bats]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[bats]${NC} $1"; }
log_error() { echo -e "${RED}[bats]${NC} $1"; }

# Check for bats
check_bats() {
  if command -v bats &>/dev/null; then
    return 0
  fi

  # Try npx bats
  if command -v npx &>/dev/null; then
    log_info "bats not found, using npx bats-core..."
    return 0
  fi

  log_error "bats not found"
  echo ""
  echo "Install bats-core:"
  echo "  brew install bats-core    # macOS"
  echo "  npm install -D bats       # npm (project-local)"
  echo "  apt install bats          # Debian/Ubuntu"
  echo ""
  return 1
}

run_bats() {
  local test_path="$1"

  if command -v bats &>/dev/null; then
    bats "$test_path"
  else
    npx bats "$test_path"
  fi
}

main() {
  local test_type="${1:-all}"

  log_info "Running bats tests..."
  echo ""

  if ! check_bats; then
    exit 1
  fi

  local exit_code=0

  case "$test_type" in
    unit)
      log_info "Running unit tests..."
      run_bats "$SCRIPT_DIR/unit" || exit_code=$?
      ;;
    integration)
      log_info "Running integration tests..."
      run_bats "$SCRIPT_DIR/integration" || exit_code=$?
      ;;
    all|*)
      if [ -d "$SCRIPT_DIR/unit" ] && [ "$(find "$SCRIPT_DIR/unit" -name '*.bats' 2>/dev/null | head -1)" ]; then
        log_info "Running unit tests..."
        run_bats "$SCRIPT_DIR/unit" || exit_code=$?
      fi

      echo ""

      if [ -d "$SCRIPT_DIR/integration" ] && [ "$(find "$SCRIPT_DIR/integration" -name '*.bats' 2>/dev/null | head -1)" ]; then
        log_info "Running integration tests..."
        run_bats "$SCRIPT_DIR/integration" || exit_code=$?
      fi
      ;;
  esac

  echo ""
  if [ "$exit_code" -eq 0 ]; then
    log_success "All bats tests passed!"
  else
    log_error "Some bats tests failed"
  fi

  return $exit_code
}

main "$@"
