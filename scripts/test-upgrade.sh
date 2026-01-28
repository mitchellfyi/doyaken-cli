#!/usr/bin/env bash
#
# Test suite for doyaken upgrade system
#
# Tests:
# 1. Fresh install
# 2. Idempotent (run twice, same result)
# 3. Version comparison
# 4. Preserve files (modified config kept)
# 5. Obsolete cleanup
# 6. Dry-run
# 7. Backup creation
# 8. Rollback
# 9. Checksum verification
# 10. Downgrade protection
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
TEST_DIR=$(mktemp -d)
TEST_HOME="$TEST_DIR/doyaken_home"
PASSED=0
FAILED=0

# Source upgrade library
source "$ROOT_DIR/lib/upgrade.sh"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

# ============================================================================
# Test Helpers
# ============================================================================

setup() {
  rm -rf "$TEST_HOME"
  mkdir -p "$TEST_HOME"
}

teardown() {
  rm -rf "$TEST_DIR"
}

pass() {
  echo -e "${GREEN}PASS${NC}: $1"
  PASSED=$((PASSED + 1))
}

fail() {
  echo -e "${RED}FAIL${NC}: $1"
  echo "  $2"
  FAILED=$((FAILED + 1))
}

skip() {
  echo -e "${YELLOW}SKIP${NC}: $1"
}

assert_file_exists() {
  if [ -f "$1" ]; then
    return 0
  else
    return 1
  fi
}

assert_dir_exists() {
  if [ -d "$1" ]; then
    return 0
  else
    return 1
  fi
}

assert_file_contains() {
  if grep -q "$2" "$1" 2>/dev/null; then
    return 0
  else
    return 1
  fi
}

# ============================================================================
# Tests
# ============================================================================

test_fresh_install() {
  echo ""
  echo "Test: Fresh install"
  setup

  # Generate manifest first
  "$ROOT_DIR/scripts/generate-manifest.sh" > /dev/null 2>&1

  if upgrade_apply "$ROOT_DIR" "$TEST_HOME" false false > /dev/null 2>&1; then
    if assert_file_exists "$TEST_HOME/bin/doyaken" && \
       assert_file_exists "$TEST_HOME/lib/cli.sh" && \
       assert_file_exists "$TEST_HOME/VERSION"; then
      pass "Fresh install creates all required files"
    else
      fail "Fresh install" "Missing required files"
    fi
  else
    fail "Fresh install" "upgrade_apply failed"
  fi
}

test_idempotent() {
  echo ""
  echo "Test: Idempotent (run twice)"
  setup

  # First install
  upgrade_apply "$ROOT_DIR" "$TEST_HOME" false false > /dev/null 2>&1

  local checksum1
  checksum1=$(upgrade_compute_checksum "$TEST_HOME/lib/cli.sh")

  # Second install (should be idempotent)
  upgrade_apply "$ROOT_DIR" "$TEST_HOME" true false > /dev/null 2>&1

  local checksum2
  checksum2=$(upgrade_compute_checksum "$TEST_HOME/lib/cli.sh")

  if [ "$checksum1" = "$checksum2" ]; then
    pass "Idempotent: files unchanged after second run"
  else
    fail "Idempotent" "File checksums differ after second run"
  fi
}

test_version_comparison() {
  echo ""
  echo "Test: Version comparison"

  # Test equal versions
  local result=0
  upgrade_compare_versions "0.1.8" "0.1.8" || result=$?
  if [ "$result" -eq 1 ]; then
    pass "Version comparison: 0.1.8 == 0.1.8"
  else
    fail "Version comparison" "Expected equal (1), got $result"
  fi

  # Test newer version
  result=0
  upgrade_compare_versions "0.2.0" "0.1.8" || result=$?
  if [ "$result" -eq 0 ]; then
    pass "Version comparison: 0.2.0 > 0.1.8"
  else
    fail "Version comparison" "Expected newer (0), got $result"
  fi

  # Test older version
  result=0
  upgrade_compare_versions "0.1.7" "0.1.8" || result=$?
  if [ "$result" -eq 2 ]; then
    pass "Version comparison: 0.1.7 < 0.1.8"
  else
    fail "Version comparison" "Expected older (2), got $result"
  fi
}

test_preserve_files() {
  echo ""
  echo "Test: Preserve modified config"
  setup

  # First install
  upgrade_apply "$ROOT_DIR" "$TEST_HOME" false false > /dev/null 2>&1

  # Modify config file
  echo "# User customization" >> "$TEST_HOME/config/global.yaml"
  local modified_checksum
  modified_checksum=$(upgrade_compute_checksum "$TEST_HOME/config/global.yaml")

  # Upgrade
  upgrade_apply "$ROOT_DIR" "$TEST_HOME" true false > /dev/null 2>&1

  # Check if modification preserved
  local after_checksum
  after_checksum=$(upgrade_compute_checksum "$TEST_HOME/config/global.yaml")

  if [ "$modified_checksum" = "$after_checksum" ]; then
    pass "Preserve files: user modifications kept"
  else
    fail "Preserve files" "Config was overwritten"
  fi
}

test_dry_run() {
  echo ""
  echo "Test: Dry run (no changes)"
  setup

  # Get initial state
  local before_files
  before_files=$(find "$TEST_HOME" -type f 2>/dev/null | wc -l | tr -d ' ')

  # Dry run
  upgrade_apply "$ROOT_DIR" "$TEST_HOME" false true > /dev/null 2>&1

  # Check no files created
  local after_files
  after_files=$(find "$TEST_HOME" -type f 2>/dev/null | wc -l | tr -d ' ')

  # Should only have the progress file (which dry-run doesn't create)
  if [ "$before_files" -eq "$after_files" ]; then
    pass "Dry run: no files created"
  else
    fail "Dry run" "Files were created (before: $before_files, after: $after_files)"
  fi
}

