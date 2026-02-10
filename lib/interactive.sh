#!/usr/bin/env bash
#
# interactive.sh - Interactive REPL mode for doyaken
#
# Provides the `dk chat` command for conversational interaction with AI agents.
# Features:
#   - Readline-based input with persistent history
#   - Slash command dispatch (/help, /quit, /clear, /status)
#   - Agent message streaming with Ctrl+C cancellation
#   - Session logging to .doyaken/sessions/<id>/messages.jsonl
#

# Prevent multiple sourcing
[[ -n "${_DOYAKEN_INTERACTIVE_LOADED:-}" ]] && return 0
_DOYAKEN_INTERACTIVE_LOADED=1

# Source dependencies
SCRIPT_DIR_INTERACTIVE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR_INTERACTIVE/logging.sh"
source "$SCRIPT_DIR_INTERACTIVE/commands.sh"

# ============================================================================
# Session Management
# ============================================================================

CHAT_SESSION_ID=""
CHAT_SESSION_DIR=""
CHAT_MESSAGES_FILE=""
CHAT_HISTORY_FILE=""
CHAT_AGENT_PID=""
CHAT_SHOULD_EXIT=0
CHAT_CURRENT_TASK=""

# Generate a unique session ID
generate_session_id() {
  echo "$(date '+%Y%m%d-%H%M%S')-$$"
}

# Initialize a new chat session
# Creates session directory and messages log file
init_session() {
  CHAT_SESSION_ID=$(generate_session_id)

  # Determine session storage location
  if [ -n "${DOYAKEN_DIR:-}" ] && [ -d "$DOYAKEN_DIR" ]; then
    CHAT_SESSION_DIR="$DOYAKEN_DIR/sessions/$CHAT_SESSION_ID"
  elif [ -n "${DOYAKEN_PROJECT:-}" ] && [ -d "$DOYAKEN_PROJECT/.doyaken" ]; then
    CHAT_SESSION_DIR="$DOYAKEN_PROJECT/.doyaken/sessions/$CHAT_SESSION_ID"
  else
    # No project — use global doyaken home
    CHAT_SESSION_DIR="${DOYAKEN_HOME:-$HOME/.doyaken}/sessions/$CHAT_SESSION_ID"
  fi

  CHAT_MESSAGES_FILE="$CHAT_SESSION_DIR/messages.jsonl"
  mkdir -p "$CHAT_SESSION_DIR"
  chmod 700 "$CHAT_SESSION_DIR"

  # History file in global doyaken home
  CHAT_HISTORY_FILE="${DOYAKEN_HOME:-$HOME/.doyaken}/chat_history"
  mkdir -p "$(dirname "$CHAT_HISTORY_FILE")"
}

# Log a message to the session JSONL file
# Usage: log_message "user" "Hello, can you help?"
log_message() {
  local role="$1"
  local content="$2"
  local timestamp
  timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  # Escape for JSON (backslash, double-quote, tabs, newlines)
  local escaped
  escaped=$(printf '%s' "$content" | sed 's/\\/\\\\/g; s/"/\\"/g; s/	/\\t/g' | tr '\n' ' ')

  echo "{\"role\":\"$role\",\"content\":\"$escaped\",\"timestamp\":\"$timestamp\"}" >> "$CHAT_MESSAGES_FILE"
}

# ============================================================================
# Agent Communication
# ============================================================================

