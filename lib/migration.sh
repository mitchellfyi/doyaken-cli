#!/usr/bin/env bash
#
# migration.sh - Migrate projects from .claude/ to .doyaken/
#
# Handles the conversion of legacy project structure to the new format.
#
set -euo pipefail

DOYAKEN_HOME="${DOYAKEN_HOME:-$HOME/.doyaken}"

# Source registry if not already loaded
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if ! declare -f add_to_registry &>/dev/null; then
  source "$SCRIPT_DIR/registry.sh"
fi

# Colors (if not already defined)
RED="${RED:-\033[0;31m}"
GREEN="${GREEN:-\033[0;32m}"
YELLOW="${YELLOW:-\033[0;33m}"
BLUE="${BLUE:-\033[0;34m}"
BOLD="${BOLD:-\033[1m}"
NC="${NC:-\033[0m}"

# ============================================================================
# Logging (if not already defined)
# ============================================================================

if ! declare -f log_info &>/dev/null; then
  log_info() { echo -e "${BLUE}[migrate]${NC} $1"; }
  log_success() { echo -e "${GREEN}[migrate]${NC} $1"; }
  log_warn() { echo -e "${YELLOW}[migrate]${NC} $1"; }
  log_error() { echo -e "${RED}[migrate]${NC} $1" >&2; }
fi

# ============================================================================
# Migration Functions
# ============================================================================

