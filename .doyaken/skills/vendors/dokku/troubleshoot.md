---
name: dokku:troubleshoot
description: Diagnose and fix Dokku deployment issues
args:
  - name: app
    description: Dokku app name
    default: ""
  - name: server
    description: Dokku server hostname
    default: ""
---

# Dokku Troubleshooting

You are diagnosing issues with a Dokku deployment.

## Context

Project: {{DOYAKEN_PROJECT}}
App Name: {{ARGS.app}}
Server: {{ARGS.server}}

## Diagnostic Process

### 1. Gather Information

Run diagnostic commands:

```bash
# App status
ssh dokku@{{ARGS.server}} ps:report {{ARGS.app}}

# Recent logs
ssh dokku@{{ARGS.server}} logs {{ARGS.app}} --tail 100

# Container inspect
ssh dokku@{{ARGS.server}} ps:inspect {{ARGS.app}}

# Environment
ssh dokku@{{ARGS.server}} config:show {{ARGS.app}}

# Nginx config
ssh dokku@{{ARGS.server}} nginx:show-config {{ARGS.app}}
```

### 2. Common Issues

**Build Failures**
- Missing dependencies
- Incorrect buildpack
- Memory exceeded during build

```bash
# Check build logs
ssh dokku@{{ARGS.server}} logs {{ARGS.app}} --type=build

# Increase build memory
ssh dokku@{{ARGS.server}} resource:limit {{ARGS.name}} --memory 1024
```

**Container Crashes**
- Application error
- Missing environment variable
- Port binding issue

```bash
# Check if app starts correctly
ssh dokku@{{ARGS.server}} run {{ARGS.app}} <start-command>

# Check port
ssh dokku@{{ARGS.server}} proxy:ports {{ARGS.app}}
```

**Network Issues**
- Domain misconfiguration
- SSL certificate problems
- Proxy timeout

```bash
# Check domains
ssh dokku@{{ARGS.server}} domains:report {{ARGS.app}}

# Check SSL
ssh dokku@{{ARGS.server}} certs:report {{ARGS.app}}

# Regenerate nginx config
ssh dokku@{{ARGS.server}} proxy:build-config {{ARGS.app}}
```

**Resource Issues**
- Memory exhaustion
- CPU throttling
- Disk space

```bash
# Check resource usage
ssh dokku@{{ARGS.server}} ps:report {{ARGS.app}}

# Check disk
ssh dokku@{{ARGS.server}} storage:report {{ARGS.app}}
```

### 3. Recovery Actions

{{include:vendors/dokku/operations.md}}

```bash
# Restart app
ssh dokku@{{ARGS.server}} ps:restart {{ARGS.app}}

# Rebuild
ssh dokku@{{ARGS.server}} ps:rebuild {{ARGS.app}}

# Rollback
ssh dokku@{{ARGS.server}} ps:rollback {{ARGS.app}}
```

## Output

```markdown
## Troubleshooting Report

**App**: {{ARGS.app}}
**Server**: {{ARGS.server}}

### Current Status
- **Running**: Yes/No
- **Containers**: [count]
- **Uptime**: [duration]

### Issue Identified
**Category**: [Build/Runtime/Network/Resource]
**Symptom**: [What's happening]

### Root Cause
[Explanation of the problem]

### Solution
```bash
[Commands to fix]
```

### Verification
- [ ] Run fix commands
- [ ] Check logs for errors
- [ ] Verify app responds
- [ ] Monitor for recurrence

### Prevention
[How to prevent this in the future]
```
