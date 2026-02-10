# Task: Scheduled Security Audit Workflow Template (Tier 2)

## Metadata

| Field       | Value                                                  |
| ----------- | ------------------------------------------------------ |
| ID          | `003-017-scheduled-security-audit-workflow`            |
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

Doyaken's `audit-security` skill runs an OWASP-based security audit. Running it monthly ensures security issues are caught early without relying on someone remembering to run it.

## Objective

Create `templates/workflows/scheduled-security-audit.yml` — a Tier 2 workflow (requires doyaken + API key) that runs monthly security audits and opens issues/PRs with findings and fixes.

## Requirements

### Trigger

- `schedule`: `{{SCHEDULE_SECURITY}}` (default: 1st of month, 6am UTC)
- `workflow_dispatch` for manual runs

### Setup Steps

1. Checkout repository
2. Install doyaken
3. Configure API key from `ANTHROPIC_API_KEY` secret

### Audit Execution

1. Run `doyaken skill audit-security`
2. If fixes were made (git diff shows changes), create a PR:
   - Branch: `doyaken/security-YYYY-MM-DD`
   - Title: `Automated Security Audit (YYYY-MM-DD)`
   - Body: summary of findings and fixes
   - Labels: `automated`, `security`
3. If findings exist but no auto-fixes, create an issue:
   - Title: `Security Audit Findings (YYYY-MM-DD)`
   - Body: audit report with findings, severity, and recommendations
   - Labels: `security`, `automated`

### Template Variables Used

- `{{SCHEDULE_SECURITY}}`
- `{{DEFAULT_BRANCH}}`
- `{{NODE_VERSION}}`

### Secrets Required

- `ANTHROPIC_API_KEY` — for the Claude API calls via doyaken

## Technical Notes

- Similar structure to scheduled-review workflow but with security-specific labeling and handling
- Security findings may contain sensitive info — the issue body should avoid exposing specific vulnerability details that could be exploited (reference line numbers, not exploit payloads)
- Use `peter-evans/create-pull-request` for PR creation
- Set appropriate timeout (30min) as security audit may take time
- Tier 2 workflows should clearly document required secrets

## Success Criteria

- [ ] Template at `templates/workflows/scheduled-security-audit.yml`
- [ ] Installs doyaken and configures API key in CI
- [ ] Runs audit-security skill on schedule
- [ ] Creates PR with security fixes when applicable
- [ ] Creates issue with findings when no auto-fix possible
- [ ] Avoids exposing exploitable details in issues
- [ ] Documents required secrets
- [ ] Valid GitHub Actions YAML after substitution
