# Task: Add MCP Server Validation and Security Checks

## Metadata

| Field       | Value                                                  |
| ----------- | ------------------------------------------------------ |
| ID          | `003-002-security-mcp-server-validation`               |
| Status      | `todo`                                                 |
| Priority    | `003` Medium                                           |
| Created     | `2026-02-01 17:00`                                     |
| Started     |                                                        |
| Completed   |                                                        |
| Blocked By  |                                                        |
| Blocks      |                                                        |
| Assigned To | `worker-1` |
| Assigned At | `2026-02-01 21:51` |

---

## Context

MCP servers are configured via YAML files and executed with `npx`. There are several security concerns:

1. **No validation that required tokens exist** before running servers
2. **npx can execute arbitrary packages** from npm registry
3. **Tokens passed via environment variables** are visible in process listings
4. **YAML parsing** could be vulnerable to injection

**From `lib/mcp.sh`**:
```bash
command=$(yq -r '.command // ""' "$server_file")
# Command like "npx -y @modelcontextprotocol/server-github" executed directly
```

**Impact**: Compromised MCP config could execute malicious npm packages.

**OWASP Category**: A08:2021 - Software and Data Integrity Failures

---

## Acceptance Criteria

All must be checked before moving to done:

- [ ] Validate required environment variables exist before running MCP servers
- [ ] Allowlist approved MCP server packages (official @modelcontextprotocol/* packages)
- [ ] Warn when using unofficial MCP packages
- [ ] Add `--mcp-strict` mode that only allows allowlisted servers
- [ ] Mask sensitive tokens in logs
- [ ] Document MCP security model
- [ ] Tests written and passing
- [ ] Quality gates pass
- [ ] Changes committed with task reference

---

## Plan

1. **Step 1**: Add env var validation
   - Files: `lib/mcp.sh`
   - Check required tokens exist before generating config
   - Warn if missing

2. **Step 2**: Implement package allowlist
   - Files: `lib/mcp.sh` or `config/mcp/allowed-servers.yaml`
   - List official MCP packages
   - Warn for unofficial packages

3. **Step 3**: Add strict mode
   - Files: `bin/doyaken`, `lib/mcp.sh`
   - `--mcp-strict` flag to only allow allowlisted packages

4. **Step 4**: Token masking
   - Files: `lib/core.sh`
   - Mask tokens in log output

---

## Approved MCP Servers

```yaml
# config/mcp/allowed-servers.yaml
allowed_packages:
  - "@modelcontextprotocol/server-github"
  - "@modelcontextprotocol/server-slack"
  - "@modelcontextprotocol/server-linear"
  - "@modelcontextprotocol/server-jira"
  - "@modelcontextprotocol/server-figma"
  - "@anthropic/mcp-server-*"
```

---

## Work Log

### 2026-02-01 17:00 - Created

- Security audit identified MCP server validation gaps
- Next: Implement validation and allowlist

---

## Links

- File: `lib/mcp.sh`
- File: `config/mcp/servers/*.yaml`
- CWE-829: Inclusion of Functionality from Untrusted Control Sphere
