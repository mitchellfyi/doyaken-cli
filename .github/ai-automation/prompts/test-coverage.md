Generate a weekly test coverage report for this repository.

## Instructions

1. **Discover the project setup** — Read the CI workflow files in `.github/workflows/` to find how the project installs dependencies, runs any codegen steps, and executes tests. Read `AGENTS.md` (if it exists) for project conventions.

2. **Set up the environment** — Run the same setup steps as CI: install dependencies, run any codegen/build steps required before tests can run.

3. **Run tests with coverage** — Run the project's test command with coverage enabled. Check the project's test config (package.json scripts, pytest.ini, Cargo.toml, etc.) for an existing coverage command. If none exists, add the appropriate coverage flag (e.g., `--coverage` for most test frameworks).

4. **Analyse coverage results** — Read the coverage output and identify source files with low coverage. Focus on application/library code, not generated files, test files, or configuration.

5. **Prioritise gaps by risk:**
   - **Critical** — Auth, authorization, security, and access control code
   - **High** — API endpoints, data mutation logic, payment/billing code
   - **Medium** — Core business logic, data processing, validation
   - **Low** — Utilities, helpers, UI components

6. **Create or update a GitHub issue:**
   - Check if an open issue with the `test-coverage` label already exists
   - If it exists: add a comment with the new report (do NOT create a duplicate)
   - If none exists: create a new issue titled "Weekly Test Coverage Report" with labels `test-coverage` and `automation`
   - Include: overall coverage percentage, a table of the lowest-coverage files, and for the top 3 gaps, describe what specific behaviours are untested

## Important

- Do NOT write test code — only report what's missing
- Do NOT modify any project files
- If the project has no test framework configured, report that in the issue and skip coverage analysis
- If coverage is already high (>90% overall), note that in the issue and highlight only genuinely important gaps
