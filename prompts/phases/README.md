# Phase Prompts

These prompts define the 8-phase pipeline executed by `dk run "<prompt>"`.

## Phases

| Phase | File | Description | Default Timeout | Retry Budget |
|-------|------|-------------|-----------------|-------------|
| 0 | [0-expand.md](0-expand.md) | Expand brief prompt into full spec | 2 min | 1 |
| 1 | [1-triage.md](1-triage.md) | Validate feasibility, check dependencies | 2 min | 1 |
| 2 | [2-plan.md](2-plan.md) | Gap analysis, detailed planning | 5 min | 1 |
| 3 | [3-implement.md](3-implement.md) | Execute the plan, write code | 30 min | 5 |
| 4 | [4-test.md](4-test.md) | Run tests, add coverage | 10 min | 3 |
| 5 | [5-docs.md](5-docs.md) | Sync documentation | 5 min | 1 |
| 6 | [6-review.md](6-review.md) | Code review, quality check | 10 min | 3 |
| 7 | [7-verify.md](7-verify.md) | Final verification, commit | 3 min | 1 |

## How It Works

Each phase runs in a fresh agent context with its own prompt. The prompt receives the original task via `{{TASK_PROMPT}}` and accumulated context from prior phases via `{{ACCUMULATED_CONTEXT}}`.

After every phase, verification gates run the project's quality commands (build, lint, format, test). If any gate fails and the phase has retries remaining (controlled by `retry_budget` in the manifest), the phase re-runs with the error output injected via `{{VERIFICATION_CONTEXT}}`.

Phases compose reusable methodology from the library using `{{include:library/...}}`.

## Template Variables

| Variable | Available In | Description |
|----------|--------------|-------------|
| `{{TASK_PROMPT}}` | All phases | The original prompt text |
| `{{ACCUMULATED_CONTEXT}}` | All phases | Context from prior phases and retries |
| `{{VERIFICATION_CONTEXT}}` | All phases | Gate failure output for retries |
| `{{TIMESTAMP}}` | All phases | Current timestamp |
| `{{RECENT_COMMITS}}` | Phase 6 | Recent git commit log |

## Customization

To customize phases for a project:
1. Copy the phase file to `.doyaken/prompts/phases/`
2. Modify as needed
3. Project prompts override global ones

## Skipping Phases

Set environment variables to skip phases:
```bash
SKIP_DOCS=1 dk run "Fix the bug"     # Skip docs phase
SKIP_TEST=1 dk run "Update README"   # Skip test phase
```
