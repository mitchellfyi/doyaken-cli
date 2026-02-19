#!/usr/bin/env bash
#
# hooks.sh - CLI agent hooks management for doyaken
#
# Manages hook scripts and generates Claude Code compatible settings.json
# with hook configurations that reference doyaken prompts.
#
# Hooks are stored in:
#   - $DOYAKEN_HOME/hooks/ (global)
#   - .doyaken/hooks/ (project-specific, overrides global)
#
set -euo pipefail

DOYAKEN_HOME="${DOYAKEN_HOME:-$HOME/.doyaken}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# ============================================================================
# Hook Discovery
# ============================================================================

# Get hook search paths (project first, then global)
get_hook_paths() {
  local paths=()

  # Project-specific hooks
  if [ -n "${DOYAKEN_PROJECT:-}" ] && [ -d "$DOYAKEN_PROJECT/.doyaken/hooks" ]; then
    paths+=("$DOYAKEN_PROJECT/.doyaken/hooks")
  fi

  # Global hooks
  if [ -d "$DOYAKEN_HOME/hooks" ]; then
    paths+=("$DOYAKEN_HOME/hooks")
  fi

  # Only print if array has elements (avoids unbound variable error with set -u)
  [ ${#paths[@]} -gt 0 ] && printf '%s\n' "${paths[@]}"
}

# Find a hook script by name
find_hook() {
  local name="$1"

  while IFS= read -r dir; do
    if [ -f "$dir/${name}.sh" ]; then
      echo "$dir/${name}.sh"
      return 0
    fi
    if [ -f "$dir/${name}" ]; then
      echo "$dir/${name}"
      return 0
    fi
  done < <(get_hook_paths)

  return 1
}

# List all available hooks
list_hooks() {
  local shown=()

  while IFS= read -r dir; do
    [ -d "$dir" ] || continue

    for hook_file in "$dir"/*.sh; do
      [ -f "$hook_file" ] || continue

      local name
      name=$(basename "$hook_file" .sh)

      # Skip if already shown (project overrides global)
      local already_shown=false
      for s in "${shown[@]:-}"; do
        [ "$s" = "$name" ] && already_shown=true && break
      done
      [ "$already_shown" = true ] && continue

      shown+=("$name")

      # Extract description from script header
      local desc
      desc=$(grep -m1 "^#.*-.*" "$hook_file" 2>/dev/null | sed 's/^# *[^ ]* *- *//' || echo "No description")

      local location="global"
      [[ "$dir" == *"/.doyaken/hooks" ]] && location="project"

      echo "${name}|${desc}|${location}|${hook_file}"
    done
  done < <(get_hook_paths)
}

# ============================================================================
# Settings Generation
# ============================================================================

# Get the hooks directory path (for settings.json)
get_hooks_dir() {
  # Prefer project hooks if they exist
  if [ -n "${DOYAKEN_PROJECT:-}" ] && [ -d "$DOYAKEN_PROJECT/.doyaken/hooks" ]; then
    echo "$DOYAKEN_PROJECT/.doyaken/hooks"
  else
    echo "$DOYAKEN_HOME/hooks"
  fi
}

# Generate Claude Code settings.json with hooks
generate_claude_settings() {
  local output_file="${1:-}"
  local hooks_dir
  hooks_dir=$(get_hooks_dir)

  # Build settings JSON
  local settings
  settings=$(cat << EOF
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "$hooks_dir/protect-sensitive-files.sh",
            "timeout": 5
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "$hooks_dir/format-on-save.sh",
            "timeout": 30
          },
          {
            "type": "command",
            "command": "$hooks_dir/security-check.sh",
            "timeout": 5
          }
        ]
      }
    ],
    "SessionStart": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "$hooks_dir/task-context.sh",
            "timeout": 5
          }
        ]
      }
    ],
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "$hooks_dir/commit-reminder.sh",
            "timeout": 5
          }
        ]
      }
    ]
  }
}
EOF
)

  if [ -n "$output_file" ]; then
    echo "$settings" > "$output_file"
    echo "Generated: $output_file"
  else
    echo "$settings"
  fi
}

