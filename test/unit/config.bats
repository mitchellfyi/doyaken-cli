#!/usr/bin/env bats
#
# Unit tests for lib/config.sh
#

load "../test_helper"

setup() {
  export TEST_TEMP_DIR
  TEST_TEMP_DIR="$(mktemp -d)"
  load_lib "logging"
  load_lib "config"
}

teardown() {
  if [[ -d "${TEST_TEMP_DIR:-}" ]]; then
    rm -rf "$TEST_TEMP_DIR"
  fi
}

# ============================================================================
# _load_config tests
# ============================================================================

@test "load_config: returns default when no manifest" {
  unset TEST_VAR
  _load_config "TEST_VAR" "test.key" "default_value" ""
  [ "$TEST_VAR" = "default_value" ]
}

@test "load_config: env var takes precedence" {
  export TEST_VAR="env_value"
  _load_config "TEST_VAR" "test.key" "default_value" ""
  [ "$TEST_VAR" = "env_value" ]
  unset TEST_VAR
}

@test "load_config: reads from manifest with yq" {
  if ! command -v yq &>/dev/null; then
    skip "yq not installed"
  fi

  cat > "$TEST_TEMP_DIR/manifest.yaml" << 'EOF'
test:
  key: "manifest_value"
EOF

  unset TEST_VAR
  _load_config "TEST_VAR" "test.key" "default_value" "$TEST_TEMP_DIR/manifest.yaml"
  [ "$TEST_VAR" = "manifest_value" ]
}

# ============================================================================
# yaml_bool tests
# ============================================================================

@test "yaml_bool: true values return 1" {
  [ "$(yaml_bool "true")" = "1" ]
  [ "$(yaml_bool "True")" = "1" ]
  [ "$(yaml_bool "TRUE")" = "1" ]
  [ "$(yaml_bool "yes")" = "1" ]
  [ "$(yaml_bool "1")" = "1" ]
}

@test "yaml_bool: false values return 0" {
  [ "$(yaml_bool "false")" = "0" ]
  [ "$(yaml_bool "False")" = "0" ]
  [ "$(yaml_bool "no")" = "0" ]
  [ "$(yaml_bool "0")" = "0" ]
  [ "$(yaml_bool "")" = "0" ]
}

@test "yaml_bool: edge cases return 0" {
  # Any unexpected value should return 0 (false)
  [ "$(yaml_bool "maybe")" = "0" ]
  [ "$(yaml_bool "y")" = "0" ]
  [ "$(yaml_bool "n")" = "0" ]
  [ "$(yaml_bool "on")" = "0" ]
  [ "$(yaml_bool "off")" = "0" ]
  [ "$(yaml_bool " true ")" = "0" ]  # with spaces
  [ "$(yaml_bool "TRUE1")" = "0" ]   # with extra chars
  [ "$(yaml_bool "null")" = "0" ]
  [ "$(yaml_bool "undefined")" = "0" ]
}

# ============================================================================
# _yq_get tests
# ============================================================================

@test "yq_get: returns default for missing file" {
  run _yq_get "/nonexistent/file.yaml" "key" "default"
  [ "$status" -eq 0 ]
  [ "$output" = "default" ]
}

@test "yq_get: reads value from yaml" {
  if ! command -v yq &>/dev/null; then
    skip "yq not installed"
  fi

  cat > "$TEST_TEMP_DIR/test.yaml" << 'EOF'
nested:
  key: "value"
EOF

  run _yq_get "$TEST_TEMP_DIR/test.yaml" "nested.key" "default"
  [ "$status" -eq 0 ]
  [ "$output" = "value" ]
}

@test "yq_get: handles null values" {
  if ! command -v yq &>/dev/null; then
    skip "yq not installed"
  fi

  cat > "$TEST_TEMP_DIR/test.yaml" << 'EOF'
nullkey: null
emptykey: ""
missingvalue:
EOF

  run _yq_get "$TEST_TEMP_DIR/test.yaml" "nullkey" "default"
  [ "$status" -eq 0 ]
  [ "$output" = "default" ]

  run _yq_get "$TEST_TEMP_DIR/test.yaml" "emptykey" "default"
  [ "$status" -eq 0 ]
  [ "$output" = "default" ]

  run _yq_get "$TEST_TEMP_DIR/test.yaml" "missingvalue" "default"
  [ "$status" -eq 0 ]
  [ "$output" = "default" ]
}

@test "yq_get: handles missing key" {
  if ! command -v yq &>/dev/null; then
    skip "yq not installed"
  fi

  cat > "$TEST_TEMP_DIR/test.yaml" << 'EOF'
existing: "value"
EOF

  run _yq_get "$TEST_TEMP_DIR/test.yaml" "nonexistent.key" "default"
  [ "$status" -eq 0 ]
  [ "$output" = "default" ]
}

@test "yq_get: handles deeply nested keys" {
  if ! command -v yq &>/dev/null; then
    skip "yq not installed"
  fi

  cat > "$TEST_TEMP_DIR/test.yaml" << 'EOF'
very:
  deeply:
    nested:
      key: "found"
EOF

  run _yq_get "$TEST_TEMP_DIR/test.yaml" "very.deeply.nested.key" "default"
  [ "$status" -eq 0 ]
  [ "$output" = "found" ]
}

# ============================================================================
# load_all_config tests
# ============================================================================

@test "load_all_config: reads model from manifest with yq" {
  if ! command -v yq &>/dev/null; then
    skip "yq not installed"
  fi

  # Create minimal manifest
  cat > "$TEST_TEMP_DIR/manifest.yaml" << 'EOF'
version: 1
project:
  name: "test"
agent:
  model: "opus"
EOF

  # Clear any existing value
  unset DOYAKEN_MODEL
  unset DOYAKEN_MODEL_FROM_CLI

  load_all_config "$TEST_TEMP_DIR/manifest.yaml"

  # Should have model set from manifest
  [ "${DOYAKEN_MODEL:-}" = "opus" ]
}

@test "load_all_config: sets default agent" {
  # Clear any existing value
  unset DOYAKEN_AGENT
  unset DOYAKEN_AGENT_FROM_CLI

  load_all_config ""

  # Should have default agent (claude)
  [ "${DOYAKEN_AGENT:-}" = "claude" ]
}
