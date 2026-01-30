#!/usr/bin/env bats
#
# Unit tests for lib/upgrade.sh
#

load "../test_helper"

setup() {
  export TEST_TEMP_DIR
  TEST_TEMP_DIR="$(mktemp -d)"
  load_lib "upgrade"
}

teardown() {
  if [[ -d "${TEST_TEMP_DIR:-}" ]]; then
    rm -rf "$TEST_TEMP_DIR"
  fi
}

# ============================================================================
# upgrade_compare_versions tests
# ============================================================================

@test "compare_versions: equal versions return 1" {
  run upgrade_compare_versions "1.0.0" "1.0.0"
  [ "$status" -eq 1 ]
}

@test "compare_versions: v1 > v2 returns 0" {
  run upgrade_compare_versions "2.0.0" "1.0.0"
  [ "$status" -eq 0 ]
}

@test "compare_versions: v1 < v2 returns 2" {
  run upgrade_compare_versions "1.0.0" "2.0.0"
  [ "$status" -eq 2 ]
}

@test "compare_versions: handles v prefix" {
  run upgrade_compare_versions "v1.0.0" "v1.0.0"
  [ "$status" -eq 1 ]

  run upgrade_compare_versions "v2.0.0" "v1.0.0"
  [ "$status" -eq 0 ]
}

@test "compare_versions: handles patch versions" {
  run upgrade_compare_versions "1.0.1" "1.0.0"
  [ "$status" -eq 0 ]

  run upgrade_compare_versions "1.0.0" "1.0.1"
  [ "$status" -eq 2 ]
}

@test "compare_versions: handles minor versions" {
  run upgrade_compare_versions "1.1.0" "1.0.0"
  [ "$status" -eq 0 ]

  run upgrade_compare_versions "1.0.0" "1.1.0"
  [ "$status" -eq 2 ]
}

@test "compare_versions: handles complex versions" {
  run upgrade_compare_versions "0.1.12" "0.1.11"
  [ "$status" -eq 0 ]

  run upgrade_compare_versions "0.1.12" "0.1.12"
  [ "$status" -eq 1 ]
}

# ============================================================================
# upgrade_verify tests
# ============================================================================

@test "verify: fails on missing directory" {
  run upgrade_verify "/nonexistent/path"
  [ "$status" -ne 0 ]
}

@test "verify: fails on missing lib directory" {
  mkdir -p "$TEST_TEMP_DIR/test_install"
  run upgrade_verify "$TEST_TEMP_DIR/test_install"
  [ "$status" -ne 0 ]
}

@test "verify: succeeds with minimal structure" {
  mkdir -p "$TEST_TEMP_DIR/test_install/lib"
  mkdir -p "$TEST_TEMP_DIR/test_install/bin"
  touch "$TEST_TEMP_DIR/test_install/lib/cli.sh"
  touch "$TEST_TEMP_DIR/test_install/lib/core.sh"
  touch "$TEST_TEMP_DIR/test_install/bin/doyaken"
  chmod +x "$TEST_TEMP_DIR/test_install/bin/doyaken"

  run upgrade_verify "$TEST_TEMP_DIR/test_install"
  [ "$status" -eq 0 ]
}

