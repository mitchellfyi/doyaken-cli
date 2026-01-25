# AI-AGENT.md - Project Operating Manual

This file configures how AI agents work on this project.

## Quick Start

```bash
# Initialize a project (if not done)
doyaken init

# Create a new task
doyaken tasks new "My first task"

# Run the agent for 1 task
doyaken run 1

# Run the agent for 5 tasks (default)
doyaken

# Show taskboard
doyaken tasks

# Check project status
doyaken status
```

## Project Configuration

Project settings are stored in `.doyaken/manifest.yaml`:

```yaml
project:
  name: "my-project"
  description: "A description"

git:
  remote: "git@github.com:user/repo.git"
  branch: "main"

quality:
  test_command: "npm test"
  lint_command: "npm run lint"
```

## Task Management

Tasks are stored in `.doyaken/tasks/`:
- `todo/` - Ready to start
- `doing/` - In progress (assigned to an agent)
- `done/` - Completed

### Task File Format

Task files use the naming convention: `PPP-SSS-slug.md`
- **PPP** = Priority (001=Critical, 002=High, 003=Medium, 004=Low)
- **SSS** = Sequence within priority (001, 002, etc.)
- **slug** = Kebab-case description

Examples:
- `001-001-fix-security-vulnerability.md`
- `003-001-add-user-profile-page.md`

### Creating Tasks

```bash
# Via CLI
doyaken tasks new "Add user authentication"

# Manually
# Create a file in .doyaken/tasks/todo/ using the template
```

## Agent Workflow

The agent operates in 7 phases:

1. **TRIAGE** (2min) - Validate task, check dependencies
2. **PLAN** (5min) - Gap analysis, detailed planning
3. **IMPLEMENT** (30min) - Execute the plan, write code
4. **TEST** (10min) - Run tests, add coverage
5. **DOCS** (5min) - Sync documentation
6. **REVIEW** (10min) - Code review, create follow-ups
7. **VERIFY** (3min) - Verify task management, commit

## Parallel Agents

Multiple agents can work simultaneously:

```bash
# Terminal 1
doyaken run 5 &

# Terminal 2
doyaken run 5 &
```

Agents coordinate via lock files in `.doyaken/locks/`.

## Environment Variables

```bash
# Model selection
CLAUDE_MODEL=sonnet doyaken run 1

# Timeout adjustments
TIMEOUT_IMPLEMENT=3600 doyaken run 1

# Dry run (no execution)
AGENT_DRY_RUN=1 doyaken run 1

# Verbose output
AGENT_VERBOSE=1 doyaken run 1

# Skip specific phases
SKIP_DOCS=1 doyaken run 1
```

## Quality Gates

Configure quality commands in the manifest:

```yaml
quality:
  test_command: "npm test"
  lint_command: "npm run lint"
  format_command: "npm run format"
  build_command: "npm run build"
```

The agent runs these during the TEST phase.

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

## Operating Principles

1. **Read before write** - Understand context first
2. **Small changes** - Easier to review, easier to revert
3. **Test everything** - No untested code
4. **Log everything** - Document in task files
5. **Fail fast** - Don't continue on broken state
6. **Be autonomous** - Make decisions, don't wait
7. **Be reversible** - Prefer undoable changes
8. **Be transparent** - Document decisions
9. **Be thorough** - "Exists" ≠ "Done"
10. **Add value** - Leave code better than found
