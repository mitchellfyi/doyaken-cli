You are performing a scheduled maintenance review of **AI agent configuration and documentation**. Your goal is to keep the AI instructions accurate, complete, and useful.

## Phase 1: Review

1. Read `CLAUDE.md` — the main entry point for AI agents
2. Read `AGENTS.md` — the full agent instructions
3. Read `.doyaken/manifest.yaml` for project configuration
4. Scan `.doyaken/prompts/library/` — all prompt library files
5. Scan `.doyaken/skills/` — all skill definitions
6. Scan `.doyaken/prompts/phases/` — all phase definitions
7. Read `.github/ai-automation/prompts/` — all AI automation prompts
8. Audit:
   - Do `CLAUDE.md` and `AGENTS.md` accurately describe the current project structure?
   - Do they reference files/directories that actually exist?
   - Are the coding conventions described still accurate?
   - Do the prompt library files reference tools, commands, or patterns that are current?
   - Do skill definitions work with the current project setup?
   - Are AI automation prompts consistent with each other and with AGENTS.md?

## Phase 2: Fix

Fix inaccurate agent docs:

- Correct file paths that have moved or been renamed
- Fix command references that have changed (e.g., npm → pnpm)
- Fix descriptions of project structure that don't match reality
- Fix references to removed features or deprecated patterns

## Phase 3: Sync

Align agent config with the codebase:

- Update `CLAUDE.md` key files section if files have moved
- Update `AGENTS.md` project structure if directory layout has changed
- Remove prompt library entries for patterns no longer used
- Update skill definitions to use current commands and paths
- Ensure AI automation prompts reference current CI commands

## Phase 4: Improve

Enhance agent instructions:

- Improve unclear instructions that could confuse AI agents
- Add missing context that agents commonly need (discovered from workflow patterns)
- Improve prompt library quality (more specific, more actionable)
- Strengthen the rules/constraints where agents commonly make mistakes

## Phase 5: Add

Fill gaps in agent documentation:

- Document new conventions that aren't captured in `AGENTS.md`
- Add missing prompt library entries for common tasks
- Document new file patterns or directory structures
- Add missing context about the tech stack or architecture

## Instructions

1. Read `CLAUDE.md` first, then `AGENTS.md`
2. Cross-reference agent docs against the actual codebase — don't trust docs at face value
3. Work through Phases 1-5 in order
4. Run `pnpm format` before committing to ensure consistent formatting
5. Commit changes with descriptive messages — group by phase where practical
6. Push to the current branch
7. Do NOT create a new PR — just push to this branch

## Rules

- Accuracy is critical — AI agents follow these instructions literally
- Keep instructions concise and actionable
- Do NOT add speculative or aspirational instructions — only document what exists
- Do NOT change the fundamental structure of CLAUDE.md or AGENTS.md without good reason
- Do NOT modify source code — only agent configuration and documentation files
- Preserve the existing template syntax (`{{include:...}}`, `{{ARGS...}}`) in prompt library files
