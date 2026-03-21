#!/usr/bin/env bash
# Rubric for: rest-api-crud

rubric_correctness() {
  local ws="$1"
  local score=0

  [[ -f "$ws/package.json" ]] && score=$((score + 5))

  # Install deps
  if ! (cd "$ws" && npm install --silent 2>/dev/null); then
    echo "$score"; return
  fi
  score=$((score + 5))

  # Find the server entry point
  local entry=""
  for f in "index.js" "src/index.js" "app.js" "src/app.js" "server.js" "src/server.js"; do
    [[ -f "$ws/$f" ]] && entry="$f" && break
  done
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

  # POST /books — create
  local create_resp
  create_resp=$(curl -s -w "\n%{http_code}" -X POST "$base/books" \
    -H "Content-Type: application/json" \
    -d '{"title":"Test Book","author":"Test Author"}' 2>/dev/null) || true
  local create_code
  create_code=$(echo "$create_resp" | tail -1)
  if [[ "$create_code" == "201" ]] || [[ "$create_code" == "200" ]]; then
    score=$((score + 15))
  fi

  # GET /books — list
  local list_resp
  list_resp=$(curl -s -w "\n%{http_code}" "$base/books" 2>/dev/null) || true
  local list_code
  list_code=$(echo "$list_resp" | tail -1)
  if [[ "$list_code" == "200" ]]; then
    score=$((score + 10))
    if echo "$list_resp" | grep -q "Test Book"; then
      score=$((score + 5))
    fi
  fi

  # GET /books/:id — single
  # Extract ID from create response or list
  local book_id
  book_id=$(echo "$list_resp" | python3 -c "
import json, sys
try:
    data = json.loads(sys.stdin.read().rsplit('\n', 1)[0])
    if isinstance(data, list) and len(data) > 0:
        print(data[0].get('id', 1))
    elif isinstance(data, dict) and 'books' in data:
        print(data['books'][0].get('id', 1))
    else:
        print(1)
except:
    print(1)
" 2>/dev/null || echo "1")

  local get_resp
  get_resp=$(curl -s -w "\n%{http_code}" "$base/books/$book_id" 2>/dev/null) || true
  local get_code
  get_code=$(echo "$get_resp" | tail -1)
  [[ "$get_code" == "200" ]] && score=$((score + 10))

  # PUT /books/:id — update
  local put_resp
  put_resp=$(curl -s -w "\n%{http_code}" -X PUT "$base/books/$book_id" \
    -H "Content-Type: application/json" \
    -d '{"title":"Updated Book","author":"Test Author"}' 2>/dev/null) || true
  local put_code
  put_code=$(echo "$put_resp" | tail -1)
  [[ "$put_code" == "200" ]] && score=$((score + 10))

  # DELETE /books/:id
  local del_resp
  del_resp=$(curl -s -w "\n%{http_code}" -X DELETE "$base/books/$book_id" 2>/dev/null) || true
  local del_code
  del_code=$(echo "$del_resp" | tail -1)
  [[ "$del_code" == "200" ]] || [[ "$del_code" == "204" ]] && score=$((score + 10))

  # GET /books/999 — 404
  local notfound_resp
  notfound_resp=$(curl -s -w "\n%{http_code}" "$base/books/99999" 2>/dev/null) || true
  local nf_code
  nf_code=$(echo "$notfound_resp" | tail -1)
  [[ "$nf_code" == "404" ]] && score=$((score + 10))

  # POST with invalid data — 400
  local invalid_resp
  invalid_resp=$(curl -s -w "\n%{http_code}" -X POST "$base/books" \
    -H "Content-Type: application/json" \
    -d '{}' 2>/dev/null) || true
  local inv_code
  inv_code=$(echo "$invalid_resp" | tail -1)
  [[ "$inv_code" == "400" ]] || [[ "$inv_code" == "422" ]] && score=$((score + 10))

  # ISBN validation — invalid ISBN should get 400
  local isbn_resp
  isbn_resp=$(curl -s -w "\n%{http_code}" -X POST "$base/books" \
    -H "Content-Type: application/json" \
    -d '{"title":"Book","author":"Author","isbn":"invalid"}' 2>/dev/null) || true
  local isbn_code
  isbn_code=$(echo "$isbn_resp" | tail -1)
  [[ "$isbn_code" == "400" ]] || [[ "$isbn_code" == "422" ]] && score=$((score + 10))

  # Cleanup
  kill "$server_pid" 2>/dev/null
  wait "$server_pid" 2>/dev/null

  echo "$score"
}

rubric_test_quality() {
  local ws="$1"
  local score=0

  local test_count
  test_count=$(find "$ws" -maxdepth 4 \( -name "*.test.*" -o -name "*.spec.*" \) ! -path "*/node_modules/*" 2>/dev/null | wc -l | tr -d ' ')
  [[ $test_count -gt 0 ]] && score=$((score + 20))

  # Tests pass
  if (cd "$ws" && npm test 2>&1 | tail -20 | grep -qiE "pass|✓|ok|success"); then
    score=$((score + 50))
  fi

  # Tests cover multiple endpoints
  local test_files
  test_files=$(find "$ws" -maxdepth 4 \( -name "*.test.*" -o -name "*.spec.*" \) ! -path "*/node_modules/*" 2>/dev/null)
  local endpoints_tested=0
  for method in "GET" "POST" "PUT" "DELETE"; do
    if echo "$test_files" | xargs grep -qli "$method\|$(echo $method | tr '[:upper:]' '[:lower:]')" 2>/dev/null; then
      endpoints_tested=$((endpoints_tested + 1))
    fi
  done
  [[ $endpoints_tested -ge 3 ]] && score=$((score + 30))

  echo "$score"
}

rubric_robustness() {
  local ws="$1"
  local score=0

  # Has validation patterns
  local src_files
  src_files=$(find "$ws" -maxdepth 4 -name "*.js" ! -path "*/node_modules/*" ! -name "*.test.*" ! -name "*.spec.*" 2>/dev/null)

  # Input validation present
  if echo "$src_files" | xargs grep -ql "valid\|required\|title.*required\|!.*title\|!.*author" 2>/dev/null; then
    score=$((score + 25))
  fi

  # Error handling middleware or try/catch
  if echo "$src_files" | xargs grep -ql "catch\|error.*handler\|err.*req.*res\|next(err" 2>/dev/null; then
    score=$((score + 25))
  fi

  # Proper status codes in code
  if echo "$src_files" | xargs grep -ql "status(4\|\.status(201\|res\.status" 2>/dev/null; then
    score=$((score + 25))
  fi

  # JSON error responses
  if echo "$src_files" | xargs grep -ql "json.*error\|error.*message\|{ error\|{error" 2>/dev/null; then
    score=$((score + 25))
  fi

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
