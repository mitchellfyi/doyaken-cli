#!/usr/bin/env bash
#
# install.sh - Install/upgrade doyaken
#
# This script uses lib/upgrade.sh for idempotent installation/upgrade.
#
# Usage:
#   ./install.sh                      # Install/upgrade to ~/.doyaken (user)
#   ./install.sh --project            # Install to ./.doyaken (current project)
#   ./install.sh --project /path      # Install to /path/.doyaken
#   ./install.sh --force              # Force reinstall
#   ./install.sh --dry-run            # Preview changes without applying
#   curl -sSL <url>/install.sh | bash # User install
#
set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[doyaken]${NC} $1"; }
log_success() { echo -e "${GREEN}[doyaken]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[doyaken]${NC} $1"; }
log_error() { echo -e "${RED}[doyaken]${NC} $1" >&2; }

# Parse arguments
INSTALL_MODE="user"  # user or project
PROJECT_PATH=""
FORCE=false
DRY_RUN=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --project|-p)
      INSTALL_MODE="project"
      if [[ "${2:-}" != "" && "${2:-}" != -* ]]; then
        PROJECT_PATH="$2"
        shift
      fi
      shift
      ;;
    --force|-f)
      FORCE=true
      shift
      ;;
    --dry-run|-n)
      DRY_RUN=true
      shift
      ;;
    --help|-h)
      cat << 'EOF'
doyaken installer

Usage:
  ./install.sh                      Install/upgrade to ~/.doyaken (user-level)
  ./install.sh --project            Install to ./.doyaken (current directory)
  ./install.sh --project /path      Install to /path/.doyaken
  ./install.sh --force              Force reinstall even if up-to-date
  ./install.sh --dry-run            Preview changes without applying

Options:
  --project, -p    Install to project directory instead of user home
  --force, -f      Force reinstall (skip version check)
  --dry-run, -n    Preview changes without applying
  --help, -h       Show this help

Examples:
  # User-level install (recommended for personal use)
  curl -sSL https://raw.githubusercontent.com/mitchellfyi/doyaken-cli/main/install.sh | bash

  # Upgrade existing installation
  ./install.sh

  # Force reinstall
  ./install.sh --force

  # Project-level install (for team/repo-specific setup)
  ./install.sh --project
EOF
      exit 0
      ;;
    *)
      shift
      ;;
  esac
done

# Determine source directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check if running from git repo or downloaded release
if [ -d "$SCRIPT_DIR/lib" ] && [ -f "$SCRIPT_DIR/lib/cli.sh" ]; then
  SOURCE_DIR="$SCRIPT_DIR"
else
  log_error "Source files not found"
  log_info "Please run this script from the doyaken repository root"
  exit 1
fi

# Determine installation directory
if [[ "$INSTALL_MODE" == "project" ]]; then
  if [[ -n "$PROJECT_PATH" ]]; then
    PROJECT_DIR="$(cd "$PROJECT_PATH" 2>/dev/null && pwd)" || {
      log_error "Project path not found: $PROJECT_PATH"
      exit 1
    }
  else
    PROJECT_DIR="$(pwd)"
  fi
  DOYAKEN_HOME="$PROJECT_DIR/.doyaken"
  INSTALL_TYPE="project"
else
  DOYAKEN_HOME="${DOYAKEN_HOME:-$HOME/.doyaken}"
  INSTALL_TYPE="user"
fi

echo ""
echo -e "${BOLD}Doyaken Installer${NC}"
echo "=================="
echo ""
echo "Install type: $INSTALL_TYPE"
echo "Install path: $DOYAKEN_HOME"
echo "Source: $SOURCE_DIR"
echo ""

# Check dependencies
log_info "Checking dependencies..."

if ! command -v claude &>/dev/null; then
  log_warn "Claude CLI not found (required to run agent)"
  echo "  Install from: https://claude.ai/cli"
else
  log_success "Claude CLI found"
fi

# Generate manifest if not exists
if [ ! -f "$SOURCE_DIR/manifest.json" ]; then
  log_info "Generating manifest..."
  if [ -x "$SOURCE_DIR/scripts/generate-manifest.sh" ]; then
    "$SOURCE_DIR/scripts/generate-manifest.sh" > /dev/null 2>&1
  fi
fi

# Source upgrade library
source "$SOURCE_DIR/lib/upgrade.sh"