check_migration_prerequisites() {
  local project_dir="$1"
  local claude_dir="$project_dir/.claude"

  # Check .claude/ exists
  if [ ! -d "$claude_dir" ]; then
    log_error "No .claude/ directory found in: $project_dir"
    return 1
  fi

  # Check .doyaken/ doesn't exist
  if [ -d "$project_dir/.doyaken" ]; then
    log_error ".doyaken/ already exists - manual merge may be needed"
    log_info "If you want to start fresh, remove .doyaken/ first"
    return 1
  fi

  # Check for tasks in doing/
  local doing_count
  doing_count=$(find "$claude_dir/tasks/doing" -maxdepth 1 -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
  if [ "$doing_count" -gt 0 ]; then
    log_warn "Found $doing_count task(s) in doing/ state"
    log_warn "Complete or move these tasks before migrating:"
    ls -1 "$claude_dir/tasks/doing/"*.md 2>/dev/null
    echo ""
    read -p "Continue anyway? (y/N) " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      return 1
    fi
  fi

  # Check git status
  if [ -d "$project_dir/.git" ]; then
    local uncommitted
    uncommitted=$(git -C "$project_dir" status --porcelain 2>/dev/null | wc -l | tr -d ' ')
    if [ "$uncommitted" -gt 0 ]; then
      log_warn "Found $uncommitted uncommitted change(s)"
      log_warn "Consider committing changes before migrating"
      echo ""
      read -p "Continue anyway? (y/N) " -n 1 -r
      echo ""
      if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        return 1
      fi
    fi
  fi

  return 0
}

migrate_project() {
  local project_dir="${1:-$(pwd)}"

  # Resolve to absolute path
  project_dir=$(cd "$project_dir" 2>/dev/null && pwd) || {
    log_error "Directory not found: $project_dir"
    return 1
  }

  local claude_dir="$project_dir/.claude"
  local ai_agent_dir="$project_dir/.doyaken"

  echo ""
  echo -e "${BOLD}AI Agent Migration${NC}"
  echo "=================="
  echo ""
  echo "Source: $claude_dir"
  echo "Target: $ai_agent_dir"
  echo ""

  # Check prerequisites
  if ! check_migration_prerequisites "$project_dir"; then
    return 1
  fi

  log_info "Starting migration..."

  # Step 1: Rename .claude/ to .doyaken/
  log_info "Renaming .claude/ to .doyaken/"
  mv "$claude_dir" "$ai_agent_dir"
  log_success "Renamed directory"

  # Step 2: Remove embedded agent code (now global)
  if [ -d "$ai_agent_dir/agent" ]; then
    log_info "Removing embedded agent code (now installed globally)"
    rm -rf "$ai_agent_dir/agent"
    log_success "Removed embedded agent code"
  fi

  # Step 3: Detect git info
  local git_remote=""
  local git_branch="main"
  if [ -d "$project_dir/.git" ]; then
    git_remote=$(git -C "$project_dir" remote get-url origin 2>/dev/null || echo "")
    git_branch=$(git -C "$project_dir" branch --show-current 2>/dev/null || echo "main")
  fi

  # Step 4: Create manifest.yaml
  local project_name
  project_name=$(basename "$project_dir")

  log_info "Creating manifest.yaml"
  cat > "$ai_agent_dir/manifest.yaml" << EOF
# AI Agent Project Manifest
# Migrated from .claude/ on $(date -u +"%Y-%m-%dT%H:%M:%SZ")

version: 1

project:
  name: "$project_name"
  description: "Migrated from legacy .claude/ format"

# Git configuration
git:
  remote: "$git_remote"
  branch: "$git_branch"

# Domains and URLs
domains: {}

# External tool integrations
tools: {}

# Quality gate commands
quality:
  test_command: ""
  lint_command: ""
  format_command: ""

# Agent behavior settings
agent:
  model: "opus"
  max_retries: 2
  parallel_workers: 2
EOF
  log_success "Created manifest.yaml"

  # Step 5: Rename CLAUDE.md to AI-AGENT.md
  if [ -f "$project_dir/CLAUDE.md" ]; then
    log_info "Renaming CLAUDE.md to AI-AGENT.md"
    mv "$project_dir/CLAUDE.md" "$project_dir/AI-AGENT.md"

    # Update internal references
    if [ -f "$project_dir/AI-AGENT.md" ]; then
      sed -i.bak 's/\.claude\//\.doyaken\//g' "$project_dir/AI-AGENT.md"
      sed -i.bak 's/CLAUDE\.md/AI-AGENT.md/g' "$project_dir/AI-AGENT.md"
      rm -f "$project_dir/AI-AGENT.md.bak"
    fi
    log_success "Renamed CLAUDE.md to AI-AGENT.md"
  fi

  # Step 6: Update TASKBOARD.md references
  if [ -f "$project_dir/TASKBOARD.md" ]; then
    log_info "Updating TASKBOARD.md references"
    sed -i.bak 's/\.claude\//\.doyaken\//g' "$project_dir/TASKBOARD.md"
    rm -f "$project_dir/TASKBOARD.md.bak"
    log_success "Updated TASKBOARD.md"
  fi

  # Step 7: Update bin/agent wrapper if it exists
  if [ -f "$project_dir/bin/agent" ]; then
    log_info "Updating bin/agent wrapper"
    cat > "$project_dir/bin/agent" << 'EOF'
#!/usr/bin/env bash
#
# Legacy wrapper - redirects to global doyaken CLI
#
# This project has been migrated to use the global doyaken installation.
# You can now run 'doyaken' directly from anywhere in this project.
#
exec doyaken run "$@"
EOF
    chmod +x "$project_dir/bin/agent"
    log_success "Updated bin/agent wrapper"
  fi

  # Step 8: Register in global registry
  log_info "Registering in global registry"
  add_to_registry "$project_dir" "$project_name" "$git_remote"
  log_success "Registered project"

  # Step 9: Create .gitignore entries if needed
  if [ -f "$project_dir/.gitignore" ]; then
    if ! grep -q "\.doyaken/logs" "$project_dir/.gitignore" 2>/dev/null; then
      log_info "Adding .doyaken entries to .gitignore"
      cat >> "$project_dir/.gitignore" << 'EOF'

# AI Agent (migrated from .claude/)
.doyaken/logs/
.doyaken/state/
.doyaken/locks/
EOF
      log_success "Updated .gitignore"
    fi
  fi

  echo ""
  echo -e "${GREEN}${BOLD}Migration Complete!${NC}"
  echo ""
  echo "Summary:"
  echo "  - .claude/ renamed to .doyaken/"
  echo "  - Embedded agent code removed (now global)"
  echo "  - manifest.yaml created"
  echo "  - CLAUDE.md renamed to AI-AGENT.md"
  echo "  - Project registered in global registry"
  echo ""
  echo "Next steps:"
  echo "  1. Review .doyaken/manifest.yaml and add project-specific settings"
  echo "  2. Run 'doyaken doctor' to verify the migration"
  echo "  3. Run 'doyaken status' to see project info"
  echo "  4. Commit the changes to git"
  echo ""
  echo "Commands:"
  echo "  doyaken run 1          # Run 1 task"
  echo "  doyaken tasks          # Show taskboard"
  echo "  doyaken status         # Show project status"
  echo ""

  return 0
}

# Batch migration for all registered projects
migrate_all() {
  log_info "Looking for legacy projects to migrate..."

  local migrated=0
  local failed=0
  local skipped=0

  # Find all directories with .claude/
  for project in $(find ~ -maxdepth 4 -type d -name ".claude" 2>/dev/null | sed 's/\/.claude$//' | head -20); do
    [ -d "$project" ] || continue

    if [ -d "$project/.doyaken" ]; then
      log_info "Skipping (already migrated): $project"
      ((skipped++))
      continue
    fi

    echo ""
    echo -e "${BOLD}Found legacy project: $project${NC}"
    read -p "Migrate this project? (y/N) " -n 1 -r
    echo ""

    if [[ $REPLY =~ ^[Yy]$ ]]; then
      if migrate_project "$project"; then
        ((migrated++))
      else
        ((failed++))
      fi
    else
      ((skipped++))
    fi
  done

  echo ""
  echo "Migration Summary:"
  echo "  Migrated: $migrated"
  echo "  Failed:   $failed"
  echo "  Skipped:  $skipped"
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  migrate_project "$@"
fi
