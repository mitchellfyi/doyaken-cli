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
for script in cli.sh core.sh registry.sh taskboard.sh hooks.sh agents.sh skills.sh mcp.sh; do
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

# Test 10: All skills exist
for skill in setup-quality.md check-quality.md audit-deps.md sync-agents.md review-codebase.md security-audit.md performance-audit.md tech-debt.md feature-discover.md ux-audit.md; do
  if [ -f "$ROOT_DIR/skills/$skill" ]; then
    pass "skills/$skill exists"
  else
    fail "skills/$skill missing"
  fi
done

# Test 11: All hooks exist
for hook in quality-check.sh quality-gates-check.sh security-check.sh; do
  if [ -f "$ROOT_DIR/hooks/$hook" ]; then
    pass "hooks/$hook exists"
  else
    fail "hooks/$hook missing"
  fi
done

# Test 12: Agent templates exist
for agent_template in AGENTS.md CLAUDE.md .cursorrules CODEX.md GEMINI.md opencode.json; do
  if [ -f "$ROOT_DIR/templates/agents/$agent_template" ]; then
    pass "templates/agents/$agent_template exists"
  else
    fail "templates/agents/$agent_template missing"
  fi
done

# Test 13: Library prompts exist
for lib_prompt in code-quality.md testing.md code-review.md planning.md security.md base.md architecture-review.md technical-debt.md competitor-analysis.md feature-discovery.md ux-review.md performance.md; do
  if [ -f "$ROOT_DIR/prompts/library/$lib_prompt" ]; then
    pass "prompts/library/$lib_prompt exists"
  else
    fail "prompts/library/$lib_prompt missing"
  fi
done

# Test 14: Functional test - init creates correct structure
TEST_DIR=$(mktemp -d)
trap "rm -rf $TEST_DIR" EXIT

if DOYAKEN_HOME="$ROOT_DIR" "$ROOT_DIR/bin/doyaken" init "$TEST_DIR" >/dev/null 2>&1; then
  # Check created structure
  if [ -d "$TEST_DIR/.doyaken/tasks/2.todo" ]; then
    pass "init creates tasks/2.todo"
  else
    fail "init missing tasks/2.todo"
  fi

  if [ -f "$TEST_DIR/.doyaken/manifest.yaml" ]; then
    pass "init creates manifest.yaml"
  else
    fail "init missing manifest.yaml"
  fi

  if [ -f "$TEST_DIR/AGENT.md" ]; then
    pass "init creates AGENT.md"
  else
    fail "init missing AGENT.md"
  fi
else
  fail "init command failed"
fi

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
