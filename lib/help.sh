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
${BOLD}doyaken${NC} - Autonomous AI agent for software development

${BOLD}USAGE:${NC}
  doyaken [command] [options]

${BOLD}COMMANDS:${NC}
  ${CYAN}(none)${NC}              Run 5 tasks in auto-detected project
  ${CYAN}run${NC} [N]             Run N tasks (default: 5)
  ${CYAN}init${NC} [path]         Initialize a new project
  ${CYAN}register${NC}            Register current project in global registry
  ${CYAN}unregister${NC}          Remove current project from registry
  ${CYAN}list${NC}                List all registered projects
  ${CYAN}tasks${NC}               Show taskboard
  ${CYAN}tasks new${NC} <title>   Create new task interactively
  ${CYAN}task${NC} "<prompt>"     Create and immediately run a single task
  ${CYAN}add${NC} "<title>"       Alias for 'tasks new'
  ${CYAN}skills${NC}              List available skills
  ${CYAN}skill${NC} <name>        Run a skill
  ${CYAN}config${NC}              Show effective configuration
  ${CYAN}config${NC} edit         Edit global or project config
  ${CYAN}upgrade${NC}             Upgrade doyaken to latest version
  ${CYAN}upgrade${NC} --check     Check if upgrade is available
  ${CYAN}review${NC}              Run periodic codebase review
  ${CYAN}review${NC} --status     Show review status and counter
  ${CYAN}mcp${NC} status          Show MCP integration status
  ${CYAN}mcp${NC} configure       Generate MCP configs for enabled integrations
  ${CYAN}hooks${NC}               List available CLI agent hooks
  ${CYAN}hooks${NC} install       Install hooks to .claude/settings.json
  ${CYAN}sync${NC}                Sync agent files, prompts, skills, and commands
  ${CYAN}commands${NC}            Regenerate slash commands (.claude/commands/)
  ${CYAN}status${NC}              Show project status
  ${CYAN}manifest${NC}            Show project manifest
  ${CYAN}doctor${NC}              Health check and diagnostics
  ${CYAN}cleanup${NC}             Clean locks, logs, state, done tasks, stale doing, registry
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
  doyaken                              # Run 5 tasks in current project
  doyaken run 3                        # Run 3 tasks
  doyaken --agent codex run 1          # Run with OpenAI Codex
  doyaken --agent gemini --model gemini-2.5-flash run 2
  doyaken --project ~/app run 1        # Run 1 task in specific project
  doyaken init                         # Initialize current directory
  doyaken tasks new "Add feature X"    # Create new task
  doyaken add "Fix the bug"            # Shortcut to create task
  doyaken task "Fix the login bug"     # Create and run task immediately
  doyaken run 1 -- --sandbox read-only # Pass extra args to agent

${BOLD}ENVIRONMENT:${NC}
  DOYAKEN_HOME         Global installation directory (default: ~/.doyaken)
  DOYAKEN_PROJECT      Override project detection
  DOYAKEN_AGENT        Default agent (claude, codex, gemini, copilot, opencode)
  DOYAKEN_MODEL        Default model for the agent
  DOYAKEN_AUTO_TIMEOUT Auto-select menu options after N seconds (default: 60)
                       Set to 0 to disable and wait for user input

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
    manifest.yaml       Project metadata
    tasks/1.blocked/    Blocked tasks (waiting on something)
    tasks/2.todo/       Ready-to-start tasks
    tasks/3.doing/      In-progress tasks
    tasks/4.done/       Completed tasks
    tasks/_templates/   Task templates
    logs/               Execution logs
    state/              Session state
    locks/              Lock files
  AGENT.md              Operating manual (if not exists)

EOF
      ;;
    run)
      cat << EOF
${BOLD}doyaken run${NC} - Run tasks with AI agent

${BOLD}USAGE:${NC}
  doyaken run [N]

${BOLD}ARGUMENTS:${NC}
  N    Number of tasks to run (default: 5)

${BOLD}OPTIONS:${NC}
  --agent <name>    Use specific agent (claude, codex, gemini, copilot, opencode)
  --model <name>    Use specific model
  --dry-run         Preview without executing

${BOLD}EXAMPLES:${NC}
  doyaken run           # Run 5 tasks
  doyaken run 1         # Run 1 task
  doyaken run 10        # Run 10 tasks

EOF
      ;;
    tasks)
      cat << EOF
${BOLD}doyaken tasks${NC} - Task management

${BOLD}USAGE:${NC}
  doyaken tasks              Show taskboard
  doyaken tasks new <title>  Create new task

${BOLD}EXAMPLES:${NC}
  doyaken tasks                        # Show taskboard
  doyaken tasks new "Add login page"   # Create new task

EOF
      ;;
    task)
      cat << EOF
${BOLD}doyaken task${NC} - Create and run a task immediately

${BOLD}USAGE:${NC}
  doyaken task "<prompt>"

${BOLD}DESCRIPTION:${NC}
  Creates a high-priority task and immediately runs the AI agent on it.
  Use this for quick one-off tasks without managing the backlog.

${BOLD}EXAMPLES:${NC}
  doyaken task "Fix the login bug"
  doyaken task "Add error handling to the API"

EOF
      ;;
    add)
      cat << EOF
${BOLD}doyaken add${NC} - Create a new task (alias for 'tasks new')

${BOLD}USAGE:${NC}
  doyaken add "<title>"

${BOLD}EXAMPLES:${NC}
  doyaken add "Implement user authentication"
  doyaken add "Fix database connection issue"

EOF
      ;;
    *)
      show_help
      ;;
  esac
}
