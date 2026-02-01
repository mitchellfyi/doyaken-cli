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
