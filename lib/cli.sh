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

# Get version from VERSION file or package.json (fallback to unknown if not found)
DOYAKEN_VERSION="unknown"
if [ -f "$(dirname "${BASH_SOURCE[0]}")/../VERSION" ]; then
  DOYAKEN_VERSION=$(cat "$(dirname "${BASH_SOURCE[0]}")/../VERSION")
elif [ -f "$DOYAKEN_HOME/VERSION" ]; then
  DOYAKEN_VERSION=$(cat "$DOYAKEN_HOME/VERSION")
elif [ -f "$(dirname "${BASH_SOURCE[0]}")/../package.json" ]; then
  DOYAKEN_VERSION=$(grep '"version"' "$(dirname "${BASH_SOURCE[0]}")/../package.json" | head -1 | sed 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
fi

# Source library files
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"
source "$SCRIPT_DIR/help.sh"
source "$SCRIPT_DIR/project.sh"
source "$SCRIPT_DIR/registry.sh"
source "$SCRIPT_DIR/agents.sh"
source "$SCRIPT_DIR/skills.sh"
source "$SCRIPT_DIR/mcp.sh"
source "$SCRIPT_DIR/hooks.sh"
source "$SCRIPT_DIR/config.sh"
source "$SCRIPT_DIR/upgrade.sh"
source "$SCRIPT_DIR/review-tracker.sh"
source "$SCRIPT_DIR/interactive.sh"

# ============================================================================
# Commands
# ============================================================================

cmd_run() {
  local num_tasks="${1:-5}"

  # Validate task count early
  if ! [[ "$num_tasks" =~ ^[0-9]+$ ]] || [ "$num_tasks" -lt 1 ]; then
    log_error "Invalid task count: $num_tasks"
    echo "Usage: doyaken run [N]  (where N is a positive number)"
    exit 1
  fi

  local project
  project=$(require_project)

  export DOYAKEN_PROJECT="$project"
  export DOYAKEN_DIR="$project/.doyaken"

  # Set agent defaults
  export DOYAKEN_AGENT="${DOYAKEN_AGENT:-claude}"
  export DOYAKEN_MODEL="${DOYAKEN_MODEL:-$(agent_default_model "$DOYAKEN_AGENT")}"

  # Validate agent and model
  if ! agent_validate "$DOYAKEN_AGENT" "$DOYAKEN_MODEL"; then
    exit 1
  fi

  # Check if there are any tasks to run
  local todo_dir doing_dir
  todo_dir=$(get_task_folder "$DOYAKEN_DIR" "todo")
  doing_dir=$(get_task_folder "$DOYAKEN_DIR" "doing")
  local todo_count doing_count
  todo_count=$(count_task_files "$todo_dir")
  doing_count=$(count_task_files "$doing_dir")

  if [ "$todo_count" -eq 0 ] && [ "$doing_count" -eq 0 ]; then
    # No tasks available - show interactive menu
    show_no_tasks_menu "$project"
    return $?
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

cmd_chat() {
  # Detect project (optional for chat mode)
  local project
  project=$(detect_project 2>/dev/null) || project=""
  if [ -n "$project" ] && [[ "$project" != LEGACY:* ]]; then
    export DOYAKEN_PROJECT="$project"
    export DOYAKEN_DIR="$project/.doyaken"
  fi

  # Set agent defaults
  export DOYAKEN_AGENT="${DOYAKEN_AGENT:-claude}"
  export DOYAKEN_MODEL="${DOYAKEN_MODEL:-$(agent_default_model "$DOYAKEN_AGENT")}"

  # Validate agent
  if ! agent_validate "$DOYAKEN_AGENT" "$DOYAKEN_MODEL"; then
    exit 1
  fi

  # Enter the REPL
  run_repl
}

# Show menu when no tasks are available
show_no_tasks_menu() {
  local project="$1"

  echo ""
  echo -e "${BOLD}No tasks in backlog${NC}"
  echo ""
  echo "What would you like to do?"
  echo ""
  echo -e "  ${CYAN}1${NC}) ${GREEN}Code Review${NC} - Comprehensive review of the codebase"
  echo "     Analyze architecture, code quality, security, and suggest improvements"
  echo ""
  echo -e "  ${CYAN}2${NC}) ${GREEN}Feature Discovery${NC} - Research and suggest the next best feature"
  echo "     Analyze competitors, industry trends, and identify opportunities"
  echo ""
  echo -e "  ${CYAN}3${NC}) ${GREEN}Create Task${NC} - Create a new task manually"
  echo "     Use: doyaken tasks new \"<description>\""
  echo ""
  echo -e "  ${CYAN}4${NC}) ${GREEN}Quick Task${NC} - Create and immediately run a task"
  echo "     Use: doyaken task \"<prompt>\""
  echo ""
  echo -e "  ${CYAN}q${NC}) Quit"
  echo ""

  local choice
  # Auto-timeout only selects from options 1-2 (Code Review, Feature Discovery)
  # Options 3-4 require user input and are not suitable for auto-selection
  read_with_timeout choice "Enter choice [1-4, q]: " 1 2

  case "$choice" in
    1)
      run_code_review "$project"
      ;;
    2)
      run_feature_discovery "$project"
      ;;
    3)
      echo ""
      local title
      read -rp "Task title: " title
      if [ -n "$title" ]; then
        cmd_tasks "new" "$title"
      else
        log_warn "No title provided"
      fi
      ;;
    4)
      echo ""
      local prompt
      read -rp "Task prompt: " prompt
      if [ -n "$prompt" ]; then
        cmd_task "$prompt"
      else
        log_warn "No prompt provided"
      fi
      ;;
    q|Q|"")
      log_info "Exiting"
      return 0
      ;;
    *)
      log_warn "Invalid choice: $choice"
      return 1
      ;;
  esac
}

