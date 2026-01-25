#!/usr/bin/env bash
#
# ai-agent CLI - Command dispatcher for multi-project AI agent
#
# This is the main entry point for the ai-agent CLI. It handles subcommand
# routing, project detection, and delegates to the appropriate handlers.
#
set -euo pipefail

# ============================================================================
# Global Configuration
# ============================================================================

AI_AGENT_HOME="${AI_AGENT_HOME:-$HOME/.ai-agent}"
AI_AGENT_VERSION="1.0.0"

# Source library files
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/registry.sh"

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

log_info() { echo -e "${BLUE}[ai-agent]${NC} $1"; }
log_success() { echo -e "${GREEN}[ai-agent]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[ai-agent]${NC} $1"; }
log_error() { echo -e "${RED}[ai-agent]${NC} $1" >&2; }

# ============================================================================
# Help
# ============================================================================

show_help() {
  cat << EOF
${BOLD}ai-agent${NC} - Autonomous AI agent for software development

${BOLD}USAGE:${NC}
  ai-agent [command] [options]

${BOLD}COMMANDS:${NC}
  ${CYAN}(none)${NC}              Run 5 tasks in auto-detected project
  ${CYAN}run${NC} [N]             Run N tasks (default: 5)
  ${CYAN}init${NC} [path]         Initialize a new project
  ${CYAN}register${NC}            Register current project in global registry
  ${CYAN}unregister${NC}          Remove current project from registry
  ${CYAN}list${NC}                List all registered projects
  ${CYAN}tasks${NC}               Show taskboard
  ${CYAN}tasks new${NC} <title>   Create new task interactively
  ${CYAN}status${NC}              Show project status
  ${CYAN}manifest${NC}            Show project manifest
  ${CYAN}migrate${NC}             Migrate from .claude/ to .ai-agent/
  ${CYAN}doctor${NC}              Health check and diagnostics
  ${CYAN}version${NC}             Show version
  ${CYAN}help${NC} [command]      Show help

${BOLD}OPTIONS:${NC}
  --project <path>    Specify project path (overrides auto-detect)
  --model <name>      Use specific model (opus, sonnet, haiku)
  --dry-run           Preview without executing
  --verbose           Show detailed output
  --quiet             Minimal output

${BOLD}EXAMPLES:${NC}
  ai-agent                              # Run 5 tasks in current project
  ai-agent run 3                        # Run 3 tasks
  ai-agent --project ~/app run 1        # Run 1 task in specific project
  ai-agent init                         # Initialize current directory
  ai-agent tasks new "Add feature X"    # Create new task

${BOLD}ENVIRONMENT:${NC}
  AI_AGENT_HOME       Global installation directory (default: ~/.ai-agent)
  AI_AGENT_PROJECT    Override project detection
  CLAUDE_MODEL        Default model (opus, sonnet, haiku)

EOF
}

show_command_help() {
  local cmd="$1"
  case "$cmd" in
    init)
      cat << EOF
${BOLD}ai-agent init${NC} - Initialize a new project

${BOLD}USAGE:${NC}
  ai-agent init [path]

${BOLD}DESCRIPTION:${NC}
  Creates the .ai-agent/ directory structure and generates a project
  manifest from detected git information and project type.

${BOLD}WHAT IT CREATES:${NC}
  .ai-agent/
    manifest.yaml       Project metadata
    tasks/todo/         Ready-to-start tasks
    tasks/doing/        In-progress tasks
    tasks/done/         Completed tasks
    tasks/_templates/   Task templates
    logs/               Execution logs
    state/              Session state
    locks/              Lock files
  AI-AGENT.md           Operating manual (if not exists)

EOF
      ;;
    migrate)
      cat << EOF
${BOLD}ai-agent migrate${NC} - Migrate from .claude/ to .ai-agent/

${BOLD}USAGE:${NC}
  ai-agent migrate [path]

${BOLD}DESCRIPTION:${NC}
  Converts a project from the legacy .claude/ structure to the new
  .ai-agent/ structure. This includes:

  - Renaming .claude/ to .ai-agent/
  - Removing embedded agent code (now global)
  - Generating manifest.yaml from git info
  - Renaming CLAUDE.md to AI-AGENT.md
  - Updating bin/agent wrapper (if exists)

${BOLD}IMPORTANT:${NC}
  - Commit all changes before migrating
  - Ensure no tasks are in doing/ state
  - Back up .claude/ directory first

EOF
      ;;
    *)
      show_help
      ;;
  esac
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

  # Check for .ai-agent/ in current directory
  if [ -d "$search_dir/.ai-agent" ]; then
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
    if [ -d "$parent/.ai-agent" ]; then
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
    log_error "Not in an ai-agent project"
    log_info "Run 'ai-agent init' to initialize this directory"
    exit 1
  }

  if [[ "$project" == LEGACY:* ]]; then
    local legacy_path="${project#LEGACY:}"
    log_warn "Legacy .claude/ project detected at $legacy_path"
    log_info "Run 'ai-agent migrate' to upgrade to the new format"
    echo "$legacy_path"
    export AI_AGENT_LEGACY=1
    export AI_AGENT_DIR="$legacy_path/.claude"
  else
    echo "$project"
    export AI_AGENT_LEGACY=0
    export AI_AGENT_DIR="$project/.ai-agent"
  fi
}

