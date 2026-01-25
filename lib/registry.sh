#!/usr/bin/env bash
#
# registry.sh - Project registry management for doyaken
#
# Manages the global project registry at ~/.doyaken/projects/registry.yaml
#
set -euo pipefail

DOYAKEN_HOME="${DOYAKEN_HOME:-$HOME/.doyaken}"
REGISTRY_FILE="$DOYAKEN_HOME/projects/registry.yaml"

# Colors (if not already defined)
RED="${RED:-\033[0;31m}"
GREEN="${GREEN:-\033[0;32m}"
YELLOW="${YELLOW:-\033[0;33m}"
BLUE="${BLUE:-\033[0;34m}"
NC="${NC:-\033[0m}"

# ============================================================================
# Logging (if not already defined)
# ============================================================================

if ! declare -f log_info &>/dev/null; then
  log_info() { echo -e "${BLUE}[registry]${NC} $1"; }
  log_success() { echo -e "${GREEN}[registry]${NC} $1"; }
  log_warn() { echo -e "${YELLOW}[registry]${NC} $1"; }
  log_error() { echo -e "${RED}[registry]${NC} $1" >&2; }
fi

# ============================================================================
# Registry Management
# ============================================================================

ensure_registry() {
  mkdir -p "$(dirname "$REGISTRY_FILE")"

  if [ ! -f "$REGISTRY_FILE" ]; then
    cat > "$REGISTRY_FILE" << 'EOF'
# AI Agent Project Registry
# Auto-generated - do not edit manually unless you know what you're doing

version: 1

projects: []

# Path aliases for quick access
aliases: {}
EOF
    log_info "Created registry at: $REGISTRY_FILE"
  fi
}

add_to_registry() {
  local path="$1"
  local name="${2:-$(basename "$path")}"
  local git_remote="${3:-}"
  local timestamp
  timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  ensure_registry

  # Normalize path
  path=$(cd "$path" 2>/dev/null && pwd) || {
    log_error "Invalid path: $path"
    return 1
  }

  # Check if already registered
  if grep -q "path: \"$path\"" "$REGISTRY_FILE" 2>/dev/null; then
    log_info "Project already registered: $path"
    # Update last_active timestamp
    update_last_active "$path"
    return 0
  fi

  # Add to registry
  if command -v yq &>/dev/null; then
    # Use yq for proper YAML manipulation
    yq -i ".projects += [{\"path\": \"$path\", \"name\": \"$name\", \"git_remote\": \"$git_remote\", \"registered_at\": \"$timestamp\", \"last_active\": \"$timestamp\"}]" "$REGISTRY_FILE"
  else
    # Fallback: manual YAML append (less robust but works)
    # Find the projects: [] line and replace it, or append to projects list
    if grep -q "^projects: \[\]$" "$REGISTRY_FILE"; then
      # Empty projects list - replace it
      sed -i.bak "s/^projects: \[\]$/projects:\n  - path: \"$path\"\n    name: \"$name\"\n    git_remote: \"$git_remote\"\n    registered_at: \"$timestamp\"\n    last_active: \"$timestamp\"/" "$REGISTRY_FILE"
      rm -f "${REGISTRY_FILE}.bak"
    else
      # Append to existing projects list
      # Find the line after "projects:" and insert there
      local temp_file
      temp_file=$(mktemp)
      awk -v path="$path" -v name="$name" -v remote="$git_remote" -v ts="$timestamp" '
        /^projects:/ {
          print
          print "  - path: \"" path "\""
          print "    name: \"" name "\""
          print "    git_remote: \"" remote "\""
          print "    registered_at: \"" ts "\""
          print "    last_active: \"" ts "\""
          next
        }
        { print }
      ' "$REGISTRY_FILE" > "$temp_file"
      mv "$temp_file" "$REGISTRY_FILE"
    fi
  fi

  log_success "Registered project: $name at $path"
}

remove_from_registry() {
  local path="$1"

  ensure_registry

  # Normalize path
  path=$(cd "$path" 2>/dev/null && pwd) || {
    log_error "Invalid path: $path"
    return 1
  }

  if ! grep -q "path: \"$path\"" "$REGISTRY_FILE" 2>/dev/null; then
    log_warn "Project not in registry: $path"
    return 0
  fi

  if command -v yq &>/dev/null; then
    yq -i "del(.projects[] | select(.path == \"$path\"))" "$REGISTRY_FILE"
  else
    # Fallback: use sed/awk (less robust)
    local temp_file
    temp_file=$(mktemp)
    awk -v path="$path" '
      BEGIN { skip = 0 }
      /^  - path: / {
        if (index($0, path) > 0) {
          skip = 1
          next
        }
      }
      skip && /^  - path: / { skip = 0 }
      skip && /^    / { next }
      skip && /^[^ ]/ { skip = 0 }
      !skip { print }
    ' "$REGISTRY_FILE" > "$temp_file"
    mv "$temp_file" "$REGISTRY_FILE"
  fi

  log_success "Removed project from registry: $path"
}