# Run comprehensive code review using skills
run_code_review() {
  local project="$1"

  echo ""
  echo -e "${BOLD}Code Review Options${NC}"
  echo ""
  echo -e "  ${CYAN}1${NC}) Full codebase review (architecture, quality, security)"
  echo -e "  ${CYAN}2${NC}) Security audit only"
  echo -e "  ${CYAN}3${NC}) Performance analysis"
  echo -e "  ${CYAN}4${NC}) Code quality & technical debt"
  echo -e "  ${CYAN}5${NC}) Review specific directory/module"
  echo ""

  local choice
  # Auto-timeout selects from options 1-4 (option 5 requires path input)
  read_with_timeout choice "Enter choice [1-5]: " 1 2 3 4

  local skill_name skill_args
  case "$choice" in
    1)
      skill_name="review-codebase"
      skill_args="--scope=full"
      ;;
    2)
      skill_name="audit-security"
      skill_args=""
      ;;
    3)
      skill_name="audit-performance"
      skill_args=""
      ;;
    4)
      skill_name="audit-debt"
      skill_args=""
      ;;
    5)
      echo ""
      local target_path
      read -rp "Path to review (relative to project root): " target_path
      skill_name="review-codebase"
      skill_args="--scope=path --path=$target_path"
      ;;
    *)
      log_warn "Invalid choice"
      return 1
      ;;
  esac

  echo ""
  log_info "Running skill: $skill_name $skill_args"
  echo ""

  # Run the skill
  run_skill "$skill_name" $skill_args
}

# Run feature discovery using skills
run_feature_discovery() {
  local project="$1"

  echo ""
  echo -e "${BOLD}Feature Discovery${NC}"
  echo ""
  echo "This will analyze the project and research opportunities for new features."
  echo ""
  echo -e "  ${CYAN}1${NC}) Full discovery (competitors, trends, user needs)"
  echo -e "  ${CYAN}2${NC}) Competitor analysis only"
  echo -e "  ${CYAN}3${NC}) Missing features analysis (based on project type)"
  echo -e "  ${CYAN}4${NC}) User experience improvements"
  echo ""

  local choice
  # All options 1-4 are suitable for auto-selection
  read_with_timeout choice "Enter choice [1-4]: " 1 2 3 4

  local skill_name skill_args
  case "$choice" in
    1)
      skill_name="research-features"
      skill_args="--scope=full"
      ;;
    2)
      skill_name="research-features"
      skill_args="--scope=competitors"
      ;;
    3)
      skill_name="research-features"
      skill_args="--scope=gaps"
      ;;
    4)
      skill_name="audit-ux"
      skill_args="--focus=full"
      ;;
    *)
      log_warn "Invalid choice"
      return 1
      ;;
  esac

  echo ""
  log_info "Running skill: $skill_name $skill_args"
  echo ""

  # Run the skill
  run_skill "$skill_name" $skill_args
}