# ============================================================================
# Commands
# ============================================================================

cmd_run() {
  local num_tasks="${1:-5}"
  local project
  project=$(require_project)

  export AI_AGENT_PROJECT="$project"

  log_info "Running $num_tasks task(s) in: $project"

  # Determine which core.sh to use
  local core_script="$AI_AGENT_HOME/lib/core.sh"
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

  local ai_agent_dir="$target_dir/.ai-agent"

  # Check if already initialized
  if [ -d "$ai_agent_dir" ]; then
    log_warn "Project already initialized at: $target_dir"
    log_info "Use 'ai-agent status' to view project info"
    return 0
  fi

  # Check for legacy .claude/
  if [ -d "$target_dir/.claude" ]; then
    log_warn "Legacy .claude/ directory found"
    log_info "Run 'ai-agent migrate' to upgrade instead"
    return 1
  fi

  log_info "Initializing ai-agent project at: $target_dir"

  # Create directory structure
  mkdir -p "$ai_agent_dir/tasks/todo"
  mkdir -p "$ai_agent_dir/tasks/doing"
  mkdir -p "$ai_agent_dir/tasks/done"
  mkdir -p "$ai_agent_dir/tasks/_templates"
  mkdir -p "$ai_agent_dir/logs"
  mkdir -p "$ai_agent_dir/state"
  mkdir -p "$ai_agent_dir/locks"

  # Create .gitkeep files
  touch "$ai_agent_dir/tasks/todo/.gitkeep"
  touch "$ai_agent_dir/tasks/doing/.gitkeep"
  touch "$ai_agent_dir/tasks/done/.gitkeep"
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
  model: "opus"
  max_retries: 2
  parallel_workers: 2
EOF

  log_success "Created manifest.yaml"

  # Copy task template
  local template_src="$AI_AGENT_HOME/templates/task.md"
  if [ -f "$template_src" ]; then
    cp "$template_src" "$ai_agent_dir/tasks/_templates/task.md"
  else
    # Fallback: create basic template
    cat > "$ai_agent_dir/tasks/_templates/task.md" << 'EOF'
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

  # Create AI-AGENT.md if it doesn't exist
  if [ ! -f "$target_dir/AI-AGENT.md" ]; then
    local agent_md_src="$AI_AGENT_HOME/templates/ai-agent.md"
    if [ -f "$agent_md_src" ]; then
      cp "$agent_md_src" "$target_dir/AI-AGENT.md"
    else
      cat > "$target_dir/AI-AGENT.md" << 'EOF'
# AI-AGENT.md - Project Operating Manual

This file configures how AI agents work on this project.

## Quick Start

```bash
ai-agent run 1    # Run 1 task
ai-agent tasks    # Show taskboard
ai-agent status   # Show project status
```

## Project Configuration

See `.ai-agent/manifest.yaml` for project settings.

## Task Management

Tasks are stored in `.ai-agent/tasks/`:
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
    log_success "Created AI-AGENT.md"
  fi

  # Register in global registry
  add_to_registry "$target_dir" "$project_name" "$git_remote"

  log_success "Project initialized successfully!"
  echo ""
  echo "Next steps:"
  echo "  1. Edit .ai-agent/manifest.yaml to configure your project"
  echo "  2. Create a task: ai-agent tasks new \"My first task\""
  echo "  3. Run the agent: ai-agent run 1"
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
      local taskboard_script="$AI_AGENT_HOME/lib/taskboard.sh"
      if [ ! -f "$taskboard_script" ]; then
        taskboard_script="$SCRIPT_DIR/taskboard.sh"
      fi

      if [ -f "$taskboard_script" ]; then
        AI_AGENT_PROJECT="$project" "$taskboard_script"
        echo ""
        cat "$project/TASKBOARD.md" 2>/dev/null || log_warn "TASKBOARD.md not found"
      else
        # Fallback: simple list
        echo "Tasks in $project:"
        echo ""
        echo "TODO:"
        ls -1 "$AI_AGENT_DIR/tasks/todo/"*.md 2>/dev/null | xargs -I {} basename {} || echo "  (none)"
        echo ""
        echo "DOING:"
        ls -1 "$AI_AGENT_DIR/tasks/doing/"*.md 2>/dev/null | xargs -I {} basename {} || echo "  (none)"
        echo ""
        echo "DONE (recent):"
        ls -1t "$AI_AGENT_DIR/tasks/done/"*.md 2>/dev/null | head -5 | xargs -I {} basename {} || echo "  (none)"
      fi
      ;;
    new)
      local title="$*"
      if [ -z "$title" ]; then
        log_error "Task title required"
        echo "Usage: ai-agent tasks new <title>"
        exit 1
      fi

      # Generate task ID
      local priority="003"
      local sequence
      sequence=$(printf "%03d" $(($(ls -1 "$AI_AGENT_DIR/tasks/todo/"*.md 2>/dev/null | wc -l | tr -d ' ') + 1)))
      local slug
      slug=$(echo "$title" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd 'a-z0-9-' | cut -c1-50)
      local task_id="${priority}-${sequence}-${slug}"
      local task_file="$AI_AGENT_DIR/tasks/todo/${task_id}.md"

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
      echo "Usage: ai-agent tasks [show|new <title>]"
      exit 1
      ;;
  esac
}

