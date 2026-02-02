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
#   TASKS_DIR       - Tasks directory
#   LOCKS_DIR       - Locks directory
#   STATE_DIR       - State directory
#   AGENT_ID        - Current agent identifier
#   AGENT_LOCK_TIMEOUT - Lock timeout in seconds
#

# ============================================================================
# Logging Stubs (silent in tests unless VERBOSE_TEST=1)
# ============================================================================

log_info()    { [[ "${VERBOSE_TEST:-}" == "1" ]] && echo "[INFO] $1" || true; }
log_success() { [[ "${VERBOSE_TEST:-}" == "1" ]] && echo "[OK] $1" || true; }
log_warn()    { [[ "${VERBOSE_TEST:-}" == "1" ]] && echo "[WARN] $1" || true; }
log_error()   { [[ "${VERBOSE_TEST:-}" == "1" ]] && echo "[ERROR] $1" || true; }
log_heal()    { [[ "${VERBOSE_TEST:-}" == "1" ]] && echo "[HEAL] $1" || true; }
log_lock()    { [[ "${VERBOSE_TEST:-}" == "1" ]] && echo "[LOCK] $1" || true; }
log_model()   { [[ "${VERBOSE_TEST:-}" == "1" ]] && echo "[MODEL] $1" || true; }
log_step()    { [[ "${VERBOSE_TEST:-}" == "1" ]] && echo "[STEP] $1" || true; }

# ============================================================================
# Lock Management Functions
# ============================================================================

# Track locks held by this agent (must be initialized by test setup)
HELD_LOCKS=()

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

  # Check if PID is still running
  if [ -n "$pid" ] && [ "$pid" != "0" ]; then
    if ! kill -0 "$pid" 2>/dev/null; then
      log_heal "Lock PID $pid is not running - lock is stale"
      return 0
    fi
  fi

  # Check if lock has exceeded timeout
  local now locked_timestamp age
  now=$(date +%s)
  # Try macOS format first, then Linux
  locked_timestamp=$(date -j -f "%Y-%m-%d %H:%M:%S" "$locked_at" +%s 2>/dev/null || \
                    date -d "$locked_at" +%s 2>/dev/null || echo "0")

  if [ "$locked_timestamp" != "0" ]; then
    age=$((now - locked_timestamp))
    if [ "$age" -gt "${AGENT_LOCK_TIMEOUT:-10800}" ]; then
      log_heal "Lock is ${age}s old (> ${AGENT_LOCK_TIMEOUT:-10800}s) - lock is stale"
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

  # Our own lock doesn't count as "locked"
  if [ "$lock_agent" = "$AGENT_ID" ]; then
    return 1
  fi

  # Check if the lock is stale
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

  # Atomic directory creation for lock acquisition
  if ! mkdir "$lock_dir" 2>/dev/null; then
    sleep 0.5
    if [ -d "$lock_dir" ]; then
      log_warn "Lock acquisition in progress by another agent for $task_id"
      return 1
    fi
  fi

  # Check if lock already exists from another agent
  if [ -f "$lock_file" ]; then
    local lock_agent
    lock_agent=$(grep "^AGENT_ID=" "$lock_file" 2>/dev/null | cut -d= -f2 | tr -d '"' || echo "")

    if [ "$lock_agent" != "$AGENT_ID" ] && ! is_lock_stale "$lock_file"; then
      rmdir "$lock_dir" 2>/dev/null || true
      return 1
    fi
  fi

  # Create the lock file
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

    # Only release if we own the lock
    if [ "$lock_agent" = "$AGENT_ID" ]; then
      rm -f "$lock_file"
      log_lock "Released lock for $task_id"

      # Remove from held locks array
      local new_held=()
      for held in "${HELD_LOCKS[@]+"${HELD_LOCKS[@]}"}"; do
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
# Task Folder Helpers
# ============================================================================

get_task_folder() {
  local state="$1"
  case "$state" in
    blocked) [ -d "$TASKS_DIR/1.blocked" ] && echo "$TASKS_DIR/1.blocked" && return ;;
    todo)    [ -d "$TASKS_DIR/2.todo" ] && echo "$TASKS_DIR/2.todo" && return ;;
    doing)   [ -d "$TASKS_DIR/3.doing" ] && echo "$TASKS_DIR/3.doing" && return ;;
    done)    [ -d "$TASKS_DIR/4.done" ] && echo "$TASKS_DIR/4.done" && return ;;
  esac
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

# ============================================================================
# Task Selection Functions
# ============================================================================

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

find_orphaned_doing_task() {
  local doing_dir
  doing_dir=$(get_task_folder "doing")

  for file in "$doing_dir"/*.md; do
    [ -f "$file" ] || continue
    local task_id
    task_id=$(get_task_id_from_file "$file")

    local lock_file
    lock_file=$(get_lock_file "$task_id")

    # Skip tasks with valid lock from THIS agent
    if [ -f "$lock_file" ]; then
      local lock_agent
      lock_agent=$(grep "^AGENT_ID=" "$lock_file" 2>/dev/null | cut -d= -f2 | tr -d '"' || echo "")
      if [ "$lock_agent" = "$AGENT_ID" ]; then
        continue
      fi

      if is_lock_stale "$lock_file"; then
        log_heal "Found orphaned task $task_id (stale lock from $lock_agent)"
        echo "$file stale:$lock_agent"
        return 0
      else
        log_heal "Found orphaned task $task_id (locked by $lock_agent)"
        echo "$file locked:$lock_agent"
        return 0
      fi
    else
      log_heal "Found orphaned task $task_id (no lock)"
      echo "$file nolock"
      return 0
    fi
  done

  return 1
}

get_next_available_task() {
  # 1. First check for OUR doing task
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

  return 1
}

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
# Backoff Calculation
# ============================================================================

AGENT_RETRY_DELAY="${AGENT_RETRY_DELAY:-5}"

calculate_backoff() {
  local attempt="$1"
  local base_delay="${AGENT_RETRY_DELAY:-5}"
  local max_delay=60

  local delay=$((base_delay * (2 ** (attempt - 1))))
  if [ "$delay" -gt "$max_delay" ]; then
    delay=$max_delay
  fi

  echo "$delay"
}

# ============================================================================
# Session State Functions
# ============================================================================

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
NUM_TASKS="${NUM_TASKS:-1}"
MODEL="${DOYAKEN_MODEL:-opus}"
LOG_DIR="${RUN_LOG_DIR:-}"
EOF
  log_info "Session state saved: $session_id (iteration $iteration)"
}

load_session() {
  local session_file="$STATE_DIR/session-$AGENT_ID"

  if [ -f "$session_file" ] && [ "${AGENT_NO_RESUME:-}" != "1" ]; then
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
# Task Metadata Functions
# ============================================================================

update_task_metadata() {
  local task_file="$1"
  local field_name="$2"
  local new_value="$3"

  [ -f "$task_file" ] || return 1

  local escaped_value="${new_value//\\/\\\\}"

  local temp_file="${task_file}.tmp.$$"
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
