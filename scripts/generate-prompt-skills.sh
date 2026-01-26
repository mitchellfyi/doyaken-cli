#!/usr/bin/env bash
#
# generate-prompt-skills.sh - Generate skills from library prompts
#
# Creates simple "prompt runner" skills for each library prompt.
# These skills just load and apply the library prompt methodology.
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Get description for a prompt name
get_description() {
  local name="$1"
  case "$name" in
    api-design) echo "Review and apply API design best practices" ;;
    architecture-review) echo "Perform architecture assessment" ;;
    base) echo "Load core development principles" ;;
    code-quality) echo "Apply SOLID, DRY, KISS, YAGNI principles" ;;
    code-review) echo "Perform multi-pass code review" ;;
    competitor-analysis) echo "Research and analyze competitors" ;;
    debugging) echo "Apply systematic debugging methodology" ;;
    diagnose) echo "Diagnose bugs and issues" ;;
    documentation) echo "Apply documentation standards" ;;
    error-handling) echo "Review error handling patterns" ;;
    feature-discovery) echo "Discover and prioritize features" ;;
    git-workflow) echo "Apply git workflow best practices" ;;
    performance) echo "Analyze performance issues" ;;
    planning) echo "Create implementation plans" ;;
    refactor) echo "Apply refactoring guidelines" ;;
    security) echo "Apply OWASP security checklist" ;;
    security-review) echo "Perform security review" ;;
    technical-debt) echo "Assess technical debt" ;;
    testing) echo "Apply testing best practices" ;;
    ux-review) echo "Perform UX/CLI review" ;;
    *) echo "Apply $name methodology" ;;
  esac
}

# Convert kebab-case to Title Case
to_title() {
  echo "$1" | sed 's/-/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) tolower(substr($i,2))}1'
}

generate_skill() {
  local prompt_name="$1"
  local skills_dir="$2"

  local description
  description=$(get_description "$prompt_name")

  local title
  title=$(to_title "$prompt_name")

  local skill_file="$skills_dir/prompt-${prompt_name}.md"

  cat > "$skill_file" << EOF
---
name: prompt-${prompt_name}
description: $description
args:
  - name: target
    description: File, directory, or code to analyze
    default: "."
  - name: output
    description: Output format (summary, detailed, checklist)
    default: "detailed"
---

# $title

Apply the $prompt_name methodology to the specified target.

## Context

Target: {{ARGS.target}}
Output format: {{ARGS.output}}
Project: {{DOYAKEN_PROJECT}}

## Methodology

{{include:library/${prompt_name}.md}}

## Instructions

1. Read and understand the target ({{ARGS.target}})
2. Apply the methodology above systematically
3. Document findings using the output format ({{ARGS.output}}):
   - **summary**: Brief overview with key points
   - **detailed**: Full analysis with all sections
   - **checklist**: Checklist format with pass/fail for each item

## Output

Provide your analysis following the templates in the methodology.
EOF

  echo "  Created: prompt-${prompt_name}"
}

main() {
  local library_dir="$ROOT_DIR/prompts/library"
  local skills_dir="$ROOT_DIR/skills"

  echo "Generating prompt-based skills..."

  local count=0
  for prompt_file in "$library_dir"/*.md; do
    [ -f "$prompt_file" ] || continue

    local name
    name=$(basename "$prompt_file" .md)

    # Skip README
    [ "$name" = "README" ] && continue

    generate_skill "$name" "$skills_dir"
    count=$((count + 1))
  done

  echo ""
  echo "Generated $count prompt-based skills"
}

main "$@"
