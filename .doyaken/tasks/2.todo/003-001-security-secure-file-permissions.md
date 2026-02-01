# Task: Implement Secure File Permissions for Logs and State

## Metadata

| Field       | Value                                                  |
| ----------- | ------------------------------------------------------ |
| ID          | `003-001-security-secure-file-permissions`             |
| Status      | `todo`                                                 |
| Priority    | `003` Medium                                           |
| Created     | `2026-02-01 17:00`                                     |
| Started     |                                                        |
| Completed   |                                                        |
| Blocked By  |                                                        |
| Blocks      |                                                        |
| Assigned To |                                                        |
| Assigned At |                                                        |

---

## Context

Log files, state files, and lock files are created with default permissions, potentially allowing other users on the system to read sensitive information.

Directories:
- `$LOGS_DIR` - Contains agent output which may include sensitive code context
- `$STATE_DIR` - Contains task state
- `$LOCKS_DIR` - Contains lock files

**Impact**: Other users on multi-user systems can read logs containing task content, code, and potentially sensitive information passed to agents.

**OWASP Category**: A01:2021 - Broken Access Control

---

## Acceptance Criteria

All must be checked before moving to done:

- [ ] Set umask 0077 at process start to ensure owner-only permissions
- [ ] Explicitly set directory permissions to 700 when creating
- [ ] Explicitly set file permissions to 600 when creating
- [ ] Add log rotation to prevent disk exhaustion
- [ ] Document log location and cleanup procedures
- [ ] Tests written and passing
- [ ] Quality gates pass
- [ ] Changes committed with task reference

---

## Plan

1. **Step 1**: Add umask at process start
   - Files: `bin/doyaken` or `lib/core.sh`
   - Add: `umask 0077`

2. **Step 2**: Secure directory creation
   - Files: `lib/core.sh`
   - Add `chmod 700` after mkdir for sensitive directories

3. **Step 3**: Implement log rotation
   - Files: `lib/core.sh`
   - Add function to rotate logs older than N days
   - Or use logrotate config

4. **Step 4**: Document log handling
   - Files: `README.md`
   - Document where logs are stored
   - Document cleanup procedures

---

## Implementation

```bash
# At process start
umask 0077

# When creating directories
mkdir -p "$LOGS_DIR"
chmod 700 "$LOGS_DIR"

# Log rotation (simple approach)
find "$LOGS_DIR" -type f -mtime +7 -delete
```

---

## Work Log

### 2026-02-01 17:00 - Created

- Security audit identified world-readable logs
- Next: Implement secure permissions

---

## Links

- File: `lib/core.sh`
- CWE-276: Incorrect Default Permissions
