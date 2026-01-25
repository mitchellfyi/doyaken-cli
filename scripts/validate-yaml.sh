#!/usr/bin/env bash
#
# validate-yaml.sh - Validate YAML files
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

echo "Validating YAML files..."
echo ""

ERRORS=0

# Determine which YAML validator to use
get_validator() {
  if command -v yq &>/dev/null; then
    echo "yq"
  elif command -v ruby &>/dev/null; then
    echo "ruby"
  elif command -v python3 &>/dev/null && python3 -c "import yaml" 2>/dev/null; then
    echo "python"
  else
    echo "none"
  fi
}

VALIDATOR=$(get_validator)

if [ "$VALIDATOR" = "none" ]; then
  echo -e "${YELLOW}WARN${NC} No YAML validator found (yq, ruby, or python3 with PyYAML)"
  echo "Skipping YAML validation"
  exit 0
fi

validate_yaml() {
  local file="$1"
  local name="${file#$ROOT_DIR/}"

  case "$VALIDATOR" in
    yq)
      if yq eval '.' "$file" >/dev/null 2>&1; then
        echo -e "${GREEN}PASS${NC} $name"
        return 0
      else
        echo -e "${RED}FAIL${NC} $name"
        yq eval '.' "$file" 2>&1 | head -5
        return 1
      fi
      ;;
    ruby)
      if ruby -ryaml -e "YAML.load_file('$file')" 2>/dev/null; then
        echo -e "${GREEN}PASS${NC} $name"
        return 0
      else
        echo -e "${RED}FAIL${NC} $name"
        ruby -ryaml -e "YAML.load_file('$file')" 2>&1 | head -5
        return 1
      fi
      ;;
    python)
      if python3 -c "import yaml; yaml.safe_load(open('$file'))" 2>/dev/null; then
        echo -e "${GREEN}PASS${NC} $name"
        return 0
      else
        echo -e "${RED}FAIL${NC} $name"
        python3 -c "import yaml; yaml.safe_load(open('$file'))" 2>&1 | head -5
        return 1
      fi
      ;;
  esac
}

# Find all YAML files
YAML_FILES=(
  "$ROOT_DIR/config/global.yaml"
  "$ROOT_DIR/templates/manifest.yaml"
)

for file in "${YAML_FILES[@]}"; do
  if [ -f "$file" ]; then
    if ! validate_yaml "$file"; then
      ERRORS=$((ERRORS + 1))
    fi
  else
    echo -e "${RED}MISS${NC} ${file#$ROOT_DIR/} (file not found)"
    ERRORS=$((ERRORS + 1))
  fi
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ "$ERRORS" -eq 0 ]; then
  echo -e "${GREEN}All YAML files valid${NC}"
else
  echo -e "${RED}$ERRORS YAML file(s) invalid${NC}"
fi
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

exit "$ERRORS"
