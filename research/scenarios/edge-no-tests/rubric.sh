#!/usr/bin/env bash
# Rubric for: edge-no-tests
# Key test: DK should write tests even though the prompt doesn't ask for them.
# Target: a "perfect" DK implementation should score ~80-85, not 100.
# This is a HARD scenario — the prompt never mentions tests, but good engineering
# practice demands them.

rubric_correctness() {
  local ws="$1"
  local score=0

  [[ -f "$ws/go.mod" ]] && score=$((score + 5))

  # Find the main source file (check subdirectories too)
  local src_file=""
  for f in "strutil.go" "str_util.go" "string_util.go" "strings.go"; do
    [[ -f "$ws/$f" ]] && src_file="$f" && break
  done
  [[ -z "$src_file" ]] && { echo "$score"; return; }

  # Go builds cleanly
  if (cd "$ws" && go build ./... 2>/dev/null); then
    score=$((score + 5))
  else
    echo "$score"; return
  fi

  # --- Reverse: basic ASCII ---
  local rev_basic
  rev_basic=$(cd "$ws" && cat <<'GOEOF' > /tmp/_dk_rev_basic.go && go run /tmp/_dk_rev_basic.go 2>/dev/null
package main
import (
    "fmt"
    "strutil"
)
func main() {
    if strutil.Reverse("hello") == "olleh" && strutil.Reverse("") == "" {
        fmt.Println("PASS")
    } else {
        fmt.Println("FAIL")
    }
}
GOEOF
  ) || true
  [[ "$rev_basic" == *"PASS"* ]] && score=$((score + 10))

  # --- Reverse: multi-byte Unicode (rune-level) ---
  local rev_unicode
  rev_unicode=$(cd "$ws" && cat <<'GOEOF' > /tmp/_dk_rev_unicode.go && go run /tmp/_dk_rev_unicode.go 2>/dev/null
package main
import (
    "fmt"
    "strutil"
)
func main() {
    // "héllo" reversed should be "olléh" (rune-correct)
    if strutil.Reverse("héllo") == "olléh" {
        fmt.Println("PASS")
    } else {
        fmt.Println("FAIL")
    }
}
GOEOF
  ) || true
  [[ "$rev_unicode" == *"PASS"* ]] && score=$((score + 7))

  # --- Reverse: emoji / grapheme clusters ---
  # This is HARD — most naive rune-based Reverse breaks combining chars.
  # e.g. "hello🇯🇵" reversed with naive rune reverse gives broken flag emoji.
  local rev_emoji
  rev_emoji=$(cd "$ws" && cat <<'GOEOF' > /tmp/_dk_rev_emoji.go && go run /tmp/_dk_rev_emoji.go 2>/dev/null
package main
import (
    "fmt"
    "strutil"
)
func main() {
    // Flag emoji is two code points (regional indicators).
    // Naive rune reverse of "ab🇯🇵" would split the flag.
    r := strutil.Reverse("ab🇯🇵")
    if r == "🇯🇵ba" {
        fmt.Println("PASS")
    } else {
        fmt.Println("FAIL")
    }
}
GOEOF
  ) || true
  [[ "$rev_emoji" == *"PASS"* ]] && score=$((score + 5))

  # --- Capitalize: basic ---
  local cap_basic
  cap_basic=$(cd "$ws" && cat <<'GOEOF' > /tmp/_dk_cap_basic.go && go run /tmp/_dk_cap_basic.go 2>/dev/null
package main
import (
    "fmt"
    "strutil"
)
func main() {
    r := strutil.Capitalize("hello world")
    if r == "Hello World" {
        fmt.Println("PASS")
    } else {
        fmt.Println("FAIL: got " + r)
    }
}
GOEOF
  ) || true
  [[ "$cap_basic" == *"PASS"* ]] && score=$((score + 10))

  # --- Capitalize: Unicode accented chars ---
  local cap_unicode
  cap_unicode=$(cd "$ws" && cat <<'GOEOF' > /tmp/_dk_cap_unicode.go && go run /tmp/_dk_cap_unicode.go 2>/dev/null
package main
import (
    "fmt"
    "strutil"
)
func main() {
    // "école de paris" -> "École De Paris" (É is correct Unicode uppercase of é)
    r := strutil.Capitalize("école de paris")
    if r == "École De Paris" {
        fmt.Println("PASS")
    } else {
        fmt.Println("FAIL: got " + r)
    }
}
GOEOF
  ) || true
  [[ "$cap_unicode" == *"PASS"* ]] && score=$((score + 5))

  # --- Capitalize: empty and whitespace ---
  local cap_empty
  cap_empty=$(cd "$ws" && cat <<'GOEOF' > /tmp/_dk_cap_empty.go && go run /tmp/_dk_cap_empty.go 2>/dev/null
package main
import (
    "fmt"
    "strutil"
)
func main() {
    if strutil.Capitalize("") == "" && strutil.Capitalize("   ") == "   " {
        fmt.Println("PASS")
    } else {
        fmt.Println("FAIL")
    }
}
GOEOF
  ) || true
  [[ "$cap_empty" == *"PASS"* ]] && score=$((score + 4))

  # --- Truncate: basic ---
  local trunc_basic
  trunc_basic=$(cd "$ws" && cat <<'GOEOF' > /tmp/_dk_trunc_basic.go && go run /tmp/_dk_trunc_basic.go 2>/dev/null
package main
import (
    "fmt"
    "strutil"
)
func main() {
    r := strutil.Truncate("hello world", 5)
    // Should be "he..." (5 total) or "hello..." — both conventions acceptable
    pass := false
    if r == "he..." || r == "hello..." {
        pass = true
    }
    // Also: no truncation if string fits
    r2 := strutil.Truncate("hi", 10)
    if pass && r2 == "hi" {
        fmt.Println("PASS")
    } else {
        fmt.Println("FAIL: got " + r + " and " + r2)
    }
}
GOEOF
  ) || true
  [[ "$trunc_basic" == *"PASS"* ]] && score=$((score + 10))

  # --- Truncate: must not break multi-byte characters ---
  local trunc_unicode
  trunc_unicode=$(cd "$ws" && cat <<'GOEOF' > /tmp/_dk_trunc_unicode.go && go run /tmp/_dk_trunc_unicode.go 2>/dev/null
package main
import (
    "fmt"
    "unicode/utf8"
    "strutil"
)
func main() {
    // Truncating "héllo" at maxLen=3 should give valid UTF-8 (not garbled bytes)
    r := strutil.Truncate("héllo", 3)
    if utf8.ValidString(r) {
        fmt.Println("PASS")
    } else {
        fmt.Println("FAIL: invalid UTF-8")
    }
}
GOEOF
  ) || true
  [[ "$trunc_unicode" == *"PASS"* ]] && score=$((score + 5))

  # --- Truncate: edge cases (0, negative, empty) ---
  local trunc_edge
  trunc_edge=$(cd "$ws" && cat <<'GOEOF' > /tmp/_dk_trunc_edge.go && go run /tmp/_dk_trunc_edge.go 2>/dev/null
package main
import (
    "fmt"
    "strutil"
)
func main() {
    r1 := strutil.Truncate("", 5)
    r2 := strutil.Truncate("hello", 0)
    // Empty input should return empty; 0 maxLen should return "..." or ""
    if r1 == "" && (r2 == "..." || r2 == "") {
        fmt.Println("PASS")
    } else {
        fmt.Println("FAIL: got '" + r1 + "' and '" + r2 + "'")
    }
}
GOEOF
  ) || true
  [[ "$trunc_edge" == *"PASS"* ]] && score=$((score + 5))

  # --- Slugify: basic ---
  local slug_basic
  slug_basic=$(cd "$ws" && cat <<'GOEOF' > /tmp/_dk_slug_basic.go && go run /tmp/_dk_slug_basic.go 2>/dev/null
package main
import (
    "fmt"
    "strutil"
)
func main() {
    r := strutil.Slugify("Hello World!")
    if r == "hello-world" {
        fmt.Println("PASS")
    } else {
        fmt.Println("FAIL: got " + r)
    }
}
GOEOF
  ) || true
  [[ "$slug_basic" == *"PASS"* ]] && score=$((score + 8))

  # --- Slugify: multiple spaces / special chars ---
  local slug_special
  slug_special=$(cd "$ws" && cat <<'GOEOF' > /tmp/_dk_slug_special.go && go run /tmp/_dk_slug_special.go 2>/dev/null
package main
import (
    "fmt"
    "strings"
    "strutil"
)
func main() {
    r := strutil.Slugify("  Hello   World!!! ---  ")
    // Should have no leading/trailing hyphens, no double hyphens
    pass := !strings.HasPrefix(r, "-") && !strings.HasSuffix(r, "-") && !strings.Contains(r, "--")
    if pass && r == "hello-world" {
        fmt.Println("PASS")
    } else {
        fmt.Println("FAIL: got " + r)
    }
}
GOEOF
  ) || true
  [[ "$slug_special" == *"PASS"* ]] && score=$((score + 6))

  # --- Slugify: Unicode / accented chars ---
  # Hard: "Café Résumé" should become "cafe-resume" (transliterated) or "caf-rsum" (stripped)
  local slug_unicode
  slug_unicode=$(cd "$ws" && cat <<'GOEOF' > /tmp/_dk_slug_unicode.go && go run /tmp/_dk_slug_unicode.go 2>/dev/null
package main
import (
    "fmt"
    "strings"
    "strutil"
)
func main() {
    r := strutil.Slugify("Café Résumé")
    // Best: "cafe-resume" (transliterated). Acceptable: "caf-rsum" (stripped).
    // Must be valid slug: lowercase, no special chars, no leading/trailing hyphens
    pass := !strings.HasPrefix(r, "-") && !strings.HasSuffix(r, "-") && !strings.Contains(r, "--")
    // Must at least have some content
    if pass && len(r) >= 3 && r == strings.ToLower(r) {
        fmt.Println("PASS")
    } else {
        fmt.Println("FAIL: got " + r)
    }
}
GOEOF
  ) || true
  [[ "$slug_unicode" == *"PASS"* ]] && score=$((score + 5))

  # --- Slugify: empty / whitespace only ---
  local slug_empty
  slug_empty=$(cd "$ws" && cat <<'GOEOF' > /tmp/_dk_slug_empty.go && go run /tmp/_dk_slug_empty.go 2>/dev/null
package main
import (
    "fmt"
    "strutil"
)
func main() {
    r1 := strutil.Slugify("")
    r2 := strutil.Slugify("   ")
    if r1 == "" && r2 == "" {
        fmt.Println("PASS")
    } else {
        fmt.Println("FAIL")
    }
}
GOEOF
  ) || true
  [[ "$slug_empty" == *"PASS"* ]] && score=$((score + 5))

  # --- Long string stress test (10K chars) ---
  local long_test
  long_test=$(cd "$ws" && cat <<'GOEOF' > /tmp/_dk_long.go && go run /tmp/_dk_long.go 2>/dev/null
package main
import (
    "fmt"
    "strings"
    "strutil"
)
func main() {
    long := strings.Repeat("abcde ", 2000) // ~12K chars
    // Should not panic on any function
    _ = strutil.Reverse(long)
    _ = strutil.Capitalize(long)
    _ = strutil.Truncate(long, 100)
    _ = strutil.Slugify(long)
    fmt.Println("PASS")
}
GOEOF
  ) || true
  [[ "$long_test" == *"PASS"* ]] && score=$((score + 5))

  # Cleanup temp files
  rm -f /tmp/_dk_*.go 2>/dev/null

  echo "$score"
}

