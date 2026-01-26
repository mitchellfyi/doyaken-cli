# Skills

Runnable prompt templates invoked via `doyaken skill <name>`.

```bash
# List all skills
doyaken skills

# Run a skill
doyaken skill security-audit

# Run with arguments
doyaken skill review-codebase --scope=security

# Show skill info
doyaken skill tech-debt --info
```

## Architecture

Skills **compose from library prompts** - they don't contain methodology directly:

```
┌─────────────────────────────────────┐
│          prompts/library/           │
│       (Single Source of Truth)      │
└─────────────────────────────────────┘
                  │
                  │ {{include:library/...}}
                  ▼
┌─────────────────────────────────────┐
│              skills/                │
│                                     │
│  • YAML frontmatter (args, etc.)    │
│  • Includes from library            │
│  • Skill-specific instructions      │
│  • Output format                    │
└─────────────────────────────────────┘
```

**Rule:** If you're writing methodology in a skill, stop. Put it in `prompts/library/` first, then include it.

## Available Skills

### Workflow & System

| Skill | Description | Slash Command |
|-------|-------------|---------------|
| `workflow` | Run 8-phase task workflow | `/workflow` |
| `mcp-status` | Check MCP integrations | `/mcp-status` |

### Code Review & Audit

| Skill | Description | Slash Command |
|-------|-------------|---------------|
| `review-codebase` | Full codebase review | `/review-codebase` |
| `security-audit` | OWASP security assessment | `/security-audit` |
| `performance-audit` | Performance analysis | `/performance-audit` |
| `tech-debt` | Technical debt assessment | `/tech-debt` |

### Quality

| Skill | Description | Slash Command |
|-------|-------------|---------------|
| `check-quality` | Run quality checks | `/check-quality` |
| `setup-quality` | Configure quality tools | `/setup-quality` |
| `audit-deps` | Audit dependencies | `/audit-deps` |

### Discovery & Planning

| Skill | Description | Slash Command |
|-------|-------------|---------------|
| `feature-discover` | Feature research | `/feature-discover` |
| `ux-audit` | UX assessment | `/ux-audit` |

### Integrations

| Skill | Description | Requires |
|-------|-------------|----------|
| `github-import` | Import GitHub issues | GitHub MCP |
| `github-sync` | Sync task status | GitHub MCP |
| `create-pr` | Create pull request | GitHub MCP |
| `notify-slack` | Slack notifications | Slack MCP |
| `sync-agents` | Sync agent files | - |

### Prompt-Based Skills

Every library prompt has a corresponding skill prefixed with `prompt-`:

| Skill | Description | Slash Command |
|-------|-------------|---------------|
| `prompt-code-quality` | Apply SOLID, DRY, KISS, YAGNI | `/prompt-code-quality` |
| `prompt-security` | OWASP security checklist | `/prompt-security` |
| `prompt-testing` | Testing methodology | `/prompt-testing` |
| `prompt-code-review` | Multi-pass code review | `/prompt-code-review` |
| `prompt-planning` | Implementation planning | `/prompt-planning` |
| `prompt-debugging` | Debugging methodology | `/prompt-debugging` |
| `prompt-performance` | Performance analysis | `/prompt-performance` |
| `prompt-architecture-review` | Architecture assessment | `/prompt-architecture-review` |
| ... | (one for each library prompt) | |

## Slash Commands

Skills are automatically available as slash commands in Claude Code:

```bash
# Regenerate slash commands
doyaken commands

# Commands are stored in:
.claude/commands/
```

On `doyaken init`, slash commands are automatically generated. Use `doyaken sync` or `doyaken commands` to regenerate after updates.

## Skill Structure

```markdown
---
name: skill-name
description: What this skill does
args:
  - name: scope
    description: Analysis scope
    default: "full"
  - name: path
    description: Path to analyze
    default: "."
requires:
  - github  # Optional: MCP servers needed
---

# Skill Title

## Context

Project: {{DOYAKEN_PROJECT}}
Scope: {{ARGS.scope}}
Path: {{ARGS.path}}

## Methodology

{{include:library/relevant-methodology.md}}

## Instructions

[Skill-specific instructions...]

## Output

[Expected output format...]
```

## Creating New Skills

### Step 1: Check for Library Content

Does the methodology exist in `prompts/library/`?

- **Yes:** Proceed to step 3
- **No:** Create it first (step 2)

### Step 2: Create Library Prompt (if needed)

```markdown
# prompts/library/my-methodology.md

## Mindset
[Principles...]

## Checklist
- [ ] Item 1
- [ ] Item 2

## [Detailed Sections...]
```

### Step 3: Create the Skill

```markdown
# skills/my-skill.md

---
name: my-skill
description: What this does
args:
  - name: target
    description: What to analyze
    default: "."
---

# My Skill

## Context

Project: {{DOYAKEN_PROJECT}}
Target: {{ARGS.target}}

## Methodology

{{include:library/my-methodology.md}}

## Instructions

1. Analyze the target
2. Apply the methodology
3. Document findings

## Output

\`\`\`
## Report

### Findings
[...]

### Recommendations
[...]
\`\`\`
```

### Step 4: Test and Document

1. Add to `scripts/test.sh` skills check
2. Test: `doyaken skill my-skill`
3. Update this README

## Arguments

### Defining Arguments

```yaml
args:
  - name: scope
    description: What to analyze (full, partial)
    default: "full"
  - name: path
    description: Path to check
    default: "."
  - name: create-tasks
    description: Create follow-up tasks
    default: "true"
```

### Using Arguments

```markdown
Scope: {{ARGS.scope}}
Path: {{ARGS.path}}

{{#if create-tasks == "true"}}
Create tasks for findings.
{{/if}}
```

### Passing Arguments

```bash
doyaken skill review-codebase --scope=security --path=src/
```

## MCP Requirements

Some skills require MCP (Model Context Protocol) servers:

```yaml
requires:
  - github    # Needs GitHub MCP server
  - slack     # Needs Slack MCP server
```

Check MCP status: `doyaken mcp status`

## Locations

Skills are loaded from (in order):
1. Project: `.doyaken/skills/`
2. Global: `$DOYAKEN_HOME/skills/`

Project skills override global skills with the same name.

## See Also

- [CONTRIBUTING.md](../CONTRIBUTING.md) - Full architecture documentation
- [prompts/library/](../prompts/library/) - Source of truth for methodology
