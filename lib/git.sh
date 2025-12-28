# shellcheck shell=bash
# Doyaken shared library — git helpers

# dk_default_branch [git_dir]
# Detect the default branch (main/master) for the given repo.
# Tries: origin/HEAD symbolic ref → origin/main exists → origin/master exists → "main" fallback.
# Optional git_dir: pass a path to run git commands against a specific worktree.
dk_default_branch() {
  local git_args=()
  [[ -n "${1:-}" ]] && git_args=(-C "$1")
  local branch
  # ${arr[@]+...} idiom: expands to nothing when the array is empty. Required because
  # bash 3.2 (macOS default) treats "${arr[@]}" as "unbound variable" under set -u.
  branch=$(git ${git_args[@]+"${git_args[@]}"} symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||')
  if [[ -z "$branch" ]]; then
    if git ${git_args[@]+"${git_args[@]}"} show-ref --verify --quiet refs/remotes/origin/main 2>/dev/null; then
      branch="main"
    elif git ${git_args[@]+"${git_args[@]}"} show-ref --verify --quiet refs/remotes/origin/master 2>/dev/null; then
      branch="master"
    else
      branch="main"
    fi
  fi
  echo "$branch"
}

# dk_slugify <string>
# Lowercase, replace non-alphanumeric with dashes, collapse double dashes, trim edges.
# Works in both bash and zsh.
dk_slugify() {
  local slug
  slug=$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')
  slug="${slug//[^a-z0-9]/-}"                              # replace non-alphanumeric → dashes
  while [[ "$slug" == *--* ]]; do slug="${slug//--/-}"; done  # collapse consecutive dashes
  slug="${slug#-}"   # trim leading dash
  slug="${slug%-}"   # trim trailing dash
  echo "$slug"
}
