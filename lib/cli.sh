#!/usr/bin/env bash
#
# doyaken CLI - Command dispatcher for multi-project AI agent
#
# This is the main entry point for the doyaken CLI. It handles subcommand
# routing, project detection, and delegates to the appropriate handlers.
#
# Aliases: doyaken, dk
#
set -euo pipefail

# ============================================================================
# Global Configuration
# ============================================================================

DOYAKEN_HOME="${DOYAKEN_HOME:-$HOME/.doyaken}"
DOYAKEN_VERSION="1.0.0"

# Source library files
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/registry.sh"
source "$SCRIPT_DIR/agents.sh"
source "$SCRIPT_DIR/skills.sh"
source "$SCRIPT_DIR/mcp.sh"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# ============================================================================
# Logging
# ============================================================================

log_info() { echo -e "${BLUE}[doyaken]${NC} $1"; }
log_success() { echo -e "${GREEN}[doyaken]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[doyaken]${NC} $1"; }
log_error() { echo -e "${RED}[doyaken]${NC} $1" >&2; }

# ============================================================================
# Help
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
  ${CYAN}skills${NC}              List available skills
  ${CYAN}skill${NC} <name>        Run a skill
  ${CYAN}mcp${NC} status          Show MCP integration status
  ${CYAN}mcp${NC} configure       Generate MCP configs for enabled integrations
  ${CYAN}status${NC}              Show project status
  ${CYAN}manifest${NC}            Show project manifest
  ${CYAN}doctor${NC}              Health check and diagnostics
  ${CYAN}version${NC}             Show version
  ${CYAN}help${NC} [command]      Show help

${BOLD}OPTIONS:${NC}
  --project <path>    Specify project path (overrides auto-detect)
  --agent <name>      Use specific agent (claude, codex, gemini, copilot, opencode)
  --model <name>      Use specific model (depends on agent)
  --dry-run           Preview without executing
  --verbose           Show detailed output
  --quiet             Minimal output
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
  doyaken task "Fix the login bug"     # Create and run task immediately
  doyaken run 1 -- --sandbox read-only # Pass extra args to agent

${BOLD}ENVIRONMENT:${NC}
  DOYAKEN_HOME       Global installation directory (default: ~/.doyaken)
  DOYAKEN_PROJECT    Override project detection
  DOYAKEN_AGENT      Default agent (claude, codex, gemini, copilot, opencode)
  DOYAKEN_MODEL      Default model for the agent

EOF
}

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
    *)
      show_help
      ;;
  esac
}

# ============================================================================
# Task Folder Helpers
# ============================================================================

# Get the actual folder path, supporting both old and new naming
get_task_folder() {
  local base_dir="$1"
  local state="$2"
  # Check for new numbered naming first
  case "$state" in
    blocked) [ -d "$base_dir/tasks/1.blocked" ] && echo "$base_dir/tasks/1.blocked" && return ;;
    todo)    [ -d "$base_dir/tasks/2.todo" ] && echo "$base_dir/tasks/2.todo" && return ;;
    doing)   [ -d "$base_dir/tasks/3.doing" ] && echo "$base_dir/tasks/3.doing" && return ;;
    done)    [ -d "$base_dir/tasks/4.done" ] && echo "$base_dir/tasks/4.done" && return ;;
  esac
  # Fall back to old naming
  echo "$base_dir/tasks/$state"
}

# ============================================================================
# Project Detection
# ============================================================================

detect_project() {
  local search_dir="${1:-$(pwd)}"

  # Resolve to absolute path
  search_dir=$(cd "$search_dir" 2>/dev/null && pwd) || {
    log_error "Directory not found: $search_dir"
    return 1
  }

  # Check for .doyaken/ in current directory
  if [ -d "$search_dir/.doyaken" ]; then
    echo "$search_dir"
    return 0
  fi

  # Check for legacy .claude/ directory
  if [ -d "$search_dir/.claude" ]; then
    echo "LEGACY:$search_dir"
    return 0
  fi

  # Walk up the directory tree
  local parent="$search_dir"
  while [ "$parent" != "/" ]; do
    if [ -d "$parent/.doyaken" ]; then
      echo "$parent"
      return 0
    fi
    if [ -d "$parent/.claude" ]; then
      echo "LEGACY:$parent"
      return 0
    fi
    parent=$(dirname "$parent")
  done

  # Check registry for this path
  local found
  found=$(lookup_registry "$search_dir") || true
  if [ -n "$found" ]; then
    echo "$found"
    return 0
  fi

  return 1
}

