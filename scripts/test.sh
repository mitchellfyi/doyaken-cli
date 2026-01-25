#!/usr/bin/env bash
#
# test.sh - Basic tests for doyaken CLI
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

TESTS_PASSED=0
TESTS_FAILED=0

pass() {
  echo -e "${GREEN}✓${NC} $1"
  TESTS_PASSED=$((TESTS_PASSED + 1))
}

fail() {
  echo -e "${RED}✗${NC} $1"
  TESTS_FAILED=$((TESTS_FAILED + 1))
}

echo "Running doyaken tests..."
echo ""

# Test 1: Binary exists and is executable
if [ -x "$ROOT_DIR/bin/doyaken" ]; then
  pass "Binary exists and is executable"
else
  fail "Binary not found or not executable"
fi

# Test 2: Version command works
if "$ROOT_DIR/bin/doyaken" --version 2>&1 | grep -q "doyaken version"; then
  pass "Version command works"
else
  fail "Version command failed"
fi

# Test 3: Help command works
if "$ROOT_DIR/bin/doyaken" help 2>&1 | grep -q "USAGE"; then
  pass "Help command works"
else
  fail "Help command failed"
fi

# Test 4: All lib scripts exist
for script in cli.sh core.sh registry.sh taskboard.sh hooks.sh; do
  if [ -f "$ROOT_DIR/lib/$script" ]; then
    pass "lib/$script exists"
  else
    fail "lib/$script missing"
  fi
done

# Test 5: All phase prompts exist
for prompt in 0-expand.md 1-triage.md 2-plan.md 3-implement.md 4-test.md 5-docs.md 6-review.md 7-verify.md; do
  if [ -f "$ROOT_DIR/prompts/phases/$prompt" ]; then
    pass "prompts/phases/$prompt exists"
  else
    fail "prompts/phases/$prompt missing"
  fi
done

# Test 6: Templates exist
for template in manifest.yaml TASK.md PROJECT.md AGENT.md; do
  if [ -f "$ROOT_DIR/templates/$template" ]; then
    pass "templates/$template exists"
  else
    fail "templates/$template missing"
  fi
done

# Test 7: Config exists
if [ -f "$ROOT_DIR/config/global.yaml" ]; then
  pass "config/global.yaml exists"
else
  fail "config/global.yaml missing"
fi

# Test 8: Install script is valid bash
if bash -n "$ROOT_DIR/install.sh" 2>/dev/null; then
  pass "install.sh is valid bash"
else
  fail "install.sh has syntax errors"
fi

# Test 9: Lib scripts are valid bash
for script in "$ROOT_DIR/lib/"*.sh; do
  name=$(basename "$script")
  if bash -n "$script" 2>/dev/null; then
    pass "lib/$name is valid bash"
  else
    fail "lib/$name has syntax errors"
  fi
done

# Summary
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "Tests passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Tests failed: ${RED}$TESTS_FAILED${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ "$TESTS_FAILED" -gt 0 ]; then
  exit 1
fi

exit 0
