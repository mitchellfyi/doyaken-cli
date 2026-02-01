# Task: Update README Commands Table with Missing Commands

## Metadata

| Field       | Value                                                  |
| ----------- | ------------------------------------------------------ |
| ID          | `003-005-docs-update-readme-commands`                  |
| Status      | `todo`                                                 |
| Priority    | `003` Medium                                           |
| Created     | `2026-02-01 17:10`                                     |
| Started     |                                                        |
| Completed   |                                                        |
| Blocked By  |                                                        |
| Blocks      |                                                        |
| Assigned To |                                                        |
| Assigned At |                                                        |

---

## Context

Documentation review identified several commands shown in `--help` that are missing from README.md's commands table:
- `dk review` - Run code review
- `dk hooks` - Manage Claude Code hooks
- `dk cleanup` - Clean up stale files

Also found:
- Agent models table mixes different agent models confusingly
- Skill vendor syntax (e.g., `vercel:deploy`) is undocumented
- Interactive menu when no tasks exist is undocumented

**Category**: Documentation
**Severity**: MEDIUM

---

## Acceptance Criteria

- [ ] Add missing commands to README commands table
- [ ] Separate agent models by agent type in documentation
- [ ] Document skill vendor namespace syntax
- [ ] Document interactive behavior when no tasks exist
- [ ] Verify all --help output matches README

---

## Plan

1. Review `lib/help.sh` for all documented commands
2. Cross-reference with README.md commands table
3. Add missing commands with descriptions
4. Improve agent models section clarity

---

## Work Log

### 2026-02-01 17:10 - Created

- Task created from periodic review documentation findings

---

## Notes

---

## Links

- Documentation review finding: missing commands