require_project() {
  local project
  project=$(detect_project) || {
    log_error "Not in an doyaken project"
    log_info "Run 'doyaken init' to initialize this directory"
    exit 1
  }

  if [[ "$project" == LEGACY:* ]]; then
    local legacy_path="${project#LEGACY:}"
    log_error "Legacy .claude/ project detected at $legacy_path"
    log_info "This project uses an old format. Please run 'doyaken init' in a fresh directory."
    exit 1
  else
    echo "$project"
    export DOYAKEN_LEGACY=0
    export DOYAKEN_DIR="$project/.doyaken"
  fi
}

# ============================================================================
# Commands
# ============================================================================

cmd_run() {
  local num_tasks="${1:-5}"
  local project
  project=$(require_project)

  export DOYAKEN_PROJECT="$project"

  # Set agent defaults
  export DOYAKEN_AGENT="${DOYAKEN_AGENT:-claude}"
  export DOYAKEN_MODEL="${DOYAKEN_MODEL:-$(agent_default_model "$DOYAKEN_AGENT")}"

  # Validate agent and model
  if ! agent_validate "$DOYAKEN_AGENT" "$DOYAKEN_MODEL"; then
    exit 1
  fi

  log_info "Running $num_tasks task(s) in: $project"
  log_info "Agent: $DOYAKEN_AGENT (model: $DOYAKEN_MODEL)"

  # Determine which core.sh to use
  local core_script="$DOYAKEN_HOME/lib/core.sh"
  if [ ! -f "$core_script" ]; then
    # Fallback to script directory (for development)
    core_script="$SCRIPT_DIR/core.sh"
  fi

  if [ ! -f "$core_script" ]; then
    log_error "core.sh not found"
    exit 1
  fi

  exec "$core_script" "$num_tasks"
}

