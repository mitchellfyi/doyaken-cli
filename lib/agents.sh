#!/usr/bin/env bash
#
# agents.sh - Multi-agent abstraction layer for doyaken
#
# Supported agents:
#   - claude (default) - Anthropic Claude Code CLI
#   - codex           - OpenAI Codex CLI
#   - gemini          - Google Gemini CLI
#   - copilot         - GitHub Copilot CLI
#   - opencode        - OpenCode CLI
#

# Agent registry with default models
# Using declare -A requires bash 4+
if [[ "${BASH_VERSINFO[0]}" -ge 4 ]]; then
  declare -A AGENT_COMMANDS
  AGENT_COMMANDS[claude]="claude"
  AGENT_COMMANDS[codex]="codex"
  AGENT_COMMANDS[gemini]="gemini"
  AGENT_COMMANDS[copilot]="copilot"
  AGENT_COMMANDS[opencode]="opencode"

  declare -A AGENT_DEFAULT_MODELS
  AGENT_DEFAULT_MODELS[claude]="opus"
  AGENT_DEFAULT_MODELS[codex]="gpt-5"
  AGENT_DEFAULT_MODELS[gemini]="gemini-2.5-pro"
  AGENT_DEFAULT_MODELS[copilot]="claude-sonnet-4.5"
  AGENT_DEFAULT_MODELS[opencode]="claude-sonnet-4"

  declare -A AGENT_MODELS
  AGENT_MODELS[claude]="opus sonnet haiku claude-opus-4 claude-sonnet-4 claude-sonnet-4.5"
  AGENT_MODELS[codex]="gpt-5 o3 o4-mini gpt-5-codex"
  AGENT_MODELS[gemini]="gemini-2.5-pro gemini-2.5-flash gemini-3-pro"
  AGENT_MODELS[copilot]="claude-sonnet-4.5 claude-sonnet-4 gpt-5"
  AGENT_MODELS[opencode]="claude-sonnet-4 claude-opus-4 gpt-5 gemini-2.5-pro"
fi

# Helper function to get agent command (works without associative arrays)
_get_agent_cmd() {
  local agent="$1"
  case "$agent" in
    claude) echo "claude" ;;
    codex) echo "codex" ;;
    gemini) echo "gemini" ;;
    copilot) echo "copilot" ;;
    opencode) echo "opencode" ;;
    *) echo "" ;;
  esac
}

# Helper function to get default model (works without associative arrays)
_get_default_model() {
  local agent="$1"
  case "$agent" in
    claude) echo "opus" ;;
    codex) echo "gpt-5" ;;
    gemini) echo "gemini-2.5-pro" ;;
    copilot) echo "claude-sonnet-4.5" ;;
    opencode) echo "claude-sonnet-4" ;;
    *) echo "opus" ;;
  esac
}

# Helper function to get supported models (works without associative arrays)
_get_supported_models() {
  local agent="$1"
  case "$agent" in
    claude) echo "opus sonnet haiku claude-opus-4 claude-sonnet-4 claude-sonnet-4.5" ;;
    codex) echo "gpt-5 o3 o4-mini gpt-5-codex" ;;
    gemini) echo "gemini-2.5-pro gemini-2.5-flash gemini-3-pro" ;;
    copilot) echo "claude-sonnet-4.5 claude-sonnet-4 gpt-5" ;;
    opencode) echo "claude-sonnet-4 claude-opus-4 gpt-5 gemini-2.5-pro" ;;
    *) echo "" ;;
  esac
}

# Check if an agent is installed
agent_installed() {
  local agent="$1"
  local cmd
  cmd=$(_get_agent_cmd "$agent")

  if [[ -z "$cmd" ]]; then
    return 1
  fi

  command -v "$cmd" &>/dev/null
}

# Get the command for an agent
agent_command() {
  local agent="$1"
  local cmd
  cmd=$(_get_agent_cmd "$agent")
  echo "${cmd:-claude}"
}

# Get default model for an agent
agent_default_model() {
  local agent="$1"
  _get_default_model "$agent"
}

# Check if a model is supported by an agent
agent_supports_model() {
  local agent="$1"
  local model="$2"
  local supported
  supported=$(_get_supported_models "$agent")

  [[ " $supported " == *" $model "* ]]
}

# List supported models for an agent
agent_list_models() {
  local agent="$1"
  _get_supported_models "$agent"
}

# List all supported agents
agent_list_all() {
  echo "claude codex gemini copilot opencode"
}

