# Task: Set Restrictive Permissions on Log and Backup Directories

## Metadata

| Field       | Value                                                  |
| ----------- | ------------------------------------------------------ |
| ID          | `003-006-quality-set-log-permissions`                  |
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

Security review identified that log files and backup directories are created with default umask permissions. On systems with permissive umask (e.g., 0022), this creates world-readable files. Phase logs may contain sensitive information like user code, agent responses, and git history.

**Locations**:
- lib/core.sh:396 - RUN_LOG_DIR creation
- lib/upgrade.sh:259-293 - backup directory creation

**Category**: Security / File Permissions
**Severity**: MEDIUM

---

## Acceptance Criteria

- [ ] Set chmod 700 on all log directories when created
- [ ] Set chmod 700 on backup directories when created
- [ ] Add umask 077 at start of scripts that create sensitive files
- [ ] Document security considerations for logs in README

---

## Plan

1. Add `chmod 700` after mkdir for log directories
2. Add `chmod 700` after mkdir for backup directories
3. Consider adding umask at script entry points

---

## Work Log

### 2026-02-01 17:10 - Created

- Task created from periodic review security findings

---

## Notes

Example fix:
```bash
mkdir -p "$RUN_LOG_DIR"
chmod 700 "$RUN_LOG_DIR"
```

---

## Links

- Security review finding: log file permissions
