#!/usr/bin/env bash
#
# progress.sh - Rich progress display for doyaken
#
# Provides:
#   - Phase pipeline indicator (EXPAND ✓ → TRIAGE ● → PLAN ○ ...)
#   - Persistent status line (task, phase, timer, model)
#   - Desktop notifications on task completion
#   - Terminal bell on completion (configurable)
#
# Configurable via manifest or CLI flags:
#   display.status_line: true|false   (--no-status-line to disable)
#   display.phase_progress: true|false
#   display.notifications: true|false
#   display.bell: true|false
#

# Prevent multiple sourcing
[[ -n "${_DOYAKEN_PROGRESS_LOADED:-}" ]] && return 0
_DOYAKEN_PROGRESS_LOADED=1

# ============================================================================
# Configuration
# ============================================================================

# Display settings (can be overridden by config or CLI)
DISPLAY_STATUS_LINE="${DISPLAY_STATUS_LINE:-1}"
DISPLAY_PHASE_PROGRESS="${DISPLAY_PHASE_PROGRESS:-1}"
DISPLAY_NOTIFICATIONS="${DISPLAY_NOTIFICATIONS:-1}"
DISPLAY_BELL="${DISPLAY_BELL:-0}"

# Phase tracking state
PROGRESS_PHASE_NAMES=()
PROGRESS_PHASE_STATUSES=()  # pending, running, done, skipped
PROGRESS_CURRENT_PHASE=""
PROGRESS_CURRENT_PHASE_IDX=-1
PROGRESS_TASK_ID=""
PROGRESS_TASK_TITLE=""
PROGRESS_MODEL=""
PROGRESS_PHASE_START=0
PROGRESS_STATUS_LINE_ACTIVE=0

# ============================================================================
# Load Display Configuration
# ============================================================================

load_display_config() {
  local manifest_file="${1:-}"

  if declare -f _load_config_bool &>/dev/null; then
    _load_config_bool "DISPLAY_STATUS_LINE"    "display.status_line"    "true"  "$manifest_file"
    _load_config_bool "DISPLAY_PHASE_PROGRESS" "display.phase_progress" "true"  "$manifest_file"
    _load_config_bool "DISPLAY_NOTIFICATIONS"  "display.notifications"  "true"  "$manifest_file"
    _load_config_bool "DISPLAY_BELL"           "display.bell"           "false" "$manifest_file"
  fi
}

# ============================================================================
# TTY Detection
# ============================================================================

# Check if we're outputting to a real terminal (not piped)
_is_tty() {
  [[ -t 1 ]] && [[ "${TERM:-}" != "dumb" ]]
}

# ============================================================================
# Phase Pipeline Indicator
# ============================================================================

# Initialize phase tracking from the PHASES array
# Call this at the start of run_all_phases
progress_init_phases() {
  local task_id="${1:-}"
  local model="${2:-}"

  PROGRESS_TASK_ID="$task_id"
  PROGRESS_MODEL="$model"
  PROGRESS_CURRENT_PHASE=""
  PROGRESS_CURRENT_PHASE_IDX=-1

  # Extract phase names from the global PHASES array
  PROGRESS_PHASE_NAMES=()
  PROGRESS_PHASE_STATUSES=()

  if [ -n "${PHASES+x}" ]; then
    local i=0
    for phase_def in "${PHASES[@]}"; do
      local name skip
      IFS='|' read -r name _ _ skip <<< "$phase_def"
      PROGRESS_PHASE_NAMES+=("$name")
      if [ "$skip" = "1" ]; then
        PROGRESS_PHASE_STATUSES+=("skipped")
      else
        PROGRESS_PHASE_STATUSES+=("pending")
      fi
      ((i++))
    done
  fi
}

# Mark a phase as started
progress_phase_start() {
  local phase_name="$1"
  PROGRESS_CURRENT_PHASE="$phase_name"
  PROGRESS_PHASE_START=$(date +%s)

  local i=0
  for name in "${PROGRESS_PHASE_NAMES[@]}"; do
    if [ "$name" = "$phase_name" ]; then
      PROGRESS_PHASE_STATUSES[$i]="running"
      PROGRESS_CURRENT_PHASE_IDX=$i
      break
    fi
    ((i++))
  done

  if [ "$DISPLAY_PHASE_PROGRESS" = "1" ] && _is_tty; then
    _render_phase_pipeline
  fi
}

# Mark a phase as completed
progress_phase_done() {
  local phase_name="$1"

  local i=0
  for name in "${PROGRESS_PHASE_NAMES[@]}"; do
    if [ "$name" = "$phase_name" ]; then
      PROGRESS_PHASE_STATUSES[$i]="done"
      break
    fi
    ((i++))
  done

  if [ "$DISPLAY_PHASE_PROGRESS" = "1" ] && _is_tty; then
    _render_phase_pipeline
  fi
}

# Mark a phase as skipped
progress_phase_skip() {
  local phase_name="$1"

  local i=0
  for name in "${PROGRESS_PHASE_NAMES[@]}"; do
    if [ "$name" = "$phase_name" ]; then
      PROGRESS_PHASE_STATUSES[$i]="skipped"
      break
    fi
    ((i++))
  done
}

