# Task: Research Agent Automation Platforms (Codex App, GitClaw, TallyAI, Scribe)

## Metadata

| Field       | Value                                                  |
| ----------- | ------------------------------------------------------ |
| ID          | `005-007-research-agent-automation-platforms`           |
| Status      | `todo`                                                 |
| Priority    | `005` Research                                         |
| Created     | `2026-02-10 20:00`                                     |
| Started     |                                                        |
| Completed   |                                                        |
| Blocked By  |                                                        |
| Blocks      |                                                        |
| Assigned To |                                                        |
| Assigned At |                                                        |

---

## Context

Doyaken runs agents locally via CLI. Several platforms are building cloud-hosted or hybrid agent automation with different UX models for triggering, monitoring, and reviewing agent work.

## Objective

Research OpenAI Codex App, GitClaw, TallyAI, and Scribe to understand their automation triggers, monitoring dashboards, and review workflows. Identify UX patterns that could improve doyaken.

## Sources

- https://developers.openai.com/codex/app/automations/
- https://openai.com/index/introducing-the-codex-app/
- https://github.com/SawyerHood/gitclaw
- https://tallyai.money/
- https://scribe.com/

## Research Questions

1. How does Codex App handle automation triggers (issue created, PR opened, scheduled)?
2. What does GitClaw's git-native agent interaction model look like?
3. How do these tools present agent progress and results to users?
4. What approval/review gates exist before agent actions take effect?
5. How do they handle agent cost tracking and budget limits?
6. What integration points do they expose (webhooks, APIs, CLI)?

## Output

A list of concrete suggestions for improving doyaken's automation triggers, monitoring, review workflows, and cost tracking, formatted as potential task descriptions.
