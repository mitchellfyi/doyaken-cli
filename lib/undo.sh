#!/usr/bin/env bash
#
# undo.sh - Undo/revert system with git checkpoint integration
#
# Provides /undo, /redo, /checkpoint, /restore commands.
# Checkpoints are created via `git stash create` and tracked per-session.
#

# Prevent multiple sourcing
[[ -n "${_DOYAKEN_UNDO_LOADED:-}" ]] && return 0
_DOYAKEN_UNDO_LOADED=1

# ============================================================================
# Checkpoint Storage
# ============================================================================

# Checkpoint stack (parallel arrays for bash 3.x compat)
UNDO_CHECKPOINT_REFS=()    # git stash refs (commit hashes)
UNDO_CHECKPOINT_DESCS=()   # descriptions
UNDO_CHECKPOINT_TIMES=()   # timestamps
UNDO_CHECKPOINT_FILES=()   # changed file list (comma-separated)

# Undo/redo stacks
UNDO_STACK_REFS=()         # patches saved for redo
UNDO_LAST_ACTION=""        # "undo" or "" — cleared on new agent action

# ============================================================================
# Git Helpers
# ============================================================================

# Check if we're in a git repo
_undo_in_git_repo() {
  local project="${DOYAKEN_PROJECT:-$(pwd)}"
  [ -d "$project/.git" ]
}

# Get the project root for git commands
_undo_git_dir() {
  echo "${DOYAKEN_PROJECT:-$(pwd)}"
}

# ============================================================================
# Checkpoint Management
# ============================================================================

