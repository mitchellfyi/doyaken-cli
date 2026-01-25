# AI-AGENT.md - Project Configuration

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
- `todo/` - Ready to start
- `doing/` - In progress (assigned to an agent)
- `done/` - Completed

### Task Naming Format

`PPP-SSS-slug.md` where:
- **PPP** = Priority (001=Critical, 002=High, 003=Medium, 004=Low)
- **SSS** = Sequence within priority
- **slug** = Kebab-case description

### Creating Tasks

```bash
# Via CLI
doyaken tasks new "Add user authentication"

# Manually: create file in .doyaken/tasks/todo/
```

## Agent Workflow

The agent operates in 7 phases per task:

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

Configure quality commands in `.doyaken/manifest.yaml`:

```yaml
quality:
  test_command: "npm test"
  lint_command: "npm run lint"
  format_command: "npm run format"
```

## Troubleshooting

```bash
# Health check
doyaken doctor

# View logs
ls -la .doyaken/logs/

# Reset stuck state
rm -rf .doyaken/locks/*.lock
mv .doyaken/tasks/doing/*.md .doyaken/tasks/todo/
```

## Project-Specific Notes

Add notes here about this specific project that agents should know:

- Coding conventions to follow
- Quality standards to maintain
- Common patterns in this codebase
- Things to avoid
