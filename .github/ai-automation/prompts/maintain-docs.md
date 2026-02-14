You are performing a scheduled maintenance review of **documentation**. Your goal is to leave the docs accurate, complete, and useful.

## Phase 1: Review

1. Read `CLAUDE.md` and `AGENTS.md` for project conventions
2. Read `package.json` to understand the current tech stack and scripts
3. Audit all documentation files:
   - `README.md` — does the getting started guide actually work? Are features listed accurate?
   - Any docs in `docs/` directory
   - API documentation (inline or separate)
   - Configuration documentation (`.env.example`, config files)
4. Look for:
   - References to features, files, or commands that no longer exist
   - Missing documentation for features that do exist
   - Broken links (internal and external)
   - Outdated version numbers, dependency references, or screenshots
   - Inconsistent formatting across doc files
   - Code examples that wouldn't work if copy-pasted

## Phase 2: Fix

Fix documentation problems:

- Correct inaccurate descriptions of existing functionality
- Fix broken internal links
- Update outdated version numbers and dependency references
- Fix code examples that don't match current APIs
- Fix incorrect command references

## Phase 3: Sync

Align documentation with reality:

- Remove documentation for features/files/commands that no longer exist
- Update configuration docs to match actual config files (`.env.example` vs real options)
- Update architecture descriptions to match current file structure
- Ensure `package.json` scripts are documented if they have non-obvious usage

## Phase 4: Improve

Enhance existing documentation:

- Improve unclear explanations
- Add examples where the docs are too abstract
- Improve README structure (clearer headings, better flow)
- Add troubleshooting sections for common issues if missing

## Phase 5: Add

Fill documentation gaps:

- Document undocumented features or APIs
- Add missing setup prerequisites
- Add missing environment variable documentation
- Add missing configuration option documentation

## Instructions

1. Read `CLAUDE.md` and `AGENTS.md` first
2. Compare docs against actual source code — don't trust docs at face value
3. Work through Phases 1-5 in order
4. Run `pnpm format` before committing to ensure consistent formatting
5. Commit changes with descriptive messages — group by phase where practical
6. Push to the current branch
7. Do NOT create a new PR — just push to this branch

## Rules

- Accuracy over completeness — wrong docs are worse than missing docs
- Keep docs concise — don't add prose for the sake of length
- Show, don't tell — use examples over descriptions where possible
- Do NOT add auto-generated documentation or boilerplate
- Do NOT create new doc files unless there's a clear gap — prefer improving existing ones
- Do NOT modify source code — only documentation files
