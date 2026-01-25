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
npm install -g @doyaken/doyaken

# Or use npx without installing
npx doyaken --help
```

### Option 2: curl (Per-User or Per-Project)

```bash
# Install to ~/.doyaken (default, per-user)
curl -sSL https://raw.githubusercontent.com/doyaken/doyaken/main/install.sh | bash

# Install to a specific project
curl -sSL https://raw.githubusercontent.com/doyaken/doyaken/main/install.sh | bash -s /path/to/project
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

### Per-Project Configuration

Set the default agent in `.doyaken/manifest.yaml`:

```yaml
agent:
  name: "codex"
  model: "gpt-5"
```

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
| `DOYAKEN_AGENT` | `claude` | AI agent (claude, codex, gemini, copilot, opencode) |
| `DOYAKEN_MODEL` | agent-specific | Model for the selected agent |
| `CLAUDE_MODEL` | `opus` | Legacy: Model for Claude (opus, sonnet, haiku) |
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
