#!/usr/bin/env bash
#
# project.sh - Project detection and task helpers for doyaken CLI
#
# Provides: detect_project, require_project, get_task_folder, create_task_file
#

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

# Create a task file with standard format
# Args: task_id, title, priority, priority_label, todo_dir, [context]
create_task_file() {
  local task_id="$1"
  local title="$2"
  local priority="$3"
  local priority_label="$4"
  local todo_dir="$5"
  local context="${6:-Why does this task exist?}"
  local task_file="$todo_dir/${task_id}.md"
  local timestamp
  timestamp=$(date '+%Y-%m-%d %H:%M')

  cat > "$task_file" << EOF
# Task: $title

## Metadata

| Field       | Value                                                  |
| ----------- | ------------------------------------------------------ |
| ID          | \`$task_id\`                                           |
| Status      | \`todo\`                                               |
| Priority    | \`$priority\` $priority_label                          |
| Created     | \`$timestamp\`                                         |
| Started     |                                                        |
| Completed   |                                                        |
| Blocked By  |                                                        |
| Blocks      |                                                        |
| Assigned To |                                                        |
| Assigned At |                                                        |

---

## Context

$context

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

- Task created via CLI

---

## Notes

---

## Links

EOF

  echo "$task_file"
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

  # Get resolved DOYAKEN_HOME for comparison
  local resolved_home=""
  if [ -d "$DOYAKEN_HOME" ]; then
    resolved_home=$(cd "$DOYAKEN_HOME" && pwd)
  fi

  # Check for .doyaken/ in current directory (but not the global install)
  if [ -d "$search_dir/.doyaken" ]; then
    # Skip if this is the parent of DOYAKEN_HOME (i.e., we're in ~ and ~/.doyaken exists)
    if [ "$search_dir/.doyaken" != "$resolved_home" ]; then
      echo "$search_dir"
      return 0
    fi
  fi

  # Check for legacy .claude/ directory (must have tasks/todo to be a doyaken project, not Claude Code's global config)
  if [ -d "$search_dir/.claude/tasks/todo" ] || [ -d "$search_dir/.claude/tasks/2.todo" ]; then
    echo "LEGACY:$search_dir"
    return 0
  fi

  # Walk up the directory tree
  local parent="$search_dir"
  while [ "$parent" != "/" ]; do
    if [ -d "$parent/.doyaken" ]; then
      # Skip if this is the global install directory
      if [ "$parent/.doyaken" != "$resolved_home" ]; then
        echo "$parent"
        return 0
      fi
    fi
    # Check for legacy .claude/ with tasks/todo subfolder (to distinguish from Claude Code's global config)
    if [ -d "$parent/.claude/tasks/todo" ] || [ -d "$parent/.claude/tasks/2.todo" ]; then
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

  # Check for explicit project override first
  if [ -n "${DOYAKEN_PROJECT:-}" ]; then
    if [ -d "$DOYAKEN_PROJECT/.doyaken" ]; then
      project="$DOYAKEN_PROJECT"
    else
      log_error "Specified project not found: $DOYAKEN_PROJECT"
      exit 1
    fi
  else
    project=$(detect_project) || {
      log_error "Not in a doyaken project"
      log_info "Run 'doyaken init' to initialize this directory"
      exit 1
    }
  fi

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
