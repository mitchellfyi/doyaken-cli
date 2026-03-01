#!/usr/bin/env bash
#
# core_functions.sh - Extracted functions from core.sh for unit testing
#
# This file provides testable versions of core.sh functions with minimal
# dependencies. It's sourced by test files to test individual functions
# in isolation.
#
# Required environment variables (set by test setup):
#   DOYAKEN_PROJECT - Project directory
#   DATA_DIR        - .doyaken directory
#   STATE_DIR       - State directory
#   AGENT_ID        - Current agent identifier
#

# ============================================================================
# Logging Stubs (silent in tests unless VERBOSE_TEST=1)
# ============================================================================

log_info()    { [[ "${VERBOSE_TEST:-}" == "1" ]] && echo "[INFO] $1" || true; }
log_success() { [[ "${VERBOSE_TEST:-}" == "1" ]] && echo "[OK] $1" || true; }
log_warn()    { [[ "${VERBOSE_TEST:-}" == "1" ]] && echo "[WARN] $1" || true; }
log_error()   { [[ "${VERBOSE_TEST:-}" == "1" ]] && echo "[ERROR] $1" || true; }
log_heal()    { [[ "${VERBOSE_TEST:-}" == "1" ]] && echo "[HEAL] $1" || true; }
log_model()   { [[ "${VERBOSE_TEST:-}" == "1" ]] && echo "[MODEL] $1" || true; }
log_step()    { [[ "${VERBOSE_TEST:-}" == "1" ]] && echo "[STEP] $1" || true; }
log_ok()      { [[ "${VERBOSE_TEST:-}" == "1" ]] && echo "[OK] $1" || true; }

# ============================================================================
# Model Fallback Functions
# ============================================================================

# Model state variables (must be initialized by test setup)
CURRENT_AGENT="${CURRENT_AGENT:-claude}"
CURRENT_MODEL="${CURRENT_MODEL:-opus}"
DOYAKEN_MODEL="${DOYAKEN_MODEL:-opus}"
MODEL_FALLBACK_TRIGGERED=0
AGENT_NO_FALLBACK="${AGENT_NO_FALLBACK:-0}"

fallback_to_sonnet() {
  if [ "$AGENT_NO_FALLBACK" = "1" ]; then
    log_warn "Model fallback disabled (AGENT_NO_FALLBACK=1)"
    return 1
  fi

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
# Session State Functions
# ============================================================================

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
LOG_DIR="${RUN_LOG_DIR:-}"
EOF
  log_info "Session state saved: $session_id"
}

load_session() {
  local session_file="$STATE_DIR/session-$AGENT_ID"

  if [ -f "$session_file" ] && [ "${AGENT_NO_RESUME:-}" != "1" ]; then
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

# ============================================================================
# Health State Functions
# ============================================================================

CONSECUTIVE_FAILURES=0

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
# Phase Progress Functions
# ============================================================================

PHASES=("PLAN|a|1|0" "IMPLEMENT|b|2|0" "TEST|c|3|0" "VERIFY|d|4|0")
AGENT_NO_RESUME="${AGENT_NO_RESUME:-0}"

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

clear_phase_progress() {
  local progress_file="$STATE_DIR/phase-progress-$AGENT_ID"
  rm -f "$progress_file"
}

# ============================================================================
# Prompt File Functions
# ============================================================================

get_prompt_file() {
  local prompt_name="$1"

  # Check project-specific prompts first
  if [ -f "$DATA_DIR/prompts/$prompt_name" ]; then
    echo "$DATA_DIR/prompts/$prompt_name"
    return 0
  fi

  # Fall back to global prompts
  if [ -f "${DOYAKEN_HOME:-}/prompts/$prompt_name" ]; then
    echo "${DOYAKEN_HOME:-}/prompts/$prompt_name"
    return 0
  fi

  return 1
}

process_includes() {
  local content="$1"
  local max_depth="${2:-5}"

  if [ "$max_depth" -le 0 ]; then
    echo "$content"
    return 0
  fi

  local result="$content"
  local include_pattern='\{\{include:([^}]+)\}\}'

  while [[ "$result" =~ $include_pattern ]]; do
    local full_match="${BASH_REMATCH[0]}"
    local include_path="${BASH_REMATCH[1]}"

    local include_file=""
    if [ -f "$DATA_DIR/prompts/$include_path" ]; then
      include_file="$DATA_DIR/prompts/$include_path"
    elif [ -f "${DOYAKEN_HOME:-}/prompts/$include_path" ]; then
      include_file="${DOYAKEN_HOME:-}/prompts/$include_path"
    fi

    if [ -n "$include_file" ] && [ -f "$include_file" ]; then
      local include_content
      include_content=$(cat "$include_file")
      include_content=$(process_includes "$include_content" $((max_depth - 1)))
      result="${result//$full_match/$include_content}"
    else
      log_warn "Include file not found: $include_path"
      break
    fi
  done

  echo "$result"
}
