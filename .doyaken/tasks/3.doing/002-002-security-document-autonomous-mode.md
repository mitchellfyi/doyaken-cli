# Task: Document Security Implications of Autonomous Mode

## Metadata

| Field       | Value                                                  |
| ----------- | ------------------------------------------------------ |
| ID          | `002-002-security-document-autonomous-mode`            |
| Status      | `todo`                                                 |
| Priority    | `002` High                                             |
| Created     | `2026-02-01 17:00`                                     |
| Started     |                                                        |
| Completed   |                                                        |
| Blocked By  |                                                        |
| Blocks      |                                                        |
| Assigned To | `worker-1` |
| Assigned At | `2026-02-01 19:53` |

---

## Context

Doyaken runs AI agents with explicit permission bypass flags that disable security controls:

**From `lib/agents.sh:154-187`**:
```bash
case "$agent" in
  claude)
    echo "--dangerously-skip-permissions --permission-mode bypassPermissions"
    ;;
  codex)
    echo "--dangerously-bypass-approvals-and-sandbox"
    ;;
  gemini)
    echo "--yolo"
    ;;
  copilot)
    echo "--allow-all-tools --allow-all-paths"
    ;;
```

This is intentional design for autonomous operation, but users should understand the security implications.

**Impact**: Agents can execute arbitrary code, modify any files, and make network requests without user approval.

---

## Acceptance Criteria

All must be checked before moving to done:

- [ ] Create SECURITY.md document explaining the security model
- [ ] Document what autonomous mode enables and its risks
- [ ] Add security warning to README.md
- [ ] Add `--interactive` or `--safe-mode` flag option that doesn't bypass permissions
- [ ] Add first-run warning about autonomous mode
- [ ] Document trust requirements for manifests and tasks
- [ ] Quality gates pass
- [ ] Changes committed with task reference

---

## Plan

1. **Step 1**: Create SECURITY.md
   - Explain trust model
   - Document what each agent bypass flag does
   - Describe attack scenarios and mitigations

2. **Step 2**: Update README.md
   - Add security warning section
   - Link to SECURITY.md

3. **Step 3**: Add safe mode option
   - Files: `lib/agents.sh`, `bin/doyaken`
   - Add `--interactive` flag that doesn't add bypass flags
   - Useful for untrusted projects

4. **Step 4**: Add first-run warning
   - Files: `lib/core.sh` or `bin/doyaken`
   - Show warning on first use about autonomous mode
   - Require explicit acknowledgment

---

## Security Documentation Outline

```markdown
# Security Model

## Trust Assumptions
- The project manifest is trusted
- Task files are trusted
- MCP server configurations are trusted

## Autonomous Mode
Doyaken runs agents with permission bypass flags to enable fully autonomous operation.
This means agents can:
- Read and write any file in the project
- Execute arbitrary shell commands
- Make network requests
- Access environment variables

## When NOT to Use Doyaken
- On projects you don't fully trust
- With manifests from unknown sources
- On systems with sensitive data outside the project

## Safe Mode
Use `doyaken --interactive` to run without permission bypasses.
```

---

## Work Log

### 2026-02-01 17:00 - Created

- Security audit identified need for better documentation of autonomous mode risks
- Next: Create SECURITY.md and add warnings

---

## Links

- File: `lib/agents.sh:154-187`
- OWASP: Security misconfiguration
