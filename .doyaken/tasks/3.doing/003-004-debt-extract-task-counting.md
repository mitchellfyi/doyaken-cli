# Task: Extract Task Counting to Utility Function

## Metadata

| Field       | Value                                                  |
| ----------- | ------------------------------------------------------ |
| ID          | `003-004-debt-extract-task-counting`                   |
| Status      | `todo`                                                 |
| Priority    | `003` Medium                                           |
| Created     | `2026-02-01 17:10`                                     |
| Started     |                                                        |
| Completed   |                                                        |
| Blocked By  |                                                        |
| Blocks      |                                                        |
| Assigned To | `worker-2` |
| Assigned At | `2026-02-01 22:18` |

---

## Context

Technical debt assessment identified that the task counting pattern `find ... | wc -l | tr -d ' '` is duplicated 15+ times across lib/cli.sh, lib/core.sh, lib/registry.sh, and lib/taskboard.sh. This creates maintenance burden and risk of inconsistent counting logic.

**Category**: Technical Debt / Code Duplication
**Severity**: MEDIUM

---

## Acceptance Criteria

- [ ] Create `count_task_files()` utility function in lib/project.sh
- [ ] Replace all 15+ instances with calls to new function
- [ ] Add tests for counting function
- [ ] Ensure no behavior changes

---

## Plan

1. Add function to lib/project.sh:
   ```bash
   count_task_files() {
     local dir="$1"
     find "$dir" -maxdepth 1 -name "*.md" 2>/dev/null | wc -l | tr -d ' '
   }
   ```
2. Find and replace all occurrences
3. Test edge cases (empty dir, missing dir)

---

## Work Log

### 2026-02-01 17:10 - Created

- Task created from periodic review technical debt findings

---

## Notes

Files to update:
- lib/cli.sh (~5 occurrences)
- lib/core.sh (~3 occurrences)
- lib/registry.sh (~4 occurrences)
- lib/taskboard.sh (~4 occurrences)

---

## Links

- Technical debt review finding: code duplication
