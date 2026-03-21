#!/usr/bin/env bash
# Rubric for: edge-no-tests
# Key test: DK should write tests even though the prompt doesn't ask for them.

rubric_correctness() {
  local ws="$1"
  local score=0

  [[ -f "$ws/go.mod" ]] && score=$((score + 10))

  # Find the main source file
  local src_file=""
  for f in "strutil.go" "str_util.go" "string_util.go" "strings.go"; do
    [[ -f "$ws/$f" ]] && src_file="$f" && break
  done
  [[ -z "$src_file" ]] && { echo "$score"; return; }

  # Go builds
  if (cd "$ws" && go build ./... 2>/dev/null); then
    score=$((score + 10))
  else
    echo "$score"; return
  fi

  # Reverse works
  local rev_test
  rev_test=$(cd "$ws" && go run -exec '' /dev/stdin 2>/dev/null <<'GOEOF'
package main
import (
    "fmt"
    "strutil"
)
func main() {
    if strutil.Reverse("hello") == "olleh" {
        fmt.Println("PASS")
    } else {
        fmt.Println("FAIL")
    }
}
GOEOF
  ) || true
  # Fallback: test via go test if inline won't work
  if [[ "$rev_test" != *"PASS"* ]]; then
    rev_test=$(cd "$ws" && go test -run "TestReverse|Test_Reverse" -v ./... 2>&1) || true
    [[ "$rev_test" == *"PASS"* ]] && score=$((score + 20))
  else
    score=$((score + 20))
  fi

  # Capitalize works
  if (cd "$ws" && go test -run "TestCapitalize|Test_Capitalize" -v ./... 2>&1 | grep -q "PASS"); then
    score=$((score + 20))
  fi

  # Truncate works
  if (cd "$ws" && go test -run "TestTruncate|Test_Truncate" -v ./... 2>&1 | grep -q "PASS"); then
    score=$((score + 20))
  fi

  # Slugify works
  if (cd "$ws" && go test -run "TestSlugify|Test_Slugify" -v ./... 2>&1 | grep -q "PASS"); then
    score=$((score + 20))
  fi

  echo "$score"
}

rubric_test_quality() {
  local ws="$1"
  local score=0

  # THIS IS THE KEY CHECK: Did DK write tests even though prompt didn't ask?
  local test_files
  test_files=$(find "$ws" -name "*_test.go" 2>/dev/null | wc -l | tr -d ' ')

  if [[ $test_files -gt 0 ]]; then
    score=$((score + 30))  # Major points for writing tests unprompted
  fi

  # Tests pass
  if (cd "$ws" && go test ./... 2>&1 | grep -q "PASS"); then
    score=$((score + 30))
  fi

  # Tests cover all 4 functions
  local funcs_tested=0
  for func in "Reverse" "Capitalize" "Truncate" "Slugify"; do
    if find "$ws" -name "*_test.go" -exec grep -ql "$func" {} + 2>/dev/null; then
      funcs_tested=$((funcs_tested + 1))
    fi
  done
  [[ $funcs_tested -ge 3 ]] && score=$((score + 20))
  [[ $funcs_tested -ge 4 ]] && score=$((score + 20))

  echo "$score"
}

rubric_robustness() {
  local ws="$1"
  local score=0

  local src_file=""
  for f in "strutil.go" "str_util.go" "string_util.go" "strings.go"; do
    [[ -f "$ws/$f" ]] && src_file="$ws/$f" && break
  done
  [[ -z "$src_file" ]] && { echo "0"; return; }

  # Handles empty string
  if grep -qE 'len\(s\)\s*==\s*0|s\s*==\s*""' "$src_file" 2>/dev/null; then
    score=$((score + 25))
  fi

  # Handles Unicode in Reverse (uses runes, not bytes)
  if grep -q "rune\|utf8\|RuneCountInString" "$src_file" 2>/dev/null; then
    score=$((score + 25))
  fi

  # Truncate handles edge cases (maxLen <= 0, maxLen > len)
  if grep -qE "maxLen\s*[<]=\s*0\|maxLen\s*>=\s*len\|len\(s\)\s*<=\s*maxLen" "$src_file" 2>/dev/null; then
    score=$((score + 25))
  fi

  # go vet passes
  if (cd "$ws" && go vet ./... 2>/dev/null); then
    score=$((score + 25))
  fi

  echo "$score"
}

# Custom issue detection: specifically check if DK's self-review caught the Unicode issue
rubric_issue_detection() {
  local ws="$1" result_dir="$2"
  local score=50

  # Check if DK mentioned Unicode handling in its output
  if [[ -f "$result_dir/stream.jsonl" ]]; then
    if grep -qi "unicode\|rune\|utf" "$result_dir/stream.jsonl" 2>/dev/null; then
      score=$((score + 25))  # Recognized the Unicode issue
    fi
    if grep -qi "test\|_test\.go" "$result_dir/stream.jsonl" 2>/dev/null; then
      score=$((score + 25))  # Mentioned testing (even though prompt didn't ask)
    fi
  fi

  echo "$score"
}
