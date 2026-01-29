---
name: dokku:deploy
description: Deploy application to Dokku
args:
  - name: app
    description: Dokku app name
    default: ""
  - name: server
    description: Dokku server hostname
    default: ""
  - name: branch
    description: Branch to deploy
    default: "main"
---

# Dokku Deployment

You are deploying an application to Dokku.

## Context

Project: {{DOYAKEN_PROJECT}}
App Name: {{ARGS.app}}
Server: {{ARGS.server}}
Branch: {{ARGS.branch}}

## Deployment Process

### 1. Pre-Deployment Checks

Verify deployment requirements:

1. **Git remote configured**
   ```bash
   git remote -v | grep dokku
   ```
   If not configured:
   ```bash
   git remote add dokku dokku@{{ARGS.server}}:{{ARGS.app}}
   ```

2. **Build files present**
   - `Dockerfile` (preferred) or
   - `Procfile` + buildpack detection files

3. **Environment variables set**
   - Check required vars are configured on Dokku

### 2. Deploy

{{include:vendors/dokku/deployment.md}}

**Push to deploy:**
```bash
git push dokku {{ARGS.branch}}:main
```

### 3. Post-Deployment

After successful deployment:

1. **Verify deployment**
   ```bash
   ssh dokku@{{ARGS.server}} ps:report {{ARGS.app}}
   ```

2. **Check logs**
   ```bash
   ssh dokku@{{ARGS.server}} logs {{ARGS.app}} --tail
   ```

3. **Verify health**
   - Check application URL
   - Verify all endpoints respond

### 4. Rollback (if needed)

If deployment fails:
```bash
ssh dokku@{{ARGS.server}} ps:rollback {{ARGS.app}}
```

## Output

```markdown
## Deployment Summary

**App**: {{ARGS.app}}
**Server**: {{ARGS.server}}
**Status**: Success / Failed

### Deployment Info
- **Commit**: [git SHA]
- **Build Type**: Docker / Buildpack
- **Container**: [container ID]

### URLs
- **Production**: https://{{ARGS.app}}.{{ARGS.server}}
- **Health Check**: [status]

### Logs (last 10 lines)
```
[deployment logs]
```

### Next Steps
- [ ] Verify application is working
- [ ] Check error logs if issues
- [ ] Monitor resource usage
```
