# Doyaken Quick Reference

## Commands

| Command | Description |
|---------|-------------|
| `dk run "<prompt>"` | Execute prompt through 8-phase pipeline |
| `dk chat` | Interactive chat/REPL mode |
| `dk chat --resume` | Resume most recent session |
| `dk init [path]` | Initialize a new project |
| `dk status` | Show project status |
| `dk doctor` | Health check and diagnostics |
| `dk validate` | Validate project configuration |
| `dk stats` | Show project statistics |
| `dk list` | List registered projects |
| `dk list --recent` | Show recently active projects |
| `dk skills` | List available skills |
| `dk skills --domains` | List domain skill packs |
| `dk skill <name>` | Run a skill |
| `dk config` | Show effective configuration |
| `dk config edit` | Edit global config |
| `dk mcp status` | MCP integration status |
| `dk mcp setup <name>` | Setup instructions for MCP server |
| `dk mcp configure` | Generate MCP configs |
| `dk audit` | View audit log |
| `dk generate` | Generate/sync tool configs |
| `dk upgrade` | Upgrade doyaken |
| `dk sync` | Sync agent files and prompts |
| `dk sessions` | List chat sessions |
| `dk cleanup` | Clean logs and state |

## Common Flags

| Flag | Description |
|------|-------------|
| `--agent <name>` | Use specific agent (claude, codex, gemini, copilot, opencode) |
| `--model <name>` | Use specific model |
| `--dry-run` | Preview without executing |
| `--verbose` | Detailed output |
| `--quiet` | Minimal output |
| `--safe-mode` | Disable autonomous mode |
| `--supervised` | Pause between phases |
| `--plan-only` | Stop after plan phase |
| `--project <path>` | Specify project path |

## Chat Slash Commands

| Command | Description |
|---------|-------------|
| `/help` | Show available commands |
| `/status` | Project and session status |
| `/diff` | Show git diff |
| `/commit [-m "msg"]` | Commit changes |
| `/undo` | Revert last change |
| `/redo` | Re-apply last undo |
| `/checkpoint save` | Create checkpoint |
| `/restore <n>` | Restore checkpoint |
| `/compact [N]` | Trim history |
| `/model [name]` | Show/change model |
| `/sessions` | List sessions |
| `/quit` | Exit chat |

## Environment Variables

| Variable | Description |
|----------|-------------|
| `DOYAKEN_HOME` | Global installation dir (default: `~/.doyaken`) |
| `DOYAKEN_PROJECT` | Override project detection |
| `DOYAKEN_AGENT` | Default agent |
| `DOYAKEN_MODEL` | Default model |
| `DOYAKEN_APPROVAL` | Approval level (full-auto, supervised, plan-only) |

## File Structure

```
.doyaken/
  manifest.yaml          # Project configuration
  prompts/
    phases/              # 8-phase workflow prompts
    library/             # Methodology prompts
  skills/                # Project-specific skills
  logs/                  # Execution logs
  state/                 # Session state
  sessions/              # Chat sessions
  audit.log              # Audit trail

~/.doyaken/
  config/global.yaml     # Global configuration
  projects/registry.yaml # Project registry
  skills/                # Global skills
  prompts/               # Global prompts
```

## Config Priority

CLI flags > ENV vars > project manifest > global config > defaults
