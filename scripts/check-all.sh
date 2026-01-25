#!/usr/bin/env bash
#
# check-all.sh - Run all quality checks
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${BOLD}Doyaken Quality Checks${NC}"
echo "======================"
echo ""

FAILED=0

# Run linting
echo -e "${BOLD}[1/3] Linting Shell Scripts${NC}"
if "$SCRIPT_DIR/lint.sh"; then
  echo ""
else
  FAILED=1
  echo ""
fi

# Run YAML validation
echo -e "${BOLD}[2/3] Validating YAML Files${NC}"
if "$SCRIPT_DIR/validate-yaml.sh"; then
  echo ""
else
  FAILED=1
  echo ""
fi

# Run tests
echo -e "${BOLD}[3/3] Running Tests${NC}"
if "$SCRIPT_DIR/test.sh"; then
  echo ""
else
  FAILED=1
  echo ""
fi

# Summary
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ "$FAILED" -eq 0 ]; then
  echo -e "${GREEN}All checks passed!${NC}"
  exit 0
else
  echo -e "${RED}Some checks failed${NC}"
  exit 1
fi
