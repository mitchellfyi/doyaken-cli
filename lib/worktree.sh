# shellcheck shell=bash
# Doyaken shared library — worktree helpers
#
# Bash/zsh-compatible utilities for worktree management.
# Used by dk.sh (dkrm, dkls, dkclean, __dk_show_header).
# Depends on: DK_STATE_DIR (from lib/common.sh)

# dk_wt_branch <wt_dir> [fallback]
# Get the current branch of a worktree. Returns empty or fallback for
# detached HEAD or query failure.
dk_wt_branch() {
  local wt_dir="$1"
  local fallback="${2:-}"
  local branch
  branch=$(git -C "$wt_dir" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
  if [[ -z "$branch" || "$branch" == "HEAD" ]]; then
    echo "$fallback"
  else
    echo "$branch"
  fi
}

# dk_wt_remove <wt_dir>
# Force-remove a worktree. Tries git worktree remove first, falls back to rm -rf.
dk_wt_remove() {
  git worktree remove "$1" --force 2>/dev/null || rm -rf "$1"
}

# dk_cleanup_last_session <wt_name>
# Remove the last-session pointer if it references the given worktree name.
dk_cleanup_last_session() {
  local wt_name="$1"
  local last_session_file="$DK_STATE_DIR/last-session"
  [[ -f "$last_session_file" ]] || return 0
  local last_info
  last_info=$(cat "$last_session_file" 2>/dev/null) || return 0
  if [[ "${last_info%%:*}" == "$wt_name" ]]; then
    rm -f "$last_session_file"
  fi
}

# dk_cleanup_stale_files <dir> <extensions> <max_age_days>
# Find and delete files matching "*.ext" older than max_age_days.
# extensions is space-separated (e.g., "state complete active").
# Prints the count of deleted files to stdout.
dk_cleanup_stale_files() {
  local dir="$1"
  local extensions="$2"
  local max_age="$3"
  [[ -d "$dir" ]] || { echo "0"; return 0; }

  local find_args=()
  local first=1
  local ext
  for ext in $extensions; do
    if [[ $first -eq 1 ]]; then
      find_args+=(-name "*.${ext}")
      first=0
    else
      find_args+=(-o -name "*.${ext}")
    fi
  done

  local count
  count=$(find "$dir" \( "${find_args[@]}" \) -mtime +"$max_age" 2>/dev/null | wc -l | tr -d ' ')
  if [[ "$count" -gt 0 ]]; then
    find "$dir" \( "${find_args[@]}" \) -mtime +"$max_age" -delete 2>/dev/null
  fi
  echo "$count"
}
