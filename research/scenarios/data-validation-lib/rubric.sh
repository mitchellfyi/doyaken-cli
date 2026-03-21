#!/usr/bin/env bash
# Rubric for: data-validation-lib

rubric_correctness() {
  local ws="$1"
  local score=0

  # Package structure exists
  [[ -d "$ws/validators" ]] && score=$((score + 5))
  [[ -f "$ws/validators/__init__.py" ]] && score=$((score + 5))

  # Email validator works
  local email_result
  email_result=$(cd "$ws" && python3 -c "
from validators import validate_email
ok, msg = validate_email('test@example.com')
assert ok, f'Should be valid: {msg}'
ok, msg = validate_email('not-an-email')
assert not ok, 'Should be invalid'
print('PASS')
" 2>&1) || true
  [[ "$email_result" == *"PASS"* ]] && score=$((score + 15))

  # URL validator works
  local url_result
  url_result=$(cd "$ws" && python3 -c "
from validators import validate_url
ok, msg = validate_url('https://example.com')
assert ok, f'Should be valid: {msg}'
ok, msg = validate_url('not-a-url')
assert not ok, 'Should be invalid'
print('PASS')
" 2>&1) || true
  [[ "$url_result" == *"PASS"* ]] && score=$((score + 15))

  # Phone validator works
  local phone_result
  phone_result=$(cd "$ws" && python3 -c "
from validators import validate_phone
ok, msg = validate_phone('(555) 234-5678')
assert ok, f'Should be valid: {msg}'
ok, msg = validate_phone('123')
assert not ok, 'Should be invalid'
print('PASS')
" 2>&1) || true
  [[ "$phone_result" == *"PASS"* ]] && score=$((score + 15))

  # Credit card (Luhn) validator works
  local cc_result
  cc_result=$(cd "$ws" && python3 -c "
from validators import validate_credit_card
# 4111111111111111 is a valid Luhn test number
ok, msg = validate_credit_card('4111111111111111')
assert ok, f'Should be valid: {msg}'
ok, msg = validate_credit_card('1234567890123456')
assert not ok, 'Should be invalid'
print('PASS')
" 2>&1) || true
  [[ "$cc_result" == *"PASS"* ]] && score=$((score + 15))

  # Date range validator works
  local date_result
  date_result=$(cd "$ws" && python3 -c "
from validators import validate_date_range
ok, msg = validate_date_range('2024-01-01', '2024-12-31')
assert ok, f'Should be valid: {msg}'
ok, msg = validate_date_range('2024-12-31', '2024-01-01')
assert not ok, 'Should be invalid'
print('PASS')
" 2>&1) || true
  [[ "$date_result" == *"PASS"* ]] && score=$((score + 15))

  # Handles None/empty gracefully (no crash)
  local null_result
  null_result=$(cd "$ws" && python3 -c "
from validators import validate_email
ok, msg = validate_email(None)
assert not ok
ok, msg = validate_email('')
assert not ok
print('PASS')
" 2>&1) || true
  [[ "$null_result" == *"PASS"* ]] && score=$((score + 15))

  echo "$score"
}

rubric_test_quality() {
  local ws="$1"
  local score=0

  # Test directory exists
  # Test directory exists (tests/ or test/)
  [[ -d "$ws/tests" || -d "$ws/test" ]] && score=$((score + 10))

  # Test files exist (search broadly)
  local test_count
  test_count=$(find "$ws" -maxdepth 4 \( -name "test_*.py" -o -name "*_test.py" \) ! -path "*/.venv/*" 2>/dev/null | wc -l | tr -d ' ')
  [[ $test_count -gt 0 ]] && score=$((score + 15))
  [[ $test_count -ge 3 ]] && score=$((score + 15))

  # Tests pass with pytest
  if (cd "$ws" && python3 -m pytest 2>&1 | tail -5 | grep -qiE "passed|ok"); then
    score=$((score + 40))
  elif (cd "$ws" && python3 -m unittest discover 2>&1 | tail -5 | grep -qi "ok"); then
    score=$((score + 40))
  fi

  # Tests cover all validators (search test files broadly)
  local validators_tested=0
  for v in "email" "url" "phone" "credit" "date"; do
    if find "$ws" -maxdepth 4 \( -name "test_*.py" -o -name "*_test.py" \) ! -path "*/.venv/*" -exec grep -ql "$v" {} + 2>/dev/null; then
      validators_tested=$((validators_tested + 1))
    fi
  done
  [[ $validators_tested -ge 4 ]] && score=$((score + 20))

  echo "$score"
}

rubric_robustness() {
  local ws="$1"
  local score=0

  # Has type checking / input guards
  local src_files
  src_files=$(find "$ws/validators" -name "*.py" 2>/dev/null)

  # Checks for None/empty handling
  if echo "$src_files" | xargs grep -ql "is None\|not.*input\|not.*value\|isinstance\|if not" 2>/dev/null; then
    score=$((score + 25))
  fi

  # Uses try/except for edge cases
  if echo "$src_files" | xargs grep -ql "try:\|except\|ValueError\|TypeError" 2>/dev/null; then
    score=$((score + 25))
  fi

  # Returns proper tuple format
  if echo "$src_files" | xargs grep -ql "return.*True\|return.*False\|return (True\|return (False" 2>/dev/null; then
    score=$((score + 25))
  fi

  # No external dependencies
  if [[ ! -f "$ws/requirements.txt" ]] || [[ $(wc -l < "$ws/requirements.txt" 2>/dev/null || echo "0") -le 1 ]]; then
    score=$((score + 25))
  fi

  echo "$score"
}