# Install hooks to a project's .claude/settings.json
install_project_hooks() {
  local project_dir="${1:-$(pwd)}"

  # Ensure .claude directory exists
  mkdir -p "$project_dir/.claude"

  local settings_file="$project_dir/.claude/settings.json"
  local hooks_dir

  # Determine hooks directory
  if [ -d "$project_dir/.doyaken/hooks" ]; then
    hooks_dir="$project_dir/.doyaken/hooks"
  else
    hooks_dir="$DOYAKEN_HOME/hooks"
  fi

  # Check if settings.json exists
  if [ -f "$settings_file" ]; then
    # Merge hooks into existing settings
    if command -v jq &>/dev/null; then
      local new_hooks
      new_hooks=$(generate_claude_settings | jq '.hooks')

      local merged
      merged=$(jq --argjson hooks "$new_hooks" '.hooks = $hooks' "$settings_file")

      echo "$merged" > "$settings_file"
      echo -e "${GREEN}Updated${NC} $settings_file with doyaken hooks"
    else
      echo -e "${YELLOW}Warning${NC}: jq not found, cannot merge settings"
      echo "Please manually add hooks to $settings_file"
      generate_claude_settings
    fi
  else
    # Create new settings file
    generate_claude_settings "$settings_file"
    echo -e "${GREEN}Created${NC} $settings_file with doyaken hooks"
  fi
}

# ============================================================================
# CLI Commands
# ============================================================================

cmd_hooks_list() {
  echo ""
  echo -e "${BOLD}Available Hooks${NC}"
  echo "==============="
  echo ""

  local found=false
  while IFS='|' read -r name desc location path; do
    [ -z "$name" ] && continue
    found=true

    local loc_tag=""
    [ "$location" = "project" ] && loc_tag=" ${CYAN}[project]${NC}"

    echo -e "  ${GREEN}$name${NC}$loc_tag"
    echo "    $desc"
    echo "    Path: $path"
    echo ""
  done < <(list_hooks)

  if [ "$found" = false ]; then
    echo "  No hooks found."
    echo ""
    echo "  Install hooks with: doyaken hooks install"
  fi
}

cmd_hooks_install() {
  local project_dir="${1:-$(pwd)}"

  echo -e "${BOLD}Installing Claude Code Hooks${NC}"
  echo ""

  # Copy hooks to project if not exists
  if [ ! -d "$project_dir/.doyaken/hooks" ]; then
    mkdir -p "$project_dir/.doyaken/hooks"

    # Copy from global
    if [ -d "$DOYAKEN_HOME/hooks" ]; then
      cp "$DOYAKEN_HOME/hooks"/*.sh "$project_dir/.doyaken/hooks/" 2>/dev/null || true
      chmod +x "$project_dir/.doyaken/hooks"/*.sh 2>/dev/null || true
      echo -e "${GREEN}Copied${NC} hooks to .doyaken/hooks/"
    fi
  else
    echo -e "${YELLOW}Hooks already exist${NC} in .doyaken/hooks/"
  fi

  # Install to .claude/settings.json
  install_project_hooks "$project_dir"

  echo ""
  echo "Hooks installed! They will run automatically with Claude Code."
  echo ""
  echo "Available hooks:"
  echo "  - protect-sensitive-files: Blocks edits to .env, credentials, etc."
  echo "  - format-on-save: Auto-formats code after edits"
  echo "  - security-check: Flags security-sensitive changes"
  echo "  - task-context: Injects active task info at session start"
  echo "  - commit-reminder: Reminds about uncommitted changes"
  echo ""
  echo "Customize hooks in .doyaken/hooks/ or .claude/settings.json"
}

cmd_hooks_show() {
  local name="$1"

  local hook_path
  hook_path=$(find_hook "$name") || {
    echo "Hook not found: $name" >&2
    return 1
  }

  echo -e "${BOLD}Hook: $name${NC}"
  echo "Path: $hook_path"
  echo ""
  echo "--- Content ---"
  cat "$hook_path"
}

cmd_hooks_generate() {
  local output="${1:-}"

  if [ -n "$output" ]; then
    generate_claude_settings "$output"
  else
    generate_claude_settings
  fi
}

# ============================================================================
# Main
# ============================================================================

hooks_main() {
  local cmd="${1:-list}"
  shift || true

  case "$cmd" in
    list|ls)
      cmd_hooks_list
      ;;
    install)
      cmd_hooks_install "$@"
      ;;
    show)
      if [ -z "${1:-}" ]; then
        echo "Usage: doyaken hooks show <name>" >&2
        exit 1
      fi
      cmd_hooks_show "$1"
      ;;
    generate)
      cmd_hooks_generate "$@"
      ;;
    *)
      echo "Unknown hooks command: $cmd" >&2
      echo "Usage: doyaken hooks [list|install|show|generate]" >&2
      exit 1
      ;;
  esac
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  hooks_main "$@"
fi
