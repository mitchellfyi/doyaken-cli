#!/usr/bin/env bash
#
# verify-install.sh - Verify doyaken installation and dependencies
#
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

PASSED=0
FAILED=0

check() {
  local name="$1"
  local cmd="$2"
  
  if eval "$cmd" &>/dev/null; then
    echo -e "${GREEN}✓${NC} $name"
    ((PASSED++))
  else
    echo -e "${RED}✗${NC} $name"
    ((FAILED++))
  fi
}

check_env() {
  local var="$1"
  local optional="${2:-false}"
  
  if [[ -n "${!var:-}" ]]; then
    echo -e "${GREEN}✓${NC} \$$var is set"
    ((PASSED++))
  elif [[ "$optional" == "true" ]]; then
    echo -e "${YELLOW}○${NC} \$$var not set (optional)"
  else
    echo -e "${RED}✗${NC} \$$var not set"
    ((FAILED++))
  fi
}

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Doyaken Installation Verification"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo

echo "Dependencies:"
check "Node.js (v18+)" "node --version | grep -qE 'v(1[89]|[2-9][0-9])'"
check "npm" "command -v npm"
check "git" "command -v git"
echo

echo "Doyaken CLI:"
check "doyaken installed" "command -v doyaken || command -v dk"
check "dk alias available" "command -v dk"

if command -v doyaken &>/dev/null || command -v dk &>/dev/null; then
  DK_CMD="${DOYAKEN_CMD:-$(command -v dk 2>/dev/null || command -v doyaken)}"
  check "doyaken --version works" "$DK_CMD --version"
  check "doyaken help works" "$DK_CMD --help"
fi
echo

echo "Environment Variables:"
check_env "ANTHROPIC_API_KEY" true
check_env "OPENAI_API_KEY" true
check_env "GEMINI_API_KEY" true
echo -e "${YELLOW}Note:${NC} At least one AI provider API key is recommended"
echo

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [[ $FAILED -eq 0 ]]; then
  echo -e "${GREEN}All checks passed!${NC} ($PASSED passed)"
  exit 0
else
  echo -e "${RED}$FAILED check(s) failed${NC}, $PASSED passed"
  exit 1
fi
