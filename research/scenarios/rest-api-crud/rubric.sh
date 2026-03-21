#!/usr/bin/env bash
# Rubric for: rest-api-crud
# Hardened rubric — a strong implementation should score ~85-90, not 100.

rubric_correctness() {
  local ws="$1"
  local score=0

  [[ -f "$ws/package.json" ]] && score=$((score + 2))

  # Install deps
  if ! (cd "$ws" && npm install --silent 2>/dev/null); then
    echo "$score"; return
  fi
  score=$((score + 3))

  # Find the server entry point (prefer main from package.json, then server.* over app.*)
  local entry=""
  local pkg_main
  pkg_main=$(cd "$ws" && node -e "try{console.log(require('./package.json').main||'')}catch(e){}" 2>/dev/null || true)
  if [[ -n "$pkg_main" && -f "$ws/$pkg_main" ]]; then
    entry="$pkg_main"
  else
    for f in "server.js" "src/server.js" "index.js" "src/index.js" "app.js" "src/app.js"; do
      [[ -f "$ws/$f" ]] && entry="$f" && break
    done
  fi
  [[ -z "$entry" ]] && { echo "$score"; return; }

  # Start the server in background, test endpoints
  local port=0
  port=$(_find_free_port)
  local server_pid=""

  # Try to start the server
  # Use exec so kill targets the node process directly (not a bash subshell)
  (cd "$ws" && exec env PORT=$port node "$entry") &>/dev/null &
  server_pid=$!
  sleep 2

  if ! kill -0 "$server_pid" 2>/dev/null; then
    echo "$score"; return
  fi

  local base="http://localhost:$port"

  # ---------- BASIC CRUD (50 points) ----------

  # POST /books — create a book (8 pts)
  local create_resp
  create_resp=$(curl -s -w "\n%{http_code}" -X POST "$base/books" \
    -H "Content-Type: application/json" \
    -d '{"title":"Test Book","author":"Test Author","isbn":"9780131103627"}' 2>/dev/null) || true
  local create_code
  create_code=$(echo "$create_resp" | tail -1)
  if [[ "$create_code" == "201" ]] || [[ "$create_code" == "200" ]]; then
    score=$((score + 8))
  fi

  # Verify created book has an ID in the response (4 pts)
  local create_body
  create_body=$(echo "$create_resp" | sed '$d')
  local created_id
  created_id=$(echo "$create_body" | python3 -c "
import json, sys
try:
    data = json.loads(sys.stdin.read())
    if isinstance(data, dict):
        print(data.get('id', ''))
    else:
        print('')
except:
    print('')
" 2>/dev/null || true)
  if [[ -n "$created_id" && "$created_id" != "None" && "$created_id" != "" ]]; then
    score=$((score + 4))
  fi

  # Verify created book echoes back the title (2 pts)
  local has_title
  has_title=$(echo "$create_body" | python3 -c "
import json, sys
try:
    data = json.loads(sys.stdin.read())
    print('yes' if data.get('title') == 'Test Book' else 'no')
except:
    print('no')
" 2>/dev/null || true)
  [[ "$has_title" == "yes" ]] && score=$((score + 2))

  # GET /books — list all books (8 pts)
  local list_resp
  list_resp=$(curl -s -w "\n%{http_code}" "$base/books" 2>/dev/null) || true
  local list_code
  list_code=$(echo "$list_resp" | tail -1)
  local list_body
  list_body=$(echo "$list_resp" | sed '$d')
  if [[ "$list_code" == "200" ]]; then
    score=$((score + 5))
    local has_book
    has_book=$(echo "$list_body" | python3 -c "
import json, sys
try:
    data = json.loads(sys.stdin.read())
    items = data if isinstance(data, list) else data.get('books', data.get('data', []))
    print('yes' if any('Test Book' in str(b.get('title','')) for b in items) else 'no')
except:
    print('no')
" 2>/dev/null || true)
    [[ "$has_book" == "yes" ]] && score=$((score + 3))
  fi

  # Extract book ID from list for subsequent tests
  local book_id
  book_id=$(echo "$list_body" | python3 -c "
import json, sys
try:
    data = json.loads(sys.stdin.read())
    items = data if isinstance(data, list) else data.get('books', data.get('data', []))
    if len(items) > 0:
        print(items[0].get('id', ''))
    else:
        print('')
except:
    print('')
" 2>/dev/null || true)
  # Fall back to created_id if list parsing failed
  [[ -z "$book_id" || "$book_id" == "None" ]] && book_id="$created_id"
  # Last resort fallback
  [[ -z "$book_id" || "$book_id" == "None" ]] && book_id="1"

  # GET /books/:id — single book (8 pts)
  local get_resp
  get_resp=$(curl -s -w "\n%{http_code}" "$base/books/$book_id" 2>/dev/null) || true
  local get_code
  get_code=$(echo "$get_resp" | tail -1)
  [[ "$get_code" == "200" ]] && score=$((score + 8))

  # PUT /books/:id — full update (8 pts)
  local put_resp
  put_resp=$(curl -s -w "\n%{http_code}" -X PUT "$base/books/$book_id" \
    -H "Content-Type: application/json" \
    -d '{"title":"Updated Book","author":"Updated Author","isbn":"9780131103627"}' 2>/dev/null) || true
  local put_code
  put_code=$(echo "$put_resp" | tail -1)
  [[ "$put_code" == "200" ]] && score=$((score + 8))

  # Verify PUT actually changed the data (3 pts)
  local verify_put
  verify_put=$(curl -s "$base/books/$book_id" 2>/dev/null) || true
  local put_changed
  put_changed=$(echo "$verify_put" | python3 -c "
import json, sys
try:
    data = json.loads(sys.stdin.read())
    print('yes' if data.get('title') == 'Updated Book' else 'no')
except:
    print('no')
" 2>/dev/null || true)
  [[ "$put_changed" == "yes" ]] && score=$((score + 3))

  # DELETE /books/:id (8 pts)
  local del_resp
  del_resp=$(curl -s -w "\n%{http_code}" -X DELETE "$base/books/$book_id" 2>/dev/null) || true
  local del_code
  del_code=$(echo "$del_resp" | tail -1)
  if [[ "$del_code" == "200" ]] || [[ "$del_code" == "204" ]]; then
    score=$((score + 8))
  fi

  # Verify deleted book is truly gone — GET after DELETE should 404 (3 pts)
  local gone_resp
  gone_resp=$(curl -s -w "\n%{http_code}" "$base/books/$book_id" 2>/dev/null) || true
  local gone_code
  gone_code=$(echo "$gone_resp" | tail -1)
  [[ "$gone_code" == "404" ]] && score=$((score + 3))

  # ---------- ERROR HANDLING (30 points) ----------

  # GET /books/nonexistent — 404 (5 pts)
  local notfound_resp
  notfound_resp=$(curl -s -w "\n%{http_code}" "$base/books/nonexistent-id-999" 2>/dev/null) || true
  local nf_code
  nf_code=$(echo "$notfound_resp" | tail -1)
  [[ "$nf_code" == "404" ]] && score=$((score + 5))

  # POST with empty body — 400 (5 pts)
  local empty_resp
  empty_resp=$(curl -s -w "\n%{http_code}" -X POST "$base/books" \
    -H "Content-Type: application/json" \
    -d '{}' 2>/dev/null) || true
  local empty_code
  empty_code=$(echo "$empty_resp" | tail -1)
  if [[ "$empty_code" == "400" ]] || [[ "$empty_code" == "422" ]]; then
    score=$((score + 5))
  fi

  # POST missing required field (author) — 400 (4 pts)
  local missing_resp
  missing_resp=$(curl -s -w "\n%{http_code}" -X POST "$base/books" \
    -H "Content-Type: application/json" \
    -d '{"title":"Only Title"}' 2>/dev/null) || true
  local missing_code
  missing_code=$(echo "$missing_resp" | tail -1)
  if [[ "$missing_code" == "400" ]] || [[ "$missing_code" == "422" ]]; then
    score=$((score + 4))
  fi

  # Invalid ISBN format — 400 (5 pts)
  local isbn_resp
  isbn_resp=$(curl -s -w "\n%{http_code}" -X POST "$base/books" \
    -H "Content-Type: application/json" \
    -d '{"title":"Book","author":"Author","isbn":"invalid"}' 2>/dev/null) || true
  local isbn_code
  isbn_code=$(echo "$isbn_resp" | tail -1)
  if [[ "$isbn_code" == "400" ]] || [[ "$isbn_code" == "422" ]]; then
    score=$((score + 5))
  fi

  # Duplicate ISBN rejection — second book with same ISBN should fail (4 pts)
  # First create a book with a specific ISBN
  local dup1_resp
  dup1_resp=$(curl -s -w "\n%{http_code}" -X POST "$base/books" \
    -H "Content-Type: application/json" \
    -d '{"title":"First Book","author":"Author One","isbn":"9781234567897"}' 2>/dev/null) || true
  local dup1_code
  dup1_code=$(echo "$dup1_resp" | tail -1)
  # Now try creating another book with the same ISBN
  local dup2_resp
  dup2_resp=$(curl -s -w "\n%{http_code}" -X POST "$base/books" \
    -H "Content-Type: application/json" \
    -d '{"title":"Second Book","author":"Author Two","isbn":"9781234567897"}' 2>/dev/null) || true
  local dup2_code
  dup2_code=$(echo "$dup2_resp" | tail -1)
  if [[ "$dup2_code" == "400" ]] || [[ "$dup2_code" == "409" ]] || [[ "$dup2_code" == "422" ]]; then
    score=$((score + 4))
  fi

  # Title too long (>200 chars) should fail validation (3 pts)
  local long_title
  long_title=$(python3 -c "print('A' * 201)" 2>/dev/null || true)
  local longstr_resp
  longstr_resp=$(curl -s -w "\n%{http_code}" -X POST "$base/books" \
    -H "Content-Type: application/json" \
    -d "{\"title\":\"$long_title\",\"author\":\"Author\"}" 2>/dev/null) || true
  local longstr_code
  longstr_code=$(echo "$longstr_resp" | tail -1)
  if [[ "$longstr_code" == "400" ]] || [[ "$longstr_code" == "422" ]]; then
    score=$((score + 3))
  fi

  # Content-Type validation — send non-JSON body with wrong content type (3 pts)
  local ct_resp
  ct_resp=$(curl -s -w "\n%{http_code}" -X POST "$base/books" \
    -H "Content-Type: text/plain" \
    -d 'this is not json' 2>/dev/null) || true
  local ct_code
  ct_code=$(echo "$ct_resp" | tail -1)
  if [[ "$ct_code" == "400" ]] || [[ "$ct_code" == "415" ]] || [[ "$ct_code" == "422" ]]; then
    score=$((score + 3))
  fi

  # Malformed JSON body handling (3 pts)
  local malformed_resp
  malformed_resp=$(curl -s -w "\n%{http_code}" -X POST "$base/books" \
    -H "Content-Type: application/json" \
    -d '{this is not valid json' 2>/dev/null) || true
  local malformed_code
  malformed_code=$(echo "$malformed_resp" | tail -1)
  if [[ "$malformed_code" == "400" ]] || [[ "$malformed_code" == "422" ]]; then
    score=$((score + 3))
  fi

  # ---------- ADVANCED (10 points) ----------

  # PATCH /books/:id — partial update (5 pts)
  # Create a fresh book to test PATCH against
  local patch_create
  patch_create=$(curl -s -w "\n%{http_code}" -X POST "$base/books" \
    -H "Content-Type: application/json" \
    -d '{"title":"Patch Target","author":"Original Author"}' 2>/dev/null) || true
  local patch_create_code
  patch_create_code=$(echo "$patch_create" | tail -1)
  local patch_body
  patch_body=$(echo "$patch_create" | sed '$d')
  local patch_id
  patch_id=$(echo "$patch_body" | python3 -c "
import json, sys
try:
    data = json.loads(sys.stdin.read())
    print(data.get('id', ''))
except:
    print('')
" 2>/dev/null || true)

  if [[ -n "$patch_id" && "$patch_id" != "None" && "$patch_id" != "" ]]; then
    local patch_resp
    patch_resp=$(curl -s -w "\n%{http_code}" -X PATCH "$base/books/$patch_id" \
      -H "Content-Type: application/json" \
      -d '{"title":"Patched Title"}' 2>/dev/null) || true
    local patch_code
    patch_code=$(echo "$patch_resp" | tail -1)
    if [[ "$patch_code" == "200" ]]; then
      # Verify only title changed, author preserved
      local verify_patch
      verify_patch=$(curl -s "$base/books/$patch_id" 2>/dev/null) || true
      local patch_ok
      patch_ok=$(echo "$verify_patch" | python3 -c "
import json, sys
try:
    data = json.loads(sys.stdin.read())
    t = data.get('title') == 'Patched Title'
    a = data.get('author') == 'Original Author'
    print('yes' if t and a else 'no')
except:
    print('no')
" 2>/dev/null || true)
      [[ "$patch_ok" == "yes" ]] && score=$((score + 5))
    fi
  fi

  # Response Content-Type header is application/json (3 pts)
  local ct_header
  ct_header=$(curl -s -o /dev/null -w "%{content_type}" "$base/books" 2>/dev/null) || true
  local ct_check
  ct_check=$(echo "$ct_header" | python3 -c "
import sys
ct = sys.stdin.read().strip().lower()
print('yes' if 'application/json' in ct else 'no')
" 2>/dev/null || true)
  [[ "$ct_check" == "yes" ]] && score=$((score + 3))

  # PUT /books/:id with missing required field should fail (2 pts)
  # (PUT should require full object replacement)
  local put_partial
  put_partial=$(curl -s -w "\n%{http_code}" -X PUT "$base/books/$patch_id" \
    -H "Content-Type: application/json" \
    -d '{"title":"Only Title No Author"}' 2>/dev/null) || true
  local put_partial_code
  put_partial_code=$(echo "$put_partial" | tail -1)
  if [[ "$put_partial_code" == "400" ]] || [[ "$put_partial_code" == "422" ]]; then
    score=$((score + 2))
  fi

  # Cleanup — kill server and don't block on wait
  kill "$server_pid" 2>/dev/null
  sleep 0.5
  kill -9 "$server_pid" 2>/dev/null || true

  echo "$score"
}

rubric_test_quality() {
  local ws="$1"
  local score=0

  # --- Test files exist (10 pts) ---
  local test_files
  test_files=$(find "$ws" -maxdepth 4 \( -name "*.test.*" -o -name "*.spec.*" \) ! -path "*/node_modules/*" 2>/dev/null || true)
  local test_count
  test_count=$(echo "$test_files" | grep -c '.' 2>/dev/null || true)
  [[ $test_count -gt 0 ]] && score=$((score + 10))

  # --- Tests actually pass (20 pts) ---
  local test_output
  test_output=$(cd "$ws" && npm test 2>&1 | tail -40) || true
  local tests_pass
  tests_pass=$(echo "$test_output" | python3 -c "
import sys, re
text = sys.stdin.read()
# Look for common pass indicators
if re.search(r'(pass|PASS|✓|Tests:.*passed|test suites.*passed)', text, re.IGNORECASE):
    # Also check there's no failure
    if not re.search(r'(FAIL|fail(?:ed|ure)|error|ERR!)', text, re.IGNORECASE):
        print('yes')
    else:
        print('no')
else:
    print('no')
" 2>/dev/null || true)
  [[ "$tests_pass" == "yes" ]] && score=$((score + 20))

  # --- Test count > 5 (individual test cases, not files) (10 pts) ---
  local individual_tests
  individual_tests=$(echo "$test_output" | python3 -c "
import sys, re
text = sys.stdin.read()
# Jest: 'Tests: X passed'
m = re.search(r'Tests:\s+(\d+)\s+passed', text)
if m:
    print(m.group(1))
    exit()
# Mocha/tap: count lines with checkmarks or 'passing'
m = re.search(r'(\d+)\s+passing', text)
if m:
    print(m.group(1))
    exit()
# Count checkmarks or 'PASS' lines
count = len(re.findall(r'[✓✔]|PASS\s', text))
print(count if count > 0 else 0)
" 2>/dev/null || true)
  [[ -n "$individual_tests" ]] && [[ "$individual_tests" -gt 5 ]] 2>/dev/null && score=$((score + 10))

  # --- Tests cover ALL HTTP methods: GET, POST, PUT, DELETE (15 pts) ---
  local methods_covered=0
  if [[ -n "$test_files" ]]; then
    for method in "GET" "POST" "PUT" "DELETE"; do
      local method_lower
      method_lower=$(echo "$method" | tr '[:upper:]' '[:lower:]')
      local found
      found=$(echo "$test_files" | while read -r f; do
        [[ -z "$f" ]] && continue
        if grep -qliE "\b${method}\b|\b${method_lower}\b|\.${method_lower}\(|\.${method}\(" "$f" 2>/dev/null; then
          echo "found"
          break
        fi
      done) || true
      [[ "$found" == "found" ]] && methods_covered=$((methods_covered + 1))
    done
  fi
  # Require all 4 methods
  [[ $methods_covered -ge 4 ]] && score=$((score + 15))

  # --- Tests include error/edge cases: 400, 404, validation (15 pts) ---
  local error_cases=0
  if [[ -n "$test_files" ]]; then
    # Check for 400 status tests
    local has_400
    has_400=$(echo "$test_files" | while read -r f; do
      [[ -z "$f" ]] && continue
      if grep -qlE "400|bad.?request|invalid|validation" "$f" 2>/dev/null; then
        echo "found"; break
      fi
    done) || true
    [[ "$has_400" == "found" ]] && error_cases=$((error_cases + 1))

    # Check for 404 status tests
    local has_404
    has_404=$(echo "$test_files" | while read -r f; do
      [[ -z "$f" ]] && continue
      if grep -qlE "404|not.?found" "$f" 2>/dev/null; then
        echo "found"; break
      fi
    done) || true
    [[ "$has_404" == "found" ]] && error_cases=$((error_cases + 1))

    # Check for validation-related tests (isbn, required, missing)
    local has_validation
    has_validation=$(echo "$test_files" | while read -r f; do
      [[ -z "$f" ]] && continue
      if grep -qlEi "isbn|required|missing|invalid|validat" "$f" 2>/dev/null; then
        echo "found"; break
      fi
    done) || true
    [[ "$has_validation" == "found" ]] && error_cases=$((error_cases + 1))
  fi
  # Need at least 2 of 3 error case categories
  [[ $error_cases -ge 2 ]] && score=$((score + 10))
  [[ $error_cases -ge 3 ]] && score=$((score + 5))

  # --- Uses proper HTTP test library (supertest, axios, node-fetch, etc.) (10 pts) ---
  local has_http_client
  has_http_client=$(echo "$test_files" | while read -r f; do
    [[ -z "$f" ]] && continue
    if grep -qlEi "supertest|request\(app\)|axios|node-fetch|got\(|chai-http|pactum" "$f" 2>/dev/null; then
      echo "found"; break
    fi
  done) || true
  [[ "$has_http_client" == "found" ]] && score=$((score + 10))

  # --- Bonus: tests are well-structured with describe/it blocks (10 pts) ---
  local has_structure
  has_structure=$(echo "$test_files" | while read -r f; do
    [[ -z "$f" ]] && continue
    if grep -qlE "describe\(|it\(|test\(" "$f" 2>/dev/null; then
      echo "found"; break
    fi
  done) || true
  [[ "$has_structure" == "found" ]] && score=$((score + 10))

  # Cap at 100
  [[ $score -gt 100 ]] && score=100

  echo "$score"
}

rubric_robustness() {
  local ws="$1"
  local score=0

  local src_files
  src_files=$(find "$ws" -maxdepth 4 -name "*.js" ! -path "*/node_modules/*" ! -name "*.test.*" ! -name "*.spec.*" 2>/dev/null || true)

  # --- Input validation present (10 pts) ---
  local has_validation
  has_validation=$(echo "$src_files" | while read -r f; do
    [[ -z "$f" ]] && continue
    if grep -qlE "required|!.*title|!.*author|\.trim\(\)|\.length|validat" "$f" 2>/dev/null; then
      echo "found"; break
    fi
  done) || true
  [[ "$has_validation" == "found" ]] && score=$((score + 10))

  # --- Error handling middleware or try/catch (10 pts) ---
  local has_error_handling
  has_error_handling=$(echo "$src_files" | while read -r f; do
    [[ -z "$f" ]] && continue
    if grep -qlE "catch|error.*handler|err.*req.*res|next\(err|app\.use\(.*err" "$f" 2>/dev/null; then
      echo "found"; break
    fi
  done) || true
  [[ "$has_error_handling" == "found" ]] && score=$((score + 10))

  # --- Proper status codes in source (10 pts) ---
  local status_count=0
  for code_pattern in "status(201" "status(400" "status(404" "status(204"; do
    local has_code
    has_code=$(echo "$src_files" | while read -r f; do
      [[ -z "$f" ]] && continue
      if grep -ql "$code_pattern" "$f" 2>/dev/null; then
        echo "found"; break
      fi
    done) || true
    [[ "$has_code" == "found" ]] && status_count=$((status_count + 1))
  done
  # Need at least 3 of 4 status codes
  [[ $status_count -ge 3 ]] && score=$((score + 10))

  # --- JSON error responses with meaningful messages (10 pts) ---
  local has_json_errors
  has_json_errors=$(echo "$src_files" | while read -r f; do
    [[ -z "$f" ]] && continue
    if grep -qlE 'json\(\s*\{.*error|json\(\s*\{.*message|\.json\(\{' "$f" 2>/dev/null; then
      echo "found"; break
    fi
  done) || true
  [[ "$has_json_errors" == "found" ]] && score=$((score + 10))

  # --- IDs are UUIDs (not sequential integers) (10 pts) ---
  local has_uuid
  has_uuid=$(echo "$src_files" | while read -r f; do
    [[ -z "$f" ]] && continue
    if grep -qlEi "uuid|uuidv4|randomUUID|crypto\.random" "$f" 2>/dev/null; then
      echo "found"; break
    fi
  done) || true
  [[ "$has_uuid" == "found" ]] && score=$((score + 10))

  # --- CORS handling (10 pts) ---
  local has_cors
  has_cors=$(echo "$src_files" | while read -r f; do
    [[ -z "$f" ]] && continue
    if grep -qlEi "cors|Access-Control-Allow" "$f" 2>/dev/null; then
      echo "found"; break
    fi
  done) || true
  [[ "$has_cors" == "found" ]] && score=$((score + 10))

  # Also check package.json for cors dependency
  if [[ "$has_cors" != "found" && -f "$ws/package.json" ]]; then
    local pkg_cors
    pkg_cors=$(python3 -c "
import json, sys
try:
    data = json.load(open('$ws/package.json'))
    deps = {**data.get('dependencies',{}), **data.get('devDependencies',{})}
    print('found' if 'cors' in deps else '')
except:
    print('')
" 2>/dev/null || true)
    [[ "$pkg_cors" == "found" ]] && score=$((score + 10))
  fi

  # --- Rate limiting or request size limits (10 pts) ---
  local has_limits
  has_limits=$(echo "$src_files" | while read -r f; do
    [[ -z "$f" ]] && continue
    if grep -qlEi "rate.?limit|express.?rate|express\.json\(\s*\{.*limit|body.?parser.*limit|helmet" "$f" 2>/dev/null; then
      echo "found"; break
    fi
  done) || true
  [[ "$has_limits" == "found" ]] && score=$((score + 10))

  # Also check package.json for rate-limit or helmet dependency
  if [[ "$has_limits" != "found" && -f "$ws/package.json" ]]; then
    local pkg_limits
    pkg_limits=$(python3 -c "
import json, sys
try:
    data = json.load(open('$ws/package.json'))
    deps = {**data.get('dependencies',{}), **data.get('devDependencies',{})}
    matches = [k for k in deps if 'rate' in k.lower() or 'limit' in k.lower() or 'helmet' in k.lower()]
    print('found' if matches else '')
except:
    print('')
" 2>/dev/null || true)
    [[ "$pkg_limits" == "found" ]] && score=$((score + 10))
  fi

  # --- Graceful server shutdown / process handling (5 pts) ---
  local has_graceful
  has_graceful=$(echo "$src_files" | while read -r f; do
    [[ -z "$f" ]] && continue
    if grep -qlE "SIGTERM|SIGINT|process\.on|graceful|server\.close" "$f" 2>/dev/null; then
      echo "found"; break
    fi
  done) || true
  [[ "$has_graceful" == "found" ]] && score=$((score + 5))

  # --- ISBN validation logic specifically (5 pts) ---
  local has_isbn_validation
  has_isbn_validation=$(echo "$src_files" | while read -r f; do
    [[ -z "$f" ]] && continue
    if grep -qlEi "isbn.*length|isbn.*\d{10}|isbn.*\d{13}|isbn.*regex|isbn.*match|isbn.*valid" "$f" 2>/dev/null; then
      echo "found"; break
    fi
  done) || true
  [[ "$has_isbn_validation" == "found" ]] && score=$((score + 5))

  # --- Module structure: routes separated from main file (10 pts) ---
  local route_files
  route_files=$(find "$ws" -maxdepth 4 -name "*.js" ! -path "*/node_modules/*" ! -name "*.test.*" ! -name "*.spec.*" 2>/dev/null | while read -r f; do
    if grep -qlE "router\.|Router\(\)|module\.exports.*router" "$f" 2>/dev/null; then
      echo "$f"
    fi
  done || true)
  local main_separate
  main_separate=$(echo "$route_files" | grep -c '.' 2>/dev/null || true)
  [[ "$main_separate" -ge 1 ]] && score=$((score + 10))

  # Cap at 100
  [[ $score -gt 100 ]] && score=100

  echo "$score"
}

# Helper to find a free port
_find_free_port() {
  python3 -c "
import socket
s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
s.bind(('', 0))
print(s.getsockname()[1])
s.close()
"
}