# Build the command to run an agent with a prompt
# Returns the full command array
agent_build_command() {
  local agent="$1"
  local model="$2"
  local prompt_file="$3"
  local dangerously_skip_permissions="${4:-false}"
  local print_only="${5:-false}"

  local cmd="${AGENT_COMMANDS[$agent]:-claude}"

  case "$agent" in
    claude)
      # Claude Code CLI
      # claude --dangerously-skip-permissions --model <model> -p "prompt"
      local args=()
      if [[ "$dangerously_skip_permissions" == "true" ]]; then
        args+=("--dangerously-skip-permissions")
      fi
      if [[ -n "$model" ]]; then
        args+=("--model" "$model")
      fi
      if [[ "$print_only" == "true" ]]; then
        args+=("--print")
      fi
      args+=("-p" "$(cat "$prompt_file")")
      echo "claude ${args[*]}"
      ;;

    codex)
      # OpenAI Codex CLI
      # codex exec -m <model> "prompt" or codex -m <model> for interactive
      local args=("exec")
      if [[ -n "$model" ]]; then
        args+=("-m" "$model")
      fi
      if [[ "$dangerously_skip_permissions" == "true" ]]; then
        args+=("--full-auto")
      else
        args+=("--auto-edit")
      fi
      args+=("$(cat "$prompt_file")")
      echo "codex ${args[*]}"
      ;;

    gemini)
      # Google Gemini CLI
      # gemini -m <model> "prompt" or interactive mode
      local args=()
      if [[ -n "$model" ]]; then
        args+=("-m" "$model")
      fi
      if [[ "$dangerously_skip_permissions" == "true" ]]; then
        args+=("--yolo")  # Full auto mode
      fi
      args+=("-p" "$(cat "$prompt_file")")
      echo "gemini ${args[*]}"
      ;;

    copilot)
      # GitHub Copilot CLI
      # copilot -m <model> "prompt"
      local args=()
      if [[ -n "$model" ]]; then
        args+=("-m" "$model")
      fi
      if [[ "$dangerously_skip_permissions" == "true" ]]; then
        args+=("--auto")
      fi
      args+=("$(cat "$prompt_file")")
      echo "copilot ${args[*]}"
      ;;

    opencode)
      # OpenCode CLI
      # opencode --model <model> --provider <provider> "prompt"
      local args=()
      if [[ -n "$model" ]]; then
        args+=("--model" "$model")
      fi
      if [[ "$dangerously_skip_permissions" == "true" ]]; then
        args+=("--auto")
      fi
      args+=("-m" "$(cat "$prompt_file")")
      echo "opencode ${args[*]}"
      ;;

    *)
      echo "claude -p \"$(cat "$prompt_file")\""
      ;;
  esac
}

# Run an agent with a prompt file
# Usage: agent_run <agent> <model> <prompt_file> [dangerously_skip_permissions] [timeout]
agent_run() {
  local agent="$1"
  local model="$2"
  local prompt_file="$3"
  local dangerously_skip_permissions="${4:-false}"
  local timeout="${5:-}"

  local cmd="${AGENT_COMMANDS[$agent]:-claude}"

  # Check if agent is installed
  if ! command -v "$cmd" &>/dev/null; then
    echo "Error: Agent '$agent' ($cmd) is not installed" >&2
    return 1
  fi

  # Build timeout prefix if specified
  local timeout_prefix=""
  if [[ -n "$timeout" ]]; then
    if command -v timeout &>/dev/null; then
      timeout_prefix="timeout $timeout"
    elif command -v gtimeout &>/dev/null; then
      timeout_prefix="gtimeout $timeout"
    fi
  fi

  case "$agent" in
    claude)
      local args=()
      if [[ "$dangerously_skip_permissions" == "true" ]]; then
        args+=("--dangerously-skip-permissions")
      fi
      if [[ -n "$model" ]]; then
        args+=("--model" "$model")
      fi
      args+=("-p" "$(cat "$prompt_file")")

      if [[ -n "$timeout_prefix" ]]; then
        $timeout_prefix claude "${args[@]}"
      else
        claude "${args[@]}"
      fi
      ;;

    codex)
      local args=("exec")
      if [[ -n "$model" ]]; then
        args+=("-m" "$model")
      fi
      if [[ "$dangerously_skip_permissions" == "true" ]]; then
        args+=("--full-auto")
      else
        args+=("--auto-edit")
      fi
      args+=("$(cat "$prompt_file")")

      if [[ -n "$timeout_prefix" ]]; then
        $timeout_prefix codex "${args[@]}"
      else
        codex "${args[@]}"
      fi
      ;;

    gemini)
      local args=()
      if [[ -n "$model" ]]; then
        args+=("-m" "$model")
      fi
      if [[ "$dangerously_skip_permissions" == "true" ]]; then
        args+=("--yolo")
      fi
      args+=("-p" "$(cat "$prompt_file")")

      if [[ -n "$timeout_prefix" ]]; then
        $timeout_prefix gemini "${args[@]}"
      else
        gemini "${args[@]}"
      fi
      ;;

    copilot)
      local args=()
      if [[ -n "$model" ]]; then
        args+=("-m" "$model")
      fi
      if [[ "$dangerously_skip_permissions" == "true" ]]; then
        args+=("--auto")
      fi
      args+=("$(cat "$prompt_file")")

      if [[ -n "$timeout_prefix" ]]; then
        $timeout_prefix copilot "${args[@]}"
      else
        copilot "${args[@]}"
      fi
      ;;

    opencode)
      local args=()
      if [[ -n "$model" ]]; then
        args+=("--model" "$model")
      fi
      if [[ "$dangerously_skip_permissions" == "true" ]]; then
        args+=("--auto")
      fi
      args+=("-m" "$(cat "$prompt_file")")

      if [[ -n "$timeout_prefix" ]]; then
        $timeout_prefix opencode "${args[@]}"
      else
        opencode "${args[@]}"
      fi
      ;;

    *)
      echo "Error: Unknown agent '$agent'" >&2
      return 1
      ;;
  esac
}

