## Instructions

1. **Understand the project** — Read `AGENTS.md` (if it exists) for project conventions. Read the README and build config (package.json, Cargo.toml, pyproject.toml, etc.) to understand the tech stack.

2. **Discover the CI pipeline** — Read the CI workflow files in `.github/workflows/` to find every command that runs: dependency installation, code generation, formatting, linting, type checking, tests, security audit, build, etc. Note the exact order — some steps (like code generation) must run before others.

3. **Reproduce the failure** — Run the exact commands that failed in CI to see the full error output. Start from the beginning of the pipeline (install dependencies, run any codegen steps) to ensure your environment matches CI.

4. **Diagnose the root cause** — Understand _why_ the failure happened, not just _what_ failed. Common patterns:
   - **Dependency issues** — lockfile drift, missing codegen steps after schema/config changes
   - **Formatting/linting** — code doesn't match the project's formatter or linter config
   - **Type errors** — strict type checking catching new or modified code
   - **Test failures** — broken assertions, missing test fixtures, changed behaviour
   - **Build failures** — import errors, missing generated files, config changes

5. **Fix the root cause** — Fix the actual code or configuration errors. Do NOT suppress, skip, weaken, or ignore checks. Do NOT disable rules, add ignore comments, or lower thresholds.

6. **Run ALL quality gates before committing** — Run every check from the CI workflow in order. If any fail, fix them before proceeding. Do not commit until everything passes.

7. **Commit and push** — Commit your changes with a descriptive message and push to the current branch immediately.

## Principles

Apply these when writing your fix:

- **Minimal fix** — Change only what is necessary to fix the failure. Do not refactor, improve, or clean up surrounding code.
- **Simple over clever** — Choose the straightforward solution. Avoid abstractions, indirection, or optimisations that aren't needed.
- **DRY** — If your fix duplicates existing code, reuse the existing implementation instead.
- **SOLID** — Respect existing boundaries. Don't violate single-responsibility or break interfaces.
- **Match existing patterns** — Follow the conventions already used in the codebase. Don't introduce new patterns.

## Important

- If a codegen or build step exists in CI, always run it before formatting/linting/type checks
- If the project uses a lockfile, do not modify it unless the fix requires adding or updating a dependency
- Push your changes immediately after committing
- Do NOT create a new PR — push to the current branch
