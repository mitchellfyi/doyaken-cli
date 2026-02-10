# CI/CD — Fix & Harden

## Mindset

- **CI is the source of truth** — if it passes locally but fails in CI, it's not done
- **Fix root causes, not symptoms** — no workarounds, skips, or `continue-on-error` to make things green
- **CI failures are blockers** — task is not complete until CI passes
- **Deploy safety is non-negotiable** — it should never be possible to deploy code that hasn't passed all checks

## Tasks

### 1. Make All CI Workflows Pass

- Run every workflow locally or trace through the YAML and identify why each failing job fails
- Fix the root cause for each failure — fix source code, tests, configs, or dependencies, not checks
- If a test is flaky, make it deterministic. If a dependency is broken, pin or replace it. If an env var is missing, document and configure it
- Ensure all workflows run successfully on a clean checkout with no local state assumptions

### 2. Organise and Clean Up Workflow Files

- Audit `.github/workflows/` for redundancy, dead workflows, and unclear naming
- Each workflow file should have a clear, descriptive name and filename (e.g., `ci.yml`, `deploy-production.yml`, `lint-and-format.yml`)
- Remove commented-out jobs, unused steps, and deprecated actions
- Pin all third-party actions to full SHA hashes (not tags) for supply chain security:
  ```yaml
  # Good
  uses: actions/checkout@b4ffde65f46336ab88eb53be808477a3936bae11
  # Bad
  uses: actions/checkout@v4
  ```
- Use `GITHUB_TOKEN` permissions at the job level with least-privilege scoping — every job should declare explicit `permissions:` with only what it needs
- Consolidate duplicated logic into reusable workflows (`workflow_call`) or composite actions (`.github/actions/`)

### 3. Improve Deploy Safety on Main

Ensure the default branch has branch protection rules requiring:

- CI passing (status checks must pass before merge)
- At least one approval (or document how to configure this)
- No force pushes
- Linear history (squash or rebase merges preferred)

The deploy workflow should:

- Only trigger on push to the default branch after CI passes
- Never allow deploys on code that hasn't passed all checks
- Use a concurrency group so only one deploy runs at a time:
  ```yaml
  concurrency:
    group: deploy-production
    cancel-in-progress: true
  ```
- Include a rollback mechanism — even if it's just a manual `workflow_dispatch` that deploys a specific commit SHA
- Post a deploy summary (commit SHA, environment, timestamp) as a workflow annotation or GitHub deployment

### 4. Add Missing Quality Gates

Review what's currently checked in CI. Add anything missing from this baseline — if it already exists, leave it alone:

- **Linting** — language-appropriate linter with zero warnings policy
- **Type checking** — if applicable (TypeScript `tsc --noEmit`, Python `mypy`, etc.)
- **Unit tests** — with coverage reporting, fail if coverage drops below current baseline
- **Build step** — ensure the project compiles/bundles without errors
- **Security audit** — `npm audit`, `pip audit`, or equivalent — at minimum flag critical vulnerabilities

Each check should run in under 2 minutes individually. Don't gold-plate.

### 5. Documentation

Add or update a CI/CD section in the project README or a dedicated `CONTRIBUTING.md` explaining:

- What each workflow does and when it runs
- How to run checks locally before pushing
- How deploys work and what triggers them
- How to rollback if a bad deploy lands

## Common Failure Patterns

### Environment Differences
- Case-sensitive filesystem (Linux vs macOS)
- Different shells and tools (GNU vs BSD)
- Path differences

### Missing Dependencies
- Check tools exist before using
- Install explicitly in CI workflows

### Permission Issues
- Ensure scripts are executable
- Check file permissions in git

### Secrets and Environment
- Never hardcode secrets
- Handle missing secrets gracefully

### Timing Issues
- Add explicit waits for services
- Use retries for flaky external calls

## Pre-Push Checklist

- [ ] All tests pass
- [ ] Linting passes
- [ ] Build succeeds
- [ ] Scripts are executable
- [ ] No hardcoded secrets or paths
- [ ] Config files are valid

## Constraints

- Do NOT skip, disable, or `xfail` any existing tests
- Do NOT add `continue-on-error: true` to mask failures
- Do NOT remove or weaken any existing checks to make CI pass
- If a failure requires external action (secret needs adding, third-party service down), create a GitHub issue documenting exactly what's needed and mark the step with a clear `# TODO:` comment explaining the blocker
