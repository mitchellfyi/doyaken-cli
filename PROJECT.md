# Doyaken

> A standalone multi-project autonomous agent CLI that works with any AI coding agent.

## Vision

Doyaken is a universal task runner for AI coding agents. Install once globally, use on any project. It manages the task lifecycle, coordinates parallel agents, and provides self-healing execution - regardless of which underlying AI agent (Claude, Codex, Gemini, Copilot, OpenCode) you choose to use.

## Goals

1. **Agent Agnostic**: Support multiple AI coding agents with a consistent interface
2. **Multi-Project**: Global installation manages multiple projects via registry
3. **Autonomous Operation**: 7-phase execution with self-healing and automatic retries
4. **Parallel Execution**: Multiple agents can work simultaneously with lock coordination
5. **Easy Migration**: Seamlessly upgrade existing `.claude/` projects to `.doyaken/`

## Non-Goals

Things explicitly out of scope:

- Not a replacement for any specific AI agent - it's a wrapper/orchestrator
- Won't implement AI capabilities itself - relies on underlying agents
- Not trying to be an IDE extension or GUI tool - CLI only
- Won't manage API keys or billing for agents

## Tech Stack

- **Language**: Bash 4.0+
- **Package Manager**: npm (for global distribution)
- **Config Format**: YAML (manifest, registry, global config)
- **Task Format**: Markdown
- **Supported Agents**: Claude Code, OpenAI Codex, Google Gemini, GitHub Copilot, OpenCode

## Getting Started

```bash
# Install globally
npm install -g @doyaken/doyaken

# Initialize a project
cd /path/to/project
dk init

# Create a task
dk tasks new "Add user authentication"

# Run the agent
dk run 1

# Check status
dk doctor
```

## Key Decisions

1. **Bash over Node/Python**: Minimal dependencies, runs anywhere with a shell
2. **YAML for config**: Human-readable, easy to edit, good tooling support
3. **Global + Local split**: Core logic global, project data local (`.doyaken/`)
4. **7-phase execution**: Triage → Plan → Implement → Test → Docs → Review → Verify
5. **Lock-based coordination**: File locks for parallel agent safety

## Agent Notes

Things to know when working on doyaken itself:

- **Bash 3.x compatibility**: Avoid associative array initialization syntax, use helper functions
- **Shellcheck compliance**: All scripts must pass `npm run lint`
- **Test suite**: Run `npm run test` before committing
- **Quality checks**: Run `npm run check` for full validation
- **Idempotent operations**: Commands should be safe to run multiple times
- **Clear error messages**: Users should understand what went wrong and how to fix it
