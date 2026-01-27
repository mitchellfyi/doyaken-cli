#!/bin/bash
#
# Hook: quality-gates-check
# Type: PreToolUse (on first tool use) or Notification
# Purpose: Warn if quality gates are missing from the project
#
# This hook checks if the project has quality gates configured
# and warns the agent if they're missing.

set -e

# Only run on session start or specific triggers
# Check if manifest exists
MANIFEST="${DOYAKEN_PROJECT:-.}/.doyaken/manifest.yaml"

if [ ! -f "$MANIFEST" ]; then
    exit 0
fi

# Check for quality commands in manifest
has_quality() {
    local cmd="$1"
    grep -q "^[[:space:]]*${cmd}:" "$MANIFEST" 2>/dev/null && \
    ! grep -q "^[[:space:]]*#[[:space:]]*${cmd}:" "$MANIFEST" 2>/dev/null
}

missing=()

# Check each quality gate
if ! has_quality "lint_command"; then
    missing+=("lint")
fi
if ! has_quality "test_command"; then
    missing+=("test")
fi
if ! has_quality "typecheck_command"; then
    missing+=("typecheck")
fi
if ! has_quality "build_command"; then
    missing+=("build")
fi
if ! has_quality "audit_command"; then
    missing+=("security audit")
fi

# Also check for CI and git hooks
CI_MISSING=false
HOOKS_MISSING=false

PROJECT_DIR="${DOYAKEN_PROJECT:-.}"

if [ ! -d "$PROJECT_DIR/.github/workflows" ] && [ ! -f "$PROJECT_DIR/.gitlab-ci.yml" ]; then
    CI_MISSING=true
fi

if [ ! -d "$PROJECT_DIR/.husky" ] && [ ! -f "$PROJECT_DIR/.pre-commit-config.yaml" ]; then
    HOOKS_MISSING=true
fi

# Output warning if issues found
if [ ${#missing[@]} -gt 0 ] || [ "$CI_MISSING" = true ] || [ "$HOOKS_MISSING" = true ]; then
    echo "⚠️  Quality Gates Warning"
    echo "========================"
    echo ""

    if [ ${#missing[@]} -gt 0 ]; then
        echo "Missing quality commands in manifest.yaml:"
        for cmd in "${missing[@]}"; do
            echo "  - $cmd"
        done
        echo ""
    fi

    if [ "$CI_MISSING" = true ]; then
        echo "Missing CI pipeline:"
        echo "  - No .github/workflows/ or .gitlab-ci.yml found"
        echo ""
    fi

    if [ "$HOOKS_MISSING" = true ]; then
        echo "Missing git hooks:"
        echo "  - No .husky/ or .pre-commit-config.yaml found"
        echo ""
    fi

    echo "To set up quality gates, run:"
    echo "  doyaken skill setup-quality"
    echo ""
fi