# Get installation instructions for an agent
agent_install_instructions() {
  local agent="$1"

  case "$agent" in
    claude)
      echo "Install Claude Code CLI:"
      echo "  npm install -g @anthropic-ai/claude-code"
      echo "  or visit: https://claude.ai/cli"
      ;;
    codex)
      echo "Install OpenAI Codex CLI:"
      echo "  npm install -g @openai/codex"
      echo "  or: brew install --cask codex"
      echo "  Docs: https://github.com/openai/codex"
      ;;
    gemini)
      echo "Install Google Gemini CLI:"
      echo "  npm install -g @google/gemini-cli"
      echo "  Docs: https://github.com/google-gemini/gemini-cli"
      ;;
    copilot)
      echo "Install GitHub Copilot CLI:"
      echo "  npm install -g @github/copilot"
      echo "  Requires: GitHub Copilot subscription"
      echo "  Docs: https://github.com/github/copilot-cli"
      ;;
    opencode)
      echo "Install OpenCode CLI:"
      echo "  npm install -g opencode-ai@latest"
      echo "  or: curl -fsSL https://opencode.ai/install | bash"
      echo "  Docs: https://github.com/opencode-ai/opencode"
      ;;
    *)
      echo "Unknown agent: $agent"
      ;;
  esac
}

# Validate agent and model combination
agent_validate() {
  local agent="$1"
  local model="$2"
  local cmd
  cmd=$(_get_agent_cmd "$agent")

  # Check if agent is known
  if [[ -z "$cmd" ]]; then
    echo "Error: Unknown agent '$agent'" >&2
    echo "Supported agents: $(agent_list_all)" >&2
    return 1
  fi

  # Check if agent is installed
  if ! agent_installed "$agent"; then
    echo "Error: Agent '$agent' is not installed" >&2
    agent_install_instructions "$agent" >&2
    return 1
  fi

  # Check if model is supported (if specified)
  if [[ -n "$model" ]] && ! agent_supports_model "$agent" "$model"; then
    echo "Error: Model '$model' is not supported by agent '$agent'" >&2
    echo "Supported models: $(agent_list_models "$agent")" >&2
    return 1
  fi

  return 0
}

# Print agent status (for doctor command)
agent_status() {
  echo "Agent Status:"
  echo "============="

  for agent in claude codex gemini copilot opencode; do
    local cmd
    cmd=$(_get_agent_cmd "$agent")
    local status="not installed"
    local version=""

    if command -v "$cmd" &>/dev/null; then
      status="installed"
      # Try to get version
      version=$($cmd --version 2>/dev/null | head -1 || echo "")
    fi

    if [[ "$status" == "installed" ]]; then
      echo -e "  ${GREEN:-}✓${NC:-} $agent ($cmd) $version"
    else
      echo -e "  ${RED:-}✗${NC:-} $agent ($cmd) - not installed"
    fi
  done
}