# Send a message to the configured agent and stream output to terminal
# Returns 0 on success, non-zero on error (interruptions are treated as success)
send_to_agent() {
  local message="$1"
  local agent="${DOYAKEN_AGENT:-claude}"
  local model="${DOYAKEN_MODEL:-}"

  # Log user message
  log_message "user" "$message"

  local exit_code=0

  case "$agent" in
    claude)
      local agent_args=()
      if [ "${DOYAKEN_SAFE_MODE:-0}" != "1" ]; then
        agent_args+=("--dangerously-skip-permissions" "--permission-mode" "bypassPermissions")
      fi
      [ -n "$model" ] && agent_args+=("--model" "$model")
      agent_args+=("--print" "--output-format" "text")
      agent_args+=("-p" "$message")

      # Run in background so Ctrl+C can kill it without exiting REPL
      claude "${agent_args[@]}" 2>&1 &
      CHAT_AGENT_PID=$!
      wait "$CHAT_AGENT_PID" 2>/dev/null || exit_code=$?
      CHAT_AGENT_PID=""
      ;;

    codex)
      local agent_args=("exec")
      if [ "${DOYAKEN_SAFE_MODE:-0}" != "1" ]; then
        agent_args+=("--dangerously-bypass-approvals-and-sandbox")
      fi
      [ -n "$model" ] && agent_args+=("-m" "$model")
      agent_args+=("$message")

      codex "${agent_args[@]}" 2>&1 &
      CHAT_AGENT_PID=$!
      wait "$CHAT_AGENT_PID" 2>/dev/null || exit_code=$?
      CHAT_AGENT_PID=""
      ;;

    gemini)
      local agent_args=()
      if [ "${DOYAKEN_SAFE_MODE:-0}" != "1" ]; then
        agent_args+=("--yolo")
      fi
      [ -n "$model" ] && agent_args+=("-m" "$model")
      agent_args+=("-p" "$message")

      gemini "${agent_args[@]}" 2>&1 &
      CHAT_AGENT_PID=$!
      wait "$CHAT_AGENT_PID" 2>/dev/null || exit_code=$?
      CHAT_AGENT_PID=""
      ;;

    *)
      # Generic agent — build command from abstraction layer
      if declare -f agent_exec_command &>/dev/null; then
        local cmd auto_args model_args prompt_flag
        cmd=$(agent_exec_command "$agent")
        auto_args=$(agent_autonomous_args "$agent")
        model_args=$(agent_model_args "$agent" "$model")
        prompt_flag=$(agent_prompt_args "$agent")

        if [ -n "$prompt_flag" ]; then
          # shellcheck disable=SC2086
          $cmd $auto_args $model_args $prompt_flag "$message" 2>&1 &
        else
          # shellcheck disable=SC2086
          $cmd $auto_args $model_args "$message" 2>&1 &
        fi
        CHAT_AGENT_PID=$!
        wait "$CHAT_AGENT_PID" 2>/dev/null || exit_code=$?
        CHAT_AGENT_PID=""
      else
        log_error "Agent '$agent' not supported in chat mode"
        return 1
      fi
      ;;
  esac

  # Handle interruption gracefully
  if [ "$exit_code" -eq 130 ] || [ "$exit_code" -eq 137 ]; then
    echo ""
    echo -e "${YELLOW}[interrupted]${NC}"
    return 0
  fi

  return "$exit_code"
}

# ============================================================================
# Signal Handling
# ============================================================================

# Handle Ctrl+C: kill running agent or show hint
handle_chat_interrupt() {
  if [ -n "$CHAT_AGENT_PID" ] && kill -0 "$CHAT_AGENT_PID" 2>/dev/null; then
    # Agent is running — kill it
    kill "$CHAT_AGENT_PID" 2>/dev/null || true
    wait "$CHAT_AGENT_PID" 2>/dev/null || true
    CHAT_AGENT_PID=""
    echo ""
    echo -e "${YELLOW}[interrupted]${NC}"
  else
    # At prompt — show hint
    CHAT_AGENT_PID=""
    echo ""
    echo -e "${DIM}Type /quit to exit${NC}"
  fi
}

# ============================================================================
# REPL Loop
# ============================================================================

# Build the prompt string (plain text for readline compatibility)
build_chat_prompt() {
  if [ -n "${CHAT_CURRENT_TASK:-}" ]; then
    echo "doyaken [$CHAT_CURRENT_TASK]> "
  elif [ -n "${DOYAKEN_PROJECT:-}" ]; then
    echo "doyaken [$(basename "$DOYAKEN_PROJECT")]> "
  else
    echo "doyaken> "
  fi
}

# Main REPL entry point
# Called by `dk chat` in cli.sh
run_repl() {
  local agent="${DOYAKEN_AGENT:-claude}"
  local model="${DOYAKEN_MODEL:-}"

  # Initialize session
  init_session

  # Register commands (builtins + skills)
  register_builtin_commands
  register_skill_commands

  # Set up tab completion
  setup_tab_completion

  # Set up signal handler
  trap handle_chat_interrupt INT

  # Welcome banner
  echo ""
  echo -e "${BOLD}doyaken interactive mode${NC}"
  echo -e "${DIM}Agent: $agent${model:+ (model: $model)}${NC}"
  echo -e "${DIM}Session: $CHAT_SESSION_ID${NC}"
  echo -e "${DIM}Type /help for commands, /quit to exit${NC}"
  echo ""

  # Load input history
  if [ -f "$CHAT_HISTORY_FILE" ]; then
    history -r "$CHAT_HISTORY_FILE" 2>/dev/null || true
  fi

  local prompt
  prompt=$(build_chat_prompt)

  # Main loop
  while [ "$CHAT_SHOULD_EXIT" -eq 0 ]; do
    local input=""

    # Rebuild prompt (may change after /pick)
    prompt=$(build_chat_prompt)

    # Read with readline editing support
    if ! IFS= read -re -p "$prompt" input; then
      # EOF (Ctrl+D)
      echo ""
      echo "Goodbye!"
      break
    fi

    # Skip empty input
    [ -z "${input// /}" ] && continue

    # Add to history
    history -s "$input" 2>/dev/null || true

    # Dispatch: slash command or agent message
    if is_command "$input"; then
      dispatch_command "$input"
    else
      send_to_agent "$input"
    fi

    echo ""
  done

  # Persist history
  history -w "$CHAT_HISTORY_FILE" 2>/dev/null || true

  # Restore default signal handling
  trap - INT
}
