#!/usr/bin/env bash
#
# install.sh - Install ai-agent globally
#
# Usage:
#   ./install.sh                    # Install to ~/.ai-agent
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
AI_AGENT_HOME="${1:-$HOME/.ai-agent}"

echo ""
echo -e "${BOLD}AI Agent Installer${NC}"
echo "==================="
echo ""
echo "Installing to: $AI_AGENT_HOME"
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
  log_info "Please run this script from the ai-agent repository root"
  exit 1
fi

# Create installation directory
log_info "Creating installation directory..."
mkdir -p "$AI_AGENT_HOME"
mkdir -p "$AI_AGENT_HOME/bin"
mkdir -p "$AI_AGENT_HOME/lib"
mkdir -p "$AI_AGENT_HOME/prompts"
mkdir -p "$AI_AGENT_HOME/templates"
mkdir -p "$AI_AGENT_HOME/config"
mkdir -p "$AI_AGENT_HOME/projects"

# Copy files
log_info "Copying files..."

# Core library files
cp "$SOURCE_DIR/lib/cli.sh" "$AI_AGENT_HOME/lib/"
cp "$SOURCE_DIR/lib/core.sh" "$AI_AGENT_HOME/lib/"
cp "$SOURCE_DIR/lib/registry.sh" "$AI_AGENT_HOME/lib/"
cp "$SOURCE_DIR/lib/migration.sh" "$AI_AGENT_HOME/lib/"
cp "$SOURCE_DIR/lib/taskboard.sh" "$AI_AGENT_HOME/lib/"

# Prompts (from agent/prompts)
if [ -d "$SOURCE_DIR/agent/prompts" ]; then
  cp "$SOURCE_DIR/agent/prompts"/*.md "$AI_AGENT_HOME/prompts/"
elif [ -d "$SOURCE_DIR/prompts" ]; then
  cp "$SOURCE_DIR/prompts"/*.md "$AI_AGENT_HOME/prompts/"
fi

# Templates
cp "$SOURCE_DIR/templates"/*.yaml "$AI_AGENT_HOME/templates/" 2>/dev/null || true
cp "$SOURCE_DIR/templates"/*.md "$AI_AGENT_HOME/templates/" 2>/dev/null || true

# Config
cp "$SOURCE_DIR/config/global.yaml" "$AI_AGENT_HOME/config/" 2>/dev/null || true

# Binary
cp "$SOURCE_DIR/bin/ai-agent" "$AI_AGENT_HOME/bin/"

# Make scripts executable
chmod +x "$AI_AGENT_HOME/bin/ai-agent"
chmod +x "$AI_AGENT_HOME/lib"/*.sh

# Create VERSION file
echo "1.0.0" > "$AI_AGENT_HOME/VERSION"

log_success "Files copied"

# Create symlink in /usr/local/bin if writable
SYMLINK_PATH="/usr/local/bin/ai-agent"
if [ -w "/usr/local/bin" ]; then
  log_info "Creating symlink at $SYMLINK_PATH"
  ln -sf "$AI_AGENT_HOME/bin/ai-agent" "$SYMLINK_PATH"
  log_success "Symlink created"
else
  log_warn "Cannot write to /usr/local/bin (not writable)"
  log_info "You may need to add $AI_AGENT_HOME/bin to your PATH"
fi

# Update shell config
update_shell_config() {
  local rc_file="$1"
  local rc_name="$2"

  if [ -f "$rc_file" ]; then
    if ! grep -q "AI_AGENT_HOME" "$rc_file"; then
      log_info "Updating $rc_name..."
      cat >> "$rc_file" << EOF

# ai-agent
export AI_AGENT_HOME="$AI_AGENT_HOME"
export PATH="\$AI_AGENT_HOME/bin:\$PATH"
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
if [ ! -f "$AI_AGENT_HOME/projects/registry.yaml" ]; then
  cat > "$AI_AGENT_HOME/projects/registry.yaml" << 'EOF'
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
echo "Installation directory: $AI_AGENT_HOME"
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
echo "  ai-agent init                 # Initialize project"
echo "  ai-agent tasks new \"My task\"  # Create a task"
echo "  ai-agent run 1                # Run 1 task"
echo ""
echo "For help:"
echo "  ai-agent help"
echo "  ai-agent doctor"
echo ""

# Test the installation
if command -v "$AI_AGENT_HOME/bin/ai-agent" &>/dev/null; then
  log_success "Installation verified"
else
  log_warn "Could not verify installation"
fi