# For user install, use upgrade system
if [[ "$INSTALL_TYPE" == "user" ]]; then
  # Check if this is fresh install or upgrade
  if [ -d "$DOYAKEN_HOME" ] && [ -f "$DOYAKEN_HOME/VERSION" ]; then
    log_info "Existing installation found"
    INSTALLED_VERSION=$(cat "$DOYAKEN_HOME/VERSION")
    log_info "Installed version: $INSTALLED_VERSION"
  else
    log_info "Fresh installation"
  fi

  # Run upgrade (handles both fresh install and upgrade)
  if upgrade_apply "$SOURCE_DIR" "$DOYAKEN_HOME" "$FORCE" "$DRY_RUN"; then
    if [ "$DRY_RUN" = true ]; then
      log_info "Dry run complete (no changes made)"
      exit 0
    fi
  else
    log_error "Installation failed"
    exit 1
  fi

  # Create symlinks for user install
  if [ -w "/usr/local/bin" ]; then
    log_info "Creating symlinks at /usr/local/bin"
    ln -sf "$DOYAKEN_HOME/bin/doyaken" "/usr/local/bin/doyaken"
    ln -sf "$DOYAKEN_HOME/bin/doyaken" "/usr/local/bin/dk"
    log_success "Symlinks created (doyaken, dk)"
  else
    log_warn "Cannot write to /usr/local/bin"
    log_info "Add to your PATH: export PATH=\"$DOYAKEN_HOME/bin:\$PATH\""
  fi

  # Create dk alias
  ln -sf "$DOYAKEN_HOME/bin/doyaken" "$DOYAKEN_HOME/bin/dk" 2>/dev/null || true

  # Update shell config
  update_shell_config() {
    local rc_file="$1"
    local rc_name="$2"

    if [ -f "$rc_file" ]; then
      if ! grep -q "DOYAKEN_HOME" "$rc_file"; then
        log_info "Updating $rc_name..."
        cat >> "$rc_file" << EOF

# doyaken
export DOYAKEN_HOME="$DOYAKEN_HOME"
export PATH="\$DOYAKEN_HOME/bin:\$PATH"
EOF
        log_success "Updated $rc_name"
        return 0
      else
        log_info "$rc_name already configured"
      fi
    fi
    return 1
  }

  # Try to update shell config
  UPDATED_RC=""
  if update_shell_config "$HOME/.zshrc" ".zshrc"; then
    UPDATED_RC=".zshrc"
  elif update_shell_config "$HOME/.bashrc" ".bashrc"; then
    UPDATED_RC=".bashrc"
  elif update_shell_config "$HOME/.bash_profile" ".bash_profile"; then
    UPDATED_RC=".bash_profile"
  fi

  # Initialize empty registry if not exists
  if [ ! -f "$DOYAKEN_HOME/projects/registry.yaml" ]; then
    mkdir -p "$DOYAKEN_HOME/projects"
    cat > "$DOYAKEN_HOME/projects/registry.yaml" << 'EOF'
# Doyaken Project Registry
version: 1
projects: []
aliases: {}
EOF
  fi