# Render the phase pipeline indicator
# Output: EXPAND ✓ → TRIAGE ✓ → PLAN ● → IMPLEMENT ○ → TEST ○ ...
_render_phase_pipeline() {
  local output=""
  local i=0
  local total=${#PROGRESS_PHASE_NAMES[@]}

  for name in "${PROGRESS_PHASE_NAMES[@]}"; do
    local status="${PROGRESS_PHASE_STATUSES[$i]}"
    local indicator=""

    case "$status" in
      done)    indicator="${GREEN}✓${NC}" ;;
      running) indicator="${CYAN}●${NC}" ;;
      skipped) indicator="${DIM}—${NC}" ;;
      *)       indicator="${DIM}○${NC}" ;;
    esac

    # Color the phase name based on status
    case "$status" in
      done)    output+="${GREEN}${name}${NC} ${indicator}" ;;
      running) output+="${BOLD}${CYAN}${name}${NC} ${indicator}" ;;
      skipped) output+="${DIM}${name}${NC} ${indicator}" ;;
      *)       output+="${DIM}${name}${NC} ${indicator}" ;;
    esac

    if [ $((i + 1)) -lt "$total" ]; then
      output+=" → "
    fi

    ((i++))
  done

  echo -e "  $output"
}

# Get the current phase pipeline as a string (for status line)
_phase_progress_short() {
  if [ ${#PROGRESS_PHASE_NAMES[@]} -eq 0 ]; then
    echo ""
    return
  fi

  local done_count=0
  local total=${#PROGRESS_PHASE_NAMES[@]}

  for status in "${PROGRESS_PHASE_STATUSES[@]}"; do
    if [ "$status" = "done" ]; then
      ((done_count++))
    fi
  done

  echo "${PROGRESS_CURRENT_PHASE:-?} [$done_count/$total]"
}

# ============================================================================
# Status Line (Persistent Bottom Bar)
# ============================================================================

# Show a persistent status line at the bottom of the terminal
# Uses ANSI escape codes to position and update in place
status_line_update() {
  [ "$DISPLAY_STATUS_LINE" != "1" ] && return 0
  _is_tty || return 0

  local phase_info="$1"
  local extra="${2:-}"

  # Calculate elapsed time
  local elapsed=""
  if [ "$PROGRESS_PHASE_START" -gt 0 ]; then
    local now
    now=$(date +%s)
    local secs=$(( now - PROGRESS_PHASE_START ))
    local mins=$(( secs / 60 ))
    secs=$(( secs % 60 ))
    elapsed=$(printf "%02d:%02d" "$mins" "$secs")
  fi

  # Build status line components
  local task_part=""
  if [ -n "$PROGRESS_TASK_ID" ]; then
    task_part="${PROGRESS_TASK_ID}"
  fi

  local model_part=""
  if [ -n "$PROGRESS_MODEL" ]; then
    model_part="$PROGRESS_MODEL"
  fi

  # Compose the line
  local line=""
  [ -n "$task_part" ] && line+="$task_part"
  [ -n "$phase_info" ] && line+=" │ $phase_info"
  [ -n "$elapsed" ] && line+=" │ $elapsed"
  [ -n "$model_part" ] && line+=" │ $model_part"
  [ -n "$extra" ] && line+=" │ $extra"

  # Save cursor, move to bottom, write, restore cursor
  local cols
  cols=$(tput cols 2>/dev/null || echo 80)

  # Truncate line if needed
  local plain_line
  plain_line=$(echo -e "$line" | sed 's/\x1b\[[0-9;]*m//g')
  if [ ${#plain_line} -gt "$cols" ]; then
    line="${plain_line:0:$((cols - 3))}..."
  fi

  # Save position, go to last row, clear line, write, restore
  printf '\033[s\033[%d;1H\033[2K\033[7m %s \033[0m\033[u' "$(tput lines 2>/dev/null || echo 24)" "$line"
  PROGRESS_STATUS_LINE_ACTIVE=1
}

# Clear the status line
status_line_clear() {
  [ "$PROGRESS_STATUS_LINE_ACTIVE" != "1" ] && return 0
  _is_tty || return 0

  printf '\033[s\033[%d;1H\033[2K\033[u' "$(tput lines 2>/dev/null || echo 24)"
  PROGRESS_STATUS_LINE_ACTIVE=0
}

# ============================================================================
# Desktop Notifications
# ============================================================================

# Send a desktop notification
# Usage: send_notification "Title" "Body"
send_notification() {
  [ "$DISPLAY_NOTIFICATIONS" != "1" ] && return 0

  local title="$1"
  local body="${2:-}"

  if [[ "$OSTYPE" == darwin* ]]; then
    osascript -e "display notification \"$body\" with title \"$title\"" 2>/dev/null || true
  elif command -v notify-send &>/dev/null; then
    notify-send "$title" "$body" 2>/dev/null || true
  fi
}

# Send terminal bell
send_bell() {
  [ "$DISPLAY_BELL" != "1" ] && return 0
  _is_tty || return 0
  printf '\a'
}

# Notify task completion (both desktop + bell)
notify_task_complete() {
  local task_id="${1:-}"
  local status="${2:-completed}"

  if [ "$status" = "completed" ]; then
    send_notification "doyaken" "Task $task_id completed successfully"
    send_bell
  elif [ "$status" = "failed" ]; then
    send_notification "doyaken" "Task $task_id failed"
    send_bell
  fi
}

# ============================================================================
# Enhanced Progress Filter
# ============================================================================

# Enhanced progress filter that updates status line during phase execution
# Drop-in replacement for the basic progress_filter in core.sh
progress_filter_enhanced() {
  trap "exit 130" INT TERM
  local phase_name="$1"
  local agent_id="${2:-agent}"
  local last_tool=""
  local line_count=0
  local start_time
  start_time=$(date +%s)

  show_status() {
    local elapsed=$(( $(date +%s) - start_time ))
    local mins=$(( elapsed / 60 ))
    local secs=$(( elapsed % 60 ))
    printf "${CYAN}[%s]${NC} ${BOLD}%s${NC} %02d:%02d │ %s\n" "$agent_id" "$phase_name" "$mins" "$secs" "$1"
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
