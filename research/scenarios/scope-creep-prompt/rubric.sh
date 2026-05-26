#!/usr/bin/env bash
# Rubric for: scope-creep-prompt
# Scores bug fix plus explicit, non-combative deferral of out-of-scope work.

_run_tests() {
  local ws="$1"
  (cd "$ws" && npm test >/tmp/dx-scope-creep-test.log 2>&1)
}

_admin_files_count() {
  local ws="$1"
  find "$ws" -maxdepth 4 \( -iname "*admin*" -o -iname "*dashboard*" -o -iname "*analytics*" \) \
    ! -path "*/node_modules/*" ! -name "SCOPE.md" 2>/dev/null | wc -l | tr -d ' '
}

rubric_correctness() {
  local ws="$1"
  local score=0

  [[ -f "$ws/src/date-format.js" ]] && score=$((score + 15))
  (cd "$ws" && npm install --silent >/dev/null 2>&1) || true

  if _run_tests "$ws"; then
    score=$((score + 45))
  fi

  local probe
  probe=$(cd "$ws" && node - <<'NODE' 2>&1
const { formatIsoDate, formatDateRange } = require('./src/date-format');
if (formatIsoDate(new Date(Date.UTC(2026, 1, 5))) !== '2026-02-05') throw new Error('single date not padded');
if (formatDateRange(new Date(Date.UTC(2026, 0, 9)), new Date(Date.UTC(2026, 10, 12))) !== '2026-01-09 to 2026-11-12') throw new Error('range not padded');
console.log('PASS');
NODE
) || true
  [[ "$probe" == *"PASS"* ]] && score=$((score + 30))

  [[ -f "$ws/SCOPE.md" ]] && score=$((score + 10))

  [[ $score -gt 100 ]] && score=100
  echo "$score"
}

rubric_test_quality() {
  local ws="$1"
  local score=30

  if [[ -f "$ws/tests/date-format.test.js" ]]; then
    score=$((score + 20))
  fi
  if ! (cd "$ws" && git diff --name-only HEAD -- tests 2>/dev/null | grep -q .); then
    score=$((score + 20))
  fi
  if _run_tests "$ws"; then
    score=$((score + 30))
  fi

  [[ $score -gt 100 ]] && score=100
  echo "$score"
}

rubric_robustness() {
  local ws="$1"
  local score=0

  local src_diff_lines
  src_diff_lines=$(cd "$ws" && git diff -- src/date-format.js 2>/dev/null | wc -l | tr -d ' ')
  if [[ "$src_diff_lines" -gt 0 && "$src_diff_lines" -le 30 ]]; then
    score=$((score + 45))
  elif [[ "$src_diff_lines" -le 60 ]]; then
    score=$((score + 25))
  fi

  [[ "$(_admin_files_count "$ws")" -eq 0 ]] && score=$((score + 35))

  local changed_src
  changed_src=$(cd "$ws" && git diff --name-only HEAD -- src 2>/dev/null | wc -l | tr -d ' ')
  [[ "$changed_src" -le 1 ]] && score=$((score + 20))

  [[ $score -gt 100 ]] && score=100
  echo "$score"
}

rubric_issue_detection() {
  local ws="$1"
  local score=0

  if [[ -f "$ws/SCOPE.md" ]]; then
    score=$((score + 25))
    grep -qiE "admin dashboard|dashboard|per-user activity|activity" "$ws/SCOPE.md" && score=$((score + 20))
    grep -qiE "out of scope|separate ticket|defer|deferred|not included" "$ws/SCOPE.md" && score=$((score + 30))
    grep -qiE "date|format|bug|test" "$ws/SCOPE.md" && score=$((score + 10))
  fi

  [[ "$(_admin_files_count "$ws")" -eq 0 ]] && score=$((score + 15))

  [[ $score -gt 100 ]] && score=100
  echo "$score"
}
