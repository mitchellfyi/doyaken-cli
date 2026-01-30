#!/usr/bin/env bash
#
# doyaken Configuration Library
#
# Centralized configuration loading with priority chain:
#   CLI flags > ENV vars > project manifest > global config > defaults
#
# This library handles loading configuration from YAML files and provides
# helper functions for accessing configuration values.
#

# ============================================================================
# Configuration Paths
# ============================================================================

DOYAKEN_HOME="${DOYAKEN_HOME:-$HOME/.doyaken}"
GLOBAL_CONFIG_FILE="${GLOBAL_CONFIG_FILE:-$DOYAKEN_HOME/config/global.yaml}"

# ============================================================================
# Helper Functions
# ============================================================================

# Convert YAML boolean to shell boolean (0 or 1)
# Usage: yaml_bool "true" → 1, yaml_bool "false" → 0
yaml_bool() {
  local value="$1"
  case "$value" in
    true|True|TRUE|yes|Yes|YES|1) echo "1" ;;
    false|False|FALSE|no|No|NO|0|"") echo "0" ;;
    *) echo "0" ;;
  esac
}

# Load a config value from YAML file
# Usage: _yq_get "file.yaml" "path.to.key" "default"
_yq_get() {
  local file="$1"
  local key="$2"
  local default="${3:-}"

  if [ ! -f "$file" ]; then
    echo "$default"
    return
  fi

  if ! command -v yq &>/dev/null; then
    echo "$default"
    return
  fi

  local value
  value=$(yq -e ".$key // \"\"" "$file" 2>/dev/null || echo "")

  if [ -z "$value" ] || [ "$value" = "null" ]; then
    echo "$default"
  else
    echo "$value"
  fi
}

# Load a config value with priority: ENV > project manifest > global config > default
# Usage: _load_config "ENV_VAR_NAME" "yaml.path" "default_value" ["manifest_file"]
_load_config() {
  local env_var="$1"
  local yaml_key="$2"
  local default="$3"
  local manifest_file="${4:-}"

  # Check if already set via ENV (highest priority after CLI)
  # Use indirect expansion instead of eval for safety
  local current_val="${!env_var:-}"
  if [ -n "$current_val" ]; then
    return 0  # Already set, don't override
  fi

  # Try project manifest first
  local value=""
  if [ -n "$manifest_file" ] && [ -f "$manifest_file" ]; then
    value=$(_yq_get "$manifest_file" "$yaml_key" "")
  fi

  # Fall back to global config
  if [ -z "$value" ] && [ -f "$GLOBAL_CONFIG_FILE" ]; then
    value=$(_yq_get "$GLOBAL_CONFIG_FILE" "$yaml_key" "")
  fi

  # Fall back to default
  if [ -z "$value" ]; then
    value="$default"
  fi

  # Export the value
  if [ -n "$value" ]; then
    export "$env_var=$value"
  fi
}

# Load a boolean config value (converts YAML true/false to 1/0)
# Usage: _load_config_bool "ENV_VAR_NAME" "yaml.path" "default_value" ["manifest_file"]
_load_config_bool() {
  local env_var="$1"
  local yaml_key="$2"
  local default="$3"
  local manifest_file="${4:-}"

  # Check if already set via ENV - use indirect expansion for safety
  local current_val="${!env_var:-}"
  if [ -n "$current_val" ]; then
    return 0
  fi

  # Try project manifest first
  local value=""
  if [ -n "$manifest_file" ] && [ -f "$manifest_file" ]; then
    value=$(_yq_get "$manifest_file" "$yaml_key" "")
  fi

  # Fall back to global config
  if [ -z "$value" ] && [ -f "$GLOBAL_CONFIG_FILE" ]; then
    value=$(_yq_get "$GLOBAL_CONFIG_FILE" "$yaml_key" "")
  fi

  # Convert to boolean and export
  if [ -n "$value" ]; then
    export "$env_var=$(yaml_bool "$value")"
  else
    export "$env_var=$(yaml_bool "$default")"
  fi
}

# ============================================================================
# Global Configuration Loading
# ============================================================================

# Load global configuration from ~/.doyaken/config/global.yaml
# Called before load_manifest() to establish base config
load_global_config() {
  if [ ! -f "$GLOBAL_CONFIG_FILE" ]; then
    return 0
  fi

  if ! command -v yq &>/dev/null; then
    return 0
  fi

  # Note: We don't export values here directly.
  # Instead, the _load_config functions handle the priority chain.
  # This function is kept for future extension if needed.
  return 0
}

