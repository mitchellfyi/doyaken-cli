# Task: Dependency Audit Workflow Template (Tier 1)

## Metadata

| Field       | Value                                                  |
| ----------- | ------------------------------------------------------ |
| ID          | `003-015-dependency-audit-workflow`                    |
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

Dependency vulnerabilities are a top attack vector. While GitHub has Dependabot, not all projects enable it, and it doesn't cover all ecosystems consistently. This template runs scheduled audits and creates issues for vulnerabilities found.

## Objective

Create `templates/workflows/dependency-audit.yml` — a Tier 1 workflow that runs scheduled dependency audits (`npm audit`, `pip audit`, etc.) and creates GitHub issues for any vulnerabilities found.

## Requirements

### Trigger

- `schedule`: `{{SCHEDULE_DEPS}}` (default: weekly Monday 6am UTC)
- `workflow_dispatch` for manual runs

### Audit Steps

1. Detect package manager (package-lock.json → npm, yarn.lock → yarn, requirements.txt → pip, etc.)
2. Run appropriate audit command (`npm audit --json`, `pip-audit --format json`, etc.)
3. Parse results for vulnerabilities above a severity threshold

### Issue Creation

- Only create an issue if vulnerabilities are found
- Title: `Dependency Audit: N vulnerabilities found (YYYY-MM-DD)`
- Body: summary table of vulnerabilities (package, severity, advisory URL)
- Labels: `dependencies`, `security`, `automated`
- Duplicate check: if an open issue with same labels exists, update it instead

### Template Variables Used

- `{{SCHEDULE_DEPS}}`
- `{{DEFAULT_BRANCH}}`

## Technical Notes

- Use `actions/github-script` for issue creation/update logic
- `npm audit --json` returns structured output that can be parsed
- For pip, `pip-audit` is the standard tool (may need `pip install pip-audit` step)
- Keep the template focused on npm initially; other ecosystems can be added later
- Truncate vulnerability list if too long for issue body

## Success Criteria

- [ ] Template at `templates/workflows/dependency-audit.yml`
- [ ] Runs on schedule and manual dispatch
- [ ] Detects package manager and runs appropriate audit
- [ ] Creates issue with vulnerability summary
- [ ] Updates existing issue instead of creating duplicates
- [ ] Valid GitHub Actions YAML after substitution
