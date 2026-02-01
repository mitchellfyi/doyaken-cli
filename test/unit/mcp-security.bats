#!/usr/bin/env bats
#
# Unit tests for MCP security functions in lib/mcp.sh
#
# Tests for mask_token(), mcp_validate_package(), mcp_validate_env_vars(),
# and mcp_validate_integration() functions.
#

load "../test_helper"

setup() {
  export TEST_TEMP_DIR
  TEST_TEMP_DIR="$(mktemp -d)"

  # Source the MCP functions directly (they have minimal dependencies)
  source "$PROJECT_ROOT/lib/mcp.sh"

  # Create test server definitions
  mkdir -p "$TEST_TEMP_DIR/servers"

  # Official package server (github)
  cat > "$TEST_TEMP_DIR/servers/github.yaml" << 'EOF'
name: github
description: GitHub MCP Server
command: npx
args:
  - "-y"
  - "@modelcontextprotocol/server-github"
env:
  GITHUB_TOKEN: "${GITHUB_TOKEN}"
EOF

  # Unofficial package server (slack)
  cat > "$TEST_TEMP_DIR/servers/slack.yaml" << 'EOF'
name: slack
description: Slack MCP Server
command: npx
args:
  - "-y"
  - "slack-mcp-server"
env:
  SLACK_BOT_TOKEN: "${SLACK_BOT_TOKEN}"
EOF

  # Server with default env var
  cat > "$TEST_TEMP_DIR/servers/optional.yaml" << 'EOF'
name: optional
description: Server with optional env
command: npx
args:
  - "-y"
  - "@modelcontextprotocol/server-optional"
env:
  OPTIONAL_VAR: "${OPTIONAL_VAR:-default_value}"
EOF

  # Server with multiple required env vars
  cat > "$TEST_TEMP_DIR/servers/multi.yaml" << 'EOF'
name: multi
description: Server with multiple required env vars
command: npx
args:
  - "-y"
  - "unofficial-multi-server"
env:
  VAR_ONE: "${VAR_ONE}"
  VAR_TWO: "${VAR_TWO}"
  VAR_THREE: "${VAR_THREE:-optional}"
EOF

  # Override MCP_SERVERS_DIR for tests
  MCP_SERVERS_DIR="$TEST_TEMP_DIR/servers"
}

teardown() {
  if [[ -d "${TEST_TEMP_DIR:-}" ]]; then
    rm -rf "$TEST_TEMP_DIR"
  fi
}

# ============================================================================
# mask_token tests
# ============================================================================

@test "mask_token: returns *** for empty string" {
  run mask_token ""
  [ "$status" -eq 0 ]
  [ "$output" = "***" ]
}

@test "mask_token: returns *** for string <= 4 chars" {
  run mask_token "abc"
  [ "$status" -eq 0 ]
  [ "$output" = "***" ]
}

@test "mask_token: returns *** for exactly 4 chars" {
  run mask_token "abcd"
  [ "$status" -eq 0 ]
  [ "$output" = "***" ]
}

@test "mask_token: returns first 4 chars + *** for longer strings" {
  run mask_token "ghp_abc123xyz789"
  [ "$status" -eq 0 ]
  [ "$output" = "ghp_***" ]
}

@test "mask_token: masks a real-looking GitHub token" {
  run mask_token "ghp_1234567890abcdefghijklmnop"
  [ "$status" -eq 0 ]
  [ "$output" = "ghp_***" ]
}

@test "mask_token: masks a Slack-style token" {
  # Use fake token format that won't trigger secret scanning
  run mask_token "FAKE-slack-token-for-testing-only"
  [ "$status" -eq 0 ]
  [ "$output" = "FAKE***" ]
}

# ============================================================================
# mcp_validate_package tests
# ============================================================================

@test "mcp_validate_package: returns 0 for @modelcontextprotocol/server-github" {
  run mcp_validate_package "@modelcontextprotocol/server-github"
  [ "$status" -eq 0 ]
}

@test "mcp_validate_package: returns 0 for @modelcontextprotocol/server-filesystem" {
  run mcp_validate_package "@modelcontextprotocol/server-filesystem"
  [ "$status" -eq 0 ]
}

@test "mcp_validate_package: returns 0 for @anthropic/mcp-server-linear" {
  run mcp_validate_package "@anthropic/mcp-server-linear"
  [ "$status" -eq 0 ]
}

@test "mcp_validate_package: returns 0 for @anthropic/mcp-server-anything" {
  run mcp_validate_package "@anthropic/mcp-server-anything"
  [ "$status" -eq 0 ]
}

@test "mcp_validate_package: returns 1 for slack-mcp-server (unofficial)" {
  run mcp_validate_package "slack-mcp-server"
  [ "$status" -eq 1 ]
}

@test "mcp_validate_package: returns 1 for figma-developer-mcp (unofficial)" {
  run mcp_validate_package "figma-developer-mcp"
  [ "$status" -eq 1 ]
}

@test "mcp_validate_package: returns 1 for empty package name" {
  run mcp_validate_package ""
  [ "$status" -eq 1 ]
}

@test "mcp_validate_package: rejects partial match like my-modelcontextprotocol-server" {
  run mcp_validate_package "my-modelcontextprotocol-server"
  [ "$status" -eq 1 ]
}

