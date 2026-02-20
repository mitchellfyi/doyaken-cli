# Task: PR Quality Gate Workflow Template (Tier 1)

## Metadata

| Field       | Value                                                  |
| ----------- | ------------------------------------------------------ |
| ID          | `003-014-pr-quality-gate-workflow`                     |
| Status      | `todo`                                                 |
| Priority    | `003` Medium                                           |
| Created     | `2026-02-10 18:00`                                     |
| Started     |                                                        |
| Completed   |                                                        |
| Blocked By  | `003-012`                                              |
| Blocks      |                                                        |
| Assigned To |                                                        |
| Assigned At |                                                        |

---

## Context

Many projects lack consistent CI checks on pull requests. This template provides a ready-made quality gate that runs lint, test, and build on every PR — works with any project that has these commands configured.

## Objective

Create `templates/workflows/pr-quality-gate.yml` — a Tier 1 workflow that runs lint, test, and build checks on pull requests.

## Requirements

### Trigger

- `pull_request` events targeting `{{DEFAULT_BRANCH}}`
- Event types: `opened`, `synchronize`, `reopened`

### Jobs

1. **Lint** — runs `{{LINT_COMMAND}}`
2. **Test** — runs `{{TEST_COMMAND}}`
3. **Build** — runs `{{BUILD_COMMAND}}` (if configured, otherwise skip)

### Configuration

- Node version: `{{NODE_VERSION}}`
- Each job should be independent (run in parallel, not sequential)
- Use caching for dependencies (npm/yarn/pnpm cache)
- Fail fast: if any job fails, the PR check shows failure

### Template Variables Used

- `{{DEFAULT_BRANCH}}`
- `{{NODE_VERSION}}`
- `{{TEST_COMMAND}}`
- `{{LINT_COMMAND}}`
- `{{BUILD_COMMAND}}`

## Technical Notes

- Use `actions/setup-node` with version from template variable
- Use `actions/cache` or built-in npm caching for speed
- Keep the workflow simple — this is a Tier 1 template that should work without doyaken installed
- Should gracefully handle missing commands (e.g., if no build command, skip that job)

## Success Criteria

- [ ] Template at `templates/workflows/pr-quality-gate.yml`
- [ ] Runs lint, test, build on PRs to default branch
- [ ] Jobs run in parallel
- [ ] Uses dependency caching
- [ ] Template variables correctly substituted
- [ ] Valid GitHub Actions YAML after substitution
