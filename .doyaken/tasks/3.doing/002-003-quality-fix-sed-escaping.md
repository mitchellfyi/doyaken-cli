# Task: Fix Incomplete sed Metacharacter Escaping in core.sh

## Metadata

| Field       | Value                                                  |
| ----------- | ------------------------------------------------------ |
| ID          | `002-003-quality-fix-sed-escaping`                     |
| Status      | `todo`                                                 |
| Priority    | `002` High                                             |
| Created     | `2026-02-01 17:10`                                     |
| Started     |                                                        |
| Completed   |                                                        |
| Blocked By  |                                                        |
| Blocks      |                                                        |
| Assigned To | `worker-1` |
| Assigned At | `2026-02-01 21:00` |

---

## Context

Security review identified incomplete sed metacharacter escaping in `lib/core.sh:716-718`. The code only escapes `&` and `/` characters, but sed also interprets `\`, `*`, `.` and other special characters. A malicious AGENT_ID could break sed patterns or cause unintended substitutions.

**Category**: Security / Input Validation
**Severity**: HIGH

---

## Acceptance Criteria

- [ ] Replace sed-based approach with safer alternative (awk, bash string operations, or Perl)
- [ ] Ensure all metadata updates in task files use the new approach
- [ ] Add tests for edge cases (special characters in AGENT_ID)
- [ ] No regressions in task assignment functionality

---

## Plan

1. Identify all sed operations in core.sh that use user-provided values
2. Replace with `awk` one-liner or bash pattern replacement
3. Add unit tests for task metadata update functions

---

## Work Log

### 2026-02-01 17:10 - Created

- Task created from periodic review security findings

---

## Notes

Locations to fix:
- lib/core.sh:716-718 (assign_task)
- lib/core.sh:731-732 (assign_task timestamp)
- lib/core.sh:746 (additional metadata)

---

## Links

- Security review finding: sed escaping vulnerability
