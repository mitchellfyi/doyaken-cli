---
name: sync-agents
description: Sync agent configuration files to project
args:
  - name: copy-prompts
    description: Also copy prompts library to project
    default: "true"
  - name: copy-skills
    description: Also copy skills to project
    default: "true"
---

# Sync Agent Files

You are syncing agent configuration files to a project.

## Context

Project directory: {{DOYAKEN_PROJECT}}
Copy prompts: {{ARGS.copy-prompts}}
Copy skills: {{ARGS.copy-skills}}

## What Gets Synced

This creates agent-specific configuration files that point to `.doyaken/` as the source of truth:

| File | Agent | Description |
|------|-------|-------------|
| `AGENTS.md` | All | Central index of all prompts and skills |
| `CLAUDE.md` | Claude Code | Instructions for Claude |
| `.cursorrules` | Cursor | Instructions with @file includes |
| `CODEX.md` | OpenAI Codex | Instructions for Codex |
| `GEMINI.md` | Google Gemini | Instructions for Gemini |
| `.opencode.json` | OpenCode | JSON configuration |

## Instructions

### 1) Verify Project Structure

Check that `.doyaken/` exists:

```bash
ls -la .doyaken/
```

If not initialized, the user should run `doyaken init` first.

### 2) Generate Agent Files

Run the sync script:

```bash
$DOYAKEN_HOME/scripts/sync-agent-files.sh "{{DOYAKEN_PROJECT}}"
```

Or manually create each file using the templates in `$DOYAKEN_HOME/templates/agents/`.

### 3) Copy Prompts Library (if enabled)

If `copy-prompts=true`, copy the prompts library:

```bash
mkdir -p .doyaken/prompts
cp -r $DOYAKEN_HOME/prompts/library .doyaken/prompts/
cp -r $DOYAKEN_HOME/prompts/phases .doyaken/prompts/
```

### 4) Copy Skills (if enabled)

If `copy-skills=true`, copy skills:

```bash
cp -r $DOYAKEN_HOME/skills .doyaken/
```

### 5) Copy Hooks

Copy hooks for quality enforcement:

```bash
cp -r $DOYAKEN_HOME/hooks .doyaken/
```

## Output

```
Agent Files Sync Complete
=========================

Project: {{DOYAKEN_PROJECT}}

Generated files:
- [x] AGENTS.md (central source of truth)
- [x] CLAUDE.md (Claude Code)
- [x] .cursorrules (Cursor)
- [x] CODEX.md (OpenAI Codex)
- [x] GEMINI.md (Google Gemini)
- [x] .opencode.json (OpenCode)

[If copy-prompts=true:]
Copied to .doyaken/:
- [x] prompts/library/ (reusable prompt modules)
- [x] prompts/phases/ (workflow phase prompts)

[If copy-skills=true:]
- [x] skills/ (on-demand skills)

[Always:]
- [x] hooks/ (quality enforcement hooks)

All agent files point to .doyaken/ as the source of truth.
To regenerate, run: doyaken sync
```

## Rules

- Never overwrite existing project-specific customizations
- Always generate a timestamp in the files
- Point all agent files to .doyaken/ paths
- Use relative paths for cross-agent compatibility
