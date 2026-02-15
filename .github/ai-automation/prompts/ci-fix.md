## Step 1: Understand the Project

**Read the project documentation first:**

1. Check for `AGENTS.md` in the repo root — this contains project-specific instructions for AI agents
2. Check for `README.md` — this describes the project setup and commands
3. Check for `.github/ai-automation/AGENTS.md` — additional AI automation guidance

**Identify the tech stack** by looking at config files:
- `package.json` / `pnpm-lock.yaml` / `yarn.lock` → Node.js
- `Gemfile` / `Gemfile.lock` → Ruby/Rails
- `requirements.txt` / `pyproject.toml` → Python
- `go.mod` → Go
- `Cargo.toml` → Rust

## Step 2: Set Up Your Environment

**Install dependencies using the EXACT commands from CI:**

1. Read `.github/workflows/ci.yml` (or similar) to find the dependency installation commands
2. Run the same commands the CI uses — don't improvise
3. If the project uses a lockfile (`package-lock.json`, `pnpm-lock.yaml`, `Gemfile.lock`), use the frozen install command (`npm ci`, `pnpm install --frozen-lockfile`, `bundle install`)

**Common setups:**
- Node.js: `npm ci` or `pnpm install --frozen-lockfile`
- Ruby: `bundle install`
- Python: `pip install -r requirements.txt`

## Step 3: Discover ALL Quality Gates

**Read the CI workflow files carefully.** Find every command that runs:

1. Dependency installation
2. Code generation (Prisma, GraphQL, Rails generators, etc.)
3. Formatting checks (`prettier`, `rubocop`, `black`)
4. Linting (`eslint`, `rubocop`, `pylint`)
5. Type checking (`tsc`, `mypy`, `sorbet`)
6. Tests (`jest`, `rspec`, `pytest`)
7. Security audits (`npm audit`, `bundle audit`, `safety`)
8. Build steps (`npm run build`, `rails assets:precompile`)

**Write down the exact commands** — you will need to run them all before pushing.

## Step 4: Reproduce the Failure

Run the exact commands that failed in CI:

1. Start from a clean state (dependencies installed)
2. Run any codegen steps first
3. Run the failing command with the same arguments as CI
4. Capture the full error output

## Step 5: Fix the Root Cause

**Understand WHY it failed, not just WHAT failed:**
- Dependency issues → lockfile drift, missing packages
- Format/lint errors → code doesn't match project style
- Type errors → new code has type mismatches
- Test failures → broken assertions, missing fixtures
- Build failures → missing generated files

**Apply the fix:**
- Change only what's necessary
- Match existing code patterns
- Do NOT suppress, skip, or weaken checks
- Do NOT add ignore comments or disable rules

## Step 6: Verify ALL Quality Gates Pass (MANDATORY)

**Before committing, run EVERY quality gate from the CI workflow:**

```bash
# Example for a Node.js project — adapt to your project
npm ci                    # Install deps
npm run generate          # If codegen exists
npm run format:check      # Formatting
npm run lint              # Linting
npm run typecheck         # Type checking
npm run test              # Tests
npm run build             # Build
```

**DO NOT COMMIT if any check fails.** Fix the issue and re-run ALL checks.

## Step 7: Commit and Push

Only after ALL quality gates pass:

1. Stage your changes: `git add -A`
2. Commit with a descriptive message: `git commit -m "fix: description of fix"`
3. Push immediately: `git push`

**Do NOT create a new PR** — push to the current branch.

## Principles

- **Minimal fix** — Only change what's necessary
- **Match existing patterns** — Follow the codebase conventions
- **Simple over clever** — Choose the straightforward solution
- **Run checks locally first** — Never push without verifying

## Common Mistakes to Avoid

- ❌ Pushing without running quality gates locally
- ❌ Skipping codegen steps before lint/type checks
- ❌ Modifying lockfiles unnecessarily
- ❌ Adding ignore comments or disabling rules
- ❌ Fixing symptoms instead of root causes
