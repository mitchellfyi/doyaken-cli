# Phase Prompts

These prompts define the 8-phase workflow executed by `doyaken run`.

## Phases

| Phase | File | Description | Default Timeout |
|-------|------|-------------|-----------------|
| 0 | [0-expand.md](0-expand.md) | Expand brief prompt into full spec | 2 min |
| 1 | [1-triage.md](1-triage.md) | Validate task, check dependencies | 2 min |
| 2 | [2-plan.md](2-plan.md) | Gap analysis, detailed planning | 5 min |
| 3 | [3-implement.md](3-implement.md) | Execute the plan, write code | 30 min |
| 4 | [4-test.md](4-test.md) | Run tests, add coverage | 10 min |
| 5 | [5-docs.md](5-docs.md) | Sync documentation | 5 min |
| 6 | [6-review.md](6-review.md) | Code review, create follow-ups | 10 min |
| 7 | [7-verify.md](7-verify.md) | Verify task management, commit | 3 min |

## How It Works

Each phase runs in a fresh context with its own prompt. Phases use `{{include:library/...}}` to pull in reusable methodology from the library.

## Customization

To customize phases for a project:
1. Copy the phase file to `.doyaken/prompts/phases/`
2. Modify as needed
3. Project prompts override global ones

## Skipping Phases

Set environment variables to skip phases:
```bash
SKIP_DOCS=1 doyaken run    # Skip docs phase
SKIP_TEST=1 doyaken run    # Skip test phase
```
