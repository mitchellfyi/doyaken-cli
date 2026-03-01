# Phase Prompts

These prompts define the 4-phase pipeline executed by `dk run "<prompt>"`.

## Phases

| Phase | File | Description | Default Timeout | Retry Budget |
|-------|------|-------------|-----------------|-------------|
| 1 | [1-plan.md](1-plan.md) | Expand, triage, plan, discover quality gates | 20 min | 1 |
| 2 | [2-implement.md](2-implement.md) | Execute the plan, write code | 2 hr | 5 |
| 3 | [3-test.md](3-test.md) | Tests and documentation | 1 hr | 3 |
| 4 | [4-verify.md](4-verify.md) | Review, verify, CI | 30 min | 1 |

## Verification

After every phase, two layers run:

1. **Deterministic gates** — lint, format, test, build (discovered from repo in PLAN phase or from `manifest.yaml`)
2. **AI review** — 3 sequential passes (configurable via `DOYAKEN_AI_REVIEW_PASSES`). Disable with `--no-ai-review` or `DOYAKEN_AI_REVIEW=0`.

If gates or AI review fail, the phase re-runs with accumulated feedback until the retry budget is exhausted.

## How It Works

Each phase runs in a fresh agent context with its own prompt. The prompt receives the original task via `{{TASK_PROMPT}}` and accumulated context from prior phases via `{{ACCUMULATED_CONTEXT}}`.

The PLAN phase discovers quality gates by scanning the repo (`package.json`, Makefile, CI config, etc.) and outputs them in a `QUALITY_GATES:` block. The engine parses this and uses those commands for deterministic verification in all phases.

Phases compose reusable methodology from the library using `{{include:library/...}}`.

## Template Variables

| Variable | Available In | Description |
|----------|--------------|-------------|
| `{{TASK_ID}}` | All phases | Generated ID from the prompt |
| `{{TASK_PROMPT}}` | All phases | The original prompt text |
| `{{ACCUMULATED_CONTEXT}}` | All phases | Context from prior phases and retries |
| `{{VERIFICATION_CONTEXT}}` | All phases | Gate/AI review failure output for retries |
| `{{TIMESTAMP}}` | All phases | Current timestamp |
| `{{AGENT_ID}}` | All phases | Worker agent ID |

Review prompts also receive:
| `{{PASS_NUMBER}}` | Review passes | 1, 2, or 3 |
| `{{TOTAL_PASSES}}` | Review passes | 3 (or DOYAKEN_AI_REVIEW_PASSES) |
| `{{REVIEW_PASS_CONTEXT}}` | Review passes | Pass-specific instructions |
| `{{PRIOR_FINDINGS}}` | Review passes 2–3 | Findings from prior passes |

## Customization

To customize phases for a project:
1. Copy the phase file to `.doyaken/prompts/phases/`
2. Modify as needed
3. Project prompts override global ones

## Legacy

The previous 8-phase prompts are in [legacy/](legacy/) for backward compatibility.
