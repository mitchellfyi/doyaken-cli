# Task: Research Agent Teams and Orchestration (Claude Teams, Letta, Shannon)

## Metadata

| Field       | Value                                                  |
| ----------- | ------------------------------------------------------ |
| ID          | `005-006-research-agent-teams-orchestration`           |
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

Doyaken supports multi-agent via file-based locking and task assignment but doesn't have explicit team coordination. New frameworks are building first-class agent team orchestration.

## Objective

Research Claude's agent teams, Letta, and Shannon to understand team coordination patterns, role assignment, and inter-agent communication. Identify what doyaken needs for real multi-agent workflows.

## Sources

- https://code.claude.com/docs/en/agent-teams
- https://letta.bot
- https://github.com/letta-ai/lettabot
- https://github.com/KeygraphHQ/shannon

## Research Questions

1. How do Claude agent teams define roles and responsibilities?
2. How does Letta handle agent memory and state across team interactions?
3. What communication patterns exist between agents (message passing, shared state, events)?
4. How do they handle task delegation and result aggregation?
5. What team topologies are supported (hierarchical, peer, hub-spoke)?
6. How do they prevent conflicting agent actions?

## Output

A list of concrete suggestions for improving doyaken's multi-agent support, team coordination, and inter-agent communication, formatted as potential task descriptions.
