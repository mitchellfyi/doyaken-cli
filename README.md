# Doyaken

A standalone multi-project autonomous agent CLI that works with any AI coding agent. Install once, use on any project.

**Aliases:** `doyaken`, `dk`

## Features

- **Agent Agnostic**: Works with Claude, Codex, Gemini, Copilot, or OpenCode
- **Multi-Project Support**: Manage multiple projects from a single global installation
- **7-Phase Execution**: Triage → Plan → Implement → Test → Docs → Review → Verify
- **Self-Healing**: Automatic retries, model fallback, crash recovery
- **Parallel Agents**: Multiple agents can work simultaneously with lock coordination
- **Project Registry**: Track projects by path, git remote, domains, and services
- **Legacy Migration**: Seamlessly upgrade existing `.claude/` projects

## Installation

### Option 1: npm (Recommended)

```bash
# Install globally
npm install -g @doyaken/doyaken

# Or use npx without installing
npx doyaken --help
```

### Option 2: curl (Per-User)

```bash
curl -sSL https://raw.githubusercontent.com/doyaken/doyaken/main/install.sh | bash
```

### Option 3: Clone & Install

```bash
git clone https://github.com/doyaken/doyaken.git
cd doyaken
./install.sh
```

## Quick Start

```bash
# Initialize a new project
cd /path/to/your/project
dk init

# Create a task
dk tasks new "Add user authentication"

# Run the agent
dk run 1     # Run 1 task
dk           # Run 5 tasks (default)

# Check status
dk status    # Project status
dk tasks     # Show taskboard
dk doctor    # Health check
```

## Commands

| Command | Description |
|---------|-------------|
| `dk` | Run 5 tasks in current project |
| `dk run [N]` | Run N tasks |
| `dk task "<prompt>"` | Create and immediately run a single task |
| `dk init [path]` | Initialize a new project |
| `dk tasks` | Show taskboard |
| `dk tasks new <title>` | Create a new task |
| `dk status` | Show project status |
| `dk list` | List all registered projects |
| `dk manifest` | Show project manifest |
| `dk migrate` | Upgrade from `.claude/` format |
| `dk doctor` | Health check |
| `dk help` | Show help |

> **Note:** `doyaken` and `dk` are interchangeable.

## Multi-Agent Support

Doyaken supports multiple AI coding agents. Use `--agent` to switch between them:

```bash
dk --agent claude run 1      # Use Claude (default)
dk --agent codex run 1       # Use OpenAI Codex
dk --agent gemini run 1      # Use Google Gemini
dk --agent copilot run 1     # Use GitHub Copilot
dk --agent opencode run 1    # Use OpenCode
```

### Supported Agents & Models

| Agent | Command | Models | Install |
|-------|---------|--------|---------|
| **claude** (default) | `claude` | opus, sonnet, haiku | `npm i -g @anthropic-ai/claude-code` |
| **codex** | `codex` | gpt-5, o3, o4-mini | `npm i -g @openai/codex` |
| **gemini** | `gemini` | gemini-2.5-pro, gemini-2.5-flash | `npm i -g @google/gemini-cli` |
| **copilot** | `copilot` | claude-sonnet-4.5, gpt-5 | `npm i -g @github/copilot` |
| **opencode** | `opencode` | claude-sonnet-4, gpt-5 | `npm i -g opencode-ai` |

### Specifying Models

```bash
dk --agent codex --model o3 run 1
dk --agent gemini --model gemini-2.5-flash run 2
```

## Agent Workflow

The agent operates in 8 phases for each task:

| Phase | Timeout | Purpose |
|-------|---------|---------|
| **EXPAND** | 2min | Expand brief prompt into full task specification |
| **TRIAGE** | 2min | Validate task, check dependencies |
| **PLAN** | 5min | Gap analysis, detailed planning |
| **IMPLEMENT** | 30min | Execute the plan, write code |
| **TEST** | 10min | Run tests, add coverage |
| **DOCS** | 5min | Sync documentation |
| **REVIEW** | 10min | Code review, create follow-ups |
| **VERIFY** | 3min | Verify task management, commit |

### Parallel Execution

Run multiple agents simultaneously:

