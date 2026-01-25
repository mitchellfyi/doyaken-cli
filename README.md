# AI Agent

A standalone multi-project autonomous agent CLI for Claude Code. Install once, use on any project.

## Features

- **Multi-Project Support**: Manage multiple projects from a single global installation
- **7-Phase Execution**: Triage → Plan → Implement → Test → Docs → Review → Verify
- **Self-Healing**: Automatic retries, model fallback, crash recovery
- **Parallel Agents**: Multiple agents can work simultaneously with lock coordination
- **Project Registry**: Track projects by path, git remote, domains, and services
- **Legacy Migration**: Seamlessly upgrade existing `.claude/` projects

## Installation

```bash
# Clone the repo
git clone https://github.com/your-org/ai-agent.git
cd ai-agent

# Install globally
./install.sh

# Restart your shell or:
source ~/.zshrc  # or ~/.bashrc
```

This installs to `~/.ai-agent/` and adds `ai-agent` to your PATH.

## Quick Start

```bash
# Initialize a new project
cd /path/to/your/project
ai-agent init

# Create a task
ai-agent tasks new "Add user authentication"

# Run the agent
ai-agent run 1     # Run 1 task
ai-agent           # Run 5 tasks (default)

# Check status
ai-agent status    # Project status
ai-agent tasks     # Show taskboard
ai-agent doctor    # Health check
```

## Commands

| Command | Description |
|---------|-------------|
| `ai-agent` | Run 5 tasks in current project |
| `ai-agent run [N]` | Run N tasks |
| `ai-agent init [path]` | Initialize a new project |
| `ai-agent tasks` | Show taskboard |
| `ai-agent tasks new <title>` | Create a new task |
| `ai-agent status` | Show project status |
| `ai-agent list` | List all registered projects |
| `ai-agent manifest` | Show project manifest |
| `ai-agent migrate` | Upgrade from `.claude/` format |
| `ai-agent doctor` | Health check |
| `ai-agent help` | Show help |

## Project Structure

After running `ai-agent init`, your project will have:

```
your-project/
├── .ai-agent/
│   ├── manifest.yaml        # Project configuration
│   ├── tasks/
│   │   ├── todo/            # Ready to start
│   │   ├── doing/           # In progress
│   │   └── done/            # Completed
│   ├── logs/                # Execution logs
│   ├── state/               # Session recovery
│   └── locks/               # Parallel coordination
├── AI-AGENT.md              # Operating manual
└── TASKBOARD.md             # Generated overview
```

## Project Manifest

Configure your project in `.ai-agent/manifest.yaml`:

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

tools:
  jira:
    enabled: true
    project_key: "MYAPP"
    base_url: "https://company.atlassian.net"

quality:
  test_command: "npm test"
  lint_command: "npm run lint"

agent:
  model: "opus"
  max_retries: 2
```

## Task Priority System

Tasks use the naming format `PPP-SSS-slug.md`:

| Priority | Code | Use For |
|----------|------|---------|
| Critical | 001  | Blocking, security, broken |
| High     | 002  | Important features, bugs |
| Medium   | 003  | Normal work |
| Low      | 004  | Nice-to-have, cleanup |

Example: `002-001-add-user-auth.md` = High priority, first in sequence

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `CLAUDE_MODEL` | `opus` | Model (opus, sonnet, haiku) |
| `AGENT_DRY_RUN` | `0` | Preview without executing |
| `AGENT_VERBOSE` | `0` | Detailed output |
| `AGENT_QUIET` | `0` | Minimal output |
| `AGENT_MAX_RETRIES` | `2` | Retries per phase |
| `TIMEOUT_IMPLEMENT` | `1800` | Implementation timeout (30min) |

## Parallel Execution

Run multiple agents simultaneously:

```bash
ai-agent run 5 &
ai-agent run 5 &
ai-agent run 5 &
```

Agents coordinate via lock files and will not work on the same task.

## Migration from `.claude/`

If you have existing projects using the `.claude/` structure:

```bash
cd /path/to/legacy/project
ai-agent migrate
```

This will:
- Rename `.claude/` to `.ai-agent/`
- Remove embedded agent code
- Create `manifest.yaml`
- Rename `CLAUDE.md` to `AI-AGENT.md`
- Register in the global project registry

## Global Installation

The global installation at `~/.ai-agent/` contains:

```
~/.ai-agent/
├── bin/ai-agent             # CLI binary
├── lib/                     # Core scripts
│   ├── cli.sh              # Command dispatcher
│   ├── core.sh             # Agent logic
│   ├── registry.sh         # Project registry
│   ├── migration.sh        # Migration helpers
│   └── taskboard.sh        # Taskboard generator
├── prompts/                 # Phase prompts
├── templates/               # Project templates
├── config/global.yaml       # Global defaults
└── projects/registry.yaml   # Project registry
```

## Requirements

- Claude Code CLI (installed and authenticated)
- Bash 4.0+
- Git
- macOS or Linux

## License

MIT
