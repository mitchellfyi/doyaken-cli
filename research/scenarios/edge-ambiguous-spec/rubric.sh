#!/usr/bin/env bash
# Rubric for: edge-ambiguous-spec
# HARDENED: The prompt is deliberately vague ("Build a rate limiter.").
# Tests whether DK makes GOOD assumptions, produces professional-grade code,
# and handles the ambiguity intelligently (not just minimally).

rubric_correctness() {
  local ws="$1"
  local score=0

  # Something was created (any code files)
  local code_files
  code_files=$(find "$ws" -maxdepth 4 \( -name "*.js" -o -name "*.ts" -o -name "*.py" -o -name "*.go" -o -name "*.rs" \) ! -path "*/node_modules/*" ! -path "*/.venv/*" 2>/dev/null | wc -l | tr -d ' ')
  [[ $code_files -gt 0 ]] && score=$((score + 5))

  # Has a package/module file
  local has_manifest=false
  for f in "package.json" "go.mod" "Cargo.toml" "setup.py" "pyproject.toml" "requirements.txt"; do
    [[ -f "$ws/$f" ]] && has_manifest=true && break
  done
  $has_manifest && score=$((score + 5))

  local all_src
  all_src=$(find "$ws" -maxdepth 4 \( -name "*.js" -o -name "*.ts" -o -name "*.py" -o -name "*.go" \) ! -path "*/node_modules/*" 2>/dev/null)

  # Has allow/deny or similar limit checking logic
  if echo "$all_src" | xargs grep -qliE "allow|deny|limit|exceed|throttle|window|bucket|token" 2>/dev/null; then
    score=$((score + 8))
  fi

  # Has configurable limits
  if echo "$all_src" | xargs grep -qliE "max.*request|window.*size|limit.*config|rate.*config|tokens.*per|requests.*per" 2>/dev/null; then
    score=$((score + 7))
  fi

  # Actually runnable — try to build/install
  local builds=false
  if [[ -f "$ws/package.json" ]]; then
    (cd "$ws" && npm install --silent 2>/dev/null) && builds=true
  elif [[ -f "$ws/go.mod" ]]; then
    (cd "$ws" && go build ./... 2>/dev/null) && builds=true
  elif [[ -f "$ws/requirements.txt" ]] || [[ -f "$ws/setup.py" ]]; then
    builds=true
  fi
  $builds && score=$((score + 10))

  # Tests exist and pass
  local tests_pass=false
  if [[ -f "$ws/package.json" ]] && grep -q '"test"' "$ws/package.json" 2>/dev/null; then
    local _npm_out; _npm_out=$(cd "$ws" && npm test 2>&1 | tail -10) || true
    echo "$_npm_out" | grep -qiE "pass|ok|success" && tests_pass=true
  elif [[ -f "$ws/go.mod" ]]; then
    local _go_out; _go_out=$(cd "$ws" && go test ./... 2>&1) || true
    [[ "$_go_out" == *"PASS"* ]] && tests_pass=true
  elif echo "$all_src" | head -1 | grep -q "\.py$" 2>/dev/null; then
    local _py_out; _py_out=$(cd "$ws" && python3 -m pytest 2>&1) || true
    [[ "$_py_out" == *"passed"* ]] || [[ "$_py_out" == *"ok"* ]] && tests_pass=true
  fi
  $tests_pass && score=$((score + 10))

  # Has a clear API (exported function/class for rate limiting)
  if echo "$all_src" | xargs grep -qliE "class RateLimiter|function.*rateLimi|func.*RateLimit|def rate_limit|export.*RateLimit" 2>/dev/null; then
    score=$((score + 10))
  fi

  # HARDER: Implements multiple algorithms or strategies
  local algorithms=0
  for algo in "fixed.*window|fixedWindow" "sliding.*window|slidingWindow" "token.*bucket|tokenBucket" "leaky.*bucket|leakyBucket"; do
    if echo "$all_src" | xargs grep -qliE "$algo" 2>/dev/null; then
      algorithms=$((algorithms + 1))
    fi
  done
  [[ $algorithms -ge 1 ]] && score=$((score + 8))
  [[ $algorithms -ge 2 ]] && score=$((score + 7))

  # HARDER: Rate limiter actually works (functional test)
  # Try to import and use it
  if [[ -f "$ws/package.json" ]]; then
    local func_test
    func_test=$(cd "$ws" && node -e "
// Try to find and use the rate limiter
const fs = require('fs');
const path = require('path');
let RateLimiter;
try {
  // Try common import paths
  for (const p of ['./src/index', './src/rate-limiter', './src/rateLimiter', './index', './src']) {
    try { RateLimiter = require(p); break; } catch(e) {}
  }
  if (!RateLimiter) { console.log('NO_IMPORT'); process.exit(); }
  // Handle default exports
  if (typeof RateLimiter === 'object' && RateLimiter.default) RateLimiter = RateLimiter.default;
  if (typeof RateLimiter === 'object' && RateLimiter.RateLimiter) RateLimiter = RateLimiter.RateLimiter;

  const limiter = typeof RateLimiter === 'function' ? new RateLimiter({maxRequests: 3, windowMs: 1000}) : null;
  if (!limiter) { console.log('NO_CONSTRUCT'); process.exit(); }

  // Test basic functionality
  const key = 'test-client';
  let allowed = 0;
  for (let i = 0; i < 5; i++) {
    const result = limiter.isAllowed ? limiter.isAllowed(key) :
                   limiter.allow ? limiter.allow(key) :
                   limiter.check ? limiter.check(key) :
                   limiter.consume ? limiter.consume(key) :
                   limiter.tryConsume ? limiter.tryConsume(key) : null;
    if (result === true || (result && result.allowed)) allowed++;
  }
  // Should allow first 3, deny remaining
  console.log(allowed <= 3 ? 'PASS' : 'FAIL:' + allowed);
} catch(e) {
  console.log('ERROR:' + e.message);
}
" 2>&1) || true
    [[ "$func_test" == *"PASS"* ]] && score=$((score + 15))
  fi

  # HARDER: Per-client isolation (different clients get their own limits)
  if [[ -f "$ws/package.json" ]]; then
    local isolation_test
    isolation_test=$(cd "$ws" && node -e "
let RateLimiter;
try {
  for (const p of ['./src/index', './src/rate-limiter', './src/rateLimiter', './index', './src']) {
    try { RateLimiter = require(p); break; } catch(e) {}
  }
  if (typeof RateLimiter === 'object' && RateLimiter.RateLimiter) RateLimiter = RateLimiter.RateLimiter;
  if (typeof RateLimiter === 'object' && RateLimiter.default) RateLimiter = RateLimiter.default;

  const limiter = new RateLimiter({maxRequests: 2, windowMs: 60000});
  const check = (key) => limiter.isAllowed ? limiter.isAllowed(key) :
                          limiter.allow ? limiter.allow(key) :
                          limiter.check ? limiter.check(key) :
                          limiter.consume ? limiter.consume(key) :
                          limiter.tryConsume ? limiter.tryConsume(key) : null;

  // Client A uses 2 requests
  check('client-a');
  check('client-a');
  // Client B should still be allowed
  const bResult = check('client-b');
  console.log(bResult === true || (bResult && bResult.allowed) ? 'PASS' : 'FAIL');
} catch(e) {
  console.log('ERROR:' + e.message);
}
" 2>&1) || true
    [[ "$isolation_test" == *"PASS"* ]] && score=$((score + 10))
  fi

  # README or documentation exists
  [[ -f "$ws/README.md" ]] && score=$((score + 5))

  [[ $score -gt 100 ]] && score=100
  echo "$score"
}

rubric_test_quality() {
  local ws="$1"
  local score=0

  local test_files
  test_files=$(find "$ws" -maxdepth 4 \( -name "*.test.*" -o -name "*.spec.*" -o -name "*_test.*" -o -name "test_*" \) ! -path "*/node_modules/*" 2>/dev/null)
  local test_count
  test_count=$(echo "$test_files" | grep -c . 2>/dev/null) || test_count=0
  [[ $test_count -gt 0 ]] && score=$((score + 15))

  # Tests pass
  if [[ -f "$ws/package.json" ]]; then
    local _npm_t; _npm_t=$(cd "$ws" && npm test 2>&1 | tail -10) || true
    echo "$_npm_t" | grep -qiE "pass|✓|ok" && score=$((score + 25))
  elif [[ -f "$ws/go.mod" ]]; then
    local _go_t; _go_t=$(cd "$ws" && go test ./... 2>&1) || true
    [[ "$_go_t" == *"PASS"* ]] && score=$((score + 25))
  else
    local _py_t; _py_t=$(cd "$ws" && python3 -m pytest 2>&1) || true
    [[ "$_py_t" == *"passed"* ]] && score=$((score + 25))
  fi

  # Tests cover rate limiting behavior (allow/deny scenarios)
  if [[ -n "$test_files" ]] && echo "$test_files" | xargs grep -qliE "allow|deny|exceed|block|limit|throttle" 2>/dev/null; then
    score=$((score + 10))
  fi

  # Tests cover edge cases
  local edge_tested=0
  if [[ -n "$test_files" ]]; then
    echo "$test_files" | xargs grep -qliE "concurrent|simultaneous|parallel" 2>/dev/null && edge_tested=$((edge_tested + 1))
    echo "$test_files" | xargs grep -qliE "reset|expire|window.*end|clean" 2>/dev/null && edge_tested=$((edge_tested + 1))
    echo "$test_files" | xargs grep -qliE "multiple.*client|different.*key|per.client|isolation" 2>/dev/null && edge_tested=$((edge_tested + 1))
    echo "$test_files" | xargs grep -qliE "burst|rapid|flood|many" 2>/dev/null && edge_tested=$((edge_tested + 1))
  fi
  [[ $edge_tested -ge 1 ]] && score=$((score + 10))
  [[ $edge_tested -ge 2 ]] && score=$((score + 10))
  [[ $edge_tested -ge 3 ]] && score=$((score + 10))

  # Test count
  local case_count=0
  if [[ -n "$test_files" ]]; then
    case_count=$(echo "$test_files" | xargs grep -cE "it\(|test\(|describe\(|func Test|def test_" 2>/dev/null | awk -F: '{s+=$2} END {print s+0}') || case_count=0
  fi
  [[ $case_count -gt 5 ]] && score=$((score + 10))
  [[ $case_count -gt 10 ]] && score=$((score + 10))

  [[ $score -gt 100 ]] && score=100
  echo "$score"
}

rubric_robustness() {
  local ws="$1"
  local score=0

  local all_src
  all_src=$(find "$ws" -maxdepth 4 \( -name "*.js" -o -name "*.ts" -o -name "*.py" -o -name "*.go" \) ! -path "*/node_modules/*" ! -name "*.test.*" ! -name "*.spec.*" ! -name "*_test.*" 2>/dev/null)

  # Has sensible defaults
  if echo "$all_src" | xargs grep -qliE "default|DEFAULT|= 100|= 60|= 1000" 2>/dev/null; then
    score=$((score + 10))
  fi

  # Has time window management
  if echo "$all_src" | xargs grep -qliE "Date\.now|time\.Now|time\(\)|datetime|window|interval" 2>/dev/null; then
    score=$((score + 10))
  fi

  # Has error handling / input validation
  if echo "$all_src" | xargs grep -qliE "throw|Error|raise|panic|if.*<.*0|invalid|IllegalArgument" 2>/dev/null; then
    score=$((score + 10))
  fi

  # Handles concurrent/multiple clients (key-based or IP-based)
  if echo "$all_src" | xargs grep -qliE "key|client|ip|identifier|Map|dict|map\[" 2>/dev/null; then
    score=$((score + 10))
  fi

  # TypeScript or type annotations used
  local has_types=false
  if find "$ws" -maxdepth 4 -name "*.ts" ! -path "*/node_modules/*" 2>/dev/null | grep -q .; then
    has_types=true
  elif echo "$all_src" | xargs grep -qlE ":\s*(number|string|boolean|void|interface|type )" 2>/dev/null; then
    has_types=true
  fi
  $has_types && score=$((score + 10))

  # Clean code: no console.log in source
  local console_in_src=0
  if [[ -n "$all_src" ]]; then
    console_in_src=$(echo "$all_src" | xargs grep -c "console.log" 2>/dev/null | awk -F: '{s+=$2} END {print s+0}') || console_in_src=0
  fi
  [[ $console_in_src -le 1 ]] && score=$((score + 5))

  # Has cleanup mechanism (memory doesn't grow unbounded)
  if echo "$all_src" | xargs grep -qliE "cleanup|clear|prune|gc|expire|evict|delete.*old|setTimeout.*clean|setInterval.*clean" 2>/dev/null; then
    score=$((score + 15))
  fi

  # Uses modern JS/TS features (const/let, arrow functions, classes)
  if echo "$all_src" | xargs grep -qE "class |=>" 2>/dev/null; then
    score=$((score + 5))
  fi

  # Has JSDoc or proper documentation comments
  if echo "$all_src" | xargs grep -qlE "/\*\*|///|\"\"\"" 2>/dev/null; then
    score=$((score + 10))
  fi

  # Implements retry-after or remaining count info
  if echo "$all_src" | xargs grep -qliE "retry.after|retryAfter|remaining|reset.*time|resetAt|X-RateLimit" 2>/dev/null; then
    score=$((score + 10))
  fi

  # Separation of concerns (algorithm in separate file from API/middleware)
  local src_file_count
  src_file_count=$(echo "$all_src" | grep -c . 2>/dev/null) || src_file_count=0
  [[ $src_file_count -ge 3 ]] && score=$((score + 5))

  [[ $score -gt 100 ]] && score=100
  echo "$score"
}