```bash
dk run 5 &
dk run 5 &
dk run 5 &
```

Agents coordinate via lock files in `.doyaken/locks/` and will not work on the same task.

## Project Structure

After running `dk init`, your project will have:

```
your-project/
├── .doyaken/
│   ├── manifest.yaml        # Project configuration
│   ├── tasks/
│   │   ├── todo/            # Ready to start
│   │   ├── doing/           # In progress
│   │   └── done/            # Completed
│   ├── logs/                # Execution logs
│   ├── state/               # Session recovery
│   └── locks/               # Parallel coordination
├── AI-AGENT.md              # Project-specific agent notes
└── TASKBOARD.md             # Generated task overview
```

## Project Manifest

Configure your project in `.doyaken/manifest.yaml`:

```yaml
project:
  name: "my-app"
  description: "My awesome app"

git:
  remote: "git@github.com:user/my-app.git"
  branch: "main"

domains:
  production: "https://my-app.com"
  staging: "https://staging.my-app.com"

quality:
  test_command: "npm test"
  lint_command: "npm run lint"

agent:
  name: "claude"
  model: "opus"
  max_retries: 2
```

## Task System

### Task Priority

Tasks use the naming format `PPP-SSS-slug.md`:

| Priority | Code | Use For |
|----------|------|---------|
| Critical | 001  | Blocking, security, broken |
| High     | 002  | Important features, bugs |
| Medium   | 003  | Normal work |
| Low      | 004  | Nice-to-have, cleanup |

Example: `002-001-add-user-auth.md` = High priority, first in sequence

### Creating Tasks

```bash
# Via CLI
dk tasks new "Add user authentication"

# Manually create in .doyaken/tasks/todo/
# Use the template format
```

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `DOYAKEN_AGENT` | `claude` | AI agent to use |
| `DOYAKEN_MODEL` | agent-specific | Model for the selected agent |
| `AGENT_DRY_RUN` | `0` | Preview without executing |
| `AGENT_VERBOSE` | `0` | Detailed output |
| `AGENT_QUIET` | `0` | Minimal output |
| `AGENT_MAX_RETRIES` | `2` | Retries per phase |
| `TIMEOUT_IMPLEMENT` | `1800` | Implementation timeout (seconds) |
| `DOYAKEN_HOME` | `~/.doyaken` | Global installation directory |

## Migration from `.claude/`

If you have existing projects using the `.claude/` structure:

```bash
cd /path/to/legacy/project
dk migrate
```

This will:
- Rename `.claude/` to `.doyaken/`
- Remove embedded agent code
- Create `manifest.yaml`
- Rename `CLAUDE.md` to `AI-AGENT.md`
- Register in the global project registry

## Troubleshooting

```bash
# Health check
dk doctor

# View logs
ls -la .doyaken/logs/

# Reset stuck state
rm -rf .doyaken/locks/*.lock
mv .doyaken/tasks/doing/*.md .doyaken/tasks/todo/
```

## Development

### Setup

```bash
git clone https://github.com/doyaken/doyaken.git
cd doyaken

# Install git hooks
npm run setup

# Run all checks
npm run check
```

### Quality Scripts

| Script | Description |
|--------|-------------|
| `npm run lint` | Lint shell scripts with shellcheck |
| `npm run validate` | Validate YAML files |
| `npm run test` | Run test suite |
| `npm run check` | Run all quality checks |
| `npm run setup` | Install git hooks |

### Git Hooks

The repository includes git hooks for quality assurance:

- **pre-commit**: Lints staged shell scripts and YAML files
- **pre-push**: Runs the full test suite

To bypass temporarily: `git commit --no-verify`

## Requirements

- At least one AI coding agent CLI installed:
  - [Claude Code](https://claude.ai/cli) (default)
  - [OpenAI Codex](https://github.com/openai/codex)
  - [Google Gemini CLI](https://github.com/google-gemini/gemini-cli)
  - [GitHub Copilot CLI](https://github.com/github/copilot-cli)
  - [OpenCode](https://opencode.ai)
- Bash 4.0+
- Git
- macOS or Linux
- Node.js 16+ (for npm install)

## License

MIT
