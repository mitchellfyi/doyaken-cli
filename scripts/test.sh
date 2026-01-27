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

# Test 10: Core skills exist
for skill in setup-quality.md check-quality.md audit-deps.md audit-security.md audit-performance.md audit-debt.md audit-ux.md sync-agents.md review-codebase.md research-features.md workflow.md mcp-status.md; do
  if [ -f "$ROOT_DIR/skills/$skill" ]; then
    pass "skills/$skill exists"
  else
    fail "skills/$skill missing"
  fi
done

# Test 11: All hooks exist
for hook in check-quality.sh check-quality-gates.sh check-security.sh; do
  if [ -f "$ROOT_DIR/hooks/$hook" ]; then
    pass "hooks/$hook exists"
  else
    fail "hooks/$hook missing"
  fi
done

# Test 12: Agent templates exist
for agent_template in AGENTS.md CLAUDE.md .cursorrules GEMINI.md opencode.json; do
  if [ -f "$ROOT_DIR/templates/agents/$agent_template" ]; then
    pass "templates/agents/$agent_template exists"
  else
    fail "templates/agents/$agent_template missing"
  fi
done

# Test 12a: GitHub Copilot instructions template exists
if [ -f "$ROOT_DIR/templates/agents/.github/copilot-instructions.md" ]; then
  pass "templates/agents/.github/copilot-instructions.md exists"
else
  fail "templates/agents/.github/copilot-instructions.md missing"
fi

# Test 12b: Cursor modern rules exist
for cursor_rule in doyaken.mdc quality.mdc testing.mdc security.mdc; do
  if [ -f "$ROOT_DIR/templates/agents/cursor/$cursor_rule" ]; then
    pass "templates/agents/cursor/$cursor_rule exists"
  else
    fail "templates/agents/cursor/$cursor_rule missing"
  fi
done

# Test 13: Library prompts exist
for lib_prompt in quality.md testing.md review.md planning.md review-security.md base.md review-architecture.md review-debt.md research-competitors.md research-features.md review-ux.md review-performance.md; do
  if [ -f "$ROOT_DIR/prompts/library/$lib_prompt" ]; then
    pass "prompts/library/$lib_prompt exists"
  else
    fail "prompts/library/$lib_prompt missing"
  fi
done

# Test 14: Auto-timeout function works
# Test that read_with_timeout auto-selects from valid options
TIMEOUT_RESULT=$(bash -c 'source "'"$ROOT_DIR"'/lib/cli.sh" 2>/dev/null; DOYAKEN_AUTO_TIMEOUT=1 read_with_timeout test_var "Test: " a b c d; echo "$test_var"' 2>&1 | tail -1)
if [[ "$TIMEOUT_RESULT" =~ ^[abcd]$ ]]; then
  pass "Auto-timeout selects valid option"
else
  fail "Auto-timeout failed (got: $TIMEOUT_RESULT)"
fi

# Test 15: Auto-timeout default is 60 seconds
if grep -q 'DOYAKEN_AUTO_TIMEOUT:-60' "$ROOT_DIR/lib/cli.sh"; then
  pass "Auto-timeout defaults to 60 seconds"
else
  fail "Auto-timeout default is not 60 seconds"
fi

# Test 16: Functional test - init creates correct structure
TEST_DIR=$(mktemp -d)
TEST_HOME=$(mktemp -d)  # Isolated DOYAKEN_HOME to avoid polluting repo
trap "rm -rf $TEST_DIR $TEST_HOME" EXIT

# Copy lib files to test home so init can find them
mkdir -p "$TEST_HOME/lib" "$TEST_HOME/templates" "$TEST_HOME/prompts" "$TEST_HOME/scripts" "$TEST_HOME/projects"
cp "$ROOT_DIR/lib"/*.sh "$TEST_HOME/lib/"
cp -r "$ROOT_DIR/templates"/* "$TEST_HOME/templates/"
cp -r "$ROOT_DIR/prompts"/* "$TEST_HOME/prompts/"
cp "$ROOT_DIR/scripts/sync-agent-files.sh" "$TEST_HOME/scripts/"
# Initialize empty registry
echo -e "version: 1\nprojects: []\naliases: {}" > "$TEST_HOME/projects/registry.yaml"

if DOYAKEN_HOME="$TEST_HOME" "$ROOT_DIR/bin/doyaken" init "$TEST_DIR" >/dev/null 2>&1; then
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

  if [ -f "$TEST_DIR/AGENTS.md" ]; then
    pass "init creates AGENTS.md"
  else
    fail "init missing AGENTS.md"
  fi

  if [ -f "$TEST_DIR/AGENT.md" ]; then
    pass "init creates AGENT.md (backward compat)"
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