cmd_status() {
  local project
  project=$(require_project)

  echo ""
  echo -e "${BOLD}Project Status${NC}"
  echo "=============="
  echo ""
  echo "Path: $project"
  echo "Data: $AI_AGENT_DIR"

  if [ "$AI_AGENT_LEGACY" = "1" ]; then
    echo -e "Format: ${YELLOW}Legacy (.claude/)${NC}"
  else
    echo -e "Format: ${GREEN}Current (.ai-agent/)${NC}"
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
  local todo doing done_count
  todo=$(find "$AI_AGENT_DIR/tasks/todo" -maxdepth 1 -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
  doing=$(find "$AI_AGENT_DIR/tasks/doing" -maxdepth 1 -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
  done_count=$(find "$AI_AGENT_DIR/tasks/done" -maxdepth 1 -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
  echo "  Todo:  $todo"
  echo "  Doing: $doing"
  echo "  Done:  $done_count"

  # Manifest info (if exists)
  local manifest="$AI_AGENT_DIR/manifest.yaml"
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

  local manifest="$AI_AGENT_DIR/manifest.yaml"

  if [ ! -f "$manifest" ]; then
    log_error "Manifest not found: $manifest"
    log_info "Run 'ai-agent init' to create one"
    exit 1
  fi

  cat "$manifest"
}

cmd_migrate() {
  local target_dir="${1:-$(pwd)}"

  # Resolve to absolute path
  target_dir=$(cd "$target_dir" 2>/dev/null && pwd) || {
    log_error "Directory not found: $target_dir"
    exit 1
  }

  source "$SCRIPT_DIR/migration.sh"
  migrate_project "$target_dir"
}

cmd_doctor() {
  local project
  project=$(detect_project 2>/dev/null) || project=""

  echo ""
  echo -e "${BOLD}AI Agent Health Check${NC}"
  echo "====================="
  echo ""

  local issues=0

  # Check Claude CLI
  if command -v claude &>/dev/null; then
    log_success "Claude CLI installed"
  else
    log_error "Claude CLI not found"
    echo "  Install from: https://claude.ai/cli"
    ((issues++))
  fi

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
  if [ -d "$AI_AGENT_HOME" ]; then
    log_success "AI_AGENT_HOME exists: $AI_AGENT_HOME"
  else
    log_warn "AI_AGENT_HOME not found: $AI_AGENT_HOME"
  fi

  # Check project
  echo ""
  echo "Current Project:"
  if [ -n "$project" ]; then
    if [[ "$project" == LEGACY:* ]]; then
      log_warn "Legacy project: ${project#LEGACY:}"
      echo "  Run 'ai-agent migrate' to upgrade"
    else
      log_success "Project found: $project"

      # Check project structure
      local ai_agent_dir="$project/.ai-agent"
      [ -d "$ai_agent_dir/tasks/todo" ] && log_success "  tasks/todo/ exists" || log_error "  tasks/todo/ missing"
      [ -d "$ai_agent_dir/tasks/doing" ] && log_success "  tasks/doing/ exists" || log_error "  tasks/doing/ missing"
      [ -d "$ai_agent_dir/tasks/done" ] && log_success "  tasks/done/ exists" || log_error "  tasks/done/ missing"
      [ -f "$ai_agent_dir/manifest.yaml" ] && log_success "  manifest.yaml exists" || log_warn "  manifest.yaml missing"
      [ -f "$project/AI-AGENT.md" ] && log_success "  AI-AGENT.md exists" || log_warn "  AI-AGENT.md missing"
    fi
  else
    log_info "Not in a project directory"
  fi

  # Registry info
  echo ""
  echo "Registry:"
  local reg_file="$AI_AGENT_HOME/projects/registry.yaml"
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
  echo "ai-agent version $AI_AGENT_VERSION"

  # Show installation info
  if [ -f "$AI_AGENT_HOME/VERSION" ]; then
    local installed_version
    installed_version=$(cat "$AI_AGENT_HOME/VERSION")
    echo "Installed: $installed_version"
  fi
}

# ============================================================================
# Main
# ============================================================================

main() {
  # Parse global options
  local project_override=""
  local cmd=""
  local args=()

  while [ $# -gt 0 ]; do
    case "$1" in
      --project)
        project_override="$2"
        shift 2
        ;;
      --model)
        export CLAUDE_MODEL="$2"
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

  # Apply project override
  if [ -n "$project_override" ]; then
    export AI_AGENT_PROJECT="$project_override"
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
    status)
      cmd_status
      ;;
    manifest)
      cmd_manifest
      ;;
    migrate)
      cmd_migrate "${args[@]+"${args[@]}"}"
      ;;
    doctor)
      cmd_doctor
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
