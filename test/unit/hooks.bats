#!/usr/bin/env bats
#
# Unit tests for lib/hooks.sh
#

load "../test_helper"

setup() {
  export TEST_TEMP_DIR
  TEST_TEMP_DIR="$(mktemp -d)"

  # Set up test environment
  export DOYAKEN_HOME="$TEST_TEMP_DIR/global"
  export DOYAKEN_PROJECT="$TEST_TEMP_DIR/project"

  # Create directory structure
  mkdir -p "$DOYAKEN_HOME/hooks"
  mkdir -p "$DOYAKEN_PROJECT/.doyaken/hooks"

  # Source the hooks library
  source "$PROJECT_ROOT/lib/hooks.sh"
}

teardown() {
  if [[ -d "${TEST_TEMP_DIR:-}" ]]; then
    rm -rf "$TEST_TEMP_DIR"
  fi
}

# ============================================================================
# Hook Discovery Tests
# ============================================================================

@test "get_hook_paths: returns both project and global paths" {
  run get_hook_paths
  [ "$status" -eq 0 ]
  [ "${#lines[@]}" -eq 2 ]
  [[ "${lines[0]}" == "$DOYAKEN_PROJECT/.doyaken/hooks" ]]
  [[ "${lines[1]}" == "$DOYAKEN_HOME/hooks" ]]
}

@test "get_hook_paths: returns only global when no project" {
  unset DOYAKEN_PROJECT
  run get_hook_paths
  [ "$status" -eq 0 ]
  [ "${#lines[@]}" -eq 1 ]
  [[ "${lines[0]}" == "$DOYAKEN_HOME/hooks" ]]
}

@test "get_hook_paths: returns empty when no directories exist" {
  rm -rf "$DOYAKEN_HOME/hooks"
  rm -rf "$DOYAKEN_PROJECT/.doyaken/hooks"
  run get_hook_paths
  # Function returns 0 but output is empty
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "find_hook: finds project hook first" {
  # Create same hook in both locations
  echo "#!/bin/bash" > "$DOYAKEN_PROJECT/.doyaken/hooks/test-hook.sh"
  echo "#!/bin/bash" > "$DOYAKEN_HOME/hooks/test-hook.sh"

  run find_hook "test-hook"
  [ "$status" -eq 0 ]
  [[ "$output" == "$DOYAKEN_PROJECT/.doyaken/hooks/test-hook.sh" ]]
}

@test "find_hook: falls back to global hook" {
  echo "#!/bin/bash" > "$DOYAKEN_HOME/hooks/test-hook.sh"

  run find_hook "test-hook"
  [ "$status" -eq 0 ]
  [[ "$output" == "$DOYAKEN_HOME/hooks/test-hook.sh" ]]
}

@test "find_hook: finds hook without .sh extension" {
  echo "#!/bin/bash" > "$DOYAKEN_HOME/hooks/test-hook"
  chmod +x "$DOYAKEN_HOME/hooks/test-hook"

  run find_hook "test-hook"
  [ "$status" -eq 0 ]
  [[ "$output" == "$DOYAKEN_HOME/hooks/test-hook" ]]
}

@test "find_hook: returns error when hook not found" {
  run find_hook "nonexistent-hook"
  [ "$status" -eq 1 ]
}

@test "list_hooks: shows hooks from both locations" {
  # Create hooks with descriptions
  cat > "$DOYAKEN_PROJECT/.doyaken/hooks/project-hook.sh" << 'EOF'
#!/bin/bash
# project-hook - Project specific hook
echo "project"
EOF

  cat > "$DOYAKEN_HOME/hooks/global-hook.sh" << 'EOF'
#!/bin/bash
# global-hook - Global hook
echo "global"
EOF

  run list_hooks
  [ "$status" -eq 0 ]
  [ "${#lines[@]}" -eq 2 ]

  # Check output contains both hooks
  [[ "$output" == *"project-hook|Project specific hook|project|"* ]]
  [[ "$output" == *"global-hook|Global hook|global|"* ]]
}

@test "list_hooks: project overrides global with same name" {
  # Create same hook in both locations
  cat > "$DOYAKEN_PROJECT/.doyaken/hooks/same-hook.sh" << 'EOF'
#!/bin/bash
# same-hook - Project version
echo "project"
EOF

  cat > "$DOYAKEN_HOME/hooks/same-hook.sh" << 'EOF'
#!/bin/bash
# same-hook - Global version
echo "global"
EOF

  run list_hooks
  [ "$status" -eq 0 ]

  # Should only show project version
  local count
  count=$(echo "$output" | grep -c "same-hook")
  [ "$count" -eq 1 ]
  [[ "$output" == *"same-hook|Project version|project|"* ]]
}

@test "list_hooks: handles hooks without description" {
  cat > "$DOYAKEN_HOME/hooks/no-desc.sh" << 'EOF'
#!/bin/bash
echo "no description"
EOF

  run list_hooks
  [ "$status" -eq 0 ]
  [[ "$output" == *"no-desc|No description|global|"* ]]
}

@test "list_hooks: handles empty hook directories" {
  run list_hooks
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

# ============================================================================
# Edge Cases
# ============================================================================

@test "find_hook: handles spaces in hook names" {
  echo "#!/bin/bash" > "$DOYAKEN_HOME/hooks/test hook.sh"

  run find_hook "test hook"
  [ "$status" -eq 0 ]
  [[ "$output" == "$DOYAKEN_HOME/hooks/test hook.sh" ]]
}

@test "list_hooks: ignores non-.sh files" {
  echo "not a hook" > "$DOYAKEN_HOME/hooks/readme.txt"
  echo "#!/bin/bash" > "$DOYAKEN_HOME/hooks/valid.sh"

  run list_hooks
  [ "$status" -eq 0 ]
  # Should only list valid.sh
  [ "${#lines[@]}" -eq 1 ]
  [[ "$output" == *"valid|"* ]]
  [[ "$output" != *"readme"* ]]
}

@test "list_hooks: handles malformed hook files gracefully" {
  # Create hook with no shebang or comments
  echo "echo test" > "$DOYAKEN_HOME/hooks/minimal.sh"

  run list_hooks
  [ "$status" -eq 0 ]
  [[ "$output" == *"minimal|No description|global|"* ]]
}

@test "get_hook_paths: handles missing DOYAKEN_HOME" {
  unset DOYAKEN_HOME
  run get_hook_paths
  # Should not crash, might return empty or use default
  [ "$status" -eq 0 ] || [ "$status" -eq 1 ]
}