test_backup_creation() {
  echo ""
  echo "Test: Backup creation"
  setup

  # First install
  upgrade_apply "$ROOT_DIR" "$TEST_HOME" false false > /dev/null 2>&1

  # Upgrade (should create backup)
  upgrade_apply "$ROOT_DIR" "$TEST_HOME" true false > /dev/null 2>&1

  # Check backup exists
  local backup_count
  backup_count=$(find "$TEST_HOME/backups" -maxdepth 1 -type d -name "20*" 2>/dev/null | wc -l | tr -d ' ')

  if [ "$backup_count" -ge 1 ]; then
    pass "Backup creation: backup directory created"
  else
    fail "Backup creation" "No backup directory found"
  fi
}

test_rollback() {
  echo ""
  echo "Test: Rollback"
  setup

  # First install with version 1
  upgrade_apply "$ROOT_DIR" "$TEST_HOME" false false > /dev/null 2>&1
  echo "0.1.0" > "$TEST_HOME/VERSION"

  # Upgrade (creates backup)
  upgrade_apply "$ROOT_DIR" "$TEST_HOME" true false > /dev/null 2>&1
  local current_version
  current_version=$(cat "$TEST_HOME/VERSION")

  # Rollback
  upgrade_rollback "$TEST_HOME" > /dev/null 2>&1

  local rolled_back_version
  rolled_back_version=$(cat "$TEST_HOME/VERSION")

  if [ "$rolled_back_version" = "0.1.0" ]; then
    pass "Rollback: restored previous version"
  else
    fail "Rollback" "Expected 0.1.0, got $rolled_back_version"
  fi
}

test_verification() {
  echo ""
  echo "Test: Installation verification"
  setup

  # Fresh install
  upgrade_apply "$ROOT_DIR" "$TEST_HOME" false false > /dev/null 2>&1

  # Should verify successfully
  if upgrade_verify "$TEST_HOME" > /dev/null 2>&1; then
    pass "Verification: valid installation passes"
  else
    fail "Verification" "Valid installation failed verification"
  fi

  # Remove critical file
  rm -f "$TEST_HOME/lib/cli.sh"

  # Should fail verification
  if upgrade_verify "$TEST_HOME" > /dev/null 2>&1; then
    fail "Verification" "Corrupted installation passed verification"
  else
    pass "Verification: corrupted installation detected"
  fi
}

test_downgrade_protection() {
  echo ""
  echo "Test: Downgrade protection"
  setup

  # Install with "newer" version
  upgrade_apply "$ROOT_DIR" "$TEST_HOME" false false > /dev/null 2>&1
  echo "9.9.9" > "$TEST_HOME/VERSION"

  # Try to "downgrade" without force
  local result=0
  upgrade_check "$ROOT_DIR" "$TEST_HOME" > /dev/null 2>&1 || result=$?

  if [ "$result" -eq 2 ]; then
    pass "Downgrade protection: downgrade detected"
  else
    fail "Downgrade protection" "Expected downgrade (2), got $result"
  fi
}

test_checksum() {
  echo ""
  echo "Test: Checksum computation"

  local test_file="$TEST_DIR/test_checksum.txt"
  echo "Hello, World!" > "$test_file"

  local checksum
  checksum=$(upgrade_compute_checksum "$test_file")

  # Verify checksum is 64 hex characters (valid SHA256)
  if [[ "$checksum" =~ ^[a-f0-9]{64}$ ]]; then
    pass "Checksum: valid SHA256 format"
  else
    fail "Checksum" "Invalid checksum format: $checksum"
  fi

  # Verify same file produces same checksum
  local checksum2
  checksum2=$(upgrade_compute_checksum "$test_file")
  if [ "$checksum" = "$checksum2" ]; then
    pass "Checksum: deterministic"
  else
    fail "Checksum" "Non-deterministic: $checksum != $checksum2"
  fi
}

# ============================================================================
# Main
# ============================================================================

main() {
  echo ""
  echo "================================"
  echo "Doyaken Upgrade System Tests"
  echo "================================"
  echo ""
  echo "Test directory: $TEST_DIR"
  echo "Source directory: $ROOT_DIR"

  # Check prerequisites
  if ! command -v jq &>/dev/null; then
    echo ""
    echo -e "${YELLOW}Warning: jq not installed. Some tests may be limited.${NC}"
  fi

  # Generate manifest if needed
  if [ ! -f "$ROOT_DIR/manifest.json" ]; then
    echo ""
    echo "Generating manifest..."
    "$ROOT_DIR/scripts/generate-manifest.sh" > /dev/null 2>&1
  fi

  # Run tests
  test_checksum
  test_version_comparison
  test_fresh_install
  test_idempotent
  test_preserve_files
  test_dry_run
  test_backup_creation
  test_rollback
  test_verification
  test_downgrade_protection

  # Cleanup
  teardown

  # Summary
  echo ""
  echo "================================"
  echo "Test Summary"
  echo "================================"
  echo ""
  echo -e "Passed: ${GREEN}$PASSED${NC}"
  echo -e "Failed: ${RED}$FAILED${NC}"
  echo ""

  if [ "$FAILED" -gt 0 ]; then
    exit 1
  fi
}

main "$@"