cmd_init() {
  local target_dir="${1:-$(pwd)}"

  # Resolve to absolute path
  target_dir=$(cd "$target_dir" 2>/dev/null && pwd) || {
    log_error "Directory not found: $target_dir"
    exit 1
  }

  local ai_agent_dir="$target_dir/.doyaken"

  # Check if already initialized
  if [ -d "$ai_agent_dir" ]; then
    log_warn "Project already initialized at: $target_dir"
    log_info "Use 'doyaken status' to view project info"
    return 0
  fi

  # Check for legacy .claude/
  if [ -d "$target_dir/.claude" ]; then
    log_warn "Legacy .claude/ directory found"
    log_info "Remove .claude/ first or use a different directory"
    return 1
  fi

  log_info "Initializing doyaken project at: $target_dir"

  # Create directory structure
  mkdir -p "$ai_agent_dir/tasks/1.blocked"
  mkdir -p "$ai_agent_dir/tasks/2.todo"
  mkdir -p "$ai_agent_dir/tasks/3.doing"
  mkdir -p "$ai_agent_dir/tasks/4.done"
  mkdir -p "$ai_agent_dir/tasks/_templates"
  mkdir -p "$ai_agent_dir/logs"
  mkdir -p "$ai_agent_dir/state"
  mkdir -p "$ai_agent_dir/locks"

  # Create .gitkeep files
  touch "$ai_agent_dir/tasks/1.blocked/.gitkeep"
  touch "$ai_agent_dir/tasks/2.todo/.gitkeep"
  touch "$ai_agent_dir/tasks/3.doing/.gitkeep"
  touch "$ai_agent_dir/tasks/4.done/.gitkeep"
  touch "$ai_agent_dir/logs/.gitkeep"
  touch "$ai_agent_dir/state/.gitkeep"
  touch "$ai_agent_dir/locks/.gitkeep"

  # Detect git info
  local git_remote=""
  local git_branch="main"
  if [ -d "$target_dir/.git" ]; then
    git_remote=$(git -C "$target_dir" remote get-url origin 2>/dev/null || echo "")
    git_branch=$(git -C "$target_dir" branch --show-current 2>/dev/null || echo "main")
  fi

  # Detect project name
  local project_name
  project_name=$(basename "$target_dir")

  # Generate manifest
  cat > "$ai_agent_dir/manifest.yaml" << EOF
# AI Agent Project Manifest
# Generated: $(date -u +"%Y-%m-%dT%H:%M:%SZ")

version: 1

project:
  name: "$project_name"
  description: ""

# Git configuration (auto-detected)
git:
  remote: "$git_remote"
  branch: "$git_branch"

# Domains and URLs associated with this project
domains:
  # production: "https://example.com"
  # staging: "https://staging.example.com"

# External tool integrations
tools:
  # jira:
  #   enabled: false
  #   project_key: ""
  #   base_url: ""
  # github:
  #   enabled: true
  #   repo: "user/repo"
  # linear:
  #   enabled: false
  #   team_id: ""

# Quality gate commands (auto-detected or configured)
quality:
  test_command: ""
  lint_command: ""
  format_command: ""
  build_command: ""

# Agent behavior settings
agent:
  # Agent to use: claude, codex, gemini, copilot, opencode
  name: "claude"
  # Model depends on agent:
  #   claude: opus, sonnet, haiku
  #   codex: gpt-5, o3, o4-mini
  #   gemini: gemini-2.5-pro, gemini-2.5-flash
  #   copilot: claude-sonnet-4.5, gpt-5
  #   opencode: claude-sonnet-4, gpt-5
  model: "opus"
  max_retries: 2
  parallel_workers: 2
EOF

  log_success "Created manifest.yaml"

  # Copy task template
  local template_src="$DOYAKEN_HOME/templates/TASK.md"
  if [ -f "$template_src" ]; then
    cp "$template_src" "$ai_agent_dir/tasks/_templates/TASK.md"
  else
    # Fallback: create basic template
    cat > "$ai_agent_dir/tasks/_templates/TASK.md" << 'EOF'
# Task: [TITLE]

## Metadata

| Field       | Value                                                  |
| ----------- | ------------------------------------------------------ |
| ID          | `PPP-SSS-slug`                                         |
| Status      | `todo` / `doing` / `done`                              |
| Priority    | `001` Critical / `002` High / `003` Medium / `004` Low |
| Created     | `YYYY-MM-DD HH:MM`                                     |
| Started     |                                                        |
| Completed   |                                                        |
| Blocked By  |                                                        |
| Blocks      |                                                        |
| Assigned To |                                                        |
| Assigned At |                                                        |

---

## Context

Why does this task exist?

---

## Acceptance Criteria

- [ ] Criterion 1
- [ ] Tests written and passing
- [ ] Quality gates pass
- [ ] Changes committed with task reference

---

## Plan

1. Step 1
2. Step 2

---

## Work Log

### YYYY-MM-DD HH:MM - Started

- Initial notes

---

## Notes

---

## Links

EOF
  fi
  log_success "Created task template"

  # Create AGENT.md if it doesn't exist
  if [ ! -f "$target_dir/AGENT.md" ]; then
    local agent_md_src="$DOYAKEN_HOME/templates/AGENT.md"
    if [ -f "$agent_md_src" ]; then
      cp "$agent_md_src" "$target_dir/AGENT.md"
    else
      cat > "$target_dir/AGENT.md" << 'EOF'
# AGENT.md - Project Operating Manual

This file configures how AI agents work on this project.

## Quick Start

```bash
doyaken run 1    # Run 1 task
doyaken tasks    # Show taskboard
doyaken status   # Show project status
```

## Project Configuration

See `.doyaken/manifest.yaml` for project settings.

## Task Management

Tasks are stored in `.doyaken/tasks/`:
- `todo/` - Ready to start
- `doing/` - In progress
- `done/` - Completed

Task files use the format: `PPP-SSS-slug.md`
- PPP = Priority (001=Critical, 002=High, 003=Medium, 004=Low)
- SSS = Sequence within priority

## Quality Gates

Configure in manifest.yaml:
```yaml
quality:
  test_command: "npm test"
  lint_command: "npm run lint"
```

EOF
    fi
    log_success "Created AGENT.md"
  fi

  # Register in global registry
  add_to_registry "$target_dir" "$project_name" "$git_remote"

  log_success "Project initialized successfully!"
  echo ""
  echo "Next steps:"
  echo "  1. Edit .doyaken/manifest.yaml to configure your project"
  echo "  2. Create a task: doyaken tasks new \"My first task\""
  echo "  3. Run the agent: doyaken run 1"
}

