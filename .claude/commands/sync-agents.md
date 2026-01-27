---
description: Sync agent configuration files to project
---

Run the doyaken skill: sync-agents

```bash
doyaken skill sync-agents $ARGUMENTS
```

If doyaken is not available, apply this methodology:

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
| `AGENTS.md` | Codex, OpenCode | Industry standard instructions file |
| `CLAUDE.md` | Claude Code | Instructions for Claude |
| `.cursorrules` | Cursor | Legacy instructions file |
| `.cursor/rules/*.mdc` | Cursor | Modern rules format |
| `GEMINI.md` | Google Gemini | Instructions for Gemini |
| `.github/copilot-instructions.md` | GitHub Copilot | Instructions for Copilot |
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
- [x] AGENTS.md (Codex, OpenCode - industry standard)
- [x] CLAUDE.md (Claude Code)
- [x] .cursorrules (Cursor - legacy)
- [x] .cursor/rules/*.mdc (Cursor - modern)
- [x] GEMINI.md (Google Gemini)
- [x] .github/copilot-instructions.md (GitHub Copilot)
- [x] .opencode.json (OpenCode config)

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
