# MCP Security Model

This document describes the security model for MCP (Model Context Protocol) server configuration in doyaken.

## Overview

MCP servers extend AI agent capabilities by providing tools for interacting with external services (GitHub, Slack, etc.). Since these servers execute code via `npx`, doyaken implements security validation to protect against:

1. **Unofficial packages** - Non-vetted npm packages that could contain malicious code
2. **Missing credentials** - Configurations with unset environment variables
3. **Token exposure** - Sensitive tokens appearing in logs

## Package Allowlist

### Location

```
config/mcp/allowed-packages.yaml
```

### Structure

```yaml
# Official package patterns (glob matching)
patterns:
  - "@modelcontextprotocol/*"
  - "@anthropic/mcp-server-*"

# Explicitly trusted community packages
trusted:
  - "some-reviewed-package"
```

### How Matching Works

1. **Pattern matching**: Scoped packages are matched using prefix patterns
   - `@modelcontextprotocol/*` matches `@modelcontextprotocol/server-github`
   - Pattern must match from the start (no partial matches)

2. **Exact matching**: Trusted packages require exact string match
   - `slack-mcp-server` only matches `slack-mcp-server`, not `my-slack-mcp-server`

3. **Unofficial packages**: Packages not in allowlist trigger warnings (or blocks in strict mode)

## Strict Mode

Enable strict mode to block unofficial packages and missing environment variables:

```bash
# Via environment variable
export DOYAKEN_MCP_STRICT=1
doyaken mcp configure

# Or check with mcp doctor
DOYAKEN_MCP_STRICT=1 doyaken mcp doctor
```

### Behavior Comparison

| Condition | Normal Mode | Strict Mode |
|-----------|-------------|-------------|
| Unofficial package | Warning | **Blocked** |
| Missing env var | Warning | **Blocked** |
| Official + all vars set | Included | Included |

## Environment Variable Validation

### Required Variables

Variables defined without defaults are considered required:

```yaml
env:
  GITHUB_TOKEN: "${GITHUB_TOKEN}"  # Required - no default
```

### Optional Variables

Variables with defaults are optional:

```yaml
env:
  LOG_LEVEL: "${LOG_LEVEL:-info}"  # Optional - has default
```

### Validation

`doyaken mcp doctor` checks that all required environment variables are set before configuration generation.

## Token Masking

Sensitive tokens in log output are automatically masked:

- First 4 characters visible for identification
- Remainder replaced with `***`

Example: `ghp_abc123xyz789` appears as `ghp_***`

## Adding Trusted Packages

To trust a community package after security review:

1. Review the package source code and npm audit
2. Add to `config/mcp/allowed-packages.yaml`:

```yaml
trusted:
  - "reviewed-package-name"
```

3. Commit the change with justification in the message

## Security Checklist

Before enabling an MCP integration:

- [ ] Package is in allowlist (official) or has been security reviewed
- [ ] Required environment variables are documented
- [ ] Tokens are stored securely (not in version control)
- [ ] Minimal permissions granted to tokens

## Related Commands

```bash
# Check integration health
doyaken mcp doctor

# Generate config with validation
doyaken mcp configure

# Generate with strict validation
DOYAKEN_MCP_STRICT=1 doyaken mcp configure
```

## References

- [OWASP A08:2021 - Software and Data Integrity Failures](https://owasp.org/Top10/A08_2021-Software_and_Data_Integrity_Failures/)
- [CWE-829: Inclusion of Functionality from Untrusted Control Sphere](https://cwe.mitre.org/data/definitions/829.html)
