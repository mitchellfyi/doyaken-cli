#!/usr/bin/env bash
#
# verify-install.sh - Verify doyaken installation
#
# Checks all dependencies, environment variables, and basic functionality.
# Provides clear pass/fail status with helpful error messages.
#
# Usage:
#   ./scripts/verify-install.sh           # Run all checks
#   ./scripts/verify-install.sh --quiet   # Only show errors
#
set -uo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

# Counters
PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

# Options
QUIET=false
[[ "${1:-}" == "--quiet" || "${1:-}" == "-q" ]] && QUIET=true

# Helper functions
log_check() {
  [[ "$QUIET" == true ]] && return
  echo -e "${BLUE}[CHECK]${NC} $1"
}

log_pass() {
  ((PASS_COUNT++))
  [[ "$QUIET" == true ]] && return
  echo -e "${GREEN}[PASS]${NC}  $1"
}

log_fail() {
  ((FAIL_COUNT++))
  echo -e "${RED}[FAIL]${NC}  $1"
  if [[ -n "${2:-}" ]]; then
    echo -e "        ${YELLOW}Hint:${NC} $2"
  fi
}

log_warn() {
  ((WARN_COUNT++))
  [[ "$QUIET" == true ]] && return
  echo -e "${YELLOW}[WARN]${NC}  $1"
  if [[ -n "${2:-}" ]]; then
    echo -e "        ${YELLOW}Hint:${NC} $2"
  fi
}

log_section() {
  [[ "$QUIET" == true ]] && return
  echo ""
  echo -e "${BOLD}$1${NC}"
  echo "$(printf '=%.0s' {1..40})"
}

# Check if command exists
check_command() {
  local cmd="$1"
  local hint="${2:-}"
  local required="${3:-true}"

  if command -v "$cmd" &>/dev/null; then
    local version
    version=$("$cmd" --version 2>/dev/null | head -1 || echo "version unknown")
    log_pass "$cmd: $version"
    return 0
  else
    if [[ "$required" == true ]]; then
      log_fail "$cmd not found" "$hint"
    else
      log_warn "$cmd not found (optional)" "$hint"
    fi
    return 1
  fi
}

# Check environment variable
check_env() {
  local var="$1"
  local hint="${2:-}"
  local required="${3:-true}"

  if [[ -n "${!var:-}" ]]; then
    log_pass "$var is set"
    return 0
  else
    if [[ "$required" == true ]]; then
      log_fail "$var not set" "$hint"
    else
      log_warn "$var not set (optional)" "$hint"
    fi
    return 1
  fi
}

# Check file exists
check_file() {
  local file="$1"
  local hint="${2:-}"

  if [[ -f "$file" ]]; then
    log_pass "File exists: $file"
    return 0
  else
    log_fail "File not found: $file" "$hint"
    return 1
  fi
}

# Check directory exists
check_dir() {
  local dir="$1"
  local hint="${2:-}"

  if [[ -d "$dir" ]]; then
    log_pass "Directory exists: $dir"
    return 0
  else
    log_fail "Directory not found: $dir" "$hint"
    return 1
  fi
}

