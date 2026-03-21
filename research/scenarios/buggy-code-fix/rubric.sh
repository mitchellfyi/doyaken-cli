#!/usr/bin/env bash
# Rubric for: buggy-code-fix
# HARDENED: Tests that DK can find and fix all 5 bugs, write regression tests,
# and produce clean, well-structured code.

rubric_correctness() {
  local ws="$1"
  local score=0

  [[ -f "$ws/src/cart.js" ]] || [[ -f "$ws/cart.js" ]] && score=$((score + 3))
  [[ -f "$ws/package.json" ]] && score=$((score + 2))

  (cd "$ws" && npm install --silent 2>/dev/null) || true

  local cart_file="$ws/src/cart.js"
  [[ -f "$cart_file" ]] || cart_file="$ws/cart.js"
  [[ -f "$cart_file" ]] || { echo "$score"; return; }

  # Bug 1: negative price/quantity validation
  local neg_test
  neg_test=$(cd "$ws" && node -e "
let Cart; try { Cart = require('./src/cart'); } catch(e) { Cart = require('./cart'); }
const c = new Cart();
let passed = 0;
try { c.addItem('A', -5, 1); } catch(e) { passed++; }
try { c.addItem('A', 10, -1); } catch(e) { passed++; }
try { c.addItem('A', 0, 1); } catch(e) { passed++; }
console.log(passed >= 2 ? 'PASS' : 'FAIL:' + passed);
" 2>&1) || true
  [[ "$neg_test" == *"PASS"* ]] && score=$((score + 12))

  # Bug 2: removeItem works correctly (filters, doesn't assign)
  local rm_test
  rm_test=$(cd "$ws" && node -e "
let Cart; try { Cart = require('./src/cart'); } catch(e) { Cart = require('./cart'); }
const c = new Cart();
c.addItem('A', 10, 1);
c.addItem('B', 20, 1);
c.addItem('C', 30, 1);
c.removeItem('B');
const ok = c.items.length === 2 && c.items.every(i => i.name !== 'B');
console.log(ok ? 'PASS' : 'FAIL');
" 2>&1) || true
  [[ "$rm_test" == *"PASS"* ]] && score=$((score + 12))

  # Bug 3: getTotal has no off-by-one
  local total_test
  total_test=$(cd "$ws" && node -e "
let Cart; try { Cart = require('./src/cart'); } catch(e) { Cart = require('./cart'); }
const c = new Cart();
c.addItem('A', 10, 2);
c.addItem('B', 5, 3);
c.addItem('C', 1, 1);
const total = c.getTotal();
console.log(total === 36 ? 'PASS' : 'FAIL:' + total);
" 2>&1) || true
  [[ "$total_test" == *"PASS"* ]] && score=$((score + 12))

  # Bug 4: discount subtracts (not adds) and applies percentage correctly
  local disc_test
  disc_test=$(cd "$ws" && node -e "
let Cart; try { Cart = require('./src/cart'); } catch(e) { Cart = require('./cart'); }
const c = new Cart();
c.addItem('A', 100, 1);
c.applyDiscount(25);
const total = c.getTotal();
console.log(total === 75 ? 'PASS' : 'FAIL:' + total);
" 2>&1) || true
  [[ "$disc_test" == *"PASS"* ]] && score=$((score + 12))

  # Bug 5: discount validates range (0-100)
  local disc_val_test
  disc_val_test=$(cd "$ws" && node -e "
let Cart; try { Cart = require('./src/cart'); } catch(e) { Cart = require('./cart'); }
const c = new Cart();
let thrown = 0;
try { c.applyDiscount(150); } catch(e) { thrown++; }
try { c.applyDiscount(-10); } catch(e) { thrown++; }
try { c.applyDiscount(101); } catch(e) { thrown++; }
console.log(thrown >= 3 ? 'PASS' : 'FAIL:' + thrown);
" 2>&1) || true
  [[ "$disc_val_test" == *"PASS"* ]] && score=$((score + 12))

  # Harder: Multiple operations chain correctly
  local chain_test
  chain_test=$(cd "$ws" && node -e "
let Cart; try { Cart = require('./src/cart'); } catch(e) { Cart = require('./cart'); }
const c = new Cart();
c.addItem('A', 100, 2);  // 200
c.addItem('B', 50, 1);   // 50
c.removeItem('A');        // -200
c.addItem('C', 30, 3);   // 90
c.applyDiscount(10);      // -10%
// Expected: (50 + 90) * 0.9 = 126
const total = c.getTotal();
console.log(total === 126 ? 'PASS' : 'FAIL:' + total);
" 2>&1) || true
  [[ "$chain_test" == *"PASS"* ]] && score=$((score + 10))

  # Harder: Empty cart total is 0
  local empty_test
  empty_test=$(cd "$ws" && node -e "
let Cart; try { Cart = require('./src/cart'); } catch(e) { Cart = require('./cart'); }
const c = new Cart();
console.log(c.getTotal() === 0 ? 'PASS' : 'FAIL');
" 2>&1) || true
  [[ "$empty_test" == *"PASS"* ]] && score=$((score + 5))

  # Harder: Discount on empty cart doesn't crash
  local disc_empty
  disc_empty=$(cd "$ws" && node -e "
let Cart; try { Cart = require('./src/cart'); } catch(e) { Cart = require('./cart'); }
const c = new Cart();
c.applyDiscount(10);
console.log(c.getTotal() === 0 ? 'PASS' : 'FAIL');
" 2>&1) || true
  [[ "$disc_empty" == *"PASS"* ]] && score=$((score + 5))

  # Harder: Input type validation (string name, numeric price/qty)
  local type_test
  type_test=$(cd "$ws" && node -e "
let Cart; try { Cart = require('./src/cart'); } catch(e) { Cart = require('./cart'); }
const c = new Cart();
let thrown = 0;
try { c.addItem('', 10, 1); } catch(e) { thrown++; }
try { c.addItem('A', 'abc', 1); } catch(e) { thrown++; }
try { c.addItem('A', 10, 1.5); } catch(e) { thrown++; }
console.log(thrown >= 2 ? 'PASS' : 'PARTIAL:' + thrown);
" 2>&1) || true
  [[ "$type_test" == *"PASS"* ]] && score=$((score + 10))

  # Harder: Discount of exactly 0 and exactly 100 work
  local edge_disc
  edge_disc=$(cd "$ws" && node -e "
let Cart; try { Cart = require('./src/cart'); } catch(e) { Cart = require('./cart'); }
const c = new Cart();
c.addItem('A', 100, 1);
c.applyDiscount(0);
const t1 = c.getTotal();
const c2 = new Cart();
c2.addItem('A', 100, 1);
c2.applyDiscount(100);
const t2 = c2.getTotal();
console.log(t1 === 100 && t2 === 0 ? 'PASS' : 'FAIL:' + t1 + ',' + t2);
" 2>&1) || true
  [[ "$edge_disc" == *"PASS"* ]] && score=$((score + 5))

  [[ $score -gt 100 ]] && score=100
  echo "$score"
}

rubric_test_quality() {
  local ws="$1"
  local score=0

  local test_files
  test_files=$(find "$ws" -maxdepth 3 \( -name "*.test.*" -o -name "*.spec.*" \) ! -path "*/node_modules/*" 2>/dev/null)
  local test_count
  test_count=$(echo "$test_files" | grep -c . 2>/dev/null) || test_count=0
  [[ $test_count -gt 0 ]] && score=$((score + 10))

  # Tests pass
  local test_output
  test_output=$(cd "$ws" && npm test 2>&1 | tail -30) || true
  if echo "$test_output" | grep -qiE "pass|✓|ok|success"; then
    score=$((score + 20))
  fi

  # Count individual test cases
  local case_count=0
  if [[ -n "$test_files" ]]; then
    case_count=$(echo "$test_files" | xargs grep -cE "it\(|test\(|describe\(" 2>/dev/null | awk -F: '{s+=$2} END {print s+0}') || case_count=0
  fi
  [[ $case_count -gt 5 ]] && score=$((score + 10))
  [[ $case_count -gt 10 ]] && score=$((score + 10))

  # Tests cover each of the 5 bugs
  local bugs_tested=0
  if [[ -n "$test_files" ]]; then
    for pattern in "negativ|invalid.*price|invalid.*quantity|price.*less|quantity.*less" \
                   "remove|filter|delete.*item" \
                   "total|getTotal|sum|off.by.one|boundary" \
                   "discount.*subtract|discount.*correct|discount.*reduce|apply.*discount" \
                   "discount.*range|discount.*valid|discount.*100|discount.*0|discount.*bound"; do
      if echo "$test_files" | xargs grep -qlEi "$pattern" 2>/dev/null; then
        bugs_tested=$((bugs_tested + 1))
      fi
    done
  fi
  score=$((score + bugs_tested * 6))

  # Tests verify error cases (try/catch, throws, expect().toThrow)
  local error_test_count=0
  if [[ -n "$test_files" ]]; then
    error_test_count=$(echo "$test_files" | xargs grep -cE "toThrow|throw|expect.*Error|reject|catch" 2>/dev/null | awk -F: '{s+=$2} END {print s+0}') || error_test_count=0
  fi
  [[ $error_test_count -ge 3 ]] && score=$((score + 10))

  # Tests have descriptive names (not just "test 1", "test 2")
  local descriptive=0
  if [[ -n "$test_files" ]]; then
    if echo "$test_files" | xargs grep -qlEi "should|when|given|invalid|negative|empty|error" 2>/dev/null; then
      descriptive=1
    fi
  fi
  [[ $descriptive -eq 1 ]] && score=$((score + 10))

  [[ $score -gt 100 ]] && score=100
  echo "$score"
}

rubric_robustness() {
  local ws="$1"
  local score=0

  local cart_file="$ws/src/cart.js"
  [[ -f "$cart_file" ]] || cart_file="$ws/cart.js"
  [[ -f "$cart_file" ]] || { echo "0"; return; }

  # Has comprehensive input validation
  if grep -qE "throw|Error|typeof|isNaN" "$cart_file" 2>/dev/null; then
    score=$((score + 15))
  fi

  # Validates ALL method inputs (not just addItem)
  local methods_validated=0
  if grep -qE "addItem.*throw|addItem.*Error|if.*name|if.*price|if.*quantity" "$cart_file" 2>/dev/null; then
    methods_validated=$((methods_validated + 1))
  fi
  if grep -qE "removeItem.*throw|removeItem.*if|removeItem.*!|removeItem.*Error" "$cart_file" 2>/dev/null || \
     grep -A5 "removeItem" "$cart_file" 2>/dev/null | grep -qE "throw|if.*!|Error"; then
    methods_validated=$((methods_validated + 1))
  fi
  if grep -A5 "applyDiscount" "$cart_file" 2>/dev/null | grep -qE "throw|if.*!|Error|<\s*0|>\s*100"; then
    methods_validated=$((methods_validated + 1))
  fi
  [[ $methods_validated -ge 2 ]] && score=$((score + 15))

  # Edge case handling
  local crash_test
  crash_test=$(cd "$ws" && node -e "
let Cart; try { Cart = require('./src/cart'); } catch(e) { Cart = require('./cart'); }
const c = new Cart();
let ok = true;
// Empty cart operations
try { c.getTotal(); } catch(e) { ok = false; }
try { c.removeItem('nonexistent'); } catch(e) { /* acceptable */ }
// Rapid add/remove
c.addItem('X', 1, 1);
c.addItem('X', 2, 1);  // Same name, different price
c.removeItem('X');
try { c.getTotal(); } catch(e) { ok = false; }
console.log(ok ? 'PASS' : 'FAIL');
" 2>&1) || true
  [[ "$crash_test" == *"PASS"* ]] && score=$((score + 20))

  # Code uses clear variable names (not single-letter in logic)
  local short_vars
  short_vars=$(grep -cE "for.*\(.*[a-z]\s*=" "$cart_file" 2>/dev/null) || short_vars=0
  # Some loop vars are fine, but business logic with single-letter vars is bad
  [[ $short_vars -lt 5 ]] && score=$((score + 10))

  # Module exports correctly
  if grep -q "module.exports\|export" "$cart_file" 2>/dev/null; then
    score=$((score + 10))
  fi

  # No console.log left in production code (only in tests)
  local console_in_src
  console_in_src=$(grep -c "console.log\|console.warn\|console.error" "$cart_file" 2>/dev/null) || console_in_src=0
  [[ $console_in_src -eq 0 ]] && score=$((score + 10))

  # Uses const/let instead of var
  if ! grep -q "\bvar\b" "$cart_file" 2>/dev/null; then
    score=$((score + 10))
  fi

  # Clean structure: class or clear function organization
  if grep -qE "class Cart|class ShoppingCart" "$cart_file" 2>/dev/null; then
    score=$((score + 10))
  fi

  [[ $score -gt 100 ]] && score=100
  echo "$score"
}