cmd_register() {
  local project
  project=$(require_project)

  local project_name
  project_name=$(basename "$project")

  local git_remote=""
  if [ -d "$project/.git" ]; then
    git_remote=$(git -C "$project" remote get-url origin 2>/dev/null || echo "")
  fi

  add_to_registry "$project" "$project_name" "$git_remote"
}

cmd_unregister() {
  local project
  project=$(require_project)

  remove_from_registry "$project"
}

cmd_list() {
  list_projects
}

cmd_tasks() {
  local subcmd="${1:-show}"
  shift || true

  local project
  project=$(require_project)

  case "$subcmd" in
    show|"")
      # Generate and show taskboard
      local taskboard_script="$DOYAKEN_HOME/lib/taskboard.sh"
      if [ ! -f "$taskboard_script" ]; then
        taskboard_script="$SCRIPT_DIR/taskboard.sh"
      fi

      if [ -f "$taskboard_script" ]; then
        DOYAKEN_PROJECT="$project" "$taskboard_script"
        echo ""
        cat "$project/TASKBOARD.md" 2>/dev/null || log_warn "TASKBOARD.md not found"
      else
        # Fallback: simple list
        echo "Tasks in $project:"
        echo ""
        local blocked_dir todo_dir doing_dir done_dir
        blocked_dir=$(get_task_folder "$DOYAKEN_DIR" "blocked")
        todo_dir=$(get_task_folder "$DOYAKEN_DIR" "todo")
        doing_dir=$(get_task_folder "$DOYAKEN_DIR" "doing")
        done_dir=$(get_task_folder "$DOYAKEN_DIR" "done")
        echo "BLOCKED:"
        find "$blocked_dir" -name "*.md" -maxdepth 1 -exec basename {} \; 2>/dev/null || echo "  (none)"
        echo ""
        echo "TODO:"
        find "$todo_dir" -name "*.md" -maxdepth 1 -exec basename {} \; 2>/dev/null || echo "  (none)"
        echo ""
        echo "DOING:"
        find "$doing_dir" -name "*.md" -maxdepth 1 -exec basename {} \; 2>/dev/null || echo "  (none)"
        echo ""
        echo "DONE (recent):"
        find "$done_dir" -name "*.md" -maxdepth 1 -exec basename {} \; 2>/dev/null | head -5 || echo "  (none)"
      fi
      ;;
    new)
      local title="$*"
      if [ -z "$title" ]; then
        log_error "Task title required"
        echo "Usage: doyaken tasks new <title>"
        exit 1
      fi

      # Generate task ID
      local priority="003"
      local sequence
      local todo_count
      local todo_dir
      todo_dir=$(get_task_folder "$DOYAKEN_DIR" "todo")
      todo_count=$(find "$todo_dir" -name "*.md" -maxdepth 1 2>/dev/null | wc -l | tr -d ' ')
      sequence=$(printf "%03d" $((todo_count + 1)))
      local slug
      slug=$(echo "$title" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd 'a-z0-9-' | cut -c1-50)
      local task_id="${priority}-${sequence}-${slug}"
      local task_file="$todo_dir/${task_id}.md"

      local timestamp
      timestamp=$(date '+%Y-%m-%d %H:%M')

      # Create task file
      cat > "$task_file" << EOF
# Task: $title

## Metadata

