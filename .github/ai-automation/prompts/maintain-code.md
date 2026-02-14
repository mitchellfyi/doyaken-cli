You are performing a scheduled maintenance review of **code quality**. Your goal is to leave the codebase better than you found it.

## Phase 1: Review

1. Read `CLAUDE.md` and `AGENTS.md` for project conventions (KISS, YAGNI, DRY, SOLID)
2. Read `package.json` to understand the tech stack and available scripts
3. Scan the `src/` directory structure to understand the architecture
4. Look for code quality issues:
   - Functions longer than 50 lines
   - Files longer than 300 lines
   - Deeply nested logic (3+ levels)
   - Duplicated code blocks
   - Dead code and unused exports
   - Inconsistent error handling patterns
   - Hardcoded values that should be constants
   - Missing null/undefined checks at system boundaries
   - TODO/FIXME comments that reference completed work

## Phase 2: Fix

Fix problems you found:

- Remove dead code and unused imports
- Fix incorrect error handling (silent failures, missing catch blocks)
- Fix null/undefined issues where the fix is obvious
- Replace hardcoded values with named constants
- Remove completed TODOs

## Phase 3: Sync

Ensure consistency across the codebase:

- Error handling follows the same pattern everywhere
- Naming conventions are consistent (camelCase, PascalCase usage)
- Import paths follow the same style (relative vs alias)
- Similar components/modules follow the same structure

## Phase 4: Improve

Enhance existing code:

- Simplify overly complex functions (extract helpers, reduce nesting)
- Improve variable/function names where they're misleading
- Add missing TypeScript types where `any` is used unnecessarily
- Improve error messages to be more actionable

## Phase 5: Add

Fill gaps:

- Add missing error handling for external API calls
- Add missing input validation at system boundaries (API routes, form handlers)
- Add missing TypeScript types for untyped interfaces

## Instructions

1. Read `CLAUDE.md` and `AGENTS.md` first
2. Focus on `src/` — skip `node_modules/`, `.next/`, and generated files
3. Work through Phases 1-5 in order
4. Run ALL quality gates before committing: `pnpm format`, `pnpm lint:fix`, `pnpm typecheck`, `pnpm test`, `pnpm build`
5. Commit changes with descriptive messages — group by phase where practical
6. Push to the current branch
7. Do NOT create a new PR — just push to this branch

## Rules

- Only make changes you are confident improve the codebase
- Do NOT suppress linting/type errors — fix them properly
- Do NOT make cosmetic-only changes (Prettier handles formatting)
- If a change requires a design decision, skip it and note it in a commit message
- Prioritize high-impact improvements over minor tweaks
- Keep changes focused — don't touch unrelated code
- Do NOT refactor working code just for style — only fix real problems
