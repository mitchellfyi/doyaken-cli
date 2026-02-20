# Task: Research Ralph/Ralphex Agent Architecture

## Metadata

| Field       | Value                                                  |
| ----------- | ------------------------------------------------------ |
| ID          | `005-008-research-ralph-architecture`                  |
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

Doyaken was partially inspired by Ralph's approach (dual-condition exit gate, response analysis). Both Ralph and Ralphex are shell-based agent orchestrators with similar goals but potentially different architectural decisions worth studying.

## Objective

Deep-dive into Ralph and Ralphex architectures to identify patterns, features, and design decisions that doyaken hasn't adopted yet. Focus on what's different, not what's already been borrowed.

## Sources

- https://github.com/umputun/ralphex
- https://github.com/frankbria/ralph-claude-code

## Research Questions

1. What architectural patterns does Ralph use that doyaken doesn't?
2. How does Ralphex differ from the original Ralph?
3. What agent safety/guardrail mechanisms do they implement?
4. How do they handle session persistence and resumption?
5. What logging/observability features do they have?
6. How do they handle configuration and project customization?
7. What features have they added since doyaken last borrowed ideas?

## Output

A list of concrete suggestions and features to adopt or adapt for doyaken, formatted as potential task descriptions.
