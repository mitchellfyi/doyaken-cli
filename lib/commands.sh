#!/usr/bin/env bash
#
# commands.sh - Slash command registry and dispatch for doyaken interactive mode
#
# Provides built-in commands (/help, /quit, /clear, /status) and
# a dispatch mechanism for routing slash commands in chat mode.
#

# Prevent multiple sourcing
[[ -n "${_DOYAKEN_COMMANDS_LOADED:-}" ]] && return 0
_DOYAKEN_COMMANDS_LOADED=1

# ============================================================================
# Command Dispatch
# ============================================================================

# Check if input is a slash command
is_command() {
  [[ "$1" == /* ]]
}

# Dispatch a slash command
# Usage: dispatch_command "/help" or dispatch_command "/status"
dispatch_command() {
  local input="$1"
  local cmd="${input%% *}"   # First word
  local args="${input#* }"   # Rest of input
  [ "$args" = "$input" ] && args=""  # No args case
  cmd="${cmd#/}"             # Strip leading /

  case "$cmd" in
    help|h)
      chat_cmd_help "$args"
      ;;
    quit|exit|q)
      chat_cmd_quit
      ;;
    clear)
      chat_cmd_clear
      ;;
    status)
      chat_cmd_status
      ;;
    *)
      echo "Unknown command: /$cmd"
      echo "Type /help for available commands"
      return 1
      ;;
  esac
}

# ============================================================================
# Built-in Command Handlers
# ============================================================================

chat_cmd_help() {
  echo ""
  echo -e "${BOLD}Available Commands${NC}"
  echo "=================="
  echo ""
  printf "  ${CYAN}/%-10s${NC} %s\n" "help"   "Show this help message"
  printf "  ${CYAN}/%-10s${NC} %s\n" "status" "Show current project and session status"
  printf "  ${CYAN}/%-10s${NC} %s\n" "clear"  "Clear the screen"
  printf "  ${CYAN}/%-10s${NC} %s\n" "quit"   "Exit interactive mode (also: /exit, Ctrl+D)"
  echo ""
}

chat_cmd_quit() {
  echo "Goodbye!"
  # Signal to the REPL loop to exit
  CHAT_SHOULD_EXIT=1
}

chat_cmd_clear() {
  clear
}

chat_cmd_status() {
  echo ""

  # Project info
  if [ -n "${DOYAKEN_PROJECT:-}" ] && [ -d "${DOYAKEN_PROJECT}/.doyaken" ]; then
    local doyaken_dir="$DOYAKEN_PROJECT/.doyaken"
    echo -e "${BOLD}Project:${NC}  $(basename "$DOYAKEN_PROJECT")"

    # Task counts (use functions from project.sh if available)
    if declare -f get_task_folder &>/dev/null && declare -f count_task_files &>/dev/null; then
      local todo_dir doing_dir done_dir
      todo_dir=$(get_task_folder "$doyaken_dir" "todo")
      doing_dir=$(get_task_folder "$doyaken_dir" "doing")
      done_dir=$(get_task_folder "$doyaken_dir" "done")
      echo -e "${BOLD}Todo:${NC}     $(count_task_files "$todo_dir")"
      echo -e "${BOLD}Doing:${NC}    $(count_task_files "$doing_dir")"
      echo -e "${BOLD}Done:${NC}     $(count_task_files "$done_dir")"
    fi
  else
    echo -e "${BOLD}Project:${NC}  (none)"
  fi

  # Agent info
  echo -e "${BOLD}Agent:${NC}    ${DOYAKEN_AGENT:-claude}"
  [ -n "${DOYAKEN_MODEL:-}" ] && echo -e "${BOLD}Model:${NC}    $DOYAKEN_MODEL"

  # Session info
  [ -n "${CHAT_SESSION_ID:-}" ] && echo -e "${BOLD}Session:${NC}  $CHAT_SESSION_ID"

  echo ""
}
