---
name: digitalocean:deploy-app
description: Deploy application to DigitalOcean App Platform
requires:
  - digitalocean-apps
args:
  - name: name
    description: App name
    default: ""
  - name: repo
    description: GitHub repository (owner/repo)
    default: ""
  - name: branch
    description: Branch to deploy
    default: "main"
---

# DigitalOcean App Platform Deployment

You are deploying to DigitalOcean App Platform using MCP tools.

## Context

Project: {{DOYAKEN_PROJECT}}
App Name: {{ARGS.name}}
Repository: {{ARGS.repo}}
Branch: {{ARGS.branch}}

## Deployment Process

### 1. Check Existing Apps

Use DigitalOcean MCP to list existing apps:
- Check if app already exists
- Note current configuration if updating

### 2. Prepare App Spec

{{include:vendors/digitalocean/app-platform.md}}

Create or update app specification:

```yaml
name: {{ARGS.name}}
region: nyc
services:
  - name: web
    github:
      repo: {{ARGS.repo}}
      branch: {{ARGS.branch}}
      deploy_on_push: true
    build_command: npm run build
    run_command: npm start
    http_port: 3000
    instance_size_slug: basic-xxs
    instance_count: 1
    envs:
      - key: NODE_ENV
        value: production
```

### 3. Deploy

Use DigitalOcean MCP to:

**New App**: Create app with spec
**Existing App**: Update app configuration

### 4. Monitor Deployment

Watch deployment progress:
- Build phase
- Deploy phase
- Health checks

### 5. Verify

After deployment:
- Check app URL responds
- Verify logs for errors
- Test functionality

## Output

```markdown
## App Platform Deployment

**App**: {{ARGS.name}}
**Status**: Deploying / Active / Failed

### Deployment Info
- **Repository**: {{ARGS.repo}}
- **Branch**: {{ARGS.branch}}
- **Region**: [region]
- **Instance**: [size]

### URLs
- **App URL**: https://{{ARGS.name}}-xxxxx.ondigitalocean.app
- **Console**: https://cloud.digitalocean.com/apps/[id]

### Build Log
```
[last build output]
```

### Next Steps
- [ ] Verify app is accessible
- [ ] Configure custom domain (optional)
- [ ] Set up alerts
- [ ] Configure auto-scaling (optional)
```
