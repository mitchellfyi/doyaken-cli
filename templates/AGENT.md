# AGENT.md - Project Configuration

This file configures how AI agents work on this project.

## Quick Start

```bash
# Create a new task
doyaken tasks new "My task description"

# Run the agent for 1 task
doyaken run 1

# Run with a specific agent
doyaken --agent codex run 1

# Show taskboard
doyaken tasks

# Check project status
doyaken status
```

## Project Configuration

Project settings are stored in `.doyaken/manifest.yaml`. Edit it to configure:

- Project name and description
- Git remote and branch
- Quality commands (test, lint, format)
- Agent preferences (default agent, model)

## Task Management

Tasks are stored in `.doyaken/tasks/`:
- `1.blocked/` - Blocked tasks (waiting on something)
- `2.todo/` - Ready to start
- `3.doing/` - In progress (assigned to an agent)
- `4.done/` - Completed

### Task Naming Format

`PPP-SSS-slug.md` where:
- **PPP** = Priority (001=Critical, 002=High, 003=Medium, 004=Low)
- **SSS** = Sequence within priority
- **slug** = Kebab-case description

### Creating Tasks

```bash
# Via CLI
doyaken tasks new "Add user authentication"

# Manually: create file in .doyaken/tasks/2.todo/
```

## Agent Workflow

The agent operates in 8 phases per task:

0. **EXPAND** - Expand brief prompt into full task specification
1. **TRIAGE** - Validate task, check dependencies
2. **PLAN** - Gap analysis, detailed planning
3. **IMPLEMENT** - Execute the plan, write code
4. **TEST** - Run tests, add coverage
5. **DOCS** - Sync documentation
6. **REVIEW** - Code review, create follow-ups
7. **VERIFY** - Verify task management, commit

## Parallel Agents

Multiple agents can work simultaneously:

```bash
doyaken run 5 &
doyaken run 5 &
```

Agents coordinate via lock files in `.doyaken/locks/`.

## Environment Variables

```bash
# Use a different agent
DOYAKEN_AGENT=codex doyaken run 1

# Use a different model
DOYAKEN_MODEL=sonnet doyaken run 1

# Dry run (no execution)
AGENT_DRY_RUN=1 doyaken run 1

# Verbose output
AGENT_VERBOSE=1 doyaken run 1
```

## Quality Gates

All code must pass quality gates before being committed. Configure commands in `.doyaken/manifest.yaml`:

```yaml
quality:
  test_command: "npm test"
  lint_command: "npm run lint"
  format_command: "npm run format"
  typecheck_command: "npm run typecheck"
  build_command: "npm run build"
  audit_command: "npm audit --audit-level=high"
```

### Quality Principles

Follow these principles for all code:

- **KISS** - Keep It Simple, Stupid. The simplest solution is usually the best.
- **YAGNI** - You Aren't Gonna Need It. Don't build features until you need them.
- **DRY** - Don't Repeat Yourself. Single source of truth for each piece of knowledge.
- **SOLID** - Single responsibility, Open/closed, Liskov substitution, Interface segregation, Dependency inversion.

### Setting Up Quality Gates

If quality gates are missing, run:

```bash
doyaken skill setup-quality
```

This will:
- Configure linters (ESLint, Ruff, golint, etc.)
- Set up formatters (Prettier, Black, gofmt)
- Add type checking (TypeScript, mypy)
- Create CI pipeline (.github/workflows/ci.yml)
- Install git hooks (pre-commit)
- Add security audit commands

### Running Quality Checks

```bash
# Run all quality checks
doyaken skill check-quality

# Audit dependencies for vulnerabilities
doyaken skill audit-deps
```

## Troubleshooting

```bash
# Health check
doyaken doctor

# View logs
ls -la .doyaken/logs/

# Reset stuck state
rm -rf .doyaken/locks/*.lock
mv .doyaken/tasks/3.doing/*.md .doyaken/tasks/2.todo/
```

## Project-Specific Notes

Add notes here about this specific project that agents should know:

### Coding Conventions
- [Describe naming conventions, file organization, etc.]

### Quality Standards
- All code must pass lint, typecheck, and tests before commit
- No console.log, debug code, or commented-out code in commits
- Handle errors appropriately - no silent failures
- Keep functions small (< 20 lines ideal)
- Maximum nesting depth: 3 levels

### Common Patterns
- [Describe patterns used in this codebase]

### Things to Avoid
- Premature optimization without measured need
- Over-engineering or "gold plating"
- Breaking existing functionality
- Introducing security vulnerabilities