lookup_registry() {
  local search_path="$1"

  ensure_registry

  # Normalize path
  search_path=$(cd "$search_path" 2>/dev/null && pwd) || return 1

  # Check for exact match
  if command -v yq &>/dev/null; then
    local found
    found=$(yq ".projects[] | select(.path == \"$search_path\") | .path" "$REGISTRY_FILE" 2>/dev/null | head -1 | tr -d '"')
    if [ -n "$found" ]; then
      echo "$found"
      return 0
    fi
  else
    # Fallback: grep
    if grep -q "path: \"$search_path\"" "$REGISTRY_FILE" 2>/dev/null; then
      echo "$search_path"
      return 0
    fi
  fi

  return 1
}

update_last_active() {
  local path="$1"
  local timestamp
  timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  if command -v yq &>/dev/null; then
    yq -i "(.projects[] | select(.path == \"$path\")).last_active = \"$timestamp\"" "$REGISTRY_FILE"
  fi
  # Fallback: skip update if yq not available
}

list_projects() {
  ensure_registry

  echo ""
  printf "%-50s %-40s %s\n" "PATH" "REMOTE" "STATUS"
  printf "%-50s %-40s %s\n" "----" "------" "------"

  if command -v yq &>/dev/null; then
    yq -r '.projects[] | [.path, .git_remote // "-", .name] | @tsv' "$REGISTRY_FILE" 2>/dev/null | while IFS=$'\t' read -r path remote name; do
      # Get task status
      local status=""
      local ai_agent_dir=""

      if [ -d "$path/.doyaken/tasks" ]; then
        ai_agent_dir="$path/.doyaken"
      elif [ -d "$path/.claude/tasks" ]; then
        ai_agent_dir="$path/.claude"
      fi

      if [ -n "$ai_agent_dir" ]; then
        local todo doing
        todo=$(find "$ai_agent_dir/tasks/todo" -maxdepth 1 -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
        doing=$(find "$ai_agent_dir/tasks/doing" -maxdepth 1 -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
        status="${todo} todo, ${doing} doing"
      else
        status="(not found)"
      fi

      # Truncate path and remote for display
      local display_path="${path:0:48}"
      [ ${#path} -gt 48 ] && display_path="${display_path}.."
      local display_remote="${remote:0:38}"
      [ ${#remote} -gt 38 ] && display_remote="${display_remote}.."

      printf "%-50s %-40s %s\n" "$display_path" "$display_remote" "$status"
    done
  else
    # Fallback: parse with grep/awk
    local in_project=0
    local path="" name="" remote=""

    while IFS= read -r line; do
      if [[ "$line" =~ ^[[:space:]]*-[[:space:]]*path:[[:space:]]*\"(.*)\"$ ]]; then
        path="${BASH_REMATCH[1]}"
        in_project=1
      elif [[ "$in_project" == 1 && "$line" =~ ^[[:space:]]*name:[[:space:]]*\"(.*)\"$ ]]; then
        name="${BASH_REMATCH[1]}"
      elif [[ "$in_project" == 1 && "$line" =~ ^[[:space:]]*git_remote:[[:space:]]*\"(.*)\"$ ]]; then
        remote="${BASH_REMATCH[1]}"
      elif [[ "$in_project" == 1 && "$line" =~ ^[[:space:]]*registered_at: ]]; then
        # End of this project entry
        local status=""
        if [ -d "$path/.doyaken/tasks" ]; then
          local todo doing
          todo=$(find "$path/.doyaken/tasks/todo" -maxdepth 1 -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
          doing=$(find "$path/.doyaken/tasks/doing" -maxdepth 1 -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
          status="${todo} todo, ${doing} doing"
        elif [ -d "$path/.claude/tasks" ]; then
          local todo doing
          todo=$(find "$path/.claude/tasks/todo" -maxdepth 1 -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
          doing=$(find "$path/.claude/tasks/doing" -maxdepth 1 -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
          status="${todo} todo, ${doing} doing (legacy)"
        else
          status="(not found)"
        fi

        printf "%-50s %-40s %s\n" "${path:0:48}" "${remote:0:38}" "$status"
        in_project=0
        path="" name="" remote=""
      fi
    done < "$REGISTRY_FILE"
  fi

  echo ""
}

get_project_count() {
  ensure_registry

  if command -v yq &>/dev/null; then
    yq '.projects | length' "$REGISTRY_FILE" 2>/dev/null
  else
    grep -c "^  - path:" "$REGISTRY_FILE" 2>/dev/null || echo "0"
  fi
}

# Export functions for use in other scripts
export -f ensure_registry add_to_registry remove_from_registry lookup_registry list_projects 2>/dev/null || true
