# Doyaken

> A coding agent that delivers robust, working code through phased execution with verification loops.

## Vision

Doyaken is a single-shot execution engine for AI coding agents. Give it a prompt, and it runs the work through an 8-phase pipeline with built-in verification gates that retry until the code actually builds, lints, and passes tests. It works with any AI agent (Claude, Cursor, Codex, Gemini, Copilot, OpenCode) and installs once globally for all your projects.

## Goals

1. **Robust output**: Code that builds, passes linting, and passes tests -- verified automatically
2. **Agent agnostic**: Support multiple AI coding agents with a consistent interface
3. **Single-shot execution**: One prompt in, working code out. No task queue, no project management.
4. **Self-healing**: Automatic retries, model fallback, crash recovery, verification loops

## Non-Goals

Things explicitly out of scope:

- Not a task manager or project manager -- use external tools for that
- Not a replacement for any specific AI agent -- it's an orchestrator
- Won't implement AI capabilities itself -- relies on underlying agents
- Not trying to be an IDE extension or GUI tool -- CLI only
- Won't manage API keys or billing for agents

## Tech Stack

- **Language**: Bash 4.0+
- **Package Manager**: npm (for global distribution)
- **Config Format**: YAML (manifest, registry, global config)
- **Supported Agents**: Claude Code, Cursor, OpenAI Codex, Google Gemini, GitHub Copilot, OpenCode

## Getting Started

```bash
# Install globally
npm install -g @doyaken/doyaken

# Initialize a project
cd /path/to/project
dk init

# Run the agent
dk run "Add user authentication with JWT"

# Check status
dk doctor
```

## Key Decisions

1. **Bash over Node/Python**: Minimal dependencies, runs anywhere with a shell
2. **YAML for config**: Human-readable, easy to edit, good tooling support
3. **Global + Local split**: Core logic global, project data local (`.doyaken/`)
4. **8-phase execution**: EXPAND -> TRIAGE -> PLAN -> IMPLEMENT -> TEST -> DOCS -> REVIEW -> VERIFY
5. **Verification gates**: Quality commands run after key phases, retrying with error context on failure
6. **Single-shot, no task queue**: One prompt per invocation. Do one thing well.

## Agent Notes

Things to know when working on doyaken itself:

- **Bash 3.x compatibility**: Avoid associative array initialization syntax, use helper functions
- **Shellcheck compliance**: All scripts must pass `npm run lint`
- **Test suite**: Run `npm run test` before committing
- **Quality checks**: Run `npm run check` for full validation
- **Idempotent operations**: Commands should be safe to run multiple times
- **Clear error messages**: Users should understand what went wrong and how to fix it
