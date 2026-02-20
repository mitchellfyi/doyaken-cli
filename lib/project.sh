#!/usr/bin/env bash
#
# project.sh - Project detection and utility helpers for doyaken CLI
#
# Provides: detect_project, require_project,
#           count_files, count_task_files, count_files_excluding_gitkeep
#

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

# Count markdown files (*.md) in a directory
# Args: dir
# Returns: count (0 if dir missing or empty)
count_md_files() {
  local dir="$1"
  count_files "$dir" "*.md"
}

# Legacy alias
count_task_files() { count_md_files "$@"; }

# Count files excluding .gitkeep (for cleanup operations)
# Args: dir
# Returns: count (0 if dir missing or empty)
count_files_excluding_gitkeep() {
  local dir="$1"
  find "$dir" -maxdepth 1 -type f ! -name '.gitkeep' 2>/dev/null | wc -l | tr -d ' '
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
