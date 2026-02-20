#!/usr/bin/env bash
#
# help.sh - Help text for doyaken CLI
#
# Provides: show_help, show_command_help
#

# ============================================================================
# Main Help
# ============================================================================

show_help() {
  cat << EOF
${BOLD}doyaken${NC} - A coding agent that delivers robust, working code

${BOLD}USAGE:${NC}
  doyaken run "<prompt>" [options]

${BOLD}COMMANDS:${NC}
  ${CYAN}run${NC} "<prompt>"     Execute a prompt through the 8-phase pipeline
  ${CYAN}chat${NC}                Interactive chat/REPL mode
  ${CYAN}chat${NC} --resume [id]   Resume a previous session
  ${CYAN}sessions${NC}             List chat sessions
  ${CYAN}init${NC} [path]         Initialize a new project
  ${CYAN}register${NC}            Register current project in global registry
  ${CYAN}unregister${NC}          Remove current project from registry
  ${CYAN}list${NC}                List all registered projects
  ${CYAN}skills${NC}              List available skills
  ${CYAN}skill${NC} <name>        Run a skill
  ${CYAN}config${NC}              Show effective configuration
  ${CYAN}config${NC} edit         Edit global or project config
  ${CYAN}upgrade${NC}             Upgrade doyaken to latest version
  ${CYAN}upgrade${NC} --check     Check if upgrade is available
  ${CYAN}review${NC}              Run codebase review
  ${CYAN}review${NC} --status     Show review status
  ${CYAN}mcp${NC} status          Show MCP integration status
  ${CYAN}mcp${NC} configure       Generate MCP configs for enabled integrations
  ${CYAN}hooks${NC}               List available CLI agent hooks
  ${CYAN}hooks${NC} install       Install hooks to .claude/settings.json
  ${CYAN}sync${NC}                Sync agent files, prompts, skills, and commands
  ${CYAN}commands${NC}            Regenerate slash commands (.claude/commands/)
  ${CYAN}status${NC}              Show project status
  ${CYAN}manifest${NC}            Show project manifest
  ${CYAN}doctor${NC}              Health check and diagnostics
  ${CYAN}cleanup${NC}             Clean logs, state, and registry
  ${CYAN}version${NC}             Show version
  ${CYAN}help${NC} [command]      Show help

${BOLD}OPTIONS:${NC}
  --project <path>    Specify project path (overrides auto-detect)
  --agent <name>      Use specific agent (claude, codex, gemini, copilot, opencode)
  --model <name>      Use specific model (depends on agent)
  --dry-run           Preview without executing
  --verbose           Show detailed output
  --quiet             Minimal output
  --safe-mode         Disable autonomous mode (agents will prompt for confirmation)
  --supervised        Pause between phases for human review
  --plan-only         Stop after plan phase for approval
  --approval <level>  Set approval level (full-auto, supervised, plan-only)
  --no-status-line    Disable persistent status line during execution
  -- <args>           Pass additional arguments to the underlying agent CLI

${BOLD}AGENTS & MODELS:${NC}
  claude (default)    opus, sonnet, haiku, claude-opus-4, claude-sonnet-4
  codex               gpt-5, o3, o4-mini, gpt-5-codex
  gemini              gemini-2.5-pro, gemini-2.5-flash, gemini-3-pro
  copilot             claude-sonnet-4.5, claude-sonnet-4, gpt-5
  opencode            claude-sonnet-4, claude-opus-4, gpt-5, gemini-2.5-pro

${BOLD}AUTONOMOUS MODE FLAGS (automatically applied):${NC}
  claude:   --dangerously-skip-permissions --permission-mode bypassPermissions
  codex:    --dangerously-bypass-approvals-and-sandbox
  gemini:   --yolo
  copilot:  --allow-all-tools --allow-all-paths
  opencode: --auto-approve

${BOLD}EXAMPLES:${NC}
  doyaken run "Add user authentication with JWT"
  doyaken --agent codex run "Fix the login bug"
  doyaken --agent gemini --model gemini-2.5-flash run "Optimize database queries"
  doyaken --project ~/app run "Add health check endpoint"
  doyaken run "Refactor error handling" -- --sandbox read-only

${BOLD}ENVIRONMENT:${NC}
  DOYAKEN_HOME         Global installation directory (default: ~/.doyaken)
  DOYAKEN_PROJECT      Override project detection
  DOYAKEN_AGENT        Default agent (claude, codex, gemini, copilot, opencode)
  DOYAKEN_MODEL        Default model for the agent

EOF
}

