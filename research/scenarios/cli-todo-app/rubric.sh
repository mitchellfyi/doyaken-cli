#!/usr/bin/env bash
# Rubric for: cli-todo-app

rubric_correctness() {
  local ws="$1"
  local score=0

  # Check package.json exists
  [[ -f "$ws/package.json" ]] && score=$((score + 5))

  # Check main entry point exists
  [[ -f "$ws/index.js" ]] || [[ -f "$ws/src/index.js" ]] || [[ -f "$ws/cli.js" ]] && score=$((score + 5))

  # Install dependencies
  if (cd "$ws" && npm install --silent 2>/dev/null); then
    score=$((score + 5))
  else
    echo "$score"; return
  fi

  # Find the entry point
  local entry="index.js"
  [[ -f "$ws/index.js" ]] || entry="src/index.js"
  [[ -f "$ws/$entry" ]] || entry="cli.js"
  [[ -f "$ws/$entry" ]] || { echo "$score"; return; }

  # Clean up any prior todos.json
  rm -f "$ws/todos.json" 2>/dev/null

  # Add a todo
  local add_output
  add_output=$(cd "$ws" && node "$entry" add "Buy groceries" 2>&1) || true
  if echo "$add_output" | grep -qi "add\|creat\|success\|todo"; then
    score=$((score + 15))
  fi

  # List todos — should show the added item
  local list_output
  list_output=$(cd "$ws" && node "$entry" list 2>&1) || true
  if echo "$list_output" | grep -q "Buy groceries"; then
    score=$((score + 15))
  fi

  # Add another todo
  (cd "$ws" && node "$entry" add "Walk the dog" 2>&1) >/dev/null || true

  # Complete a todo
  local complete_output
  complete_output=$(cd "$ws" && node "$entry" complete 1 2>&1) || true
  if echo "$complete_output" | grep -qi "complet\|done\|mark\|success\|✓\|✔\|\[x\]"; then
    score=$((score + 15))
  fi

  # Verify completion shows in list
  list_output=$(cd "$ws" && node "$entry" list 2>&1) || true
  if echo "$list_output" | grep -qE "\[x\]|✓|✔|done|completed"; then
    score=$((score + 10))
  fi

  # Delete a todo
  local delete_output
  delete_output=$(cd "$ws" && node "$entry" delete 1 2>&1) || true
  if echo "$delete_output" | grep -qi "delet\|remov\|success"; then
    score=$((score + 10))
  fi

  # Persistence — todos.json should exist
  [[ -f "$ws/todos.json" ]] && score=$((score + 10))

  # List after delete should not show deleted item
  list_output=$(cd "$ws" && node "$entry" list 2>&1) || true
  if ! echo "$list_output" | grep -q "Buy groceries"; then
    score=$((score + 10))
  fi

  echo "$score"
}

rubric_test_quality() {
  local ws="$1"
  local score=0

  # Test files exist
  local test_count
  test_count=$(find "$ws" -maxdepth 3 \( -name "*.test.*" -o -name "*.spec.*" \) ! -path "*/node_modules/*" 2>/dev/null | wc -l | tr -d ' ')
  [[ $test_count -gt 0 ]] && score=$((score + 20))
  [[ $test_count -gt 1 ]] && score=$((score + 10))

  # package.json has test script
  if [[ -f "$ws/package.json" ]] && grep -q '"test"' "$ws/package.json" 2>/dev/null; then
    score=$((score + 10))
  fi

  # Tests pass
  if (cd "$ws" && npm test 2>&1 | tail -20 | grep -qiE "pass|✓|ok|success|tests? (passed|complete)"); then
    score=$((score + 40))
  fi

  # Tests cover multiple commands (check test file contents)
  local test_files
  test_files=$(find "$ws" -maxdepth 3 \( -name "*.test.*" -o -name "*.spec.*" \) ! -path "*/node_modules/*" 2>/dev/null)
  local commands_tested=0
  for cmd in "add" "list" "complete" "delete"; do
    if echo "$test_files" | xargs grep -ql "$cmd" 2>/dev/null; then
      commands_tested=$((commands_tested + 1))
    fi
  done
  [[ $commands_tested -ge 3 ]] && score=$((score + 20))

  echo "$score"
}

rubric_robustness() {
  local ws="$1"
  local score=0

  local entry="index.js"
  [[ -f "$ws/index.js" ]] || entry="src/index.js"
  [[ -f "$ws/$entry" ]] || entry="cli.js"
  [[ -f "$ws/$entry" ]] || { echo "0"; return; }

  # Install deps first
  (cd "$ws" && npm install --silent 2>/dev/null) || true

  # Missing arguments — should not crash (exit 139 = segfault)
  local exit_code
  (cd "$ws" && node "$entry" add 2>/dev/null); exit_code=$?
  [[ $exit_code -ne 139 && $exit_code -ne 134 ]] && score=$((score + 15))

  # No command — should show help or error message
  local no_cmd_output
  no_cmd_output=$(cd "$ws" && node "$entry" 2>&1) || true
  if echo "$no_cmd_output" | grep -qiE "usage|help|command|add|list"; then
    score=$((score + 15))
  fi

  # Invalid ID
  (cd "$ws" && node "$entry" complete 99999 2>/dev/null); exit_code=$?
  [[ $exit_code -ne 139 && $exit_code -ne 134 ]] && score=$((score + 15))

  # Non-numeric ID
  (cd "$ws" && node "$entry" complete "abc" 2>/dev/null); exit_code=$?
  [[ $exit_code -ne 139 && $exit_code -ne 134 ]] && score=$((score + 15))

  # Empty string todo
  (cd "$ws" && node "$entry" add "" 2>/dev/null); exit_code=$?
  [[ $exit_code -ne 139 && $exit_code -ne 134 ]] && score=$((score + 10))

  # Has error handling patterns in code
  local src_files
  src_files=$(find "$ws" -maxdepth 3 -name "*.js" ! -path "*/node_modules/*" ! -name "*.test.*" ! -name "*.spec.*" 2>/dev/null)
  if echo "$src_files" | xargs grep -ql "throw\|Error\|process\.exit\|console\.error" 2>/dev/null; then
    score=$((score + 15))
  fi

  # Has input validation
  if echo "$src_files" | xargs grep -ql "!.*\|\|.*undefined\|typeof\|isNaN\|parseInt\|Number(" 2>/dev/null; then
    score=$((score + 15))
  fi

  echo "$score"
}
