#!/usr/bin/env bash
#
# generate-commands.sh - Generate slash commands from skills
#
# Creates Claude Code compatible slash commands in .claude/commands/
# from doyaken skills.
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[generate]${NC} $1"; }
log_success() { echo -e "${GREEN}[generate]${NC} $1"; }

# Generate a single slash command from a skill
generate_command() {
  local skill_file="$1"
  local output_dir="$2"

  local name
  name=$(basename "$skill_file" .md)

  # Extract description from frontmatter
  local description=""
  description=$(awk '
    /^---$/ { if (started) exit; started = 1; next }
    started && /^description:/ {
      gsub(/^description:[[:space:]]*/, "")
      gsub(/"/, "")
      print
      exit
    }
  ' "$skill_file")

  [ -z "$description" ] && description="Run the $name skill"

  # Create command file
  local cmd_file="$output_dir/${name}.md"

  cat > "$cmd_file" << EOF
---
description: $description
---

Run the doyaken skill: $name

\`\`\`bash
doyaken skill $name \$ARGUMENTS
\`\`\`

If doyaken is not available, follow the instructions below:

$(cat "$skill_file" | tail -n +$(awk '/^---$/{count++; if(count==2){print NR; exit}}' "$skill_file"))
EOF

  echo "$name"
}

# Generate commands for a directory of skills
generate_commands() {
  local skills_dir="$1"
  local output_dir="$2"

  mkdir -p "$output_dir"

  local count=0
  for skill_file in "$skills_dir"/*.md; do
    [ -f "$skill_file" ] || continue
    [ "$(basename "$skill_file")" = "README.md" ] && continue

    generate_command "$skill_file" "$output_dir"
    count=$((count + 1))
  done

  echo "$count"
}

# Generate commands for library prompts (create simple wrapper skills first)
generate_library_commands() {
  local library_dir="$1"
  local output_dir="$2"

  mkdir -p "$output_dir"

  local count=0
  for prompt_file in "$library_dir"/*.md; do
    [ -f "$prompt_file" ] || continue
    [ "$(basename "$prompt_file")" = "README.md" ] && continue

    local name
    name=$(basename "$prompt_file" .md)

    # Create command that loads the library prompt
    local cmd_file="$output_dir/${name}.md"

    cat > "$cmd_file" << EOF
---
description: Apply $name methodology to the current context
---

$(cat "$prompt_file")

---

Apply this methodology to the current context. If given a specific file or code, analyze it according to these guidelines. Provide structured output following the templates above.
EOF

    count=$((count + 1))
  done

  echo "$count"
}

# Main
main() {
  local target_dir="${1:-.}"

  # Resolve to absolute path
  target_dir=$(cd "$target_dir" 2>/dev/null && pwd)

  local commands_dir="$target_dir/.claude/commands"

  log_info "Generating slash commands in: $commands_dir"

  mkdir -p "$commands_dir"

  # Determine source directories
  local doyaken_home="${DOYAKEN_HOME:-$ROOT_DIR}"

  # Generate from skills
  if [ -d "$doyaken_home/skills" ]; then
    log_info "Generating from skills..."
    local skill_count
    skill_count=$(generate_commands "$doyaken_home/skills" "$commands_dir")
    log_success "Generated $skill_count skill commands"
  fi

  # Generate from library prompts
  if [ -d "$doyaken_home/prompts/library" ]; then
    log_info "Generating from library prompts..."
    local lib_count
    lib_count=$(generate_library_commands "$doyaken_home/prompts/library" "$commands_dir")
    log_success "Generated $lib_count library commands"
  fi

  # Generate workflow command
  cat > "$commands_dir/workflow.md" << 'EOF'
---
description: Run the full 8-phase task workflow on a task
---

# Workflow: 8-Phase Task Execution

Run the doyaken 8-phase workflow on a task:

```bash
doyaken run 1
```

Or create and run a single task:

```bash
doyaken task "your task description"
```

## Phases

1. **EXPAND** - Expand brief prompt into full task specification
2. **TRIAGE** - Validate task, check dependencies
3. **PLAN** - Gap analysis, detailed planning
4. **IMPLEMENT** - Execute the plan, write code
5. **TEST** - Run tests, add coverage
6. **DOCS** - Sync documentation
7. **REVIEW** - Code review, create follow-ups
8. **VERIFY** - Verify task management, commit

If doyaken is not available, work through these phases manually in sequence.
EOF
  log_success "Generated workflow command"

  # Generate MCP command
  cat > "$commands_dir/mcp.md" << 'EOF'
---
description: Check and configure MCP integrations
---

# MCP Integration Status

Check MCP (Model Context Protocol) integration status:

```bash
doyaken mcp status
```

Configure MCP for your project:

```bash
doyaken mcp configure
```

## Available Integrations

- **GitHub** - Issues, PRs, repos
- **Linear** - Issues, projects
- **Slack** - Messages, channels
- **Jira** - Issues, sprints

Enable in `.doyaken/manifest.yaml`:

```yaml
integrations:
  github:
    enabled: true
```
EOF
  log_success "Generated mcp command"

  log_info "Done! Commands available via /command in Claude Code"
}

main "$@"