# ============================================================================
# Command-Specific Help
# ============================================================================

show_command_help() {
  local cmd="$1"
  case "$cmd" in
    init)
      cat << EOF
${BOLD}doyaken init${NC} - Initialize a new project

${BOLD}USAGE:${NC}
  doyaken init [path]

${BOLD}DESCRIPTION:${NC}
  Creates the .doyaken/ directory structure and generates a project
  manifest from detected git information and project type.

${BOLD}WHAT IT CREATES:${NC}
  .doyaken/
    manifest.yaml       Project configuration (quality gates, retry budgets)
    prompts/library/     Methodology prompts
    prompts/phases/      8-phase workflow prompts
    skills/              Project-specific skills
    logs/                Execution logs
    state/               Session state
  AGENTS.md              AI agent instructions

EOF
      ;;
    run)
      cat << EOF
${BOLD}doyaken run${NC} - Execute a prompt through the 8-phase pipeline

${BOLD}USAGE:${NC}
  doyaken run "<prompt>"

${BOLD}ARGUMENTS:${NC}
  prompt    The task to execute (required)

${BOLD}OPTIONS:${NC}
  --agent <name>    Use specific agent (claude, codex, gemini, copilot, opencode)
  --model <name>    Use specific model
  --dry-run         Preview without executing

${BOLD}PIPELINE:${NC}
  EXPAND -> TRIAGE -> PLAN -> IMPLEMENT -> TEST -> DOCS -> REVIEW -> VERIFY

  After each phase, verification gates run your quality commands.
  If gates fail and the phase has retries remaining, it re-runs
  with error context so the agent can fix the issue.

${BOLD}EXAMPLES:${NC}
  doyaken run "Add user authentication with JWT"
  doyaken run "Fix the login bug in src/auth.ts"
  doyaken --agent codex run "Optimize database queries"

EOF
      ;;
    chat)
      cat << EOF
${BOLD}doyaken chat${NC} - Interactive chat/REPL mode

${BOLD}USAGE:${NC}
  doyaken chat [--resume [id]]

${BOLD}DESCRIPTION:${NC}
  Enters an interactive REPL where you can have a conversation with the
  AI agent. Send messages, use slash commands, and see streaming output.

${BOLD}OPTIONS:${NC}
  --resume          Resume the most recent session
  --resume <id>     Resume a specific session by ID (partial match OK)

${BOLD}SLASH COMMANDS:${NC}
  /help             Show available commands
  /status           Show project and session status
  /sessions         List recent sessions
  /session save     Save current session (optionally with a tag)
  /session resume   Resume a saved session
  /session fork     Fork a session into a new branch
  /session export   Export session as markdown
  /session delete   Delete a session
  /undo             Revert last agent change
  /redo             Re-apply last undone change
  /checkpoint       Show checkpoint history
  /checkpoint save  Create a manual checkpoint
  /restore <n>      Restore to checkpoint number
  /clear            Clear the screen
  /quit             Exit interactive mode (also: /exit, Ctrl+D)

${BOLD}KEYBOARD:${NC}
  Ctrl+C      Cancel running agent operation
  Ctrl+D      Exit interactive mode
  Up/Down     Navigate input history

${BOLD}EXAMPLES:${NC}
  doyaken chat                        # Start interactive session
  dk chat --resume                    # Resume last session
  dk chat --resume 20260210           # Resume session by partial ID
  dk --agent codex chat               # Chat with Codex agent

EOF
      ;;
    sessions)
      cat << EOF
${BOLD}doyaken sessions${NC} - List chat sessions

${BOLD}USAGE:${NC}
  doyaken sessions [limit]

${BOLD}DESCRIPTION:${NC}
  Lists recent chat sessions with their status, message count, and task info.
  Default limit is 20 sessions.

${BOLD}EXAMPLES:${NC}
  doyaken sessions              # List recent sessions
  dk sessions 50                # List up to 50 sessions

EOF
      ;;
    *)
      show_help
      ;;
  esac
}