# ============================================================================
# Timeout Configuration
# ============================================================================

# Load all timeout settings with priority chain
# Usage: load_timeout_config "manifest_file"
load_timeout_config() {
  local manifest_file="${1:-}"

  _load_config "TIMEOUT_EXPAND"    "timeouts.expand"    "900"  "$manifest_file"
  _load_config "TIMEOUT_TRIAGE"    "timeouts.triage"    "540"  "$manifest_file"
  _load_config "TIMEOUT_PLAN"      "timeouts.plan"      "900"  "$manifest_file"
  _load_config "TIMEOUT_IMPLEMENT" "timeouts.implement" "5400" "$manifest_file"
  _load_config "TIMEOUT_TEST"      "timeouts.test"      "1800" "$manifest_file"
  _load_config "TIMEOUT_DOCS"      "timeouts.docs"      "900"  "$manifest_file"
  _load_config "TIMEOUT_REVIEW"    "timeouts.review"    "1800" "$manifest_file"
  _load_config "TIMEOUT_VERIFY"    "timeouts.verify"    "900"  "$manifest_file"
}

# ============================================================================
# Skip Phase Configuration
# ============================================================================

# Load all skip_phases settings with priority chain
# Usage: load_skip_phases_config "manifest_file"
load_skip_phases_config() {
  local manifest_file="${1:-}"

  _load_config_bool "SKIP_EXPAND"    "skip_phases.expand"    "false" "$manifest_file"
  _load_config_bool "SKIP_TRIAGE"    "skip_phases.triage"    "false" "$manifest_file"
  _load_config_bool "SKIP_PLAN"      "skip_phases.plan"      "false" "$manifest_file"
  _load_config_bool "SKIP_IMPLEMENT" "skip_phases.implement" "false" "$manifest_file"
  _load_config_bool "SKIP_TEST"      "skip_phases.test"      "false" "$manifest_file"
  _load_config_bool "SKIP_DOCS"      "skip_phases.docs"      "false" "$manifest_file"
  _load_config_bool "SKIP_REVIEW"    "skip_phases.review"    "false" "$manifest_file"
  _load_config_bool "SKIP_VERIFY"    "skip_phases.verify"    "false" "$manifest_file"
}

# ============================================================================
# Agent Configuration
# ============================================================================

# Load agent settings with priority chain
# Usage: load_agent_config "manifest_file"
load_agent_config() {
  local manifest_file="${1:-}"

  # Agent and model (special handling for CLI override flags)
  if [ -z "${DOYAKEN_AGENT_FROM_CLI:-}" ]; then
    _load_config "DOYAKEN_AGENT" "defaults.agent" "claude" "$manifest_file"
    # Also check agent.name for project manifest compatibility
    if [ -n "$manifest_file" ] && [ -f "$manifest_file" ]; then
      local agent_name
      agent_name=$(_yq_get "$manifest_file" "agent.name" "")
      if [ -n "$agent_name" ]; then
        export DOYAKEN_AGENT="$agent_name"
      fi
    fi
  fi

  if [ -z "${DOYAKEN_MODEL_FROM_CLI:-}" ]; then
    _load_config "DOYAKEN_MODEL" "defaults.model" "" "$manifest_file"
    # Also check agent.model for project manifest compatibility
    if [ -n "$manifest_file" ] && [ -f "$manifest_file" ]; then
      local agent_model
      agent_model=$(_yq_get "$manifest_file" "agent.model" "")
      if [ -n "$agent_model" ]; then
        export DOYAKEN_MODEL="$agent_model"
      fi
    fi
  fi

  # Retry settings
  _load_config "AGENT_MAX_RETRIES"  "defaults.max_retries"       "2"     "$manifest_file"
  _load_config "AGENT_RETRY_DELAY"  "defaults.retry_delay"       "5"     "$manifest_file"
  _load_config "AGENT_LOCK_TIMEOUT" "defaults.lock_timeout"      "10800" "$manifest_file"
  _load_config "AGENT_HEARTBEAT"    "defaults.heartbeat_interval" "3600"  "$manifest_file"

  # Boolean settings
  _load_config_bool "AGENT_NO_FALLBACK" "defaults.no_fallback" "false" "$manifest_file"
  _load_config_bool "AGENT_NO_RESUME"   "defaults.no_resume"   "false" "$manifest_file"
}

# ============================================================================
# Output Configuration
# ============================================================================