# Create a checkpoint (snapshot of current working tree state)
# Usage: checkpoint_create "description"
# Returns 0 on success, 1 if nothing to checkpoint or no git
checkpoint_create() {
  local desc="${1:-manual checkpoint}"

  if ! _undo_in_git_repo; then
    return 1
  fi

  local project
  project=$(_undo_git_dir)

  # Create a stash-like commit without changing the working tree
  local ref
  ref=$(git -C "$project" stash create 2>/dev/null) || ref=""

  if [ -z "$ref" ]; then
    # No changes to checkpoint — record HEAD instead
    ref=$(git -C "$project" rev-parse HEAD 2>/dev/null) || return 1
  fi

  local now
  now=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  # Get changed files
  local files
  files=$(git -C "$project" diff --name-only HEAD 2>/dev/null | tr '\n' ',' | sed 's/,$//')
  [ -z "$files" ] && files=$(git -C "$project" diff --name-only --cached HEAD 2>/dev/null | tr '\n' ',' | sed 's/,$//')

  # Push to checkpoint stack
  UNDO_CHECKPOINT_REFS+=("$ref")
  UNDO_CHECKPOINT_DESCS+=("$desc")
  UNDO_CHECKPOINT_TIMES+=("$now")
  UNDO_CHECKPOINT_FILES+=("$files")

  # Enforce max checkpoint limit (keep last 50)
  local max_checkpoints=50
  while [ ${#UNDO_CHECKPOINT_REFS[@]} -gt "$max_checkpoints" ]; do
    UNDO_CHECKPOINT_REFS=("${UNDO_CHECKPOINT_REFS[@]:1}")
    UNDO_CHECKPOINT_DESCS=("${UNDO_CHECKPOINT_DESCS[@]:1}")
    UNDO_CHECKPOINT_TIMES=("${UNDO_CHECKPOINT_TIMES[@]:1}")
    UNDO_CHECKPOINT_FILES=("${UNDO_CHECKPOINT_FILES[@]:1}")
  done

  # Clear redo stack on new checkpoint
  UNDO_STACK_REFS=()
  UNDO_LAST_ACTION=""

  return 0
}

# List checkpoints
# Usage: checkpoint_list [limit]
checkpoint_list() {
  local limit="${1:-10}"
  local count=${#UNDO_CHECKPOINT_REFS[@]}

  if [ "$count" -eq 0 ]; then
    echo "No checkpoints"
    return 0
  fi

  local start=0
  if [ "$count" -gt "$limit" ]; then
    start=$((count - limit))
  fi

  for (( i=start; i < count; i++ )); do
    local idx=$((i - start + 1))
    local short_ref="${UNDO_CHECKPOINT_REFS[$i]:0:8}"
    local short_time
    short_time=$(echo "${UNDO_CHECKPOINT_TIMES[$i]}" | sed 's/T/ /; s/Z//' | cut -c1-16)
    local files="${UNDO_CHECKPOINT_FILES[$i]}"
    local file_count=0
    if [ -n "$files" ]; then
      file_count=$(echo "$files" | tr ',' '\n' | wc -l | tr -d ' ')
    fi

    printf "  %2d. ${DIM}%s${NC}  %s  %s" "$idx" "$short_ref" "$short_time" "${UNDO_CHECKPOINT_DESCS[$i]}"
    [ "$file_count" -gt 0 ] && printf "  ${DIM}(%d files)${NC}" "$file_count"
    echo ""
  done
}

# Get the latest checkpoint ref
checkpoint_latest_ref() {
  local count=${#UNDO_CHECKPOINT_REFS[@]}
  [ "$count" -eq 0 ] && return 1
  echo "${UNDO_CHECKPOINT_REFS[$((count - 1))]}"
}

# ============================================================================
# Undo / Redo
# ============================================================================

# Undo: revert working tree to the last checkpoint
# Returns 0 on success, 1 on failure
undo_last_change() {
  if ! _undo_in_git_repo; then
    echo "Not in a git repository"
    return 1
  fi

  local count=${#UNDO_CHECKPOINT_REFS[@]}
  if [ "$count" -eq 0 ]; then
    echo "No checkpoints to undo to"
    return 1
  fi

  local project
  project=$(_undo_git_dir)

  # Save current state for redo before reverting
  local current_ref
  current_ref=$(git -C "$project" stash create 2>/dev/null) || current_ref=""
  if [ -z "$current_ref" ]; then
    current_ref=$(git -C "$project" rev-parse HEAD 2>/dev/null)
  fi
  UNDO_STACK_REFS+=("$current_ref")

  # Get the checkpoint to restore to
  local target_ref="${UNDO_CHECKPOINT_REFS[$((count - 1))]}"

  # Show what will change
  local diff_stat
  diff_stat=$(git -C "$project" diff --stat "$target_ref" 2>/dev/null)
  if [ -z "$diff_stat" ]; then
    echo "No changes to undo"
    # Remove the redo entry we just added
    unset 'UNDO_STACK_REFS[${#UNDO_STACK_REFS[@]}-1]'
    return 0
  fi

  echo -e "${DIM}Reverting to checkpoint: ${UNDO_CHECKPOINT_DESCS[$((count - 1))]}${NC}"
  echo "$diff_stat"

  # Restore files to checkpoint state
  git -C "$project" checkout "$target_ref" -- . 2>/dev/null || {
    echo "Failed to restore checkpoint"
    return 1
  }

  # Handle untracked files that were added after checkpoint
  local added_files
  added_files=$(git -C "$project" diff --name-only --diff-filter=A "$target_ref" HEAD 2>/dev/null)
  if [ -n "$added_files" ]; then
    echo "$added_files" | while IFS= read -r f; do
      [ -f "$project/$f" ] && rm -f "$project/$f"
    done
  fi

  # Remove last checkpoint from stack (we've reverted past it)
  unset 'UNDO_CHECKPOINT_REFS[${#UNDO_CHECKPOINT_REFS[@]}-1]'
  unset 'UNDO_CHECKPOINT_DESCS[${#UNDO_CHECKPOINT_DESCS[@]}-1]'
  unset 'UNDO_CHECKPOINT_TIMES[${#UNDO_CHECKPOINT_TIMES[@]}-1]'
  unset 'UNDO_CHECKPOINT_FILES[${#UNDO_CHECKPOINT_FILES[@]}-1]'

  UNDO_LAST_ACTION="undo"
  return 0
}

# Redo: re-apply the last undone change
redo_last_change() {
  if ! _undo_in_git_repo; then
    echo "Not in a git repository"
    return 1
  fi

  if [ "$UNDO_LAST_ACTION" != "undo" ] || [ ${#UNDO_STACK_REFS[@]} -eq 0 ]; then
    echo "Nothing to redo"
    return 1
  fi

  local project
  project=$(_undo_git_dir)
  local redo_ref="${UNDO_STACK_REFS[$((${#UNDO_STACK_REFS[@]} - 1))]}"

  # Re-apply the saved state
  git -C "$project" checkout "$redo_ref" -- . 2>/dev/null || {
    echo "Failed to redo"
    return 1
  }

  # Pop from redo stack
  unset 'UNDO_STACK_REFS[${#UNDO_STACK_REFS[@]}-1]'

  # Re-create checkpoint
  checkpoint_create "redo"

  UNDO_LAST_ACTION=""
  return 0
}

# Restore to a specific checkpoint by index (1-based from most recent listing)
# Usage: restore_to_checkpoint <index>
restore_to_checkpoint() {
  local target_idx="${1:-}"

  if [ -z "$target_idx" ] || ! [[ "$target_idx" =~ ^[0-9]+$ ]]; then
    echo "Usage: /restore <checkpoint-number>"
    return 1
  fi

  if ! _undo_in_git_repo; then
    echo "Not in a git repository"
    return 1
  fi

  local count=${#UNDO_CHECKPOINT_REFS[@]}
  if [ "$count" -eq 0 ]; then
    echo "No checkpoints available"
    return 1
  fi

  # Convert display index to array index
  local display_limit=10
  local start=0
  if [ "$count" -gt "$display_limit" ]; then
    start=$((count - display_limit))
  fi
  local array_idx=$((start + target_idx - 1))

  if [ "$array_idx" -lt 0 ] || [ "$array_idx" -ge "$count" ]; then
    echo "Invalid checkpoint number: $target_idx"
    return 1
  fi

  local project
  project=$(_undo_git_dir)
  local target_ref="${UNDO_CHECKPOINT_REFS[$array_idx]}"

  # Save current state for potential redo
  local current_ref
  current_ref=$(git -C "$project" stash create 2>/dev/null) || current_ref=""
  [ -z "$current_ref" ] && current_ref=$(git -C "$project" rev-parse HEAD 2>/dev/null)
  UNDO_STACK_REFS+=("$current_ref")

  echo -e "${DIM}Restoring to: ${UNDO_CHECKPOINT_DESCS[$array_idx]}${NC}"

  git -C "$project" checkout "$target_ref" -- . 2>/dev/null || {
    echo "Failed to restore checkpoint"
    return 1
  }

  # Trim checkpoint stack to the restored point
  UNDO_CHECKPOINT_REFS=("${UNDO_CHECKPOINT_REFS[@]:0:$((array_idx + 1))}")
  UNDO_CHECKPOINT_DESCS=("${UNDO_CHECKPOINT_DESCS[@]:0:$((array_idx + 1))}")
  UNDO_CHECKPOINT_TIMES=("${UNDO_CHECKPOINT_TIMES[@]:0:$((array_idx + 1))}")
  UNDO_CHECKPOINT_FILES=("${UNDO_CHECKPOINT_FILES[@]:0:$((array_idx + 1))}")

  UNDO_LAST_ACTION="undo"
  return 0
}

# Show diff since last checkpoint
diff_since_checkpoint() {
  if ! _undo_in_git_repo; then
    echo "Not in a git repository"
    return 1
  fi

  local project
  project=$(_undo_git_dir)

  local count=${#UNDO_CHECKPOINT_REFS[@]}
  if [ "$count" -eq 0 ]; then
    # No checkpoints — show diff against HEAD
    git -C "$project" diff --stat 2>/dev/null
    return 0
  fi

  local last_ref="${UNDO_CHECKPOINT_REFS[$((count - 1))]}"
  git -C "$project" diff --stat "$last_ref" 2>/dev/null
}

# Clear redo stack (called when agent takes a new action)
undo_clear_redo() {
  UNDO_STACK_REFS=()
  UNDO_LAST_ACTION=""
}
