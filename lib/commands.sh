#!/usr/bin/env bash
#
# commands.sh - Extensible slash command system for doyaken interactive mode
#
# Provides:
#   - Built-in commands (/help, /quit, /tasks, /model, /diff, etc.)
#   - Fuzzy/partial matching for command names
#   - Auto-registration of skills as slash commands
#   - Tab completion for command names (when rlwrap or bash 4+ available)
#

# Prevent multiple sourcing
[[ -n "${_DOYAKEN_COMMANDS_LOADED:-}" ]] && return 0
_DOYAKEN_COMMANDS_LOADED=1

# ============================================================================
# Command Registry (parallel arrays for bash 3.x compatibility)
# ============================================================================

REGISTERED_CMD_NAMES=()
REGISTERED_CMD_DESCS=()
REGISTERED_CMD_TYPES=()  # "builtin" or "skill"

# Register a command
# Usage: register_command "name" "description" ["builtin"|"skill"]
register_command() {
  local name="$1"
  local description="$2"
  local type="${3:-builtin}"
  REGISTERED_CMD_NAMES+=("$name")
  REGISTERED_CMD_DESCS+=("$description")
  REGISTERED_CMD_TYPES+=("$type")
}

# ============================================================================
# Command Dispatch
# ============================================================================

# Check if input is a slash command
is_command() {
  [[ "$1" == /* ]]
}

# Dispatch a slash command
# Usage: dispatch_command "/help" or dispatch_command "/tasks new"
dispatch_command() {
  local input="$1"
  local cmd="${input%% *}"   # First word
  local args="${input#* }"   # Rest of input
  [ "$args" = "$input" ] && args=""  # No args case
  cmd="${cmd#/}"             # Strip leading /

  # Try exact match first
  case "$cmd" in
    help|h)       chat_cmd_help "$args" ;;
    quit|exit|q)  chat_cmd_quit ;;
    clear)        chat_cmd_clear ;;
    status)       chat_cmd_status ;;
    tasks)        chat_cmd_tasks "$args" ;;
    task)         chat_cmd_task "$args" ;;
    pick)         chat_cmd_pick "$args" ;;
    run)          chat_cmd_run "$args" ;;
    phase)        chat_cmd_phase "$args" ;;
    skip)         chat_cmd_skip "$args" ;;
    model)        chat_cmd_model "$args" ;;
    agent)        chat_cmd_agent "$args" ;;
    config)       chat_cmd_config "$args" ;;
    log)          chat_cmd_log "$args" ;;
    diff)         chat_cmd_diff ;;
    *)
      # Try skill command
      if _try_skill_command "$cmd" "$args"; then
        return 0
      fi

      # Try fuzzy match
      local match
      match=$(fuzzy_match_slash_command "$cmd")
      if [ -n "$match" ]; then
        echo -e "Unknown command: ${RED}/$cmd${NC}"
        echo -e "Did you mean ${CYAN}/$match${NC}?"
        return 1
      fi

      echo -e "Unknown command: ${RED}/$cmd${NC}"
      echo "Type /help for available commands"
      return 1
      ;;
  esac
}

# ============================================================================
# Fuzzy Matching
# ============================================================================

# Find the closest matching command name
# Returns the match on stdout, or empty if none found
fuzzy_match_slash_command() {
  local input="$1"
  local input_len=${#input}

  # Too short to match
  (( input_len < 2 )) && return 0

  # Collect all known command names
  local all_cmds="help quit exit clear status tasks task pick run phase skip model agent config log diff"

  # Add registered skill commands
  local i
  for (( i=0; i < ${#REGISTERED_CMD_NAMES[@]}; i++ )); do
    if [ "${REGISTERED_CMD_TYPES[$i]}" = "skill" ]; then
      all_cmds="$all_cmds ${REGISTERED_CMD_NAMES[$i]}"
    fi
  done

  for cmd in $all_cmds; do
    # Prefix match (user typed partial command)
    if [[ "$cmd" == "$input"* ]] && (( input_len >= 2 )); then
      echo "$cmd"
      return 0
    fi
  done

  # One-edit-distance match (typo correction)
  for cmd in $all_cmds; do
    local cmd_len=${#cmd}

    # One char missing
    if (( cmd_len == input_len + 1 )); then
      for (( j=0; j<=cmd_len; j++ )); do
        local without="${cmd:0:$j}${cmd:$((j+1))}"
        if [[ "$without" == "$input" ]]; then
          echo "$cmd"
          return 0
        fi
      done
    fi

    # One char extra
    if (( cmd_len == input_len - 1 )); then
      for (( j=0; j<=input_len; j++ )); do
        local without="${input:0:$j}${input:$((j+1))}"
        if [[ "$without" == "$cmd" ]]; then
          echo "$cmd"
          return 0
        fi
      done
    fi

    # Adjacent swap
    if (( cmd_len == input_len )); then
      for (( j=0; j<input_len-1; j++ )); do
        local swapped="${input:0:$j}${input:$((j+1)):1}${input:$j:1}${input:$((j+2))}"
        if [[ "$swapped" == "$cmd" ]]; then
          echo "$cmd"
          return 0
        fi
      done
    fi
  done

  return 0
}

# ============================================================================
# Skills Auto-Registration
# ============================================================================

# Register skills from .doyaken/skills/ and global skills as slash commands
register_skill_commands() {
  local skills_dirs=()

  # Project skills
  if [ -n "${DOYAKEN_PROJECT:-}" ] && [ -d "$DOYAKEN_PROJECT/.doyaken/skills" ]; then
    skills_dirs+=("$DOYAKEN_PROJECT/.doyaken/skills")
  fi

  # Global skills
  if [ -n "${DOYAKEN_HOME:-}" ] && [ -d "$DOYAKEN_HOME/skills" ]; then
    skills_dirs+=("$DOYAKEN_HOME/skills")
  fi

  local seen_names=""
  for dir in "${skills_dirs[@]}"; do
    for skill_file in "$dir"/*.md; do
      [ -f "$skill_file" ] || continue
      [ "$(basename "$skill_file")" = "README.md" ] && continue

      local name
      name=$(basename "$skill_file" .md)

      # Skip duplicates (project overrides global)
      [[ " $seen_names " == *" $name "* ]] && continue
      seen_names="$seen_names $name"

      # Extract description from frontmatter
      local description=""
      description=$(awk '
        /^---$/ { if (started) exit; started = 1; next }
        started && /^description:/ {
          gsub(/^description:[[:space:]]*/, "")
          gsub(/"/, "")
          print
          exit
        }
      ' "$skill_file")
      [ -z "$description" ] && description="Run skill: $name"

      register_command "$name" "$description" "skill"
    done
  done
}

# Try to execute a command as a skill
# Returns 0 if skill was found and executed, 1 otherwise
_try_skill_command() {
  local cmd="$1"
  local args="$2"

  local i
  for (( i=0; i < ${#REGISTERED_CMD_NAMES[@]}; i++ )); do
    if [ "${REGISTERED_CMD_NAMES[$i]}" = "$cmd" ] && [ "${REGISTERED_CMD_TYPES[$i]}" = "skill" ]; then
      echo -e "${DIM}Running skill: $cmd${NC}"
      if declare -f run_skill &>/dev/null; then
        # shellcheck disable=SC2086
        run_skill "$cmd" $args
      else
        echo "Skill system not available. Run: doyaken skill $cmd"
      fi
      return 0
    fi
  done

  return 1
}

# ============================================================================
# Tab Completion
# ============================================================================

# Generate completions file for rlwrap
# Usage: generate_completions_file "/path/to/file"
generate_completions_file() {
  local file="$1"
  local cmds="/help /quit /exit /clear /status /tasks /task /pick /run /phase /skip /model /agent /config /log /diff"

  # Add skill commands
  local i
  for (( i=0; i < ${#REGISTERED_CMD_NAMES[@]}; i++ )); do
    if [ "${REGISTERED_CMD_TYPES[$i]}" = "skill" ]; then
      cmds="$cmds /${REGISTERED_CMD_NAMES[$i]}"
    fi
  done

  echo "$cmds" | tr ' ' '\n' > "$file"
}

# Set up tab completion for the REPL (bash 4+ only)
setup_tab_completion() {
  # Build list of completions
  local completions="/help /quit /exit /clear /status /tasks /task /pick /run /phase /skip /model /agent /config /log /diff"

  local i
  for (( i=0; i < ${#REGISTERED_CMD_NAMES[@]}; i++ )); do
    if [ "${REGISTERED_CMD_TYPES[$i]}" = "skill" ]; then
      completions="$completions /${REGISTERED_CMD_NAMES[$i]}"
    fi
  done

  # Use bind to add custom completion (bash 4+ with bind -x)
  if [[ "${BASH_VERSINFO[0]}" -ge 4 ]]; then
    # Store completions for the completion function
    export _DOYAKEN_COMPLETIONS="$completions"

    # Define completion function
    _doyaken_complete() {
      local cur="${READLINE_LINE}"
      if [[ "$cur" == /* ]]; then
        local partial="${cur#/}"
        local matches=()
        for comp in $_DOYAKEN_COMPLETIONS; do
          local comp_name="${comp#/}"
          if [[ "$comp_name" == "$partial"* ]]; then
            matches+=("$comp")
          fi
        done
        if [ ${#matches[@]} -eq 1 ]; then
          READLINE_LINE="${matches[0]} "
          READLINE_POINT=${#READLINE_LINE}
        elif [ ${#matches[@]} -gt 1 ]; then
          echo ""
          printf '%s\n' "${matches[@]}"
          echo -ne "${_DOYAKEN_PROMPT:-doyaken> }${READLINE_LINE}"
        fi
      fi
    }

    # Bind Tab to our completion function
    bind -x '"\t": _doyaken_complete' 2>/dev/null || true
  fi
}

# ============================================================================
# Register All Built-in Commands
# ============================================================================

register_builtin_commands() {
  register_command "help"   "Show available commands"
  register_command "quit"   "Exit interactive mode"
  register_command "exit"   "Exit interactive mode"
  register_command "clear"  "Clear the screen"
  register_command "status" "Show project and session status"
  register_command "tasks"  "List tasks (todo/doing/done)"
  register_command "task"   "Show task details: /task <id>"
  register_command "pick"   "Pick up a task: /pick <id>"
  register_command "run"    "Run phases on current task"
  register_command "phase"  "Run a specific phase: /phase <name>"
  register_command "skip"   "Skip a phase: /skip <name>"
  register_command "model"  "Show or change model: /model [name]"
  register_command "agent"  "Show or change agent: /agent [name]"
  register_command "config" "Show or set config: /config [key] [value]"
  register_command "log"    "Show recent log entries"
  register_command "diff"   "Show git diff of changes"
}

# ============================================================================
# Built-in Command Handlers
# ============================================================================

chat_cmd_help() {
  local filter="$1"
  echo ""
  echo -e "${BOLD}Available Commands${NC}"
  echo "=================="
  echo ""

  # Built-in commands
  local i
  for (( i=0; i < ${#REGISTERED_CMD_NAMES[@]}; i++ )); do
    local name="${REGISTERED_CMD_NAMES[$i]}"
    local desc="${REGISTERED_CMD_DESCS[$i]}"
    local type="${REGISTERED_CMD_TYPES[$i]}"

    # Skip aliases (exit is alias for quit)
    [ "$name" = "exit" ] && continue

    # If filter given, only show matching
    if [ -n "$filter" ] && [[ "$name" != *"$filter"* ]] && [[ "$desc" != *"$filter"* ]]; then
      continue
    fi

    if [ "$type" = "skill" ]; then
      printf "  ${GREEN}/%-14s${NC} %s ${DIM}[skill]${NC}\n" "$name" "$desc"
    else
      printf "  ${CYAN}/%-14s${NC} %s\n" "$name" "$desc"
    fi
  done

  echo ""
}

chat_cmd_quit() {
  echo "Goodbye!"
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

  echo -e "${BOLD}Agent:${NC}    ${DOYAKEN_AGENT:-claude}"
  [ -n "${DOYAKEN_MODEL:-}" ] && echo -e "${BOLD}Model:${NC}    $DOYAKEN_MODEL"
  [ -n "${CHAT_SESSION_ID:-}" ] && echo -e "${BOLD}Session:${NC}  $CHAT_SESSION_ID"

  echo ""
}

chat_cmd_tasks() {
  local filter="$1"

  if [ -z "${DOYAKEN_PROJECT:-}" ] || [ ! -d "${DOYAKEN_PROJECT}/.doyaken" ]; then
    echo "Not in a project"
    return 1
  fi

  local doyaken_dir="$DOYAKEN_PROJECT/.doyaken"
  echo ""

  if declare -f get_task_folder &>/dev/null; then
    local dir state
    for state in doing todo blocked done; do
      dir=$(get_task_folder "$doyaken_dir" "$state")
      local label
      case "$state" in
        doing)   label="${YELLOW}DOING${NC}" ;;
        todo)    label="${CYAN}TODO${NC}" ;;
        blocked) label="${RED}BLOCKED${NC}" ;;
        done)    label="${GREEN}DONE${NC}" ;;
      esac

      local count=0
      local files=()
      if [ -d "$dir" ]; then
        while IFS= read -r f; do
          [ -z "$f" ] && continue
          local basename_f
          basename_f=$(basename "$f" .md)
          if [ -z "$filter" ] || [[ "$basename_f" == *"$filter"* ]]; then
            files+=("$basename_f")
            count=$((count + 1))
          fi
        done < <(find "$dir" -maxdepth 1 -name "*.md" -type f 2>/dev/null | sort)
      fi

      echo -e "  $label ($count)"
      for f in "${files[@]}"; do
        echo "    $f"
      done
      [ "$state" = "done" ] && [ "$count" -gt 5 ] && echo "    ... (showing first entries)"
    done
  fi

  echo ""
}

chat_cmd_task() {
  local task_pattern="$1"

  if [ -z "$task_pattern" ]; then
    echo "Usage: /task <id-pattern>"
    return 1
  fi

  if [ -z "${DOYAKEN_PROJECT:-}" ]; then
    echo "Not in a project"
    return 1
  fi

  local doyaken_dir="$DOYAKEN_PROJECT/.doyaken"

  if declare -f get_task_folder &>/dev/null; then
    local dir state
    for state in doing todo blocked done; do
      dir=$(get_task_folder "$doyaken_dir" "$state")
      local found
      found=$(find "$dir" -maxdepth 1 -name "*${task_pattern}*.md" 2>/dev/null | head -1)
      if [ -n "$found" ]; then
        echo ""
        cat "$found"
        return 0
      fi
    done
  fi

  echo "No task found matching: $task_pattern"
  return 1
}

chat_cmd_pick() {
  local task_pattern="$1"

  if [ -z "$task_pattern" ]; then
    echo "Usage: /pick <task-id-pattern>"
    return 1
  fi

  if [ -z "${DOYAKEN_PROJECT:-}" ]; then
    echo "Not in a project"
    return 1
  fi

  local doyaken_dir="$DOYAKEN_PROJECT/.doyaken"

  if declare -f get_task_folder &>/dev/null; then
    local todo_dir doing_dir
    todo_dir=$(get_task_folder "$doyaken_dir" "todo")
    doing_dir=$(get_task_folder "$doyaken_dir" "doing")

    local found
    found=$(find "$todo_dir" -maxdepth 1 -name "*${task_pattern}*.md" 2>/dev/null | head -1)
    if [ -n "$found" ]; then
      mv "$found" "$doing_dir/"
      local task_name
      task_name=$(basename "$found" .md)
      CHAT_CURRENT_TASK="$task_name"
      echo -e "${GREEN}Picked up:${NC} $task_name"
      return 0
    fi
  fi

  echo "No todo task found matching: $task_pattern"
  return 1
}

chat_cmd_run() {
  local args="$1"

  if [ -z "${CHAT_CURRENT_TASK:-}" ]; then
    echo "No task picked. Use /pick <task-id> first, or /tasks to see available tasks."
    return 1
  fi

  echo -e "${DIM}Sending task to agent...${NC}"
  if declare -f send_to_agent &>/dev/null; then
    send_to_agent "Work on the current task: ${CHAT_CURRENT_TASK}. Read the task file and execute all phases: expand, triage, plan, implement, test, docs, review, verify. ${args}"
  else
    echo "Agent not available"
    return 1
  fi
}

chat_cmd_phase() {
  local phase_name="$1"

  if [ -z "$phase_name" ]; then
    echo "Usage: /phase <name>"
    echo "Phases: expand, triage, plan, implement, test, docs, review, verify"
    return 1
  fi

  # Validate phase name
  case "$phase_name" in
    expand|triage|plan|implement|test|docs|review|verify) ;;
    *)
      echo "Unknown phase: $phase_name"
      echo "Valid phases: expand, triage, plan, implement, test, docs, review, verify"
      return 1
      ;;
  esac

  local task="${CHAT_CURRENT_TASK:-}"
  echo -e "${DIM}Running $phase_name phase...${NC}"
  if declare -f send_to_agent &>/dev/null; then
    send_to_agent "Run the $phase_name phase${task:+ on task $task}. Follow the methodology for this phase."
  else
    echo "Agent not available"
    return 1
  fi
}

chat_cmd_skip() {
  local phase_name="$1"

  if [ -z "$phase_name" ]; then
    echo "Usage: /skip <phase>"
    echo "Phases: expand, triage, plan, implement, test, docs, review, verify"
    return 1
  fi

  local var_name
  case "$phase_name" in
    expand)    var_name="SKIP_EXPAND" ;;
    triage)    var_name="SKIP_TRIAGE" ;;
    plan)      var_name="SKIP_PLAN" ;;
    implement) var_name="SKIP_IMPLEMENT" ;;
    test)      var_name="SKIP_TEST" ;;
    docs)      var_name="SKIP_DOCS" ;;
    review)    var_name="SKIP_REVIEW" ;;
    verify)    var_name="SKIP_VERIFY" ;;
    *)
      echo "Unknown phase: $phase_name"
      return 1
      ;;
  esac

  export "$var_name=1"
  echo -e "${YELLOW}Skipping${NC} $phase_name phase"
}

chat_cmd_model() {
  local new_model="$1"

  if [ -z "$new_model" ]; then
    # Show current model and available options
    echo -e "${BOLD}Current model:${NC} ${DOYAKEN_MODEL:-auto}"
    echo -e "${BOLD}Current agent:${NC} ${DOYAKEN_AGENT:-claude}"
    if declare -f agent_list_models &>/dev/null; then
      local models
      models=$(agent_list_models "${DOYAKEN_AGENT:-claude}")
      echo -e "${BOLD}Available:${NC}     $models"
    fi
    return 0
  fi

  # Validate model
  if declare -f agent_supports_model &>/dev/null; then
    if ! agent_supports_model "${DOYAKEN_AGENT:-claude}" "$new_model"; then
      echo -e "${RED}Model '$new_model' not supported by ${DOYAKEN_AGENT:-claude}${NC}"
      if declare -f agent_list_models &>/dev/null; then
        echo "Available: $(agent_list_models "${DOYAKEN_AGENT:-claude}")"
      fi
      return 1
    fi
  fi

  export DOYAKEN_MODEL="$new_model"
  echo -e "${GREEN}Model changed to:${NC} $new_model"
}

chat_cmd_agent() {
  local new_agent="$1"

  if [ -z "$new_agent" ]; then
    echo -e "${BOLD}Current agent:${NC} ${DOYAKEN_AGENT:-claude}"
    echo -e "${BOLD}Available:${NC}     claude codex gemini copilot opencode"
    return 0
  fi

  # Validate agent
  if declare -f agent_installed &>/dev/null; then
    if ! agent_installed "$new_agent"; then
      echo -e "${RED}Agent '$new_agent' is not installed${NC}"
      if declare -f agent_install_instructions &>/dev/null; then
        agent_install_instructions "$new_agent"
      fi
      return 1
    fi
  fi

  export DOYAKEN_AGENT="$new_agent"
  # Reset model to agent's default
  if declare -f agent_default_model &>/dev/null; then
    export DOYAKEN_MODEL="$(agent_default_model "$new_agent")"
  fi
  echo -e "${GREEN}Agent changed to:${NC} $new_agent (model: ${DOYAKEN_MODEL:-auto})"
}

chat_cmd_config() {
  local args="$1"
  local key="${args%% *}"
  local value="${args#* }"
  [ "$value" = "$key" ] && value=""

  if [ -z "$key" ]; then
    # Show current config summary
    echo ""
    echo -e "${BOLD}Agent:${NC}    ${DOYAKEN_AGENT:-claude}"
    echo -e "${BOLD}Model:${NC}    ${DOYAKEN_MODEL:-auto}"
    echo -e "${BOLD}Safe:${NC}     ${DOYAKEN_SAFE_MODE:-0}"
    echo -e "${BOLD}Verbose:${NC}  ${AGENT_VERBOSE:-0}"
    echo -e "${BOLD}Quiet:${NC}    ${AGENT_QUIET:-0}"
    echo ""
    echo "Set with: /config <key> <value>"
    echo "Keys: agent, model, safe_mode, verbose, quiet"
    echo ""
    return 0
  fi

  if [ -z "$value" ]; then
    # Show specific key
    case "$key" in
      agent)     echo "${DOYAKEN_AGENT:-claude}" ;;
      model)     echo "${DOYAKEN_MODEL:-auto}" ;;
      safe_mode) echo "${DOYAKEN_SAFE_MODE:-0}" ;;
      verbose)   echo "${AGENT_VERBOSE:-0}" ;;
      quiet)     echo "${AGENT_QUIET:-0}" ;;
      *)         echo "Unknown config key: $key" ; return 1 ;;
    esac
    return 0
  fi

  # Set value
  case "$key" in
    agent)     export DOYAKEN_AGENT="$value" ;;
    model)     export DOYAKEN_MODEL="$value" ;;
    safe_mode) export DOYAKEN_SAFE_MODE="$value" ;;
    verbose)   export AGENT_VERBOSE="$value" ;;
    quiet)     export AGENT_QUIET="$value" ;;
    *)         echo "Unknown config key: $key" ; return 1 ;;
  esac
  echo -e "${GREEN}Set${NC} $key = $value"
}

chat_cmd_log() {
  local lines="${1:-20}"

  if [ -z "${DOYAKEN_PROJECT:-}" ]; then
    echo "Not in a project"
    return 1
  fi

  local logs_dir="$DOYAKEN_PROJECT/.doyaken/logs"
  if [ ! -d "$logs_dir" ]; then
    echo "No logs directory"
    return 1
  fi

  # Find most recent log file
  local latest
  latest=$(find "$logs_dir" -name "*.log" -type f 2>/dev/null | sort -r | head -1)
  if [ -z "$latest" ]; then
    echo "No log files found"
    return 0
  fi

  echo -e "${DIM}Latest log: $(basename "$latest")${NC}"
  echo ""
  tail -n "$lines" "$latest"
}

chat_cmd_diff() {
  if [ -z "${DOYAKEN_PROJECT:-}" ]; then
    echo "Not in a project"
    return 1
  fi

  if [ ! -d "$DOYAKEN_PROJECT/.git" ]; then
    echo "Not a git repository"
    return 1
  fi

  local diff_output
  diff_output=$(git -C "$DOYAKEN_PROJECT" diff --stat 2>/dev/null)

  if [ -z "$diff_output" ]; then
    echo "No uncommitted changes"
    return 0
  fi

  echo ""
  git -C "$DOYAKEN_PROJECT" diff --stat 2>/dev/null
  echo ""
  echo -e "${DIM}Use 'git diff' for full diff${NC}"
}
