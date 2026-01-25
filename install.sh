#!/usr/bin/env bash
#
# install.sh - Install doyaken
#
# Usage:
#   ./install.sh                      # Install to ~/.doyaken (user)
#   ./install.sh --project            # Install to ./.doyaken (current project)
#   ./install.sh --project /path      # Install to /path/.doyaken
#   curl -sSL <url>/install.sh | bash                    # User install
#   curl -sSL <url>/install.sh | bash -s -- --project    # Project install
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
    --help|-h)
      cat << 'EOF'
doyaken installer

Usage:
  ./install.sh                      Install to ~/.doyaken (user-level)
  ./install.sh --project            Install to ./.doyaken (current directory)
  ./install.sh --project /path      Install to /path/.doyaken

Options:
  --project, -p    Install to project directory instead of user home
  --help, -h       Show this help

Examples:
  # User-level install (recommended for personal use)
  curl -sSL https://raw.githubusercontent.com/doyaken/doyaken/main/install.sh | bash

  # Project-level install (for team/repo-specific setup)
  curl -sSL https://raw.githubusercontent.com/doyaken/doyaken/main/install.sh | bash -s -- --project
EOF
      exit 0
      ;;
    *)
      # Legacy: treat first arg as path for user install
      if [[ "$INSTALL_MODE" == "user" && -z "$PROJECT_PATH" ]]; then
        DOYAKEN_HOME="$1"
      fi
      shift
      ;;
  esac
done

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
echo ""

# Check dependencies
log_info "Checking dependencies..."

if ! command -v claude &>/dev/null; then
  log_warn "Claude CLI not found (required to run agent)"
  echo "  Install from: https://claude.ai/cli"
else
  log_success "Claude CLI found"
fi

if ! command -v bash &>/dev/null || [[ "${BASH_VERSION%%.*}" -lt 4 ]]; then
  log_warn "Bash 4+ recommended (found: ${BASH_VERSION:-unknown})"
fi

# Determine source directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check if running from git repo or downloaded release
if [ -d "$SCRIPT_DIR/lib" ] && [ -f "$SCRIPT_DIR/lib/cli.sh" ]; then
  SOURCE_DIR="$SCRIPT_DIR"
  log_info "Installing from local source: $SOURCE_DIR"
else
  log_error "Source files not found"
  log_info "Please run this script from the doyaken repository root"
  exit 1
fi

# Create installation directory structure
log_info "Creating directory structure..."
mkdir -p "$DOYAKEN_HOME/bin"
mkdir -p "$DOYAKEN_HOME/lib"
mkdir -p "$DOYAKEN_HOME/prompts"
mkdir -p "$DOYAKEN_HOME/templates"
mkdir -p "$DOYAKEN_HOME/config"
mkdir -p "$DOYAKEN_HOME/projects"

# Copy files
log_info "Copying files..."

# Core library files
cp "$SOURCE_DIR/lib/cli.sh" "$DOYAKEN_HOME/lib/"
cp "$SOURCE_DIR/lib/core.sh" "$DOYAKEN_HOME/lib/"
cp "$SOURCE_DIR/lib/registry.sh" "$DOYAKEN_HOME/lib/"
cp "$SOURCE_DIR/lib/migration.sh" "$DOYAKEN_HOME/lib/"
cp "$SOURCE_DIR/lib/taskboard.sh" "$DOYAKEN_HOME/lib/"

# Prompts
if [ -d "$SOURCE_DIR/prompts" ]; then
  cp "$SOURCE_DIR/prompts"/*.md "$DOYAKEN_HOME/prompts/"
fi

# Templates
cp "$SOURCE_DIR/templates"/*.yaml "$DOYAKEN_HOME/templates/" 2>/dev/null || true
cp "$SOURCE_DIR/templates"/*.md "$DOYAKEN_HOME/templates/" 2>/dev/null || true

# Config
cp "$SOURCE_DIR/config/global.yaml" "$DOYAKEN_HOME/config/" 2>/dev/null || true

# Binary
cp "$SOURCE_DIR/bin/doyaken" "$DOYAKEN_HOME/bin/"

# Make scripts executable
chmod +x "$DOYAKEN_HOME/bin/doyaken"
chmod +x "$DOYAKEN_HOME/lib"/*.sh

# Create VERSION file
echo "1.0.0" > "$DOYAKEN_HOME/VERSION"

# Create dk alias
ln -sf "$DOYAKEN_HOME/bin/doyaken" "$DOYAKEN_HOME/bin/dk"

log_success "Files copied"

# Handle PATH and symlinks based on install type
if [[ "$INSTALL_TYPE" == "user" ]]; then
  # User install: create symlinks in /usr/local/bin if writable
  if [ -w "/usr/local/bin" ]; then
    log_info "Creating symlinks at /usr/local/bin"
    ln -sf "$DOYAKEN_HOME/bin/doyaken" "/usr/local/bin/doyaken"
    ln -sf "$DOYAKEN_HOME/bin/doyaken" "/usr/local/bin/dk"
    log_success "Symlinks created (doyaken, dk)"
  else
    log_warn "Cannot write to /usr/local/bin"
    log_info "Add to your PATH: export PATH=\"$DOYAKEN_HOME/bin:\$PATH\""
  fi

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
    cat > "$DOYAKEN_HOME/projects/registry.yaml" << 'EOF'
# Doyaken Project Registry
version: 1
projects: []
aliases: {}
EOF
  fi
else
  # Project install: create wrapper scripts in project bin/
  PROJECT_BIN="$PROJECT_DIR/bin"
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

  # Initialize project structure
  mkdir -p "$DOYAKEN_HOME/tasks/todo"
  mkdir -p "$DOYAKEN_HOME/tasks/doing"
  mkdir -p "$DOYAKEN_HOME/tasks/done"
  mkdir -p "$DOYAKEN_HOME/tasks/_templates"
  mkdir -p "$DOYAKEN_HOME/logs"
  mkdir -p "$DOYAKEN_HOME/state"
  mkdir -p "$DOYAKEN_HOME/locks"

  # Copy task template
  if [ -f "$DOYAKEN_HOME/templates/task.md" ]; then
    cp "$DOYAKEN_HOME/templates/task.md" "$DOYAKEN_HOME/tasks/_templates/"
  fi

  # Create .gitkeep files
  touch "$DOYAKEN_HOME/tasks/todo/.gitkeep"
  touch "$DOYAKEN_HOME/tasks/doing/.gitkeep"
  touch "$DOYAKEN_HOME/tasks/done/.gitkeep"
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

  # Create AI-AGENT.md if not exists
  if [ ! -f "$PROJECT_DIR/AI-AGENT.md" ]; then
    cp "$DOYAKEN_HOME/templates/AI-AGENT.md" "$PROJECT_DIR/AI-AGENT.md" 2>/dev/null || true
    log_success "Created AI-AGENT.md"
  fi

  # Add to .gitignore
  if [ -f "$PROJECT_DIR/.gitignore" ]; then
    if ! grep -q ".doyaken/logs" "$PROJECT_DIR/.gitignore" 2>/dev/null; then
      cat >> "$PROJECT_DIR/.gitignore" << 'EOF'

# Doyaken
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
if [ -x "$DOYAKEN_HOME/bin/doyaken" ]; then
  log_success "Installation verified"
else
  log_warn "Could not verify installation"
fi
