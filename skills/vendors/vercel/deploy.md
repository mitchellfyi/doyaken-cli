---
name: vercel:deploy
description: Deploy application to Vercel
requires:
  - vercel
args:
  - name: prod
    description: Deploy to production (default is preview)
    default: "false"
  - name: message
    description: Deployment message
    default: ""
---

# Vercel Deployment

You are deploying the current project to Vercel using the Vercel MCP tools.

## Context

Project: {{DOYAKEN_PROJECT}}
Deploy to production: {{ARGS.prod}}
Message: {{ARGS.message}}

## Deployment Process

### 1. Pre-Deployment Checks

Before deploying, verify:

1. **Build passes locally**
   ```bash
   npm run build
   # or
   vercel build
   ```

2. **Environment variables are set**
   - Check that all required env vars are configured in Vercel
   - Use `vercel env ls` to verify

3. **No uncommitted changes** (for production)
   ```bash
   git status
   ```

### 2. Deploy Using MCP

Use the Vercel MCP tools to deploy:

{{#if prod == "true"}}
**Production Deployment**

Use the MCP `deploy` tool with production flag:
- This deploys to the production URL
- Requires the project to be linked (`vercel link`)
- Creates a deployment that serves on custom domains
{{else}}
**Preview Deployment**

Use the MCP `deploy` tool:
- Creates a unique preview URL
- Good for testing and review
- Shareable with team members
{{/if}}

### 3. Post-Deployment Verification

After deployment:

1. **Check deployment status**
   - Use MCP tools to get deployment status
   - Verify the deployment completed successfully

2. **Test the deployment**
   - Visit the deployment URL
   - Verify core functionality works
   - Check for console errors

3. **Monitor logs**
   - Check function logs for errors
   - Monitor performance metrics

## Deployment Best Practices

{{include:vendors/vercel/deployment.md}}

## Output

Report the deployment result:

```
## Deployment Summary

**Status**: Success / Failed
**Type**: {{#if prod == "true"}}Production{{else}}Preview{{/if}}
**URL**: [deployment URL]
{{#if message}}**Message**: {{ARGS.message}}{{/if}}

### Build Info
- Framework detected: [framework]
- Build time: [duration]
- Functions deployed: [count]

### Next Steps
- [ ] Verify deployment at [URL]
- [ ] Check function logs
- [ ] Monitor analytics
{{#if prod != "true"}}
- [ ] When ready, promote to production
{{/if}}
```