rubric_test_quality() {
  local ws="$1"
  local score=0

  # ============================================================
  # THIS IS THE KEY DIMENSION: The prompt NEVER asks for tests.
  # A great DK should write them anyway — that's the whole point
  # of this scenario.
  # ============================================================

  # Step 1: Do test files exist at all? (CRITICAL — 40pt bonus)
  local test_files
  test_files=$(find "$ws" -name "*_test.go" 2>/dev/null | wc -l | tr -d ' ')

  if [[ $test_files -gt 0 ]]; then
    score=$((score + 40))  # Massive bonus for writing tests unprompted
  else
    # No tests at all — this dimension is effectively 0
    echo "0"
    return
  fi

  # Step 2: Tests actually pass (not just present)
  local tests_output
  tests_output=$(cd "$ws" && go test ./... -count=1 2>&1) || true
  if [[ "$tests_output" == *"PASS"* && "$tests_output" != *"FAIL"* ]]; then
    score=$((score + 10))
  fi

  # Step 3: Tests cover ALL 4 functions
  local funcs_tested=0
  for func in "Reverse" "Capitalize" "Truncate" "Slugify"; do
    if find "$ws" -name "*_test.go" -exec grep -ql "$func" {} + 2>/dev/null; then
      funcs_tested=$((funcs_tested + 1))
    fi
  done
  [[ $funcs_tested -ge 3 ]] && score=$((score + 5))
  [[ $funcs_tested -ge 4 ]] && score=$((score + 5))

  # Step 4: Table-driven tests (idiomatic Go)
  local has_table_driven=0
  if find "$ws" -name "*_test.go" -exec grep -ql "[]struct\|test.*cases\|test.*table\|tt\.\|tc\.\|tests\s*:=\s*\[\]" {} + 2>/dev/null; then
    has_table_driven=1
    score=$((score + 8))
  fi

  # Step 5: Edge cases in tests (empty strings, Unicode)
  local edge_cases=0
  # Check for empty string test cases
  if find "$ws" -name "*_test.go" -exec grep -ql '""' {} + 2>/dev/null; then
    edge_cases=$((edge_cases + 1))
  fi
  # Check for Unicode test cases
  if find "$ws" -name "*_test.go" -exec grep -qlE 'unicode|rune|utf|emoji|héllo|café|accented|ñ|ü|é' {} + 2>/dev/null; then
    edge_cases=$((edge_cases + 1))
  fi
  # Check for long string or boundary tests
  if find "$ws" -name "*_test.go" -exec grep -qlE 'Repeat|long|boundary|10000|1000|large' {} + 2>/dev/null; then
    edge_cases=$((edge_cases + 1))
  fi
  [[ $edge_cases -ge 1 ]] && score=$((score + 5))
  [[ $edge_cases -ge 2 ]] && score=$((score + 5))
  [[ $edge_cases -ge 3 ]] && score=$((score + 7))

  # Step 6: Benchmark tests (bonus — very few DKs will do this)
  if find "$ws" -name "*_test.go" -exec grep -ql "func Benchmark" {} + 2>/dev/null; then
    score=$((score + 5))
  fi

  # Step 7: Test count — more tests = more thorough
  # Count test functions
  local test_func_count
  test_func_count=$(find "$ws" -name "*_test.go" -exec grep -c "func Test" {} + 2>/dev/null | awk -F: '{s+=$NF}END{print s+0}') || true
  # Lots of individual tests OR table-driven with many cases = good
  [[ $test_func_count -ge 4 ]] && score=$((score + 5))
  [[ $test_func_count -ge 8 ]] && score=$((score + 5))

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

  # --- Empty string handling (explicit checks in source) ---
  if grep -qE 'len\(s\)\s*==\s*0|s\s*==\s*""|len\(.*\)\s*==\s*0' "$src_file" 2>/dev/null; then
    score=$((score + 10))
  fi

  # --- Unicode-aware: uses runes not bytes in Reverse ---
  if grep -q "rune\|utf8\|RuneCountInString" "$src_file" 2>/dev/null; then
    score=$((score + 10))
  fi

  # --- Truncate boundary checks (maxLen <= 0, maxLen >= len) ---
  if grep -qE 'maxLen\s*[<]=\s*0|maxLen\s*>=\s*len|maxLen\s*>\s*len|len\(.*\)\s*<=\s*max' "$src_file" 2>/dev/null; then
    score=$((score + 10))
  fi

  # --- go vet passes ---
  if (cd "$ws" && go vet ./... 2>/dev/null); then
    score=$((score + 10))
  fi

  # --- Go doc comments on all exported functions ---
  local exported_funcs
  exported_funcs=$(grep -cE '^func [A-Z]' "$src_file" 2>/dev/null) || true
  local documented_funcs
  # A doc comment is a // comment immediately before func
  documented_funcs=$(grep -cB1 '^func [A-Z]' "$src_file" 2>/dev/null | grep -c '//' 2>/dev/null) || true
  if [[ $exported_funcs -gt 0 && $documented_funcs -ge $exported_funcs ]]; then
    score=$((score + 10))
  elif [[ $documented_funcs -ge 2 ]]; then
    score=$((score + 5))  # Partial credit
  fi

  # --- staticcheck / golangci-lint passes (if available) ---
  local lint_pass=0
  if command -v staticcheck &>/dev/null; then
    if (cd "$ws" && staticcheck ./... 2>/dev/null); then
      lint_pass=1
    fi
  elif command -v golangci-lint &>/dev/null; then
    if (cd "$ws" && golangci-lint run ./... 2>/dev/null); then
      lint_pass=1
    fi
  else
    # Neither available — give benefit of the doubt if go vet passed
    lint_pass=1
  fi
  [[ $lint_pass -eq 1 ]] && score=$((score + 10))

  # --- No unnecessary dependencies (stdlib only) ---
  local dep_count
  dep_count=$(cd "$ws" && grep -c "require" go.mod 2>/dev/null) || true
  if [[ $dep_count -le 0 ]]; then
    score=$((score + 10))
  fi

  # --- Thread safety: test concurrent calls don't panic ---
  local concurrent_test
  concurrent_test=$(cd "$ws" && cat <<'GOEOF' > /tmp/_dk_concurrent.go && go run /tmp/_dk_concurrent.go 2>/dev/null
package main
import (
    "fmt"
    "sync"
    "strutil"
)
func main() {
    var wg sync.WaitGroup
    for i := 0; i < 100; i++ {
        wg.Add(4)
        go func() { defer wg.Done(); _ = strutil.Reverse("hello world") }()
        go func() { defer wg.Done(); _ = strutil.Capitalize("hello world") }()
        go func() { defer wg.Done(); _ = strutil.Truncate("hello world", 5) }()
        go func() { defer wg.Done(); _ = strutil.Slugify("Hello World!") }()
    }
    wg.Wait()
    fmt.Println("PASS")
}
GOEOF
  ) || true
  rm -f /tmp/_dk_concurrent.go 2>/dev/null
  [[ "$concurrent_test" == *"PASS"* ]] && score=$((score + 10))

  # --- Uses strings.Builder or efficient concatenation (not naive += in loops) ---
  if grep -qE 'strings\.Builder|bytes\.Buffer|strings\.Join|append.*rune' "$src_file" 2>/dev/null; then
    score=$((score + 10))
  fi

  # --- Slugify uses regexp or manual approach for special char handling ---
  if grep -qE 'regexp\.|unicode\.|strings\.Map' "$src_file" 2>/dev/null; then
    score=$((score + 10))
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
