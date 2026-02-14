You are performing a scheduled maintenance review of **CI/CD and quality infrastructure**. Your goal is to keep the pipeline efficient, secure, and comprehensive.

## Phase 1: Review

1. Read `CLAUDE.md` and `AGENTS.md` for project conventions
2. Read all workflow files in `.github/workflows/`
3. Read `package.json` scripts (lint, format, test, build, typecheck, audit)
4. Read quality config files (ESLint, Prettier, TypeScript, Vitest configs)
5. Audit:
   - CI job efficiency (unnecessary steps, missing caching, slow builds)
   - Security: run `pnpm audit --prod --audit-level=moderate` — check for vulnerabilities
   - Actions versions: are all `uses:` references pinned to recent stable versions?
   - Quality gate coverage: does CI run everything it should? (format, lint, typecheck, test, audit, build)
   - Workflow correctness: are conditions, permissions, and triggers correct?
   - Missing quality checks that should exist

## Phase 2: Fix

Fix CI/CD problems:

- Fix incorrect workflow triggers or conditions
- Fix misconfigured permissions (too broad or too narrow)
- Update outdated GitHub Actions to latest major versions (e.g., `actions/checkout@v3` → `actions/checkout@v4`)
- Fix security vulnerabilities found by `pnpm audit` (use `pnpm audit fix` for safe fixes)
- Fix quality config issues (rules that conflict, missing rules for common mistakes)

## Phase 3: Sync

Align CI with the actual project:

- Ensure CI commands match the actual `package.json` scripts
- Remove CI steps for tools/checks that are no longer used
- Ensure CI node/pnpm versions match the project's requirements
- Ensure `.gitignore` covers all generated/cached files

## Phase 4: Improve

Enhance the pipeline:

- Add caching where missing (pnpm store, Next.js cache, Playwright browsers)
- Optimize job parallelism where possible
- Improve error messages from quality scripts
- Tighten ESLint rules for common mistakes that currently pass

## Phase 5: Add

Fill infrastructure gaps:

- Add missing quality checks to CI (if the project has a tool locally but CI doesn't run it)
- Add missing npm scripts that would be useful (e.g., `quality` that runs all checks)

## Instructions

1. Read `CLAUDE.md` and `AGENTS.md` first
2. Read all `.github/workflows/*.yml` files
3. Work through Phases 1-5 in order
4. Run ALL quality gates before committing: `pnpm format`, `pnpm lint:fix`, `pnpm typecheck`, `pnpm test`
5. Commit changes with descriptive messages — group by phase where practical
6. Push to the current branch
7. Do NOT create a new PR — just push to this branch

## Rules

- Do NOT remove quality checks — only add or improve them
- Do NOT suppress linting rules to make errors go away — fix the code instead
- Do NOT modify lockfiles unless `pnpm audit fix` requires it
- Be careful with CI workflow changes — test them mentally before committing
- Prefer standard, well-known actions over custom scripts
- Keep CI fast — don't add slow checks without good reason
