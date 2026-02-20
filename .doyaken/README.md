# Doyaken

A coding agent that delivers robust, working code through phased execution with verification loops. One prompt in, verified code out.

**Aliases:** `doyaken`, `dk`

## Features

- **Single-Shot Execution**: `dk run "prompt"` runs your work through an 8-phase pipeline
- **Verification Gates**: Build, lint, and test checks run after key phases, retrying on failure with error context
- **Agent Agnostic**: Works with Claude, Codex, Gemini, Copilot, Cursor, or OpenCode
- **Multi-Project Support**: Manage multiple projects from a single global installation
- **Self-Healing**: Automatic retries, model fallback, crash recovery
- **Skills System**: Reusable prompts with MCP tool integration
- **MCP Integration**: Connect to GitHub, Linear, Slack, Jira via MCP tools
- **Project Registry**: Track projects by path, git remote, domains, and services

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
curl -sSL https://raw.githubusercontent.com/mitchellfyi/doyaken-cli/main/install.sh | bash
```

### Option 3: Clone & Install

```bash
git clone https://github.com/mitchellfyi/doyaken-cli.git
cd doyaken-cli
./install.sh
```

## Quick Start

```bash
# Initialize a new project
cd /path/to/your/project
dk init

# Run the agent
dk run "Add user authentication with JWT"

# Check status
dk status
dk doctor
```

## Commands

| Command | Description |
|---------|-------------|
| `dk run "<prompt>"` | Execute a prompt through the 8-phase pipeline |
| `dk init [path]` | Initialize a new project |
| `dk skills` | List available skills |
| `dk skill <name>` | Run a skill |
| `dk mcp status` | Show MCP integration status |
| `dk mcp configure` | Generate MCP configs |
| `dk status` | Show project status |
| `dk list` | List all registered projects |
| `dk manifest` | Show project manifest |
| `dk doctor` | Health check |
| `dk help` | Show help |

> **Note:** `doyaken` and `dk` are interchangeable.

## Multi-Agent Support

Doyaken supports multiple AI coding agents. Use `--agent` to switch between them:

```bash
dk --agent claude run "Add auth"      # Use Claude (default)
dk --agent codex run "Add auth"       # Use OpenAI Codex
dk --agent gemini run "Add auth"      # Use Google Gemini
dk --agent cursor run "Add auth"      # Use Cursor
dk --agent copilot run "Add auth"     # Use GitHub Copilot
dk --agent opencode run "Add auth"    # Use OpenCode
```

### Supported Agents & Models

| Agent | Command | Models | Install |
|-------|---------|--------|---------|
| **claude** (default) | `claude` | opus, sonnet, haiku | `npm i -g @anthropic-ai/claude-code` |
| **cursor** | `cursor agent` | claude-sonnet-4, gpt-4o | `curl https://cursor.com/install -fsS \| bash` |
| **codex** | `codex exec` | gpt-5, o3, o4-mini | `npm i -g @openai/codex` |
| **gemini** | `gemini` | gemini-2.5-pro, gemini-2.5-flash | `npm i -g @google/gemini-cli` |
| **copilot** | `copilot` | claude-sonnet-4.5, gpt-5 | `npm i -g @github/copilot` |
| **opencode** | `opencode run` | claude-sonnet-4, gpt-5 | `npm i -g opencode-ai` |

### Specifying Models

```bash
dk --agent codex --model o3 run "Optimize queries"
dk --agent gemini --model gemini-2.5-flash run "Fix login bug"
```

## 8-Phase Pipeline

Each phase runs in a fresh agent context with dedicated prompts:

| Phase | Timeout | Purpose |
|-------|---------|---------|
| **EXPAND** | 2min | Expand brief prompt into full specification |
| **TRIAGE** | 2min | Validate feasibility, check dependencies |
| **PLAN** | 5min | Gap analysis, detailed planning |
| **IMPLEMENT** | 30min | Write the code |
| **TEST** | 10min | Run tests, add coverage |
| **DOCS** | 5min | Sync documentation |
| **REVIEW** | 10min | Code review, quality check |
| **VERIFY** | 3min | Final verification, commit |

### Verification Gates

After every phase, doyaken runs your project's quality commands (build, lint, format, test). If any gate fails and the phase has retries remaining, it re-runs with the error output injected into the prompt.

Configure gates and per-phase retry budgets in `.doyaken/manifest.yaml`:

```yaml
quality:
  build_command: "npm run build"
  lint_command: "npm run lint"
  format_command: "npm run format"
  test_command: "npm test"

retry_budget:
  expand: 1       # 1 = single pass (no retry)
  triage: 1
  plan: 1
  implement: 5    # Up to 5 attempts for IMPLEMENT
  test: 3
  docs: 1
  review: 3
  verify: 1
```

## Skills

Skills are reusable prompts with YAML frontmatter that declare tool requirements:

```bash
dk skills                          # List available skills
dk skill github-import --filter=open  # Run a skill
dk skill github-import --info         # Show skill info
```

### Built-in Skills

**Quality & Audits:**
| Skill | Description |
|-------|-------------|
| `setup-quality` | Set up quality gates, CI, and git hooks |
| `check-quality` | Run all quality checks and report issues |
| `audit-security` | OWASP-based security audit |
| `audit-deps` | Audit dependencies for vulnerabilities |
| `audit-debt` | Technical debt assessment |
| `audit-performance` | Performance analysis |
| `audit-ux` | User experience audit |

