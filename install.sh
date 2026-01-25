#!/usr/bin/env bash
#
# install.sh - Install doyaken globally
#
# Usage:
#   ./install.sh                    # Install to ~/.doyaken
#   ./install.sh /custom/path       # Install to custom location
#   curl -sSL <url>/install.sh | bash  # One-liner install
#
set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[install]${NC} $1"; }
log_success() { echo -e "${GREEN}[install]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[install]${NC} $1"; }
log_error() { echo -e "${RED}[install]${NC} $1" >&2; }

# Default installation directory
DOYAKEN_HOME="${1:-$HOME/.doyaken}"

echo ""
echo -e "${BOLD}AI Agent Installer${NC}"
echo "==================="
echo ""
echo "Installing to: $DOYAKEN_HOME"
echo ""

# Check dependencies
log_info "Checking dependencies..."

if ! command -v claude &>/dev/null; then
  log_error "Claude CLI not found"
  echo ""
  echo "Please install the Claude CLI first:"
  echo "  https://claude.ai/cli"
  echo ""
  exit 1
fi
log_success "Claude CLI found"

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

# Create installation directory
log_info "Creating installation directory..."
mkdir -p "$DOYAKEN_HOME"
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

# Prompts (from agent/prompts)
if [ -d "$SOURCE_DIR/agent/prompts" ]; then
  cp "$SOURCE_DIR/agent/prompts"/*.md "$DOYAKEN_HOME/prompts/"
elif [ -d "$SOURCE_DIR/prompts" ]; then
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

log_success "Files copied"

# Create symlinks in /usr/local/bin if writable
if [ -w "/usr/local/bin" ]; then
  log_info "Creating symlinks at /usr/local/bin"
  ln -sf "$DOYAKEN_HOME/bin/doyaken" "/usr/local/bin/doyaken"
  ln -sf "$DOYAKEN_HOME/bin/doyaken" "/usr/local/bin/dk"
  log_success "Symlinks created (doyaken, dk)"
else
  log_warn "Cannot write to /usr/local/bin (not writable)"
  log_info "You may need to add $DOYAKEN_HOME/bin to your PATH"
  # Create dk alias in bin directory
  ln -sf "$DOYAKEN_HOME/bin/doyaken" "$DOYAKEN_HOME/bin/dk"
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
# AI Agent Project Registry
version: 1
projects: []
aliases: {}
EOF
fi

# Done!
echo ""
echo -e "${GREEN}${BOLD}Installation Complete!${NC}"
echo ""
echo "Installation directory: $DOYAKEN_HOME"
echo ""

if [ -n "$UPDATED_RC" ]; then
  echo "Shell config updated: ~/$UPDATED_RC"
  echo ""
  echo "To use immediately, run:"
  echo "  source ~/$UPDATED_RC"
  echo ""
fi

echo "Quick start:"
echo "  cd /path/to/your/project"
echo "  doyaken init                 # Initialize project"
echo "  doyaken tasks new \"My task\"  # Create a task"
echo "  doyaken run 1                # Run 1 task"
echo ""
echo "For help:"
echo "  doyaken help"
echo "  doyaken doctor"
echo ""

# Test the installation
if command -v "$DOYAKEN_HOME/bin/doyaken" &>/dev/null; then
  log_success "Installation verified"
else
  log_warn "Could not verify installation"
fi
