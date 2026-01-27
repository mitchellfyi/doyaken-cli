# Task: Test dogfooding doyaken

## Metadata

| Field       | Value                                                  |
| ----------- | ------------------------------------------------------ |
| ID          | `003-001-test-dogfooding-doyaken`                      |
| Status      | `done`                                                 |
| Priority    | `003` Medium                                           |
| Created     | `2026-01-27 18:12`                                     |
| Started     | `2026-01-27 18:17`                                     |
| Completed   | `2026-01-27 18:25`                                     |
| Blocked By  |                                                        |
| Blocks      |                                                        |
| Assigned To |                                                        |
| Assigned At |                                                        |

---

## Context

Test doyaken by installing it globally and using it to manage tasks in its own repository (dogfooding).

---

## Acceptance Criteria

- [x] Install doyaken globally
- [x] Test CLI commands (status, tasks, doctor, etc.)
- [x] Fix any bugs discovered during testing
- [x] Changes committed with task reference

---

## Plan

1. Install doyaken globally using install.sh
2. Initialize doyaken within its own project
3. Test core commands
4. Fix any bugs found

---

## Work Log

### 2026-01-27 18:12 - Created

- Task created via CLI

### 2026-01-27 18:17 - Testing

- Ran `dk status` - found DOYAKEN_DIR unbound variable error
- Ran `dk tasks` - worked correctly
- Ran `dk doctor` - all checks passed
- Ran `dk task 003-001` - discovered it creates a task instead of viewing
- Added `dk tasks view <id>` subcommand

### 2026-01-27 18:24 - Bugs Fixed

- Fixed DOYAKEN_DIR unbound variable (subshell export issue)
- Fixed CLAUDE_MODEL unbound variable (use DOYAKEN_MODEL)
- Fixed ${var^^} bashism (use tr for portability)
- Added `tasks view` subcommand

---

## Notes

The main issues found were related to variable scoping - exports in subshells don't propagate to the parent shell. Fixed by using local variables after calling require_project.

---

## Links

- Commit: 71291e1 fix: Resolve unbound variable errors in CLI commands
