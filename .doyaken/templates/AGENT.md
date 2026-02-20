# AGENT.md - Project Configuration

This file configures how AI agents work on this project.

## Quick Start

```bash
# Run the agent
dk run "Add user authentication"

# Run with a specific agent
dk --agent codex run "Add auth"

# Interactive chat mode
dk chat

# Check project status
dk status
dk doctor
```

## Project Configuration

Project settings are in `.doyaken/manifest.yaml` (loaded automatically by the CLI). Edit it to configure:

- Project name and description
- Git remote and branch
- Quality commands (test, lint, format, build)
- Agent preferences (default agent, model)
- Retry budgets for verification gates

## Agent Workflow

Doyaken runs prompts through an 8-phase pipeline:

0. **EXPAND** - Expand brief prompt into full specification
1. **TRIAGE** - Validate feasibility, check dependencies
2. **PLAN** - Gap analysis, detailed planning
3. **IMPLEMENT** - Write the code
4. **TEST** - Run tests, add coverage
5. **DOCS** - Update documentation
6. **REVIEW** - Code review, quality check
7. **VERIFY** - Final verification and commit

After IMPLEMENT, TEST, and REVIEW, verification gates run your quality commands. If a gate fails, the phase retries with the error context injected.

## Quality Gates

All code must pass quality gates before commit. These are configured in `.doyaken/manifest.yaml` and run automatically by the CLI:

```yaml
quality:
  test_command: "npm test"
  lint_command: "npm run lint"
  format_command: "npm run format"
  build_command: "npm run build"
```

### Running Quality Checks

```bash
dk skill check-quality     # Run all quality checks
dk skill audit-deps        # Audit dependencies
dk skill setup-quality     # Set up quality gates from scratch
```

## Environment Variables

```bash
DOYAKEN_AGENT=codex dk run "Fix bug"     # Use a different agent
DOYAKEN_MODEL=sonnet dk run "Add auth"   # Use a different model
AGENT_DRY_RUN=1 dk run "Test prompt"     # Preview without executing
AGENT_VERBOSE=1 dk run "Debug issue"     # Verbose output
```

## Multi-Agent Support

Generate configuration files for all major AI agents:

```bash
dk sync  # Generates CLAUDE.md, .cursorrules, GEMINI.md, etc.
```

| File | Agent |
|------|-------|
| `AGENTS.md` | Industry standard (Codex, OpenCode) |
| `CLAUDE.md` | Claude Code |
| `.cursor/rules/*.mdc` | Cursor |
| `GEMINI.md` | Google Gemini |
| `.github/copilot-instructions.md` | GitHub Copilot |

## Troubleshooting

```bash
dk doctor       # Health check
dk cleanup      # Clean logs and state
dk sync         # Regenerate agent files
```

## Project-Specific Notes

Add notes here about this specific project that agents should know:

### Coding Conventions
- [Describe naming conventions, file organization, etc.]

### Common Patterns
- [Describe patterns used in this codebase]

### Things to Avoid
- [Known pitfalls, anti-patterns for this project]
