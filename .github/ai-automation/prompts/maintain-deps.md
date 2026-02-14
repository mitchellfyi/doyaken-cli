You are performing a scheduled maintenance review of **dependencies**. Your goal is to keep dependencies secure, current, and minimal.

## Phase 1: Review

1. Read `CLAUDE.md` and `AGENTS.md` for project conventions
2. Read `package.json` — both `dependencies` and `devDependencies`
3. Audit:
   - **Vulnerabilities:** Run `pnpm audit --prod --audit-level=moderate`
   - **Outdated:** Run `pnpm outdated` to find packages behind latest
   - **Unused:** Check for packages in `package.json` that are never imported in source code
   - **Duplicates:** Check for multiple versions of the same package (`pnpm ls --depth=0`)
   - **Size:** Check for unnecessarily heavy packages that have lighter alternatives
   - **Deprecated:** Look for deprecation warnings in package READMEs or npm pages
   - **License:** Check for packages with incompatible or missing licenses

## Phase 2: Fix

Fix dependency problems:

- Fix known vulnerabilities: `pnpm audit fix` for safe fixes
- Remove unused dependencies from `package.json`
- Update packages with critical/high vulnerabilities to patched versions
- Replace deprecated packages with their recommended replacements

## Phase 3: Sync

Align dependency config with the project:

- Ensure `engines` field in `package.json` matches CI node version
- Ensure `packageManager` field matches the pnpm version used in CI
- Ensure dev-only packages are in `devDependencies`, not `dependencies`
- Remove packages that were replaced by built-in features (e.g., Node.js fetch)

## Phase 4: Improve

Enhance dependency management:

- Update packages to latest minor/patch versions (non-breaking)
- Replace heavy packages with lighter alternatives where drop-in replacements exist
- Consolidate packages that serve the same purpose (e.g., two date libraries)

## Phase 5: Add

Fill dependency gaps:

- Document in a commit message any major version upgrades that were skipped and why
- Add missing `@types/*` packages for untyped dependencies

## Instructions

1. Read `CLAUDE.md` and `AGENTS.md` first
2. Review `package.json` and run audit commands
3. Work through Phases 1-5 in order
4. After any dependency changes, run `pnpm install` to update the lockfile
5. Run ALL quality gates: `pnpm format`, `pnpm lint:fix`, `pnpm typecheck`, `pnpm test`, `pnpm build`
6. Commit changes with descriptive messages — group by phase where practical
7. Push to the current branch
8. Do NOT create a new PR — just push to this branch

## Rules

- Do NOT upgrade major versions unless the migration is trivial and well-documented
- Do NOT remove packages you're unsure about — verify with grep/search first
- Do NOT modify source code to accommodate dependency changes unless necessary
- Always run the full test suite after dependency changes
- Keep the lockfile in sync — run `pnpm install` after any `package.json` changes
- If a vulnerability has no fix available, note it in a commit message but don't suppress it
