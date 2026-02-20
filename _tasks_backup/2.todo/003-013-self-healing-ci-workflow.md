# Task: Self-Healing CI Workflow Template (Tier 1)

## Metadata

| Field       | Value                                                  |
| ----------- | ------------------------------------------------------ |
| ID          | `003-013-self-healing-ci-workflow`                     |
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

When CI fails on the default branch, the current workflow is: someone notices, reads the logs, diagnoses, and fixes it. This workflow automates that by creating a GitHub issue with failure context and optionally assigning it to an AI agent (Copilot, Claude API, or just creating the issue).

## Objective

Create `templates/workflows/self-healing-ci.yml` — a Tier 1 workflow (no doyaken needed in CI) that triggers on CI failure and creates/updates a GitHub issue with failure logs.

## Requirements

### Trigger

- Fires on `workflow_run` completed with conclusion `failure` on the default branch (`{{DEFAULT_BRANCH}}`)
- Only triggers for the CI workflow (`{{CI_WORKFLOW_NAME}}`)
- Never self-heals the self-healing workflow (prevent infinite loops)

### Issue Creation

- Title: `CI Fix: <workflow name> failed on <branch>` (or similar structured format)
- Body includes: failed job names, failure logs (truncated to fit), link to the failed run, commit that triggered it
- Labels: `ci-fix`, `automated`
- Milestone: none

### Agent Strategy (via `{{AGENT_STRATEGY}}`)

- `copilot` — also add `copilot` label so GitHub Copilot coding agent picks it up
- `claude-api` — add a step that runs `doyaken skill ci-fix` (Tier 2 behavior embedded)
- `issue-only` — just create the issue, no agent assignment

### Safety Measures

1. **Duplicate check** — before creating, check for existing open issue with `ci-fix` + `automated` labels. If found, append a comment instead of creating a new issue
2. **Escalation** — after 3 comments on the same issue (3 consecutive failures), add `needs-human` label
3. **Loop prevention** — workflow file name check: skip if the failing workflow is the self-healing workflow itself
4. **Branch guard** — only fires on default branch failures

### Template Variables Used

- `{{DEFAULT_BRANCH}}`
- `{{CI_WORKFLOW_NAME}}`
- `{{AGENT_STRATEGY}}`

## Technical Notes

- Use `actions/github-script` for issue creation/comment logic (keeps it self-contained, no external deps)
- Fetch failure logs via GitHub API (`GET /repos/{owner}/{repo}/actions/runs/{run_id}/jobs` → `GET /repos/{owner}/{repo}/actions/jobs/{job_id}/logs`)
- Truncate logs to ~3000 chars to stay within issue body limits
- The template should be valid GitHub Actions YAML after variable substitution

## Success Criteria

- [ ] Template at `templates/workflows/self-healing-ci.yml`
- [ ] Triggers on CI failure on default branch only
- [ ] Creates issue with failure context and logs
- [ ] Appends comment on duplicate instead of new issue
- [ ] Adds `needs-human` label after 3 consecutive failures
- [ ] Supports all 3 agent strategies via template variable
- [ ] Never triggers on itself (loop prevention)
- [ ] Valid GitHub Actions YAML after variable substitution