# Generate slash commands for Claude Code
# Creates .claude/commands/ directory with commands that invoke skills
generate_slash_commands() {
  local target_dir="$1"
  local commands_dir="$target_dir/.claude/commands"

  mkdir -p "$commands_dir"

  # Generate commands from skills
  local skills_dir="$DOYAKEN_HOME/skills"
  if [ -d "$skills_dir" ]; then
    for skill_file in "$skills_dir"/*.md; do
      [ -f "$skill_file" ] || continue
      [ "$(basename "$skill_file")" = "README.md" ] && continue

      local name
      name=$(basename "$skill_file" .md)

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
      [ -z "$description" ] && description="Run the $name skill"

      # Create command file that invokes the skill
      cat > "$commands_dir/${name}.md" << EOF
---
description: $description
---

Run the doyaken skill: $name

\`\`\`bash
doyaken skill $name \$ARGUMENTS
\`\`\`

If doyaken is not available, apply this methodology:

$(tail -n +$(awk '/^---$/{count++; if(count==2){print NR; exit}}' "$skill_file") "$skill_file")
EOF
    done
  fi

  # Generate commands from library prompts (direct access)
  local library_dir="$DOYAKEN_HOME/prompts/library"
  if [ -d "$library_dir" ]; then
    for prompt_file in "$library_dir"/*.md; do
      [ -f "$prompt_file" ] || continue
      [ "$(basename "$prompt_file")" = "README.md" ] && continue

      local name
      name=$(basename "$prompt_file" .md)

      # Create command that loads the library prompt directly
      cat > "$commands_dir/${name}.md" << EOF
---
description: Apply $name methodology
---

$(cat "$prompt_file")

---

Apply this methodology to the current context. If given a specific file or code, analyze it according to these guidelines.
EOF
    done
  fi

  log_success "Generated slash commands (.claude/commands/)"
}

# ============================================================================
# Init Helper Functions
# ============================================================================

# Create .doyaken directory structure
# Usage: init_directories "target_dir"
init_directories() {
  local target_dir="$1"
  local ai_agent_dir="$target_dir/.doyaken"

  mkdir -p "$ai_agent_dir/tasks/1.blocked"
  mkdir -p "$ai_agent_dir/tasks/2.todo"
  mkdir -p "$ai_agent_dir/tasks/3.doing"
  mkdir -p "$ai_agent_dir/tasks/4.done"
  mkdir -p "$ai_agent_dir/tasks/_templates"
  mkdir -p "$ai_agent_dir/logs"
  chmod 700 "$ai_agent_dir/logs"
  mkdir -p "$ai_agent_dir/state"
  chmod 700 "$ai_agent_dir/state"
  mkdir -p "$ai_agent_dir/locks"
  chmod 700 "$ai_agent_dir/locks"

  touch "$ai_agent_dir/tasks/1.blocked/.gitkeep"
  touch "$ai_agent_dir/tasks/2.todo/.gitkeep"
  touch "$ai_agent_dir/tasks/3.doing/.gitkeep"
  touch "$ai_agent_dir/tasks/4.done/.gitkeep"
  touch "$ai_agent_dir/logs/.gitkeep"
  touch "$ai_agent_dir/state/.gitkeep"
  touch "$ai_agent_dir/locks/.gitkeep"
}

# Create manifest.yaml with project configuration
# Usage: init_manifest "target_dir" "project_name" "git_remote" "git_branch"
init_manifest() {
  local target_dir="$1"
  local project_name="$2"
  local git_remote="${3:-}"
  local git_branch="${4:-main}"
  local ai_agent_dir="$target_dir/.doyaken"

  cat > "$ai_agent_dir/manifest.yaml" << EOF
# AI Agent Project Manifest
# Generated: $(date -u +"%Y-%m-%dT%H:%M:%SZ")

version: 1

project:
  name: "$project_name"
  description: ""

git:
  remote: "$git_remote"
  branch: "$git_branch"

domains: {}

tools: {}

quality:
  test_command: ""
  lint_command: ""
  format_command: ""
  build_command: ""

agent:
  name: "claude"
  model: "opus"
  max_retries: 2
  parallel_workers: 2
EOF

  log_success "Created manifest.yaml"
}

# Copy or create task template
# Usage: init_task_template "target_dir"
init_task_template() {
  local target_dir="$1"
  local ai_agent_dir="$target_dir/.doyaken"
  local template_src="$DOYAKEN_HOME/templates/TASK.md"

  if [ -f "$template_src" ]; then
    cp "$template_src" "$ai_agent_dir/tasks/_templates/TASK.md"
  else
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
}

# Copy doyaken README to project
# Usage: init_readme "target_dir"
init_readme() {
  local target_dir="$1"
  local ai_agent_dir="$target_dir/.doyaken"
  local readme_src="$DOYAKEN_HOME/README.md"

  if [ ! -f "$readme_src" ]; then
    readme_src="$(dirname "$SCRIPT_DIR")/README.md"
  fi

  if [ -f "$readme_src" ]; then
    cp "$readme_src" "$ai_agent_dir/README.md"
    log_success "Copied doyaken README to .doyaken/"
  fi
}

# Sync agent configuration files (AGENTS.md, CLAUDE.md, etc.)
# Usage: init_agent_files "target_dir"
init_agent_files() {
  local target_dir="$1"
  local sync_script="$DOYAKEN_HOME/scripts/sync-agent-files.sh"

  if [ ! -f "$sync_script" ]; then
    sync_script="$SCRIPT_DIR/../scripts/sync-agent-files.sh"
  fi

  if [ -f "$sync_script" ]; then
    "$sync_script" "$target_dir"
  else
    log_warn "sync-agent-files.sh not found - manually copy agent templates"
  fi
}

# Show post-init instructions
# Usage: show_init_success
show_init_success() {
  log_success "Project initialized successfully!"
  echo ""
  echo "Next steps:"
  echo "  1. Edit .doyaken/manifest.yaml to configure your project"
  echo "  2. Create a task: doyaken tasks new \"My first task\""
  echo "  3. Run the agent: doyaken run 1"
  echo ""
  echo "Slash commands available:"
  echo "  /workflow    - Run 8-phase workflow"
  echo "  /code-review - Perform code review"
  echo "  /security    - Security checklist"
  echo "  /testing     - Testing methodology"
  echo "  (and more - see .claude/commands/)"
}

# ============================================================================
# Init Command
# ============================================================================

cmd_init() {
  local target_dir="${1:-$(pwd)}"
  target_dir=$(cd "$target_dir" 2>/dev/null && pwd) || {
    log_error "Directory not found: $target_dir"; exit 1
  }

  # Check if already initialized
  if [ -d "$target_dir/.doyaken" ]; then
    log_warn "Project already initialized at: $target_dir"
    log_info "Use 'doyaken status' to view project info"; return 0
  fi

  # Check for legacy .claude/
  if [ -d "$target_dir/.claude" ]; then
    log_warn "Legacy .claude/ directory found"
    log_info "Remove .claude/ first or use a different directory"; return 1
  fi

  log_info "Initializing doyaken project at: $target_dir"

  # Detect git info
  local git_remote="" git_branch="main"
  if [ -d "$target_dir/.git" ]; then
    git_remote=$(git -C "$target_dir" remote get-url origin 2>/dev/null || echo "")
    git_branch=$(git -C "$target_dir" branch --show-current 2>/dev/null || echo "main")
  fi
  local project_name
  project_name=$(basename "$target_dir")

  # Run init steps
  init_directories "$target_dir"
  init_manifest "$target_dir" "$project_name" "$git_remote" "$git_branch"
  init_task_template "$target_dir"
  init_readme "$target_dir"
  init_agent_files "$target_dir"
  generate_slash_commands "$target_dir"

  # Register in global registry (non-fatal if yq missing)
  add_to_registry "$target_dir" "$project_name" "$git_remote" || {
    log_warn "Could not register project (yq required for registry)"
    log_info "Project will work, but won't appear in 'dk projects'"
  }
  show_init_success
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

cmd_cleanup() {
  local project
  project=$(require_project)

  local doyaken_dir="$project/.doyaken"
  local total_cleaned=0

  echo "Cleaning up project: $(basename "$project")"
  echo ""

  # Clean locks
  if [ -d "$doyaken_dir/locks" ]; then
    local lock_count
    lock_count=$(count_files_excluding_gitkeep "$doyaken_dir/locks")
    if [ "$lock_count" -gt 0 ]; then
      find "$doyaken_dir/locks" -type f ! -name '.gitkeep' -delete
      echo "  ${GREEN}✓${NC} Removed $lock_count lock file(s)"
      total_cleaned=$((total_cleaned + lock_count))
    fi
  fi

  # Clean logs
  if [ -d "$doyaken_dir/logs" ]; then
    local log_count
    log_count=$(count_files_excluding_gitkeep "$doyaken_dir/logs")
    if [ "$log_count" -gt 0 ]; then
      find "$doyaken_dir/logs" -type f ! -name '.gitkeep' -delete
      echo "  ${GREEN}✓${NC} Removed $log_count log file(s)"
      total_cleaned=$((total_cleaned + log_count))
    fi
  fi

  # Clean state
  if [ -d "$doyaken_dir/state" ]; then
    local state_count
    state_count=$(count_files_excluding_gitkeep "$doyaken_dir/state")
    if [ "$state_count" -gt 0 ]; then
      find "$doyaken_dir/state" -type f ! -name '.gitkeep' -delete
      echo "  ${GREEN}✓${NC} Removed $state_count state file(s)"
      total_cleaned=$((total_cleaned + state_count))
    fi
  fi

  # Clean done tasks
  if [ -d "$doyaken_dir/tasks/4.done" ]; then
    local done_count
    done_count=$(count_files_excluding_gitkeep "$doyaken_dir/tasks/4.done")
    if [ "$done_count" -gt 0 ]; then
      find "$doyaken_dir/tasks/4.done" -type f ! -name '.gitkeep' -delete
      echo "  ${GREEN}✓${NC} Removed $done_count completed task(s)"
      total_cleaned=$((total_cleaned + done_count))
    fi
  fi

  # Move stale "doing" tasks back to todo (older than 24 hours)
  if [ -d "$doyaken_dir/tasks/3.doing" ]; then
    local stale_count=0
    local now
    now=$(date +%s)
    while IFS= read -r task_file; do
      [ -z "$task_file" ] && continue
      local mtime
      # Get modification time in seconds since epoch (works on macOS and Linux)
      if stat -f %m "$task_file" &>/dev/null; then
        mtime=$(stat -f %m "$task_file")  # macOS
      else
        mtime=$(stat -c %Y "$task_file")  # Linux
      fi
      local age=$((now - mtime))
      # 24 hours = 86400 seconds
      if [ "$age" -gt 86400 ]; then
        mv "$task_file" "$doyaken_dir/tasks/2.todo/"
        stale_count=$((stale_count + 1))
      fi
    done < <(find "$doyaken_dir/tasks/3.doing" -maxdepth 1 -name "*.md" -type f 2>/dev/null)
    if [ "$stale_count" -gt 0 ]; then
      echo "  ${GREEN}✓${NC} Moved $stale_count stale task(s) back to todo"
      total_cleaned=$((total_cleaned + stale_count))
    fi
  fi

  # Clean temp files in scratchpad if it exists
  local scratchpad_dir="$doyaken_dir/scratchpad"
  if [ -d "$scratchpad_dir" ]; then
    local scratch_count
    scratch_count=$(find "$scratchpad_dir" -type f 2>/dev/null | wc -l | tr -d ' ')
    if [ "$scratch_count" -gt 0 ]; then
      rm -rf "${scratchpad_dir:?}"/*
      echo "  ${GREEN}✓${NC} Removed $scratch_count scratchpad file(s)"
      total_cleaned=$((total_cleaned + scratch_count))
    fi
  fi

  # Prune orphaned projects from registry
  local pruned
  pruned=$(prune_registry 2>/dev/null) || pruned=0
  if [ "$pruned" -gt 0 ]; then
    echo "  ${GREEN}✓${NC} Pruned $pruned orphaned project(s) from registry"
    total_cleaned=$((total_cleaned + pruned))
  fi

  echo ""
  if [ "$total_cleaned" -gt 0 ]; then
    echo "Cleaned up $total_cleaned item(s)"
  else
    echo "Nothing to clean up"
  fi
}

cmd_list() {
  list_projects
}

cmd_tasks() {
  local subcmd="${1:-show}"
  shift || true

  local project
  project=$(require_project)
  local doyaken_dir="$project/.doyaken"

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
        blocked_dir=$(get_task_folder "$doyaken_dir" "blocked")
        todo_dir=$(get_task_folder "$doyaken_dir" "todo")
        doing_dir=$(get_task_folder "$doyaken_dir" "doing")
        done_dir=$(get_task_folder "$doyaken_dir" "done")
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
      local todo_dir
      todo_dir=$(get_task_folder "$doyaken_dir" "todo")
      local todo_count
      todo_count=$(count_task_files "$todo_dir")
      local sequence
      sequence=$(printf "%03d" $((todo_count + 1)))
      local slug
      slug=$(echo "$title" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd 'a-z0-9-' | cut -c1-50)
      local task_id="${priority}-${sequence}-${slug}"

      # Create task file using helper
      local task_file
      task_file=$(create_task_file "$task_id" "$title" "$priority" "Medium" "$todo_dir")

      log_success "Created task: $task_id"
      echo "  File: $task_file"
      ;;
    view)
      local task_pattern="$*"
      if [ -z "$task_pattern" ]; then
        log_error "Task ID or pattern required"
        echo "Usage: doyaken tasks view <task-id-pattern>"
        exit 1
      fi

      # Search all task directories for matching file
      local task_file=""
      local blocked_dir todo_dir doing_dir done_dir
      blocked_dir=$(get_task_folder "$doyaken_dir" "blocked")
      todo_dir=$(get_task_folder "$doyaken_dir" "todo")
      doing_dir=$(get_task_folder "$doyaken_dir" "doing")
      done_dir=$(get_task_folder "$doyaken_dir" "done")

      for dir in "$doing_dir" "$todo_dir" "$blocked_dir" "$done_dir"; do
        local found
        found=$(find "$dir" -maxdepth 1 -name "*${task_pattern}*.md" 2>/dev/null | head -1)
        if [ -n "$found" ]; then
          task_file="$found"
          break
        fi
      done

      if [ -z "$task_file" ]; then
        log_error "No task found matching: $task_pattern"
        exit 1
      fi

      cat "$task_file"
      ;;
    *)
      log_error "Unknown tasks subcommand: $subcmd"
      echo "Usage: doyaken tasks [show|new <title>|view <task-id>]"
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

  # Check for common mistakes - user might mean a different command
  local first_word="${prompt%% *}"
  case "$first_word" in
    list|ls)
      log_warn "Did you mean 'dk tasks' to see the taskboard?"
      echo "  dk tasks        - Show taskboard"
      echo "  dk tasks new    - Create a new task"
      echo "  dk task \"...\"   - Create AND run a task immediately"
      exit 1
      ;;
    show|view|get)
      log_warn "To view a task, open the file directly:"
      echo "  cat .doyaken/tasks/2.todo/<task-id>.md"
      echo ""
      echo "Or use 'dk tasks' to see all tasks."
      exit 1
      ;;
    new|add|create)
      log_warn "Did you mean 'dk tasks new \"${prompt#* }\"'?"
      echo "  dk tasks new    - Create a task (without running)"
      echo "  dk task \"...\"   - Create AND run immediately"
      exit 1
      ;;
    delete|remove|rm)
      log_warn "To delete a task, remove the file:"
      echo "  rm .doyaken/tasks/2.todo/<task-id>.md"
      exit 1
      ;;
  esac

  local project
  project=$(require_project)
  local doyaken_dir="$project/.doyaken"

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
  # Use timestamp-based sequence to ensure uniqueness
  local sequence
  sequence=$(date '+%H%M%S')
  local slug
  slug=$(echo "$prompt" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd 'a-z0-9-' | cut -c1-50)
  local task_id="${priority}-${sequence}-${slug}"
  local todo_dir
  todo_dir=$(get_task_folder "$doyaken_dir" "todo")

  log_info "Creating task: $task_id"

  # Create task file using helper with custom context
  local context="Task created via \`doyaken task\` for immediate execution.

Prompt: $prompt"
  local task_file
  task_file=$(create_task_file "$task_id" "$prompt" "$priority" "High (immediate)" "$todo_dir" "$context")

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
  local doyaken_dir="$project/.doyaken"

  echo ""
  echo -e "${BOLD}Project Status${NC}"
  echo "=============="
  echo ""
  echo "Path: $project"
  echo "Data: $doyaken_dir"

  echo -e "Format: ${GREEN}Current (.doyaken/)${NC}"

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
  blocked_dir=$(get_task_folder "$doyaken_dir" "blocked")
  todo_dir=$(get_task_folder "$doyaken_dir" "todo")
  doing_dir=$(get_task_folder "$doyaken_dir" "doing")
  done_dir=$(get_task_folder "$doyaken_dir" "done")
  local blocked todo doing done_count
  blocked=$(count_task_files "$blocked_dir")
  todo=$(count_task_files "$todo_dir")
  doing=$(count_task_files "$doing_dir")
  done_count=$(count_task_files "$done_dir")
  echo "  Blocked: $blocked"
  echo "  Todo:    $todo"
  echo "  Doing:   $doing"
  echo "  Done:    $done_count"

  # Manifest info (if exists)
  local manifest="$doyaken_dir/manifest.yaml"
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
  local doyaken_dir="$project/.doyaken"

  local manifest="$doyaken_dir/manifest.yaml"

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
  for agent in claude cursor codex gemini copilot opencode; do
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

  # Check yq (required for registry operations)
  if command -v yq &>/dev/null; then
    log_success "YAML parser available (yq)"
  else
    log_error "yq not found (required for project registry)"
    echo "  Install: brew install yq (macOS) or snap install yq (Ubuntu)"
    ((issues++))
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
  if [ -n "$project" ] && [[ "$project" != LEGACY:* ]]; then
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
      ((issues++))
    fi
    if [ -d "$ai_agent_dir/tasks/3.doing" ] || [ -d "$ai_agent_dir/tasks/doing" ]; then
      log_success "  tasks/doing exists"
    else
      log_error "  tasks/doing missing"
      ((issues++))
    fi
    if [ -d "$ai_agent_dir/tasks/4.done" ] || [ -d "$ai_agent_dir/tasks/done" ]; then
      log_success "  tasks/done exists"
    else
      log_error "  tasks/done missing"
      ((issues++))
    fi
    [ -f "$ai_agent_dir/manifest.yaml" ] && log_success "  manifest.yaml exists" || log_warn "  manifest.yaml missing"
    [ -f "$project/AGENT.md" ] && log_success "  AGENT.md exists" || log_warn "  AGENT.md missing"
  elif [[ "$project" == LEGACY:* ]]; then
    log_warn "Legacy project: ${project#LEGACY:}"
    echo "  Run 'doyaken init' in a new directory instead"
  else
    log_info "Not in a project directory (run 'dk init' to create one)"
  fi

  # Registry info
  echo ""
  echo "Registry:"
  local reg_file="$DOYAKEN_HOME/projects/registry.yaml"
  if [ -f "$reg_file" ]; then
    local project_count=0
    project_count=$(grep -c "^  - path:" "$reg_file" 2>/dev/null) || true
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

cmd_config() {
  local subcmd="${1:-show}"
  shift || true

  case "$subcmd" in
    show|"")
      # Detect project (optional)
      local project manifest_file=""
      project=$(detect_project 2>/dev/null) || project=""
      if [ -n "$project" ] && [[ "$project" != LEGACY:* ]]; then
        manifest_file="$project/.doyaken/manifest.yaml"
      fi

      # Load all config
      load_all_config "$manifest_file"

      # Show effective configuration
      show_effective_config "$manifest_file"
      ;;
    edit)
      local target="${1:-global}"
      local config_file=""

      if [ "$target" = "global" ]; then
        config_file="$DOYAKEN_HOME/config/global.yaml"
        if [ ! -f "$config_file" ]; then
          log_warn "Global config not found, creating from template..."
          mkdir -p "$(dirname "$config_file")"
          local template="$SCRIPT_DIR/../config/global.yaml"
          if [ -f "$template" ]; then
            cp "$template" "$config_file"
          else
            log_error "Template not found"
            exit 1
          fi
        fi
      elif [ "$target" = "project" ]; then
        local project
        project=$(require_project)
        config_file="$project/.doyaken/manifest.yaml"
      else
        log_error "Unknown target: $target (use 'global' or 'project')"
        exit 1
      fi

      local editor="${EDITOR:-vi}"
      log_info "Opening $config_file with $editor"
      "$editor" "$config_file"
      ;;
    path)
      local target="${1:-all}"
      case "$target" in
        global)
          echo "$DOYAKEN_HOME/config/global.yaml"
          ;;
        project)
          local project
          project=$(require_project)
          echo "$project/.doyaken/manifest.yaml"
          ;;
        all|*)
          echo "Global: $DOYAKEN_HOME/config/global.yaml"
          local project
          project=$(detect_project 2>/dev/null) || project=""
          if [ -n "$project" ] && [[ "$project" != LEGACY:* ]]; then
            echo "Project: $project/.doyaken/manifest.yaml"
          else
            echo "Project: (not in a project)"
          fi
          ;;
      esac
      ;;
    *)
      log_error "Unknown config subcommand: $subcmd"
      echo "Usage: doyaken config [show|edit|path]"
      echo ""
      echo "Commands:"
      echo "  show              Show effective configuration (default)"
      echo "  edit [global|project]  Edit config file in \$EDITOR"
      echo "  path [global|project]  Show config file paths"
      exit 1
      ;;
  esac
}

cmd_upgrade() {
  local subcmd="apply"
  local force=false
  local dry_run=false

  # Parse flags
  while [ $# -gt 0 ]; do
    case "$1" in
      --force|-f)
        force=true
        shift
        ;;
      --dry-run|-n)
        dry_run=true
        shift
        ;;
      --check|-c)
        subcmd="check"
        shift
        ;;
      --rollback|-r)
        subcmd="rollback"
        shift
        ;;
      --list-backups|-l)
        subcmd="list-backups"
        shift
        ;;
      check|apply|rollback|list-backups|verify)
        subcmd="$1"
        shift
        ;;
      *)
        log_error "Unknown upgrade option: $1"
        echo ""
        echo "Usage: doyaken upgrade [--check|--force|--dry-run|--rollback]"
        return 1
        ;;
    esac
  done

  # Find source directory (where we're upgrading from)
  local source_dir="$SCRIPT_DIR/.."

  case "$subcmd" in
    check)
      local result=0
      upgrade_check "$source_dir" "$DOYAKEN_HOME" || result=$?
      case $result in
        0) log_info "Upgrade available" ;;
        1) log_info "Already up to date" ;;
        2) log_warn "Installed version is newer (downgrade)" ;;
      esac
      return $result
      ;;
    apply|"")
      log_info "Upgrading doyaken..."

      if [ "$dry_run" = true ]; then
        upgrade_preview "$source_dir" "$DOYAKEN_HOME"
        log_info "Dry run complete (no changes made)"
        return 0
      fi

      if upgrade_apply "$source_dir" "$DOYAKEN_HOME" "$force" "$dry_run"; then
        log_success "Upgrade complete!"
        return 0
      else
        log_error "Upgrade failed"
        return 1
      fi
      ;;
    rollback)
      log_info "Rolling back to previous version..."
      if upgrade_rollback "$DOYAKEN_HOME"; then
        log_success "Rollback complete"
        return 0
      else
        log_error "Rollback failed"
        return 1
      fi
      ;;
    list-backups)
      upgrade_list_backups "$DOYAKEN_HOME"
      ;;
    verify)
      if upgrade_verify "$DOYAKEN_HOME"; then
        log_success "Installation is valid"
        return 0
      else
        log_error "Installation has errors (run 'doyaken upgrade --force' to repair)"
        return 1
      fi
      ;;
    *)
      log_error "Unknown upgrade subcommand: $subcmd"
      echo ""
      echo "Usage: doyaken upgrade [options]"
      echo ""
      echo "Options:"
      echo "  --check, -c       Check if upgrade is available"
      echo "  --dry-run, -n     Preview changes without applying"
      echo "  --force, -f       Force upgrade (skip version check)"
      echo "  --rollback, -r    Rollback to previous version"
      echo "  --list-backups    List available backups"
      echo ""
      echo "Commands:"
      echo "  verify            Verify installation integrity"
      exit 1
      ;;
  esac
}

# ============================================================================
# Review Command
# ============================================================================

cmd_review() {
  local fix_mode="true"
  local create_tasks="true"
  local scope="all"

  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --fix|-f)
        fix_mode="true"
        shift
        ;;
      --no-tasks)
        create_tasks="false"
        shift
        ;;
      --scope=*)
        scope="${1#*=}"
        shift
        ;;
      --scope)
        if [ $# -lt 2 ] || [[ "$2" == --* ]]; then
          log_error "--scope requires a value"
          exit 1
        fi
        scope="$2"
        shift 2
        ;;
      --status|-s)
        # Show review status
        if review_tracker_is_enabled; then
          echo ""
          echo "Periodic Review Status"
          echo "======================"
          echo ""
          echo "  Enabled: yes"
          echo "  $(review_tracker_status)"
          echo "  Threshold: $(review_tracker_get_threshold)"
          echo "  Auto-fix: ${REVIEW_AUTO_FIX:-0}"
          echo ""
        else
          echo ""
          echo "Periodic reviews are disabled"
          echo ""
        fi
        return 0
        ;;
      --reset)
        # Reset counter
        review_tracker_reset
        log_success "Review counter reset to 0"
        return 0
        ;;
      --no-fix)
        fix_mode="false"
        shift
        ;;
      --help|-h)
        echo ""
        echo "doyaken review - Periodic codebase review"
        echo ""
        echo "Usage:"
        echo "  doyaken review              Run full periodic review (auto-fix enabled)"
        echo "  doyaken review --no-fix     Run without auto-fix (only create tasks)"
        echo "  doyaken review --status     Show review status"
        echo "  doyaken review --reset      Reset completion counter"
        echo ""
        echo "Options:"
        echo "  --fix, -f         Auto-fix issues where possible (default)"
        echo "  --no-fix          Disable auto-fix, only create tasks"
        echo "  --no-tasks        Don't create follow-up tasks"
        echo "  --scope=SCOPE     Review scope: all, quality, security, performance, debt, ux, docs"
        echo "  --status, -s      Show review status (counter, threshold)"
        echo "  --reset           Reset the task completion counter"
        echo ""
        echo "Examples:"
        echo "  doyaken review                      # Full review with auto-fix"
        echo "  doyaken review --no-fix             # Review only, create tasks"
        echo "  doyaken review --scope=security     # Security-focused review"
        echo "  doyaken review --status             # Check review status"
        echo ""
        return 0
        ;;
      *)
        shift
        ;;
    esac
  done

  # Check if enabled
  if ! review_tracker_is_enabled; then
    log_warn "Periodic reviews are disabled in configuration"
    log_info "Enable in config: periodic_review.enabled: true"
    return 0
  fi

  # Run the review script
  local review_script="$SCRIPT_DIR/run-periodic-review.sh"
  if [ ! -f "$review_script" ]; then
    log_error "Review script not found: $review_script"
    return 1
  fi

  # Make it executable
  chmod +x "$review_script"

  # Build args
  local args=""
  [ "$fix_mode" = "true" ] && args="$args --fix"
  [ "$create_tasks" = "false" ] && args="$args --no-tasks"
  [ "$scope" != "all" ] && args="$args --scope=$scope"

  # Execute
  # shellcheck disable=SC2086
  "$review_script" $args
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

cmd_sync() {
  local project
  project=$(require_project)

  log_info "Syncing agent files to: $project"

  # Use the sync script for agent files
  local sync_script="$DOYAKEN_HOME/scripts/sync-agent-files.sh"
  if [ ! -f "$sync_script" ]; then
    sync_script="$SCRIPT_DIR/../scripts/sync-agent-files.sh"
  fi

  if [ -f "$sync_script" ]; then
    "$sync_script" "$project"
  else
    log_error "sync-agent-files.sh not found"
    exit 1
  fi

  # Regenerate slash commands
  log_info "Regenerating slash commands..."
  generate_slash_commands "$project"

  # Update prompts library
  local ai_agent_dir="$project/.doyaken"
  if [ -d "$DOYAKEN_HOME/prompts/library" ]; then
    mkdir -p "$ai_agent_dir/prompts/library"
    cp -r "$DOYAKEN_HOME/prompts/library/"*.md "$ai_agent_dir/prompts/library/" 2>/dev/null || true
    log_success "Updated prompt library"
  fi

  # Update skills
  if [ -d "$DOYAKEN_HOME/skills" ]; then
    mkdir -p "$ai_agent_dir/skills"
    cp -r "$DOYAKEN_HOME/skills/"*.md "$ai_agent_dir/skills/" 2>/dev/null || true
    log_success "Updated skills"
  fi
}

cmd_commands() {
  local project
  project=$(require_project)

  log_info "Regenerating slash commands..."
  generate_slash_commands "$project"

  # List generated commands
  local commands_dir="$project/.claude/commands"
  if [ -d "$commands_dir" ]; then
    local count
    count=$(count_task_files "$commands_dir")
    log_success "Generated $count slash commands"
    echo ""
    echo "Available commands:"
    for cmd_file in "$commands_dir"/*.md; do
      [ -f "$cmd_file" ] || continue
      local name
      name=$(basename "$cmd_file" .md)
      local desc
      desc=$(awk '
        /^---$/ { if (started) exit; started = 1; next }
        started && /^description:/ {
          gsub(/^description:[[:space:]]*/, "")
          print
          exit
        }
      ' "$cmd_file")
      printf "  /%s - %s\n" "$name" "${desc:-No description}"
    done | sort | head -20
    echo ""
    echo "  (showing first 20, see .claude/commands/ for all)"
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
        if [ $# -lt 2 ] || [[ "$2" == --* ]]; then
          log_error "--project requires a value"
          exit 1
        fi
        project_override="$2"
        shift 2
        ;;
      --agent)
        if [ $# -lt 2 ] || [[ "$2" == --* ]]; then
          log_error "--agent requires a value"
          exit 1
        fi
        export DOYAKEN_AGENT="$2"
        export DOYAKEN_AGENT_FROM_CLI=1
        shift 2
        ;;
      --model)
        if [ $# -lt 2 ] || [[ "$2" == --* ]]; then
          log_error "--model requires a value"
          exit 1
        fi
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
      --safe-mode|--interactive)
        export DOYAKEN_SAFE_MODE=1
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
        # If command is already set, pass option to command
        if [ -n "$cmd" ]; then
          args+=("$1")
          shift
        else
          log_error "Unknown option: $1"
          show_help
          exit 1
        fi
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
    chat)
      cmd_chat
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
    cleanup|clean)
      cmd_cleanup
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
    add)
      # Alias: dk add "title" -> dk tasks new "title"
      cmd_tasks "new" "${args[@]+"${args[@]}"}"
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
    config)
      cmd_config "${args[@]+"${args[@]}"}"
      ;;
    upgrade)
      cmd_upgrade "${args[@]+"${args[@]}"}"
      ;;
    review)
      cmd_review "${args[@]+"${args[@]}"}"
      ;;
    mcp)
      cmd_mcp "${args[@]+"${args[@]}"}"
      ;;
    hooks)
      hooks_main "${args[@]+"${args[@]}"}"
      ;;
    sync)
      cmd_sync
      ;;
    commands)
      cmd_commands
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

        # Try to suggest similar command
        local suggestion
        suggestion=$(fuzzy_match_command "$cmd")
        if [ -n "$suggestion" ]; then
          echo ""
          echo -e "  Did you mean ${BOLD}dk $suggestion${NC}?"
        else
          echo ""
          echo "Common commands:"
          echo "  dk init          Initialize project"
          echo "  dk tasks         Show taskboard"
          echo "  dk tasks new     Create a task"
          echo "  dk run [N]       Run N tasks (default: 5)"
          echo "  dk status        Project status"
          echo "  dk help          Full help"
        fi
        exit 1
      fi
      ;;
  esac
}

# Run main if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
