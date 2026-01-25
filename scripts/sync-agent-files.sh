#!/usr/bin/env bash
#
# sync-agent-files.sh - Generate agent-specific configuration files
#
# This script copies agent templates to a project and updates them
# with the current timestamp. The generated files point to .doyaken/
# as the source of truth.
#
# Usage:
#   ./scripts/sync-agent-files.sh [project_dir]
#
# Options:
#   project_dir  Target project directory (default: current directory)
#
# Generated Files:
#   AGENTS.md     - Central source of truth listing all prompts
#   CLAUDE.md     - Claude Code configuration
#   .cursorrules  - Cursor configuration
#   CODEX.md      - OpenAI Codex configuration
#   GEMINI.md     - Google Gemini configuration
#   .opencode.json - OpenCode configuration
#

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOYAKEN_HOME="${DOYAKEN_HOME:-$(cd "$SCRIPT_DIR/.." && pwd)}"
TEMPLATES_DIR="$DOYAKEN_HOME/templates/agents"

# Target directory
PROJECT_DIR="${1:-$(pwd)}"

# Timestamp for generated files
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if project has .doyaken directory
if [ ! -d "$PROJECT_DIR/.doyaken" ]; then
    log_error "No .doyaken/ directory found in $PROJECT_DIR"
    log_info "Run 'doyaken init' first to initialize the project"
    exit 1
fi

log_info "Syncing agent files to $PROJECT_DIR"

# Function to process template
process_template() {
    local template="$1"
    local output="$2"

    # Replace {{TIMESTAMP}} placeholder
    sed "s/{{TIMESTAMP}}/$TIMESTAMP/g" "$template" > "$output"
}

# Sync each agent file
sync_file() {
    local template_name="$1"
    local output_name="${2:-$template_name}"
    local template="$TEMPLATES_DIR/$template_name"
    local output="$PROJECT_DIR/$output_name"

    if [ -f "$template" ]; then
        process_template "$template" "$output"
        log_success "Generated $output_name"
    else
        log_warn "Template not found: $template_name"
    fi
}

# Generate all agent files
sync_file "AGENTS.md"
sync_file "CLAUDE.md"
sync_file ".cursorrules"
sync_file "CODEX.md"
sync_file "GEMINI.md"
sync_file "opencode.json" ".opencode.json"

# Copy prompts library to project if it doesn't exist
if [ ! -d "$PROJECT_DIR/.doyaken/prompts/library" ]; then
    log_info "Copying prompts library to project..."
    mkdir -p "$PROJECT_DIR/.doyaken/prompts"

    if [ -d "$DOYAKEN_HOME/prompts/library" ]; then
        cp -r "$DOYAKEN_HOME/prompts/library" "$PROJECT_DIR/.doyaken/prompts/"
        log_success "Copied prompts/library/"
    fi
fi

# Copy phases to project if they don't exist
if [ ! -d "$PROJECT_DIR/.doyaken/prompts/phases" ]; then
    log_info "Copying phase prompts to project..."

    if [ -d "$DOYAKEN_HOME/prompts/phases" ]; then
        cp -r "$DOYAKEN_HOME/prompts/phases" "$PROJECT_DIR/.doyaken/prompts/"
        log_success "Copied prompts/phases/"
    fi
fi

# Copy skills to project if they don't exist
if [ ! -d "$PROJECT_DIR/.doyaken/skills" ]; then
    log_info "Copying skills to project..."

    if [ -d "$DOYAKEN_HOME/skills" ]; then
        cp -r "$DOYAKEN_HOME/skills" "$PROJECT_DIR/.doyaken/"
        log_success "Copied skills/"
    fi
fi

# Copy hooks to project if they don't exist
if [ ! -d "$PROJECT_DIR/.doyaken/hooks" ]; then
    log_info "Copying hooks to project..."

    if [ -d "$DOYAKEN_HOME/hooks" ]; then
        cp -r "$DOYAKEN_HOME/hooks" "$PROJECT_DIR/.doyaken/"
        log_success "Copied hooks/"
    fi
fi

echo ""
log_success "Agent files synced successfully!"
echo ""
echo "Generated files:"
echo "  - AGENTS.md      (central source of truth)"
echo "  - CLAUDE.md      (Claude Code)"
echo "  - .cursorrules   (Cursor)"
echo "  - CODEX.md       (OpenAI Codex)"
echo "  - GEMINI.md      (Google Gemini)"
echo "  - .opencode.json (OpenCode)"
echo ""
echo "All files point to .doyaken/ as the source of truth."
echo "To update, edit files in .doyaken/ and run: doyaken sync"
