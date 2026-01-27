#!/usr/bin/env bash
#
# agents.sh - Multi-agent abstraction layer for doyaken
#
# Supported agents:
#   - claude (default) - Anthropic Claude Code CLI
#   - cursor          - Cursor CLI
#   - codex           - OpenAI Codex CLI
#   - gemini          - Google Gemini CLI
#   - copilot         - GitHub Copilot CLI
#   - opencode        - OpenCode CLI
#
# Each agent runs in fully autonomous mode with permissions bypassed.
#

# Agent registry with default models
# Using declare -A requires bash 4+
if [[ "${BASH_VERSINFO[0]}" -ge 4 ]]; then
  declare -A AGENT_COMMANDS
  AGENT_COMMANDS[claude]="claude"
  AGENT_COMMANDS[cursor]="cursor"
  AGENT_COMMANDS[codex]="codex"
  AGENT_COMMANDS[gemini]="gemini"
  AGENT_COMMANDS[copilot]="copilot"
  AGENT_COMMANDS[opencode]="opencode"

  declare -A AGENT_DEFAULT_MODELS
  AGENT_DEFAULT_MODELS[claude]="opus"
  AGENT_DEFAULT_MODELS[cursor]="claude-sonnet-4"
  AGENT_DEFAULT_MODELS[codex]="gpt-5"
  AGENT_DEFAULT_MODELS[gemini]="gemini-2.5-pro"
  AGENT_DEFAULT_MODELS[copilot]="claude-sonnet-4.5"
  AGENT_DEFAULT_MODELS[opencode]="claude-sonnet-4"

  declare -A AGENT_MODELS
  AGENT_MODELS[claude]="opus sonnet haiku claude-opus-4 claude-sonnet-4 claude-sonnet-4.5"
  AGENT_MODELS[cursor]="claude-sonnet-4 claude-sonnet-4.5 gpt-4o gpt-4o-mini"
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
    cursor) echo "cursor" ;;
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
    cursor) echo "claude-sonnet-4" ;;
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
    cursor) echo "claude-sonnet-4 claude-sonnet-4.5 gpt-4o gpt-4o-mini" ;;
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
  echo "claude cursor codex gemini copilot opencode"
}

# =============================================================================
# Agent-specific autonomous mode flags
# =============================================================================
#
# Each agent has different flags for:
#   1. Skipping permissions/sandbox (autonomous mode)
#   2. Model selection
#   3. Prompt input
#
# References:
#   - Claude: --dangerously-skip-permissions --permission-mode bypassPermissions
#   - Cursor: Uses project rules (.cursor/rules/), no bypass flags
#   - Codex:  --dangerously-bypass-approvals-and-sandbox (or --yolo)
#   - Gemini: --yolo (or --approval-mode=yolo)
#   - Copilot: --allow-all-tools --allow-all-paths
#   - OpenCode: Uses opencode run with --auto-approve
# =============================================================================

# Build base autonomous args for an agent (without model or prompt)
# Usage: agent_autonomous_args <agent>
agent_autonomous_args() {
  local agent="$1"

  case "$agent" in
    claude)
      # Claude Code CLI - full bypass mode
      echo "--dangerously-skip-permissions --permission-mode bypassPermissions"
      ;;
    cursor)
      # Cursor CLI - uses project rules, no autonomous bypass flags
      echo ""
      ;;
    codex)
      # OpenAI Codex CLI - full autonomous mode
      # --dangerously-bypass-approvals-and-sandbox is equivalent to --yolo
      echo "--dangerously-bypass-approvals-and-sandbox"
      ;;
    gemini)
      # Google Gemini CLI - yolo mode for auto-approval
      echo "--yolo"
      ;;
    copilot)
      # GitHub Copilot CLI - allow all tools and paths
      echo "--allow-all-tools --allow-all-paths"
      ;;
    opencode)
      # OpenCode CLI - auto-approve mode
      echo "--auto-approve"
      ;;
    *)
      echo ""
      ;;
  esac
}

# Build model args for an agent
# Usage: agent_model_args <agent> <model>
agent_model_args() {
  local agent="$1"
  local model="$2"

  if [[ -z "$model" ]]; then
    echo ""
    return
  fi

  case "$agent" in
    claude)
      echo "--model $model"
      ;;
    cursor)
      echo "--model $model"
      ;;
    codex)
      echo "-m $model"
      ;;
    gemini)
      echo "-m $model"
      ;;
    copilot)
      echo "-m $model"
      ;;
    opencode)
      # OpenCode uses provider/model format, but we accept just model name
      echo "--model $model"
      ;;
    *)
      echo ""
      ;;
  esac
}

# Build prompt args for an agent
# Usage: agent_prompt_args <agent> <prompt_text>
agent_prompt_args() {
  local agent="$1"
  local prompt="$2"

  case "$agent" in
    claude)
      # Claude uses -p for prompt
      echo "-p"
      ;;
    cursor)
      # Cursor agent takes prompt as positional arg or -p
      echo "-p"
      ;;
    codex)
      # Codex exec takes prompt as positional arg
      echo ""
      ;;
    gemini)
      # Gemini uses -p for prompt
      echo "-p"
      ;;
    copilot)
      # Copilot uses -p or --prompt
      echo "-p"
      ;;
    opencode)
      # OpenCode run takes message as positional
      echo ""
      ;;
    *)
      echo "-p"
      ;;
  esac
}

# Build the execution command for an agent
# Usage: agent_exec_command <agent>
# Returns: The base command (e.g., "codex exec" vs just "codex")
agent_exec_command() {
  local agent="$1"

  case "$agent" in
    cursor)
      # Cursor uses "cursor agent" for AI interactions
      echo "cursor agent"
      ;;
    codex)
      # Codex uses "codex exec" for non-interactive execution
      echo "codex exec"
      ;;
    opencode)
      # OpenCode uses "opencode run" for non-interactive execution
      echo "opencode run"
      ;;
    *)
      # Other agents use just their command name
      _get_agent_cmd "$agent"
      ;;
  esac
}

# Build verbose/output args for an agent (for progress tracking)
# Usage: agent_verbose_args <agent>
agent_verbose_args() {
  local agent="$1"

  case "$agent" in
    claude)
      echo "--output-format stream-json --verbose"
      ;;
    cursor)
      echo ""
      ;;
    codex)
      echo "--verbose"
      ;;
    gemini)
      echo "--verbose"
      ;;
    copilot)
      echo "--verbose"
      ;;
    opencode)
      echo "--print-logs"
      ;;
    *)
      echo ""
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
    cursor)
      echo "Install Cursor CLI:"
      echo "  macOS/Linux: curl https://cursor.com/install -fsS | bash"
      echo "  Windows: irm 'https://cursor.com/install?win32=true' | iex"
      echo "  Docs: https://cursor.com/docs/cli"
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

  for agent in claude cursor codex gemini copilot opencode; do
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

# Print autonomous mode flags for reference
agent_show_flags() {
  local agent="$1"

  echo "Autonomous mode flags for $agent:"
  echo "  Base command: $(agent_exec_command "$agent")"
  echo "  Auto flags:   $(agent_autonomous_args "$agent")"
  echo "  Model flag:   $(agent_model_args "$agent" "<model>")"
  echo "  Prompt flag:  $(agent_prompt_args "$agent")"
  echo "  Verbose:      $(agent_verbose_args "$agent")"
}
