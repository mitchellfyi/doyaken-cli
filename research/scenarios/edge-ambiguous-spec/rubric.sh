#!/usr/bin/env bash
# Rubric for: edge-ambiguous-spec
# The prompt is deliberately vague ("Build a rate limiter.").
# Tests whether DK makes reasonable assumptions and produces something functional.

rubric_correctness() {
  local ws="$1"
  local score=0

  # Something was created (any code files)
  local code_files
  code_files=$(find "$ws" -maxdepth 4 \( -name "*.js" -o -name "*.ts" -o -name "*.py" -o -name "*.go" -o -name "*.rs" \) ! -path "*/node_modules/*" ! -path "*/.venv/*" 2>/dev/null | wc -l | tr -d ' ')
  [[ $code_files -gt 0 ]] && score=$((score + 10))
  [[ $code_files -gt 2 ]] && score=$((score + 5))

  # Has a package/module file
  local has_manifest=false
  for f in "package.json" "go.mod" "Cargo.toml" "setup.py" "pyproject.toml" "requirements.txt"; do
    [[ -f "$ws/$f" ]] && has_manifest=true && break
  done
  $has_manifest && score=$((score + 10))

  # Core rate limiter logic exists (check for rate limiting patterns)
  local all_src
  all_src=$(find "$ws" -maxdepth 4 \( -name "*.js" -o -name "*.ts" -o -name "*.py" -o -name "*.go" \) ! -path "*/node_modules/*" 2>/dev/null)

  # Has allow/deny or similar limit checking logic
  if echo "$all_src" | xargs grep -qliE "allow|deny|limit|exceed|throttle|window|bucket|token" 2>/dev/null; then
    score=$((score + 15))
  fi

  # Has configurable limits (window size, max requests, etc.)
  if echo "$all_src" | xargs grep -qliE "max.*request|window.*size|limit.*config|rate.*config|tokens.*per|requests.*per" 2>/dev/null; then
    score=$((score + 15))
  fi

  # Actually runnable — try to build/install
  local builds=false
  if [[ -f "$ws/package.json" ]]; then
    (cd "$ws" && npm install --silent 2>/dev/null) && builds=true
  elif [[ -f "$ws/go.mod" ]]; then
    (cd "$ws" && go build ./... 2>/dev/null) && builds=true
  elif [[ -f "$ws/requirements.txt" ]] || [[ -f "$ws/setup.py" ]]; then
    builds=true  # Python doesn't need build step
  fi
  $builds && score=$((score + 15))

  # Tests exist and pass
  local tests_pass=false
  if [[ -f "$ws/package.json" ]] && grep -q '"test"' "$ws/package.json" 2>/dev/null; then
    (cd "$ws" && npm test 2>&1 | tail -5 | grep -qiE "pass|ok|success") && tests_pass=true
  elif [[ -f "$ws/go.mod" ]]; then
    (cd "$ws" && go test ./... 2>&1 | grep -q "PASS") && tests_pass=true
  elif echo "$all_src" | head -1 | grep -q "\.py$" 2>/dev/null; then
    (cd "$ws" && python3 -m pytest 2>&1 | grep -qiE "passed|ok") && tests_pass=true
  fi
  $tests_pass && score=$((score + 15))

  # Has a clear API (exported function/class for rate limiting)
  if echo "$all_src" | xargs grep -qliE "class RateLimiter|function.*rateLimi|func.*RateLimit|def rate_limit|export.*RateLimit" 2>/dev/null; then
    score=$((score + 15))
  fi

  echo "$score"
}

rubric_test_quality() {
  local ws="$1"
  local score=0

  # Tests exist
  local test_count
  test_count=$(find "$ws" -maxdepth 4 \( -name "*.test.*" -o -name "*.spec.*" -o -name "*_test.*" -o -name "test_*" \) ! -path "*/node_modules/*" 2>/dev/null | wc -l | tr -d ' ')
  [[ $test_count -gt 0 ]] && score=$((score + 30))
  [[ $test_count -gt 1 ]] && score=$((score + 10))

  # Tests pass
  if [[ -f "$ws/package.json" ]]; then
    (cd "$ws" && npm test 2>&1 | tail -10 | grep -qiE "pass|✓|ok") && score=$((score + 40))
  elif [[ -f "$ws/go.mod" ]]; then
    (cd "$ws" && go test ./... 2>&1 | grep -q "PASS") && score=$((score + 40))
  else
    (cd "$ws" && python3 -m pytest 2>&1 | grep -qiE "passed") && score=$((score + 40))
  fi

  # Tests cover rate limiting behavior (allow/deny scenarios)
  local test_files
  test_files=$(find "$ws" -maxdepth 4 \( -name "*.test.*" -o -name "*.spec.*" -o -name "*_test.*" -o -name "test_*" \) ! -path "*/node_modules/*" 2>/dev/null)
  if echo "$test_files" | xargs grep -qliE "allow|deny|exceed|block|limit|throttle" 2>/dev/null; then
    score=$((score + 20))
  fi

  echo "$score"
}

rubric_robustness() {
  local ws="$1"
  local score=0

  local all_src
  all_src=$(find "$ws" -maxdepth 4 \( -name "*.js" -o -name "*.ts" -o -name "*.py" -o -name "*.go" \) ! -path "*/node_modules/*" ! -name "*.test.*" ! -name "*.spec.*" ! -name "*_test.*" 2>/dev/null)

  # Has sensible defaults
  if echo "$all_src" | xargs grep -qliE "default|DEFAULT|= 100|= 60|= 1000" 2>/dev/null; then
    score=$((score + 20))
  fi

  # Has time window management
  if echo "$all_src" | xargs grep -qliE "Date\.now|time\.Now|time\(\)|datetime|window|interval|setTimeout|setInterval" 2>/dev/null; then
    score=$((score + 20))
  fi

  # Has error handling
  if echo "$all_src" | xargs grep -qliE "throw|Error|raise|panic|if.*<.*0|invalid" 2>/dev/null; then
    score=$((score + 20))
  fi

  # Handles concurrent/multiple clients (key-based or IP-based)
  if echo "$all_src" | xargs grep -qliE "key|client|ip|identifier|Map|dict|map\[" 2>/dev/null; then
    score=$((score + 20))
  fi

  # Has documentation (README, comments, or docstrings)
  if [[ -f "$ws/README.md" ]] || echo "$all_src" | xargs grep -qliE "\/\*\*|\"\"\"|\#\#|\/\/" 2>/dev/null; then
    score=$((score + 20))
  fi

  echo "$score"
}
