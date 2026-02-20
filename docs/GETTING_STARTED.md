# Getting Started with Doyaken

Doyaken is a coding agent CLI that delivers robust, working code through phased execution with verification loops.

## Install

```bash
# Clone the repository
git clone <repo-url> ~/.doyaken

# Add to PATH
echo 'export PATH="$HOME/.doyaken/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc

# Verify installation
dk version
dk doctor
```

### Prerequisites

- **AI agent CLI** (at least one): `claude`, `codex`, `gemini`, `copilot`, or `opencode`
- **yq** (YAML parser): `brew install yq`
- **Optional**: `coreutils` for timeout support on macOS (`brew install coreutils`)

## Initialize a Project

```bash
cd your-project
dk init
```

This creates `.doyaken/` with:
- `manifest.yaml` — project configuration
- `prompts/` — phase prompts (customizable)
- `skills/` — project-specific skills
- `logs/` — execution logs

## Run a Task

```bash
dk run "Add user authentication with JWT"
```

This executes the 8-phase pipeline:
1. **EXPAND** — Expands your brief prompt into a full specification
2. **TRIAGE** — Validates the task and checks dependencies
3. **PLAN** — Creates a detailed implementation plan
4. **IMPLEMENT** — Writes the code
5. **TEST** — Runs and adds tests
6. **DOCS** — Updates documentation
7. **REVIEW** — Code review and quality check
8. **VERIFY** — Final verification and commit

## Interactive Chat Mode

```bash
dk chat
```

Chat mode gives you a REPL where you can:
- Send messages to the AI agent
- Use slash commands (`/help`, `/commit`, `/diff`, `/undo`)
- Attach files with `@path/to/file`
- Run shell commands with `!command`
- Resume sessions with `dk chat --resume`

## Key Concepts

### Verification Gates

After IMPLEMENT, TEST, and REVIEW phases, your quality commands (build, lint, format, test) run automatically. If they fail, the phase retries with the error output injected so the agent can fix the issue.

Configure in `.doyaken/manifest.yaml`:
```yaml
quality:
  test_command: "npm test"
  lint_command: "npm run lint"
  format_command: "npm run format"
  build_command: "npm run build"
```

### Skills

Skills are reusable prompt templates. List available skills:
```bash
dk skills
dk skill security-audit --info
dk skill security-audit
```

### MCP Integrations

Doyaken can configure MCP (Model Context Protocol) servers for GitHub, Slack, Linear, and more:
```bash
dk mcp status
dk mcp setup github
dk mcp configure
```

### Multiple Agents

Switch between AI agents:
```bash
dk --agent codex run "Fix the bug"
dk --agent gemini --model gemini-2.5-flash run "Optimize queries"
```

## Next Steps

- Edit `.doyaken/manifest.yaml` to configure quality gates
- Run `dk doctor` to check your setup
- Run `dk help <command>` for detailed help on any command
- Run `dk validate` to check your project configuration