**Development:**
| Skill | Description |
|-------|-------------|
| `review-codebase` | Comprehensive codebase review |
| `research-features` | Discover next best feature to build |
| `ci-fix` | Diagnose and fix CI/CD failures |
| `workflow` | Run the 8-phase workflow |
| `sync-agents` | Sync agent config files to project |

**Integrations** (require MCP servers):
| Skill | Description | Requires |
|-------|-------------|----------|
| `github-import` | Import GitHub issues | GitHub MCP |
| `github-sync` | Sync status to GitHub | GitHub MCP |
| `github-pr` | Create PR from recent commits | GitHub MCP |
| `notify-slack` | Send Slack notifications | Slack MCP |
| `mcp-status` | Check MCP integration status | - |

### Creating Custom Skills

Create a `.md` file in `~/.doyaken/skills/` (global) or `.doyaken/skills/` (project):

```markdown
---
name: my-skill
description: What this skill does
requires:
  - github                     # MCP servers needed
args:
  - name: filter
    description: Filter option
    default: "open"
---

# My Skill Prompt

Instructions for the AI agent...
```

## MCP Integration

Doyaken supports MCP (Model Context Protocol) tools for external integrations:

```bash
dk mcp status       # Show integration status
dk mcp configure    # Generate MCP configs
```

### Enabling Integrations

Edit `.doyaken/manifest.yaml`:

```yaml
integrations:
  github:
    enabled: true
  linear:
    enabled: false
  slack:
    enabled: false
  jira:
    enabled: false
```

After enabling, run `dk mcp configure` to generate the MCP configuration.

### Supported Integrations

| Integration | Description | Required Env Var |
|-------------|-------------|------------------|
| GitHub | Issues, PRs, repos | `GITHUB_TOKEN` |
| Linear | Issues, projects | `LINEAR_API_KEY` |
| Slack | Messages, channels | `SLACK_BOT_TOKEN` |
| Jira | Issues, sprints | `JIRA_API_TOKEN` |

### Skill Hooks

Auto-run skills at specific workflow points:

```yaml
# In manifest.yaml
skills:
  hooks:
    before-triage:
      - github-import       # Sync issues before starting
    after-verify:
      - github-sync         # Update issues after completion
```

## Project Structure

After running `dk init`, your project will have:

```
your-project/
├── .doyaken/
│   ├── manifest.yaml        # Project configuration
│   ├── prompts/
│   │   ├── library/         # 25+ methodology prompts
│   │   └── phases/          # 8-phase workflow prompts
│   ├── skills/              # Project-specific skills
│   ├── hooks/               # Claude Code hooks
│   ├── logs/                # Execution logs
│   └── state/               # Session recovery
├── AGENTS.md                # Multi-agent instructions
└── CLAUDE.md                # Claude Code config
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
  build_command: "npm run build"
  test_command: "npm test"
  lint_command: "npm run lint"
  format_command: "npm run format"

retry_budget:
  implement: 5
  test: 3
  review: 3

agent:
  name: "claude"
  model: "opus"
  max_retries: 2
```

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `DOYAKEN_AGENT` | `claude` | AI agent to use |
| `DOYAKEN_MODEL` | agent-specific | Model for the selected agent |
| `AGENT_DRY_RUN` | `0` | Preview without executing |
| `AGENT_VERBOSE` | `0` | Detailed output |
| `AGENT_QUIET` | `0` | Minimal output |
| `AGENT_MAX_RETRIES` | `2` | Retries per phase (rate limit retries) |
| `RETRY_BUDGET_EXPAND` | `1` | Verification gate retries for EXPAND |
| `RETRY_BUDGET_TRIAGE` | `1` | Verification gate retries for TRIAGE |
| `RETRY_BUDGET_PLAN` | `1` | Verification gate retries for PLAN |
| `RETRY_BUDGET_IMPLEMENT` | `5` | Verification gate retries for IMPLEMENT |
| `RETRY_BUDGET_TEST` | `3` | Verification gate retries for TEST |
| `RETRY_BUDGET_DOCS` | `1` | Verification gate retries for DOCS |
| `RETRY_BUDGET_REVIEW` | `3` | Verification gate retries for REVIEW |
| `RETRY_BUDGET_VERIFY` | `1` | Verification gate retries for VERIFY |
| `TIMEOUT_EXPAND` | `300` | Expand phase timeout (seconds) |
| `TIMEOUT_IMPLEMENT` | `1800` | Implement phase timeout (seconds) |
| `TIMEOUT_TEST` | `600` | Test phase timeout (seconds) |
| `TIMEOUT_REVIEW` | `600` | Review phase timeout (seconds) |
| `DOYAKEN_HOME` | `~/.doyaken` | Global installation directory |

## Troubleshooting

```bash
# Health check
dk doctor

# View logs
ls -la .doyaken/logs/

# Clean up old logs and state
dk cleanup
```

## Development

### Setup

```bash
git clone https://github.com/mitchellfyi/doyaken-cli.git
cd doyaken-cli

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
  - [Claude Code](https://claude.ai/code) (default)
  - [Cursor CLI](https://cursor.com/docs/cli)
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
