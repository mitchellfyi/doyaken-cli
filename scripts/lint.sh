#!/usr/bin/env bash
#
# lint.sh - Lint all shell scripts with shellcheck
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

# Check if shellcheck is installed
if ! command -v shellcheck &>/dev/null; then
  echo -e "${RED}Error: shellcheck is not installed${NC}"
  echo "Install it with:"
  echo "  macOS:  brew install shellcheck"
  echo "  Ubuntu: apt-get install shellcheck"
  exit 1
fi

echo "Running shellcheck..."
echo ""

ERRORS=0
WARNINGS=0

# Find all shell scripts
SCRIPTS=(
  "$ROOT_DIR/bin/doyaken"
  "$ROOT_DIR/install.sh"
)

# Add lib scripts
for script in "$ROOT_DIR/lib/"*.sh; do
  [ -f "$script" ] && SCRIPTS+=("$script")
done

# Add other scripts (excluding this script to avoid self-lint issues)
for script in "$ROOT_DIR/scripts/"*.sh; do
  [ -f "$script" ] && SCRIPTS+=("$script")
done

# Add githooks
for script in "$ROOT_DIR/.githooks/"*; do
  [ -f "$script" ] && SCRIPTS+=("$script")
done

# Lint each script
for script in "${SCRIPTS[@]}"; do
  if [ ! -f "$script" ]; then
    continue
  fi

  name="${script#$ROOT_DIR/}"

  # Run shellcheck with specific exclusions
  # SC1091: Not following sourced files (they may not exist during lint)
  # SC2034: Variable appears unused (may be used in sourced files)
  output=$(shellcheck -e SC1091,SC2034 -f gcc "$script" 2>&1 || true)

  if [ -n "$output" ]; then
    error_count=$(echo "$output" | grep -c " error:" || true)
    warning_count=$(echo "$output" | grep -c " warning:" || true)
    info_count=$(echo "$output" | grep -c " info:" || true)
    style_count=$(echo "$output" | grep -c " style:" || true)
    note_count=$((info_count + style_count))

    if [ "$error_count" -gt 0 ]; then
      echo -e "${RED}FAIL${NC} $name ($error_count errors, $warning_count warnings)"
      echo "$output" | head -20
      ERRORS=$((ERRORS + error_count))
    elif [ "$warning_count" -gt 0 ]; then
      echo -e "${YELLOW}WARN${NC} $name ($warning_count warnings)"
      WARNINGS=$((WARNINGS + warning_count))
    elif [ "$note_count" -gt 0 ]; then
      # Info/style issues - pass but note
      echo -e "${GREEN}PASS${NC} $name (${note_count} notes)"
    else
      echo -e "${GREEN}PASS${NC} $name"
    fi
  else
    echo -e "${GREEN}PASS${NC} $name"
  fi
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "Errors:   ${RED}$ERRORS${NC}"
echo -e "Warnings: ${YELLOW}$WARNINGS${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ "$ERRORS" -gt 0 ]; then
  exit 1
fi

exit 0