| Field       | Value                                                  |
| ----------- | ------------------------------------------------------ |
| ID          | \`$task_id\`                                           |
| Status      | \`todo\`                                               |
| Priority    | \`$priority\` Medium                                   |
| Created     | \`$timestamp\`                                         |
| Started     |                                                        |
| Completed   |                                                        |
| Blocked By  |                                                        |
| Blocks      |                                                        |
| Assigned To |                                                        |
| Assigned At |                                                        |

---

## Context

Why does this task exist?

---

## Acceptance Criteria

- [ ] Implement the feature
- [ ] Tests written and passing
- [ ] Quality gates pass
- [ ] Changes committed with task reference

---

## Plan

(To be filled in during planning phase)

---

## Work Log

### $timestamp - Created

- Task created via CLI

---

## Notes

---

## Links

EOF

      log_success "Created task: $task_id"
      echo "  File: $task_file"
      ;;
    *)
      log_error "Unknown tasks subcommand: $subcmd"
      echo "Usage: doyaken tasks [show|new <title>]"
      exit 1
      ;;
  esac
}

# Run a single task immediately (create and execute)
cmd_task() {
  local prompt="$*"
  if [ -z "$prompt" ]; then
    log_error "Task prompt required"
    echo "Usage: doyaken task \"<prompt>\""
    echo ""
    echo "Creates a high-priority task and immediately runs it."
    echo "Use this to work on something specific without managing the backlog."
    exit 1
  fi

  local project
  project=$(require_project)

  export DOYAKEN_PROJECT="$project"

  # Set agent defaults
  export DOYAKEN_AGENT="${DOYAKEN_AGENT:-claude}"
  export DOYAKEN_MODEL="${DOYAKEN_MODEL:-$(agent_default_model "$DOYAKEN_AGENT")}"

  # Validate agent and model
  if ! agent_validate "$DOYAKEN_AGENT" "$DOYAKEN_MODEL"; then
    exit 1
  fi

  # Generate task ID with high priority (002) to run before medium tasks
  local priority="002"
  local sequence
  local timestamp
  timestamp=$(date '+%Y-%m-%d %H:%M')

  # Use timestamp-based sequence to ensure uniqueness
  sequence=$(date '+%H%M%S')

  local slug
  slug=$(echo "$prompt" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd 'a-z0-9-' | cut -c1-50)
  local task_id="${priority}-${sequence}-${slug}"
  local todo_dir
  todo_dir=$(get_task_folder "$DOYAKEN_DIR" "todo")
  local task_file="$todo_dir/${task_id}.md"

  log_info "Creating task: $task_id"

  # Create task file
  cat > "$task_file" << EOF
# Task: $prompt

## Metadata

| Field       | Value                                                  |
| ----------- | ------------------------------------------------------ |
| ID          | \`$task_id\`                                           |
| Status      | \`todo\`                                               |
| Priority    | \`$priority\` High (immediate)                         |
| Created     | \`$timestamp\`                                         |
| Started     |                                                        |
| Completed   |                                                        |
| Blocked By  |                                                        |
| Blocks      |                                                        |
| Assigned To |                                                        |
| Assigned At |                                                        |

---

## Context

Task created via \`doyaken task\` for immediate execution.

Prompt: $prompt

---

## Acceptance Criteria

- [ ] Complete the requested work
- [ ] Tests written and passing (if applicable)
- [ ] Quality gates pass
- [ ] Changes committed with task reference

---

## Plan

(To be filled in during planning phase)

---

## Work Log

### $timestamp - Created

- Task created via CLI for immediate execution
- Prompt: $prompt

---

## Notes

---

## Links

EOF

  log_success "Created task: $task_id"
  echo ""

  # Now run the agent for 1 task
  log_info "Running task with agent: $DOYAKEN_AGENT (model: $DOYAKEN_MODEL)"

  # Determine which core.sh to use
  local core_script="$DOYAKEN_HOME/lib/core.sh"
  if [ ! -f "$core_script" ]; then
    core_script="$SCRIPT_DIR/core.sh"
  fi

  if [ ! -f "$core_script" ]; then
    log_error "core.sh not found"
    exit 1
  fi

  exec "$core_script" 1
}

cmd_status() {
  local project
  project=$(require_project)

  echo ""
  echo -e "${BOLD}Project Status${NC}"
  echo "=============="
  echo ""
  echo "Path: $project"
  echo "Data: $DOYAKEN_DIR"

  if [ "$DOYAKEN_LEGACY" = "1" ]; then
    echo -e "Format: ${YELLOW}Legacy (.claude/)${NC}"
  else
    echo -e "Format: ${GREEN}Current (.doyaken/)${NC}"
  fi

  # Git info
  if [ -d "$project/.git" ]; then
    local branch
    branch=$(git -C "$project" branch --show-current 2>/dev/null || echo "unknown")
    local remote
    remote=$(git -C "$project" remote get-url origin 2>/dev/null || echo "none")
    echo ""
    echo "Git:"
    echo "  Branch: $branch"
    echo "  Remote: $remote"
  fi

  # Task counts
  echo ""
  echo "Tasks:"
  local blocked_dir todo_dir doing_dir done_dir
  blocked_dir=$(get_task_folder "$DOYAKEN_DIR" "blocked")
  todo_dir=$(get_task_folder "$DOYAKEN_DIR" "todo")
  doing_dir=$(get_task_folder "$DOYAKEN_DIR" "doing")
  done_dir=$(get_task_folder "$DOYAKEN_DIR" "done")
  local blocked todo doing done_count
  blocked=$(find "$blocked_dir" -maxdepth 1 -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
  todo=$(find "$todo_dir" -maxdepth 1 -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
  doing=$(find "$doing_dir" -maxdepth 1 -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
  done_count=$(find "$done_dir" -maxdepth 1 -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
  echo "  Blocked: $blocked"
  echo "  Todo:    $todo"
  echo "  Doing:   $doing"
  echo "  Done:    $done_count"

  # Manifest info (if exists)
  local manifest="$DOYAKEN_DIR/manifest.yaml"
  if [ -f "$manifest" ]; then
    echo ""
    echo "Manifest: $manifest"
    if command -v yq &>/dev/null; then
      local name desc
      name=$(yq '.project.name // ""' "$manifest" 2>/dev/null)
      desc=$(yq '.project.description // ""' "$manifest" 2>/dev/null)
      [ -n "$name" ] && echo "  Name: $name"
      [ -n "$desc" ] && [ "$desc" != "\"\"" ] && echo "  Description: $desc"
    fi
  fi
  echo ""
}

cmd_manifest() {
  local project
  project=$(require_project)

  local manifest="$DOYAKEN_DIR/manifest.yaml"

  if [ ! -f "$manifest" ]; then
    log_error "Manifest not found: $manifest"
    log_info "Run 'doyaken init' to create one"
    exit 1
  fi

  cat "$manifest"
}

cmd_doctor() {
  local project
  project=$(detect_project 2>/dev/null) || project=""

  echo ""
  echo -e "${BOLD}Doyaken Health Check${NC}"
  echo "===================="
  echo ""

  local issues=0
  local current_agent="${DOYAKEN_AGENT:-claude}"

  # Check agents
  echo "AI Agents:"
  for agent in claude codex gemini copilot opencode; do
    local cmd
    cmd=$(_get_agent_cmd "$agent")
    if command -v "$cmd" &>/dev/null; then
      if [ "$agent" = "$current_agent" ]; then
        log_success "$agent ($cmd) - ACTIVE"
      else
        log_success "$agent ($cmd)"
      fi
    else
      if [ "$agent" = "$current_agent" ]; then
        log_error "$agent ($cmd) - NOT INSTALLED (selected agent!)"
        agent_install_instructions "$agent"
        ((issues++))
      else
        echo -e "  ${YELLOW}○${NC} $agent ($cmd) - not installed"
      fi
    fi
  done

  # Check timeout command
  if command -v gtimeout &>/dev/null; then
    log_success "Timeout available (gtimeout)"
  elif command -v timeout &>/dev/null; then
    log_success "Timeout available (timeout)"
  else
    log_warn "No timeout command (phases will run without limits)"
    echo "  Install: brew install coreutils (macOS)"
  fi

  # Check yq (optional)
  if command -v yq &>/dev/null; then
    log_success "YAML parser available (yq)"
  else
    log_warn "yq not found (manifest parsing will be limited)"
    echo "  Install: brew install yq"
  fi

  # Check global installation
  echo ""
  echo "Global Installation:"
  if [ -d "$DOYAKEN_HOME" ]; then
    log_success "DOYAKEN_HOME exists: $DOYAKEN_HOME"
  else
    log_warn "DOYAKEN_HOME not found: $DOYAKEN_HOME"
  fi

  # Check project
  echo ""
  echo "Current Project:"
  if [ -n "$project" ]; then
    if [[ "$project" == LEGACY:* ]]; then
      log_warn "Legacy project: ${project#LEGACY:}"
      echo "  Run 'doyaken init' in a new directory instead"
    else
      log_success "Project found: $project"

      # Check project structure (supports both old and new folder naming)
      local ai_agent_dir="$project/.doyaken"
      # Check for numbered folders first, fall back to old naming
      if [ -d "$ai_agent_dir/tasks/1.blocked" ] || [ -d "$ai_agent_dir/tasks/blocked" ]; then
        log_success "  tasks/blocked exists"
      else
        log_warn "  tasks/blocked missing (optional)"
      fi
      if [ -d "$ai_agent_dir/tasks/2.todo" ] || [ -d "$ai_agent_dir/tasks/todo" ]; then
        log_success "  tasks/todo exists"
      else
        log_error "  tasks/todo missing"
      fi
      if [ -d "$ai_agent_dir/tasks/3.doing" ] || [ -d "$ai_agent_dir/tasks/doing" ]; then
        log_success "  tasks/doing exists"
      else
        log_error "  tasks/doing missing"
      fi
      if [ -d "$ai_agent_dir/tasks/4.done" ] || [ -d "$ai_agent_dir/tasks/done" ]; then
        log_success "  tasks/done exists"
      else
        log_error "  tasks/done missing"
      fi
      [ -f "$ai_agent_dir/manifest.yaml" ] && log_success "  manifest.yaml exists" || log_warn "  manifest.yaml missing"
      [ -f "$project/AGENT.md" ] && log_success "  AGENT.md exists" || log_warn "  AGENT.md missing"
    fi
  else
    log_info "Not in a project directory"
  fi

  # Registry info
  echo ""
  echo "Registry:"
  local reg_file="$DOYAKEN_HOME/projects/registry.yaml"
  if [ -f "$reg_file" ]; then
    local project_count
    project_count=$(grep -c "^  - path:" "$reg_file" 2>/dev/null || echo "0")
    log_success "Registry exists with $project_count project(s)"
  else
    log_info "No projects registered yet"
  fi

  echo ""
  if [ "$issues" -gt 0 ]; then
    log_error "$issues critical issue(s) found"
    return 1
  else
    log_success "All checks passed!"
    return 0
  fi
}

cmd_version() {
  echo "doyaken version $DOYAKEN_VERSION"

  # Show installation info
  if [ -f "$DOYAKEN_HOME/VERSION" ]; then
    local installed_version
    installed_version=$(cat "$DOYAKEN_HOME/VERSION")
    echo "Installed: $installed_version"
  fi
}

cmd_skills() {
  echo ""
  echo -e "${BOLD}Available Skills${NC}"
  echo "================"
  echo ""

  local found=false
  while IFS='|' read -r name desc location; do
    [ -z "$name" ] && continue
    found=true
    local loc_tag=""
    [ "$location" = "project" ] && loc_tag=" ${CYAN}[project]${NC}"
    echo -e "  ${GREEN}$name${NC}$loc_tag"
    echo "    $desc"
  done < <(list_skills)

  if [ "$found" = false ]; then
    echo "  No skills found."
    echo ""
    echo "  Skills are prompt templates in:"
    echo "    - \$DOYAKEN_HOME/skills/ (global)"
    echo "    - .doyaken/skills/ (project-specific)"
  fi

  echo ""
  echo "Run a skill: ${CYAN}doyaken skill <name> [--arg=value]${NC}"
  echo "Skill info:  ${CYAN}doyaken skill <name> --info${NC}"
}

cmd_skill() {
  local name="${1:-}"
  shift || true

  if [ -z "$name" ]; then
    log_error "Skill name required"
    echo "Usage: doyaken skill <name> [--arg=value ...]"
    echo "       doyaken skill <name> --info"
    echo ""
    echo "Run 'doyaken skills' to list available skills"
    exit 1
  fi

  # Check for --info flag
  for arg in "$@"; do
    if [ "$arg" = "--info" ]; then
      skill_info "$name"
      return
    fi
  done

  # Detect project (optional for skills)
  local project
  project=$(detect_project 2>/dev/null) || project=""
  if [ -n "$project" ] && [[ "$project" != LEGACY:* ]]; then
    export DOYAKEN_PROJECT="$project"
    export DOYAKEN_DIR="$project/.doyaken"
  fi

  # Set agent defaults
  export DOYAKEN_AGENT="${DOYAKEN_AGENT:-claude}"
  export DOYAKEN_MODEL="${DOYAKEN_MODEL:-$(agent_default_model "$DOYAKEN_AGENT")}"

  run_skill "$name" "$@"
}

cmd_mcp() {
  local subcmd="${1:-status}"
  shift || true

  case "$subcmd" in
    status)
      # Detect project
      local project
      project=$(detect_project 2>/dev/null) || project=""
      if [ -n "$project" ] && [[ "$project" != LEGACY:* ]]; then
        export DOYAKEN_PROJECT="$project"
      fi
      mcp_status
      ;;
    configure)
      local project
      project=$(require_project)
      export DOYAKEN_PROJECT="$project"
      mcp_configure "$@"
      ;;
    doctor)
      local project
      project=$(detect_project 2>/dev/null) || project=""
      if [ -n "$project" ] && [[ "$project" != LEGACY:* ]]; then
        export DOYAKEN_PROJECT="$project"
      fi
      mcp_doctor
      ;;
    *)
      log_error "Unknown mcp subcommand: $subcmd"
      echo "Usage: doyaken mcp [status|configure|doctor]"
      exit 1
      ;;
  esac
}

# ============================================================================
# Main
# ============================================================================

main() {
  # Parse global options
  local project_override=""
  local cmd=""
  local args=()
  local passthrough_args=()
  local parsing_passthrough=false

  while [ $# -gt 0 ]; do
    # Check for -- separator (pass remaining args to agent)
    if [ "$1" = "--" ]; then
      parsing_passthrough=true
      shift
      continue
    fi

    # If we've seen --, collect as passthrough args
    if [ "$parsing_passthrough" = true ]; then
      passthrough_args+=("$1")
      shift
      continue
    fi

    case "$1" in
      --project)
        project_override="$2"
        shift 2
        ;;
      --agent)
        export DOYAKEN_AGENT="$2"
        export DOYAKEN_AGENT_FROM_CLI=1
        shift 2
        ;;
      --model)
        export DOYAKEN_MODEL="$2"
        export DOYAKEN_MODEL_FROM_CLI=1
        shift 2
        ;;
      --dry-run)
        export AGENT_DRY_RUN=1
        shift
        ;;
      --verbose)
        export AGENT_VERBOSE=1
        export AGENT_QUIET=0
        export AGENT_PROGRESS=0
        shift
        ;;
      --quiet)
        export AGENT_QUIET=1
        export AGENT_PROGRESS=0
        shift
        ;;
      --help|-h)
        show_help
        exit 0
        ;;
      --version|-v)
        cmd_version
        exit 0
        ;;
      -*)
        log_error "Unknown option: $1"
        show_help
        exit 1
        ;;
      *)
        if [ -z "$cmd" ]; then
          cmd="$1"
        else
          args+=("$1")
        fi
        shift
        ;;
    esac
  done

  # Export passthrough args for core.sh
  if [ ${#passthrough_args[@]} -gt 0 ]; then
    export DOYAKEN_PASSTHROUGH_ARGS="${passthrough_args[*]}"
  fi

  # Apply project override
  if [ -n "$project_override" ]; then
    export DOYAKEN_PROJECT="$project_override"
  fi

  # Default command is run
  cmd="${cmd:-run}"

  # Dispatch command
  case "$cmd" in
    run)
      cmd_run "${args[@]+"${args[@]}"}"
      ;;
    init)
      cmd_init "${args[@]+"${args[@]}"}"
      ;;
    register)
      cmd_register
      ;;
    unregister)
      cmd_unregister
      ;;
    list)
      cmd_list
      ;;
    tasks)
      cmd_tasks "${args[@]+"${args[@]}"}"
      ;;
    task)
      cmd_task "${args[@]+"${args[@]}"}"
      ;;
    status)
      cmd_status
      ;;
    manifest)
      cmd_manifest
      ;;
    doctor)
      cmd_doctor
      ;;
    skills)
      cmd_skills
      ;;
    skill)
      cmd_skill "${args[@]+"${args[@]}"}"
      ;;
    mcp)
      cmd_mcp "${args[@]+"${args[@]}"}"
      ;;
    version)
      cmd_version
      ;;
    help)
      if [ ${#args[@]} -gt 0 ]; then
        show_command_help "${args[0]}"
      else
        show_help
      fi
      ;;
    *)
      # Check if it's a number (shortcut for run N)
      if [[ "$cmd" =~ ^[0-9]+$ ]]; then
        cmd_run "$cmd"
      else
        log_error "Unknown command: $cmd"
        show_help
        exit 1
      fi
      ;;
  esac
}

# Run main if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