else
  # Project install: Use the old copy-based approach for project-specific setup
  log_info "Installing project-level doyaken..."

  # Create directory structure
  mkdir -p "$DOYAKEN_HOME/bin"
  mkdir -p "$DOYAKEN_HOME/lib"
  mkdir -p "$DOYAKEN_HOME/prompts"
  mkdir -p "$DOYAKEN_HOME/templates/agents/cursor"
  mkdir -p "$DOYAKEN_HOME/config/mcp/servers"
  mkdir -p "$DOYAKEN_HOME/skills"
  mkdir -p "$DOYAKEN_HOME/hooks"
  mkdir -p "$DOYAKEN_HOME/scripts"
  mkdir -p "$DOYAKEN_HOME/tasks/1.blocked"
  mkdir -p "$DOYAKEN_HOME/tasks/2.todo"
  mkdir -p "$DOYAKEN_HOME/tasks/3.doing"
  mkdir -p "$DOYAKEN_HOME/tasks/4.done"
  mkdir -p "$DOYAKEN_HOME/tasks/_templates"
  mkdir -p "$DOYAKEN_HOME/logs"
  mkdir -p "$DOYAKEN_HOME/state"
  mkdir -p "$DOYAKEN_HOME/locks"

  # Copy core files
  /bin/cp -f "$SOURCE_DIR/lib"/*.sh "$DOYAKEN_HOME/lib/"
  /bin/cp -f "$SOURCE_DIR/bin/doyaken" "$DOYAKEN_HOME/bin/"

  # Copy prompts (including vendor prompts)
  if [ -d "$SOURCE_DIR/prompts/library" ]; then
    mkdir -p "$DOYAKEN_HOME/prompts/library"
    /bin/cp -f "$SOURCE_DIR/prompts/library"/*.md "$DOYAKEN_HOME/prompts/library/" 2>/dev/null || true
  fi
  if [ -d "$SOURCE_DIR/prompts/phases" ]; then
    mkdir -p "$DOYAKEN_HOME/prompts/phases"
    /bin/cp -f "$SOURCE_DIR/prompts/phases"/*.md "$DOYAKEN_HOME/prompts/phases/" 2>/dev/null || true
  fi
  if [ -d "$SOURCE_DIR/prompts/vendors" ]; then
    cp -r "$SOURCE_DIR/prompts/vendors" "$DOYAKEN_HOME/prompts/"
  fi
  # Copy prompts README
  if [ -f "$SOURCE_DIR/prompts/README.md" ]; then
    /bin/cp -f "$SOURCE_DIR/prompts/README.md" "$DOYAKEN_HOME/prompts/"
  fi

  # Copy templates
  # Copy templates (including subdirectories)
  cp -r "$SOURCE_DIR/templates"/* "$DOYAKEN_HOME/templates/" 2>/dev/null || true

  # Copy skills (including vendor skills)
  if [ -d "$SOURCE_DIR/skills" ]; then
    /bin/cp -f "$SOURCE_DIR/skills"/*.md "$DOYAKEN_HOME/skills/" 2>/dev/null || true
    # Copy vendor skills
    if [ -d "$SOURCE_DIR/skills/vendors" ]; then
      cp -r "$SOURCE_DIR/skills/vendors" "$DOYAKEN_HOME/skills/"
    fi
  fi

  # Copy hooks
  if [ -d "$SOURCE_DIR/hooks" ]; then
    /bin/cp -f "$SOURCE_DIR/hooks"/*.sh "$DOYAKEN_HOME/hooks/" 2>/dev/null || true
    chmod +x "$DOYAKEN_HOME/hooks"/*.sh 2>/dev/null || true
  fi

  # Copy config (preserve if exists)
  if [ ! -f "$DOYAKEN_HOME/config/global.yaml" ]; then
    /bin/cp -f "$SOURCE_DIR/config/global.yaml" "$DOYAKEN_HOME/config/" 2>/dev/null || true
  fi

  # Make scripts executable
  chmod +x "$DOYAKEN_HOME/bin/doyaken"
  chmod +x "$DOYAKEN_HOME/lib"/*.sh

  # Create VERSION file
  if [ -f "$SOURCE_DIR/package.json" ]; then
    grep '"version"' "$SOURCE_DIR/package.json" | head -1 | sed 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/' > "$DOYAKEN_HOME/VERSION"
  fi

  # Copy root-level documentation
  for doc in README.md CHANGELOG.md LICENSE; do
    if [ -f "$SOURCE_DIR/$doc" ]; then
      /bin/cp -f "$SOURCE_DIR/$doc" "$DOYAKEN_HOME/"
    fi
  done

  # Copy scripts
  mkdir -p "$DOYAKEN_HOME/scripts"
  for script in sync-agent-files.sh generate-commands.sh setup-hooks.sh; do
    if [ -f "$SOURCE_DIR/scripts/$script" ]; then
      /bin/cp -f "$SOURCE_DIR/scripts/$script" "$DOYAKEN_HOME/scripts/"
      chmod +x "$DOYAKEN_HOME/scripts/$script"
    fi
  done

  # Create wrapper scripts (only if not installing into doyaken source repo)
  PROJECT_BIN="$PROJECT_DIR/bin"

  # Check if we're installing into the source repo itself
  if [ "$PROJECT_DIR" = "$SOURCE_DIR" ]; then
    log_info "Installing into source repo - skipping wrapper creation"
  else
    mkdir -p "$PROJECT_BIN"

    cat > "$PROJECT_BIN/doyaken" << 'WRAPPER'
#!/usr/bin/env bash
# Project-local doyaken wrapper
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
export DOYAKEN_HOME="$PROJECT_DIR/.doyaken"
exec "$DOYAKEN_HOME/bin/doyaken" "$@"
WRAPPER
    chmod +x "$PROJECT_BIN/doyaken"
    ln -sf "$PROJECT_BIN/doyaken" "$PROJECT_BIN/dk"
    log_success "Created project wrappers at $PROJECT_BIN/{doyaken,dk}"
  fi

  # Copy task template
  if [ -f "$DOYAKEN_HOME/templates/TASK.md" ]; then
    /bin/cp -f "$DOYAKEN_HOME/templates/TASK.md" "$DOYAKEN_HOME/tasks/_templates/"
  fi

  # Create .gitkeep files
  touch "$DOYAKEN_HOME/tasks/1.blocked/.gitkeep"
  touch "$DOYAKEN_HOME/tasks/2.todo/.gitkeep"
  touch "$DOYAKEN_HOME/tasks/3.doing/.gitkeep"
  touch "$DOYAKEN_HOME/tasks/4.done/.gitkeep"
  touch "$DOYAKEN_HOME/logs/.gitkeep"
  touch "$DOYAKEN_HOME/state/.gitkeep"
  touch "$DOYAKEN_HOME/locks/.gitkeep"

  # Create manifest
  git_remote=""
  git_branch="main"
  if [ -d "$PROJECT_DIR/.git" ]; then
    git_remote=$(git -C "$PROJECT_DIR" remote get-url origin 2>/dev/null || echo "")
    git_branch=$(git -C "$PROJECT_DIR" branch --show-current 2>/dev/null || echo "main")
  fi

  project_name=$(basename "$PROJECT_DIR")

  cat > "$DOYAKEN_HOME/manifest.yaml" << EOF
# Doyaken Project Manifest
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

agent:
  model: "opus"
  max_retries: 2
EOF
  log_success "Created project manifest"

  # Create AGENT.md if not exists
  if [ ! -f "$PROJECT_DIR/AGENT.md" ]; then
    /bin/cp -f "$DOYAKEN_HOME/templates/AGENT.md" "$PROJECT_DIR/AGENT.md" 2>/dev/null || true
    log_success "Created AGENT.md"
  fi

  # Add to .gitignore
  if [ -f "$PROJECT_DIR/.gitignore" ]; then
    if ! grep -q ".doyaken/logs" "$PROJECT_DIR/.gitignore" 2>/dev/null; then
      cat >> "$PROJECT_DIR/.gitignore" << 'EOF'

# Doyaken runtime (not committed)
.doyaken/logs/
.doyaken/state/
.doyaken/locks/
EOF
      log_success "Updated .gitignore"
    fi
  fi
fi

# Done!
echo ""
echo -e "${GREEN}${BOLD}Installation Complete!${NC}"
echo ""
echo "Install type: $INSTALL_TYPE"
echo "Install path: $DOYAKEN_HOME"
echo "Version: $(cat "$DOYAKEN_HOME/VERSION" 2>/dev/null || echo "unknown")"
echo ""

if [[ "$INSTALL_TYPE" == "user" ]]; then
  if [ -n "${UPDATED_RC:-}" ]; then
    echo "Shell config updated: ~/$UPDATED_RC"
    echo ""
    echo "To use immediately, run:"
    echo "  source ~/$UPDATED_RC"
    echo ""
  fi

  echo "Quick start:"
  echo "  cd /path/to/your/project"
  echo "  dk init                    # Initialize project"
  echo "  dk tasks new \"My task\"     # Create a task"
  echo "  dk run 1                   # Run 1 task"
  echo ""
  echo "Upgrade:"
  echo "  dk upgrade --check         # Check for updates"
  echo "  dk upgrade                 # Apply upgrade"
else
  echo "Quick start (from project root):"
  echo "  ./bin/dk tasks new \"My task\"   # Create a task"
  echo "  ./bin/dk run 1                  # Run 1 task"
  echo "  ./bin/dk status                 # Show status"
fi

echo ""
echo "For help:"
echo "  dk help"
echo "  dk doctor"
echo ""

# Verify installation
if upgrade_verify "$DOYAKEN_HOME" > /dev/null 2>&1; then
  log_success "Installation verified"
else
  log_warn "Some files may be missing (run 'dk upgrade --force' to repair)"
fi