@test "mcp_validate_package: rejects partial match like modelcontextprotocol-clone" {
  run mcp_validate_package "modelcontextprotocol-clone"
  [ "$status" -eq 1 ]
}

@test "mcp_validate_package: returns 1 if allowlist file missing" {
  # Save current DOYAKEN_HOME and set to non-existent path
  local old_home="${DOYAKEN_HOME:-}"
  export DOYAKEN_HOME="$TEST_TEMP_DIR/nonexistent"

  run mcp_validate_package "@modelcontextprotocol/server-github"
  [ "$status" -eq 1 ]

  # Restore
  export DOYAKEN_HOME="$old_home"
}

# ============================================================================
# mcp_validate_env_vars tests
# ============================================================================

@test "mcp_validate_env_vars: returns 0 when all vars set" {
  export GITHUB_TOKEN="test-token"

  run mcp_validate_env_vars "github"
  [ "$status" -eq 0 ]

  unset GITHUB_TOKEN
}

@test "mcp_validate_env_vars: returns 1 when required var missing" {
  unset GITHUB_TOKEN 2>/dev/null || true

  run mcp_validate_env_vars "github"
  [ "$status" -eq 1 ]
}

@test "mcp_validate_env_vars: sets MCP_MISSING_VARS on failure" {
  unset GITHUB_TOKEN 2>/dev/null || true

  mcp_validate_env_vars "github" || true
  [[ "$MCP_MISSING_VARS" == *"GITHUB_TOKEN"* ]]
}

@test "mcp_validate_env_vars: returns 0 for vars with defaults" {
  # optional.yaml uses ${OPTIONAL_VAR:-default_value}
  unset OPTIONAL_VAR 2>/dev/null || true

  run mcp_validate_env_vars "optional"
  [ "$status" -eq 0 ]
}

@test "mcp_validate_env_vars: reports all missing vars" {
  unset VAR_ONE VAR_TWO 2>/dev/null || true

  mcp_validate_env_vars "multi" || true
  [[ "$MCP_MISSING_VARS" == *"VAR_ONE"* ]]
  [[ "$MCP_MISSING_VARS" == *"VAR_TWO"* ]]
}

@test "mcp_validate_env_vars: returns 1 for nonexistent server" {
  run mcp_validate_env_vars "nonexistent"
  [ "$status" -eq 1 ]
}

# ============================================================================
# mcp_validate_integration tests
# ============================================================================

@test "mcp_validate_integration: returns 0 in non-strict mode (warns only)" {
  unset SLACK_BOT_TOKEN 2>/dev/null || true

  run mcp_validate_integration "slack"
  [ "$status" -eq 0 ]
}

@test "mcp_validate_integration: warns about unofficial package" {
  run mcp_validate_integration "slack" 2>&1
  [[ "$output" == *"[WARN]"* ]] || [[ "$output" == *"Unofficial"* ]]
}

@test "mcp_validate_integration: returns 1 in strict mode for unofficial package" {
  export SLACK_BOT_TOKEN="test-token"

  run mcp_validate_integration "slack" "strict"
  [ "$status" -eq 1 ]

  unset SLACK_BOT_TOKEN
}

@test "mcp_validate_integration: blocks message includes package name in strict mode" {
  export SLACK_BOT_TOKEN="test-token"

  output=$(mcp_validate_integration "slack" "strict" 2>&1) || true
  [[ "$output" == *"[BLOCK]"* ]]
  [[ "$output" == *"slack-mcp-server"* ]]

  unset SLACK_BOT_TOKEN
}

@test "mcp_validate_integration: returns 1 in strict mode for missing env vars" {
  unset GITHUB_TOKEN 2>/dev/null || true

  run mcp_validate_integration "github" "strict"
  [ "$status" -eq 1 ]
}

@test "mcp_validate_integration: returns 0 for official package with env vars set" {
  export GITHUB_TOKEN="test-token"

  run mcp_validate_integration "github"
  [ "$status" -eq 0 ]

  unset GITHUB_TOKEN
}

@test "mcp_validate_integration: returns 1 for nonexistent server" {
  run mcp_validate_integration "nonexistent"
  [ "$status" -eq 1 ]
}

@test "mcp_validate_integration: strict mode returns 1 for missing env in official package" {
  unset GITHUB_TOKEN 2>/dev/null || true

  run mcp_validate_integration "github" "strict"
  [ "$status" -eq 1 ]
}

# ============================================================================
# Edge cases
# ============================================================================

@test "mcp_validate_package: handles scoped package with unusual name" {
  run mcp_validate_package "@modelcontextprotocol/server-with-dashes-123"
  [ "$status" -eq 0 ]
}

@test "mask_token: handles token with special chars" {
  run mask_token "abc!@#\$%^&*()"
  [ "$status" -eq 0 ]
  [ "$output" = "abc!***" ]
}

@test "mcp_validate_env_vars: handles server with no env section" {
  # Create a server with no env
  cat > "$TEST_TEMP_DIR/servers/noenv.yaml" << 'EOF'
name: noenv
description: Server with no env vars
command: npx
args:
  - "-y"
  - "@modelcontextprotocol/server-memory"
EOF

  run mcp_validate_env_vars "noenv"
  [ "$status" -eq 0 ]
}