# Main verification
main() {
  echo ""
  echo -e "${BOLD}Doyaken Installation Verification${NC}"
  echo "==================================="
  echo ""

  # ============================================
  # Required Dependencies
  # ============================================
  log_section "Required Dependencies"

  check_command "bash" "Bash 3.2+ is required" true
  check_command "git" "Install git: https://git-scm.com/downloads" true
  check_command "yq" "Install yq: https://github.com/mikefarah/yq#install" true

  # ============================================
  # Optional Dependencies
  # ============================================
  log_section "Optional Dependencies"

  # Node.js (for npm installation)
  check_command "node" "Install Node.js 16+: https://nodejs.org" false
  check_command "npm" "Comes with Node.js" false

  # ============================================
  # AI Agent CLIs (at least one required)
  # ============================================
  log_section "AI Agent CLIs (at least one required)"

  AGENT_FOUND=false

  if command -v claude &>/dev/null; then
    log_pass "claude CLI found (recommended)"
    AGENT_FOUND=true
  else
    log_warn "claude CLI not found" "Install: npm i -g @anthropic-ai/claude-code"
  fi

  if command -v cursor &>/dev/null; then
    log_pass "cursor CLI found"
    AGENT_FOUND=true
  else
    [[ "$QUIET" == false ]] && log_warn "cursor CLI not found" "Install: curl https://cursor.com/install -fsS | bash"
  fi

  if command -v codex &>/dev/null; then
    log_pass "codex CLI found"
    AGENT_FOUND=true
  else
    [[ "$QUIET" == false ]] && log_warn "codex CLI not found" "Install: npm i -g @openai/codex"
  fi

  if command -v gemini &>/dev/null; then
    log_pass "gemini CLI found"
    AGENT_FOUND=true
  else
    [[ "$QUIET" == false ]] && log_warn "gemini CLI not found" "Install: npm i -g @google/gemini-cli"
  fi

  if command -v copilot &>/dev/null; then
    log_pass "copilot CLI found"
    AGENT_FOUND=true
  else
    [[ "$QUIET" == false ]] && log_warn "copilot CLI not found" "Install: npm i -g @github/copilot"
  fi

  if command -v opencode &>/dev/null; then
    log_pass "opencode CLI found"
    AGENT_FOUND=true
  else
    [[ "$QUIET" == false ]] && log_warn "opencode CLI not found" "Install: npm i -g opencode-ai"
  fi

  if [[ "$AGENT_FOUND" == false ]]; then
    log_fail "No AI agent CLI found" "Install at least one: claude (recommended), cursor, codex, gemini, copilot, or opencode"
  fi

  # ============================================
  # Doyaken Installation
  # ============================================
  log_section "Doyaken Installation"

  # Check if doyaken is installed
  DOYAKEN_HOME="${DOYAKEN_HOME:-$HOME/.doyaken}"

  if command -v doyaken &>/dev/null; then
    local dk_version
    dk_version=$(doyaken --version 2>/dev/null || echo "unknown")
    log_pass "doyaken CLI available: $dk_version"
  elif command -v dk &>/dev/null; then
    local dk_version
    dk_version=$(dk --version 2>/dev/null || echo "unknown")
    log_pass "dk CLI available: $dk_version"
  elif [[ -x "$DOYAKEN_HOME/bin/doyaken" ]]; then
    local dk_version
    dk_version=$("$DOYAKEN_HOME/bin/doyaken" --version 2>/dev/null || echo "unknown")
    log_pass "doyaken found at $DOYAKEN_HOME/bin/doyaken: $dk_version"
    log_warn "doyaken not in PATH" "Add to PATH: export PATH=\"$DOYAKEN_HOME/bin:\$PATH\""
  else
    log_fail "doyaken not installed" "Run: npm install -g @doyaken/doyaken OR curl -sSL https://raw.githubusercontent.com/mitchellfyi/doyaken-cli/main/install.sh | bash"
  fi

  # Check installation directory
  if [[ -d "$DOYAKEN_HOME" ]]; then
    log_pass "DOYAKEN_HOME exists: $DOYAKEN_HOME"

    # Check key subdirectories
    check_dir "$DOYAKEN_HOME/bin" "Missing bin directory"
    check_dir "$DOYAKEN_HOME/lib" "Missing lib directory"
    check_dir "$DOYAKEN_HOME/prompts" "Missing prompts directory"

    # Check VERSION file
    if [[ -f "$DOYAKEN_HOME/VERSION" ]]; then
      local version
      version=$(cat "$DOYAKEN_HOME/VERSION")
      log_pass "VERSION file: $version"
    else
      log_warn "VERSION file not found" "Run: dk upgrade"
    fi
  else
    log_warn "DOYAKEN_HOME not found: $DOYAKEN_HOME" "Run install script or set DOYAKEN_HOME"
  fi

  # ============================================
  # Environment Variables
  # ============================================
  log_section "Environment Variables"

  # Check optional but useful env vars
  check_env "DOYAKEN_HOME" "Set to installation directory (default: ~/.doyaken)" false

  # Check for API keys (optional, but needed for agents)
  if [[ -n "${ANTHROPIC_API_KEY:-}" ]]; then
    log_pass "ANTHROPIC_API_KEY is set (for claude)"
  else
    log_warn "ANTHROPIC_API_KEY not set" "Required for claude CLI without login"
  fi

  if [[ -n "${OPENAI_API_KEY:-}" ]]; then
    log_pass "OPENAI_API_KEY is set (for codex)"
  else
    [[ "$QUIET" == false ]] && log_warn "OPENAI_API_KEY not set (optional)" "Required for codex CLI"
  fi

  if [[ -n "${GITHUB_TOKEN:-}" ]]; then
    log_pass "GITHUB_TOKEN is set (for GitHub MCP integration)"
  else
    [[ "$QUIET" == false ]] && log_warn "GITHUB_TOKEN not set (optional)" "Required for GitHub MCP integration"
  fi

  # ============================================
  # Basic Functionality Test
  # ============================================
  log_section "Basic Functionality Test"

  # Find doyaken binary
  DOYAKEN_BIN=""
  if command -v doyaken &>/dev/null; then
    DOYAKEN_BIN="doyaken"
  elif command -v dk &>/dev/null; then
    DOYAKEN_BIN="dk"
  elif [[ -x "$DOYAKEN_HOME/bin/doyaken" ]]; then
    DOYAKEN_BIN="$DOYAKEN_HOME/bin/doyaken"
  fi

  if [[ -n "$DOYAKEN_BIN" ]]; then
    # Test version command
    if $DOYAKEN_BIN --version &>/dev/null; then
      log_pass "doyaken --version works"
    else
      log_fail "doyaken --version failed"
    fi

    # Test help command
    if $DOYAKEN_BIN help &>/dev/null; then
      log_pass "doyaken help works"
    else
      log_fail "doyaken help failed"
    fi

    # Test doctor command (may have warnings but should not fail)
    if $DOYAKEN_BIN doctor &>/dev/null; then
      log_pass "doyaken doctor works"
    else
      log_warn "doyaken doctor had issues" "Run 'dk doctor' for details"
    fi
  else
    log_fail "Cannot test doyaken functionality" "Install doyaken first"
  fi

  # ============================================
  # Summary
  # ============================================
  echo ""
  echo -e "${BOLD}Summary${NC}"
  echo "======="
  echo -e "Passed:   ${GREEN}$PASS_COUNT${NC}"
  echo -e "Warnings: ${YELLOW}$WARN_COUNT${NC}"
  echo -e "Failed:   ${RED}$FAIL_COUNT${NC}"
  echo ""

  if [[ $FAIL_COUNT -eq 0 ]]; then
    echo -e "${GREEN}${BOLD}✓ Installation verification passed!${NC}"
    echo ""
    echo "Quick start:"
    echo "  cd /path/to/your/project"
    echo "  dk init"
    echo "  dk tasks new \"My first task\""
    echo "  dk run 1"
    echo ""
    exit 0
  else
    echo -e "${RED}${BOLD}✗ Installation verification failed!${NC}"
    echo ""
    echo "Please fix the issues above and run this script again."
    echo ""
    exit 1
  fi
}

main "$@"
