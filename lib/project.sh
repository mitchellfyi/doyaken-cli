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
# File Counting Utilities
# ============================================================================

# Count files in a directory with optional pattern
# Args: dir, [pattern]
# Returns: count (0 if dir missing or empty)
count_files() {
  local dir="$1"
  local pattern="${2:-*}"
  find "$dir" -maxdepth 1 -name "$pattern" -type f 2>/dev/null | wc -l | tr -d ' '
}

# Count task files (*.md) in a directory
# Args: dir
# Returns: count (0 if dir missing or empty)
count_task_files() {
  local dir="$1"
  count_files "$dir" "*.md"
}

# Count files excluding .gitkeep (for cleanup operations)
# Args: dir
# Returns: count (0 if dir missing or empty)
count_files_excluding_gitkeep() {
  local dir="$1"
  find "$dir" -maxdepth 1 -type f ! -name '.gitkeep' 2>/dev/null | wc -l | tr -d ' '
}

# ============================================================================
# Priority Helpers
# ============================================================================

# Map priority code to human-readable label
# Args: priority_code (e.g., "001", "003")
# Returns: label string (e.g., "Critical", "Medium")
get_priority_label() {
  local code="$1"
  case "$code" in
    001) echo "Critical" ;;
    002) echo "High" ;;
    003) echo "Medium" ;;
    004) echo "Low" ;;
    *) echo "Unknown" ;;
  esac
}

# Rename a task file's priority prefix and update metadata
# Args: task_file, new_priority
# Returns: echoes new file path on success; returns 1 on error
rename_task_priority() {
  local task_file="$1"
  local new_priority="$2"

  # Validate file exists
  if [[ ! -f "$task_file" ]]; then
    echo "Error: file not found: $task_file" >&2
    return 1
  fi

  # Validate priority format (exactly 3 digits)
  if [[ ! "$new_priority" =~ ^[0-9]{3}$ ]]; then
    echo "Error: invalid priority format: $new_priority (expected 3 digits)" >&2
    return 1
  fi

  local filename
  filename=$(basename "$task_file")
  local dir
  dir=$(dirname "$task_file")

  # Validate filename matches PPP-SSS-* pattern
  if [[ ! "$filename" =~ ^([0-9]{3})-(.+)$ ]]; then
    echo "Error: filename does not match PPP-* pattern: $filename" >&2
    return 1
  fi

  local old_priority="${BASH_REMATCH[1]}"
  local rest="${BASH_REMATCH[2]}"

  # No-op if priority unchanged
  if [[ "$old_priority" == "$new_priority" ]]; then
    echo "$task_file"
    return 0
  fi

  local new_filename="${new_priority}-${rest}"
  local new_path="${dir}/${new_filename}"

  # Check for collision
  if [[ -f "$new_path" ]]; then
    echo "Error: target file already exists: $new_path" >&2
    return 1
  fi

  # Rename the file
  mv "$task_file" "$new_path" || {
    echo "Error: failed to rename $task_file to $new_path" >&2
    return 1
  }

  # Update Priority metadata row inside the file
  local label
  label=$(get_priority_label "$new_priority")
  awk -v priority="$new_priority" -v label="$label" '
    /^\| Priority/ {
      printf "| Priority    | `%s` %s                          |\n", priority, label
      next
    }
    { print }
  ' "$new_path" > "${new_path}.tmp" && mv "${new_path}.tmp" "$new_path"

  echo "$new_path"
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
