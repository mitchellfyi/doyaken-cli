#!/usr/bin/env bash
# Rubric for: buggy-code-fix

rubric_correctness() {
  local ws="$1"
  local score=0

  [[ -f "$ws/src/cart.js" ]] || [[ -f "$ws/cart.js" ]] && score=$((score + 5))
  [[ -f "$ws/package.json" ]] && score=$((score + 5))

  (cd "$ws" && npm install --silent 2>/dev/null) || true

  local cart_file="$ws/src/cart.js"
  [[ -f "$cart_file" ]] || cart_file="$ws/cart.js"
  [[ -f "$cart_file" ]] || { echo "$score"; return; }

  # Bug 1 fixed: negative price/quantity validation
  if grep -qE "price\s*[<]=?\s*0|quantity\s*[<]=?\s*0|throw.*negativ|throw.*invalid|if.*price|if.*quantity" "$cart_file" 2>/dev/null; then
    score=$((score + 15))
  fi

  # Bug 2 fixed: filter uses === (not =) and removeItem works correctly
  if grep -qE '!==|!==' "$cart_file" 2>/dev/null || ! grep -q 'i\.name = name' "$cart_file" 2>/dev/null; then
    # Verify removeItem actually filters correctly (not assigns)
    local rm_test
    rm_test=$(cd "$ws" && node -e "
let Cart; try { Cart = require('./src/cart'); } catch(e) { Cart = require('./cart'); }
const c = new Cart();
c.addItem('A', 10, 1);
c.addItem('B', 20, 1);
c.removeItem('A');
console.log(c.items.length === 1 && c.items[0].name === 'B' ? 'PASS' : 'FAIL');
" 2>&1) || true
    [[ "$rm_test" == *"PASS"* ]] && score=$((score + 15))
  fi

  # Bug 3 fixed: no off-by-one in getTotal loop (< not <=)
  local total_test
  total_test=$(cd "$ws" && node -e "
let Cart; try { Cart = require('./src/cart'); } catch(e) { Cart = require('./cart'); }
const c = new Cart();
c.addItem('A', 10, 2);
c.addItem('B', 5, 1);
const total = c.getTotal();
console.log(total === 25 ? 'PASS' : 'FAIL:' + total);
" 2>&1) || true
  [[ "$total_test" == *"PASS"* ]] && score=$((score + 15))

  # Bug 4 fixed: discount subtracts (not adds)
  local discount_test
  discount_test=$(cd "$ws" && node -e "
let Cart; try { Cart = require('./src/cart'); } catch(e) { Cart = require('./cart'); }
const c = new Cart();
c.addItem('A', 100, 1);
c.applyDiscount(10);
const total = c.getTotal();
console.log(total === 90 ? 'PASS' : 'FAIL:' + total);
" 2>&1) || true
  [[ "$discount_test" == *"PASS"* ]] && score=$((score + 15))

  # Bug 5 fixed: discount validation
  local disc_validate_test
  disc_validate_test=$(cd "$ws" && node -e "
let Cart; try { Cart = require('./src/cart'); } catch(e) { Cart = require('./cart'); }
const c = new Cart();
try {
  c.applyDiscount(150);
  console.log('FAIL: should have thrown');
} catch(e) {
  console.log('PASS');
}
try {
  c.applyDiscount(-10);
  console.log('FAIL: should have thrown');
} catch(e) {
  console.log('PASS');
}
" 2>&1) || true
  local pass_count
  pass_count="$(echo "$disc_validate_test" | grep -c "PASS")" || pass_count=0
  [[ $pass_count -ge 2 ]] && score=$((score + 15))

  # All 5 bugs fixed — bonus for clean code
  [[ $score -ge 80 ]] && score=$((score + 15))

  [[ $score -gt 100 ]] && score=100
  echo "$score"
}

rubric_test_quality() {
  local ws="$1"
  local score=0

  local test_count
  test_count=$(find "$ws" -maxdepth 3 \( -name "*.test.*" -o -name "*.spec.*" \) ! -path "*/node_modules/*" 2>/dev/null | wc -l | tr -d ' ')
  [[ $test_count -gt 0 ]] && score=$((score + 15))

  # Tests pass
  if (cd "$ws" && npm test 2>&1 | tail -20 | grep -qiE "pass|✓|ok|success"); then
    score=$((score + 35))
  fi

  # Tests cover each bug (check for specific test descriptions or patterns)
  local test_files
  test_files=$(find "$ws" -maxdepth 3 \( -name "*.test.*" -o -name "*.spec.*" \) ! -path "*/node_modules/*" 2>/dev/null)
  local bugs_tested=0
  for pattern in "negativ|invalid.*price|invalid.*quantity" "remove|filter" "total|off.by.one|boundary" "discount.*subtract|discount.*correct" "discount.*range|discount.*valid|discount.*100"; do
    if echo "$test_files" | xargs grep -qlEi "$pattern" 2>/dev/null; then
      bugs_tested=$((bugs_tested + 1))
    fi
  done
  # Scale: 10 points per bug tested, up to 50
  score=$((score + bugs_tested * 10))

  echo "$score"
}

rubric_robustness() {
  local ws="$1"
  local score=0

  local cart_file="$ws/src/cart.js"
  [[ -f "$cart_file" ]] || cart_file="$ws/cart.js"
  [[ -f "$cart_file" ]] || { echo "0"; return; }

  # Has input validation
  if grep -qE "throw|Error|typeof|isNaN|!.*name\b|!.*price\b" "$cart_file" 2>/dev/null; then
    score=$((score + 30))
  fi

  # Has edge case handling
  if grep -qE "length\s*===?\s*0|empty|no items|not found" "$cart_file" 2>/dev/null; then
    score=$((score + 25))
  fi

  # All methods handle bad input without crashing
  local crash_test
  crash_test=$(cd "$ws" && node -e "
let Cart; try { Cart = require('./src/cart'); } catch(e) { Cart = require('./cart'); }
const c = new Cart();
try { c.removeItem('nonexistent'); } catch(e) {}
try { c.getTotal(); } catch(e) {}
console.log('NO_CRASH');
" 2>&1) || true
  [[ "$crash_test" == *"NO_CRASH"* ]] && score=$((score + 25))

  # Module exports correctly
  if grep -q "module.exports\|export" "$cart_file" 2>/dev/null; then
    score=$((score + 20))
  fi

  echo "$score"
}
