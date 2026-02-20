# Task: Scheduled Codebase Review Workflow Template (Tier 2)

## Metadata

| Field       | Value                                                  |
| ----------- | ------------------------------------------------------ |
| ID          | `003-016-scheduled-review-workflow`                    |
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

Doyaken's `periodic-review` skill runs a comprehensive codebase review (quality, security, performance, debt, UX, docs). Currently this only happens when someone manually runs it. Automating it on a weekly schedule means the codebase gets continuous attention without human initiative.

## Objective

Create `templates/workflows/scheduled-review.yml` — a Tier 2 workflow (requires doyaken + API key) that runs weekly codebase reviews and opens PRs with fixes.

## Requirements

### Trigger

- `schedule`: `{{SCHEDULE_REVIEW}}` (default: Monday 6am UTC)
- `workflow_dispatch` for manual runs

### Setup Steps

1. Checkout repository
2. Install doyaken (via npm or direct install — decide best approach)
3. Configure API key from `ANTHROPIC_API_KEY` secret

### Review Execution

1. Run `doyaken skill periodic-review` (or equivalent CLI invocation)
2. If fixes were made (git diff shows changes), create a PR:
   - Branch: `doyaken/review-YYYY-MM-DD`
   - Title: `Automated Codebase Review (YYYY-MM-DD)`
   - Body: summary of findings and changes
   - Labels: `automated`, `review`
3. If no fixes needed, optionally create an issue with the review report

### Template Variables Used

- `{{SCHEDULE_REVIEW}}`
- `{{DEFAULT_BRANCH}}`
- `{{NODE_VERSION}}`

### Secrets Required

- `ANTHROPIC_API_KEY` — for the Claude API calls via doyaken

## Technical Notes

- Use `peter-evans/create-pull-request` action for PR creation (well-maintained, handles branch creation)
- Doyaken install: could use `npm install -g doyaken` or a curl-based installer
- The review skill may take several minutes — set appropriate timeout (30min)
- Tier 2 workflows should clearly document the required secrets in a comment at the top of the template

## Success Criteria

- [ ] Template at `templates/workflows/scheduled-review.yml`
- [ ] Installs doyaken and configures API key in CI
- [ ] Runs periodic-review skill on schedule
- [ ] Creates PR with fixes when changes are made
- [ ] Creates issue with report when no changes needed
- [ ] Documents required secrets
- [ ] Valid GitHub Actions YAML after substitution