# Load output settings with priority chain
# Usage: load_output_config "manifest_file"
load_output_config() {
  local manifest_file="${1:-}"

  _load_config_bool "AGENT_PROGRESS" "output.progress_mode" "true"  "$manifest_file"
  _load_config_bool "AGENT_VERBOSE"  "output.verbose"       "false" "$manifest_file"
  _load_config_bool "AGENT_QUIET"    "output.quiet"         "false" "$manifest_file"
}

# ============================================================================
# Periodic Review Configuration
# ============================================================================

# Load periodic review settings with priority chain
# Usage: load_periodic_review_config "manifest_file"
load_periodic_review_config() {
  local manifest_file="${1:-}"

  _load_config_bool "REVIEW_ENABLED"   "periodic_review.enabled"   "true"  "$manifest_file"
  _load_config      "REVIEW_THRESHOLD" "periodic_review.threshold" "3"     "$manifest_file"
  _load_config_bool "REVIEW_AUTO_FIX"  "periodic_review.auto_fix"  "false" "$manifest_file"
}

# ============================================================================
# Main Configuration Loader
# ============================================================================

# Load all configuration from global and project configs
# Usage: load_all_config "manifest_file"
load_all_config() {
  local manifest_file="${1:-}"

  # Load global config first (establishes base)
  load_global_config

  # Load all config sections (project overrides global)
  load_timeout_config "$manifest_file"
  load_skip_phases_config "$manifest_file"
  load_agent_config "$manifest_file"
  load_output_config "$manifest_file"
  load_periodic_review_config "$manifest_file"
}

# ============================================================================
# Configuration Display
# ============================================================================

# Show effective configuration (for doyaken config command)
show_effective_config() {
  local manifest_file="${1:-}"

  echo "# Effective Configuration"
  echo "# Priority: CLI > ENV > project manifest > global config > defaults"
  echo ""

  echo "## Sources"
  echo "Global config: $GLOBAL_CONFIG_FILE"
  [ -f "$GLOBAL_CONFIG_FILE" ] && echo "  (exists)" || echo "  (not found)"
  if [ -n "$manifest_file" ]; then
    echo "Project manifest: $manifest_file"
    [ -f "$manifest_file" ] && echo "  (exists)" || echo "  (not found)"
  fi
  echo ""

  echo "## Agent Settings"
  echo "  agent: ${DOYAKEN_AGENT:-claude}"
  echo "  model: ${DOYAKEN_MODEL:-(auto)}"
  echo "  max_retries: ${AGENT_MAX_RETRIES:-2}"
  echo "  retry_delay: ${AGENT_RETRY_DELAY:-5}s"
  echo "  lock_timeout: ${AGENT_LOCK_TIMEOUT:-10800}s"
  echo "  heartbeat_interval: ${AGENT_HEARTBEAT:-3600}s"
  echo "  no_fallback: ${AGENT_NO_FALLBACK:-0}"
  echo "  no_resume: ${AGENT_NO_RESUME:-0}"
  echo ""

  echo "## Output Settings"
  echo "  progress_mode: ${AGENT_PROGRESS:-1}"
  echo "  verbose: ${AGENT_VERBOSE:-0}"
  echo "  quiet: ${AGENT_QUIET:-0}"
  echo ""

  echo "## Phase Timeouts (seconds)"
  echo "  expand: ${TIMEOUT_EXPAND:-900}"
  echo "  triage: ${TIMEOUT_TRIAGE:-540}"
  echo "  plan: ${TIMEOUT_PLAN:-900}"
  echo "  implement: ${TIMEOUT_IMPLEMENT:-5400}"
  echo "  test: ${TIMEOUT_TEST:-1800}"
  echo "  docs: ${TIMEOUT_DOCS:-900}"
  echo "  review: ${TIMEOUT_REVIEW:-1800}"
  echo "  verify: ${TIMEOUT_VERIFY:-900}"
  echo ""

  echo "## Skip Phases"
  echo "  expand: ${SKIP_EXPAND:-0}"
  echo "  triage: ${SKIP_TRIAGE:-0}"
  echo "  plan: ${SKIP_PLAN:-0}"
  echo "  implement: ${SKIP_IMPLEMENT:-0}"
  echo "  test: ${SKIP_TEST:-0}"
  echo "  docs: ${SKIP_DOCS:-0}"
  echo "  review: ${SKIP_REVIEW:-0}"
  echo "  verify: ${SKIP_VERIFY:-0}"
  echo ""

  echo "## Periodic Review"
  echo "  enabled: ${REVIEW_ENABLED:-1}"
  echo "  threshold: ${REVIEW_THRESHOLD:-3}"
  echo "  auto_fix: ${REVIEW_AUTO_FIX:-0}"
}
