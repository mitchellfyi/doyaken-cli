#!/usr/bin/env bash
# Rubric for: refactor-duplication

rubric_correctness() {
  local ws="$1"
  local score=0

  [[ -f "$ws/package.json" ]] && score=$((score + 5))
  (cd "$ws" && npm install --silent 2>/dev/null) || true

  # Shared utility exists
  local shared_found=false
  for f in "src/validators.js" "src/utils/validators.js" "src/lib/validators.js" "src/validate.js" "src/utils/validate.js" "src/validation.js" "src/shared/validation.js"; do
    if [[ -f "$ws/$f" ]]; then
      shared_found=true
      break
    fi
  done
  $shared_found && score=$((score + 15))

  # Route files still exist and export their validators
  [[ -f "$ws/src/routes/users.js" ]] && score=$((score + 5))
  [[ -f "$ws/src/routes/products.js" ]] && score=$((score + 5))
  [[ -f "$ws/src/routes/orders.js" ]] && score=$((score + 5))

  # User validation still works
  local user_test
  user_test=$(cd "$ws" && node -e "
const { validateUserInput } = require('./src/routes/users');
let r;
r = validateUserInput({name: 'Alice', email: 'a@b.com'});
if (!r.valid) { console.log('FAIL1'); process.exit(); }
r = validateUserInput({});
if (r.valid || r.errors.length === 0) { console.log('FAIL2'); process.exit(); }
r = validateUserInput({name: 'x'.repeat(101), email: 'a@b.com'});
if (r.valid) { console.log('FAIL3'); process.exit(); }
r = validateUserInput({name: 'A', email: 'bad'});
if (r.valid) { console.log('FAIL4'); process.exit(); }
console.log('PASS');
" 2>&1) || true
  [[ "$user_test" == *"PASS"* ]] && score=$((score + 15))

  # Product validation still works
  local prod_test
  prod_test=$(cd "$ws" && node -e "
const { validateProductInput } = require('./src/routes/products');
let r;
r = validateProductInput({name: 'Widget', sku: 'W-001'});
if (!r.valid) { console.log('FAIL1'); process.exit(); }
r = validateProductInput({});
if (r.valid) { console.log('FAIL2'); process.exit(); }
r = validateProductInput({name: 'W', sku: 'S', price: -5});
if (r.valid) { console.log('FAIL3'); process.exit(); }
console.log('PASS');
" 2>&1) || true
  [[ "$prod_test" == *"PASS"* ]] && score=$((score + 15))

  # Order validation still works
  local order_test
  order_test=$(cd "$ws" && node -e "
const { validateOrderInput } = require('./src/routes/orders');
let r;
r = validateOrderInput({customerId: 'C1', items: ['a']});
if (!r.valid) { console.log('FAIL1'); process.exit(); }
r = validateOrderInput({});
if (r.valid) { console.log('FAIL2'); process.exit(); }
r = validateOrderInput({customerId: 'C1', items: []});
if (r.valid) { console.log('FAIL3'); process.exit(); }
console.log('PASS');
" 2>&1) || true
  [[ "$order_test" == *"PASS"* ]] && score=$((score + 15))

  # Route files USE the shared utility (import it)
  local routes_use_shared=0
  for f in "$ws/src/routes/users.js" "$ws/src/routes/products.js" "$ws/src/routes/orders.js"; do
    [[ -f "$f" ]] || continue
    if grep -qE "require.*validat|import.*validat" "$f" 2>/dev/null; then
      routes_use_shared=$((routes_use_shared + 1))
    fi
  done
  [[ $routes_use_shared -ge 2 ]] && score=$((score + 20))

  [[ $score -gt 100 ]] && score=100
  echo "$score"
}

rubric_test_quality() {
  local ws="$1"
  local score=0

  local test_count
  test_count=$(find "$ws" -maxdepth 4 \( -name "*.test.*" -o -name "*.spec.*" \) ! -path "*/node_modules/*" 2>/dev/null | wc -l | tr -d ' ')
  [[ $test_count -gt 0 ]] && score=$((score + 20))

  if (cd "$ws" && npm test 2>&1 | tail -20 | grep -qiE "pass|✓|ok|success"); then
    score=$((score + 40))
  fi

  # Tests cover all 3 routes
  local routes_tested=0
  for route in "user" "product" "order"; do
    if find "$ws" -maxdepth 4 \( -name "*.test.*" -o -name "*.spec.*" \) ! -path "*/node_modules/*" -exec grep -ql "$route" {} + 2>/dev/null; then
      routes_tested=$((routes_tested + 1))
    fi
  done
  [[ $routes_tested -ge 2 ]] && score=$((score + 20))
  [[ $routes_tested -ge 3 ]] && score=$((score + 20))

  echo "$score"
}

rubric_robustness() {
  local ws="$1"
  local score=0

  # Shared utility is well-structured (has multiple exported functions)
  local shared_file=""
  for f in "src/validators.js" "src/utils/validators.js" "src/lib/validators.js" "src/validate.js" "src/utils/validate.js" "src/validation.js" "src/shared/validation.js"; do
    [[ -f "$ws/$f" ]] && shared_file="$ws/$f" && break
  done

  if [[ -n "$shared_file" ]]; then
    # Has multiple validation helper functions
    local func_count
    func_count=$(grep -cE "function |const .* = |module\.exports\." "$shared_file" 2>/dev/null || echo "0")
    [[ $func_count -ge 2 ]] && score=$((score + 30))

    # Is reusable (parameterized, not hardcoded)
    if grep -qE "maxLength|max|min|required|options|config|rules|schema" "$shared_file" 2>/dev/null; then
      score=$((score + 30))
    fi
  fi

  # No duplication remains in route files
  local duplication_score=40
  for f in "$ws/src/routes/users.js" "$ws/src/routes/products.js" "$ws/src/routes/orders.js"; do
    [[ -f "$f" ]] || continue
    # Penalize if route files still have inline validation patterns
    local inline_checks
    inline_checks=$(grep -c "typeof.*!==\|\.length\s*>\|\.includes(" "$f" 2>/dev/null || echo "0")
    if [[ $inline_checks -gt 2 ]]; then
      duplication_score=$((duplication_score - 15))
    fi
  done
  [[ $duplication_score -lt 0 ]] && duplication_score=0
  score=$((score + duplication_score))

  echo "$score"
}
