#!/usr/bin/env bash
#
# setup-hooks.sh - Install git hooks for development
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

echo "Setting up git hooks..."

# Configure git to use our hooks directory
git config core.hooksPath .githooks

echo -e "${GREEN}Git hooks installed!${NC}"
echo ""
echo "Hooks enabled:"
echo "  - pre-commit: Lint staged shell scripts and YAML"
echo "  - pre-push: Run full test suite"
echo ""
echo -e "${YELLOW}To disable hooks temporarily:${NC}"
echo "  git commit --no-verify"
echo "  git push --no-verify"
