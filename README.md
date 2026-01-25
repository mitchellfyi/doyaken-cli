# Doyaken

A standalone multi-project autonomous agent CLI for Claude Code. Install once, use on any project.

**Aliases:** `doyaken`, `dk`

## Features

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
npm install -g doyaken

# Or use npx without installing
npx doyaken --help
```

### Option 2: curl (Per-User or Per-Project)

```bash
# Install to ~/.doyaken (default, per-user)
curl -sSL https://raw.githubusercontent.com/your-org/doyaken/main/install.sh | bash

# Install to a specific project
curl -sSL https://raw.githubusercontent.com/your-org/doyaken/main/install.sh | bash -s /path/to/project
```

### Option 3: Clone & Install

```bash
git clone https://github.com/your-org/doyaken.git
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
| `dk init [path]` | Initialize a new project |
| `dk tasks` | Show taskboard |
| `dk tasks new <title>` | Create a new task |
| `dk status` | Show project status |
| `dk list` | List all registered projects |
| `dk manifest` | Show project manifest |
| `dk migrate` | Upgrade from `.claude/` format |
| `dk doctor` | Health check |
| `dk help` | Show help |

> **Note:** `doyaken` and `dk` are interchangeable. Use whichever you prefer.

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
├── AI-AGENT.md              # Operating manual
└── TASKBOARD.md             # Generated overview
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
| `DOYAKEN_HOME` | `~/.doyaken` | Global installation directory |

## Parallel Execution

Run multiple agents simultaneously:

```bash
dk run 5 &
dk run 5 &
dk run 5 &
```

Agents coordinate via lock files and will not work on the same task.

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

## Global Installation

The global installation at `~/.doyaken/` contains:

```
~/.doyaken/
├── bin/doyaken              # CLI binary
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
- Node.js 16+ (for npm install)

## License

MIT
