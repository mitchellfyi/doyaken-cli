---
name: dokku:setup-app
description: Create and configure a new Dokku app
args:
  - name: name
    description: Application name
    default: ""
  - name: domain
    description: Custom domain
    default: ""
  - name: server
    description: Dokku server hostname
    default: ""
---

# Dokku App Setup

You are setting up a new application on Dokku.

## Context

Project: {{DOYAKEN_PROJECT}}
App Name: {{ARGS.name}}
Domain: {{ARGS.domain}}
Server: {{ARGS.server}}

## Setup Process

### 1. Create Application

```bash
ssh dokku@{{ARGS.server}} apps:create {{ARGS.name}}
```

### 2. Configure Domain

{{#if domain}}
```bash
# Set custom domain
ssh dokku@{{ARGS.server}} domains:set {{ARGS.name}} {{ARGS.domain}}

# Enable SSL with Let's Encrypt
ssh dokku@{{ARGS.server}} letsencrypt:enable {{ARGS.name}}
```
{{else}}
Default domain: `{{ARGS.name}}.{{ARGS.server}}`
{{/if}}

### 3. Set Environment Variables

Identify required environment variables from the project:

```bash
# Set each variable
ssh dokku@{{ARGS.server}} config:set {{ARGS.name}} KEY=value

# Or set multiple at once
ssh dokku@{{ARGS.server}} config:set {{ARGS.name}} \
  NODE_ENV=production \
  DATABASE_URL=postgres://... \
  SECRET_KEY=...
```

### 4. Configure Resources

{{include:vendors/dokku/operations.md}}

```bash
# Set resource limits (optional)
ssh dokku@{{ARGS.server}} resource:limit {{ARGS.name}} --memory 512
ssh dokku@{{ARGS.server}} ps:scale {{ARGS.name}} web=1
```

### 5. Database Setup (if needed)

```bash
# PostgreSQL
ssh dokku@{{ARGS.server}} postgres:create {{ARGS.name}}-db
ssh dokku@{{ARGS.server}} postgres:link {{ARGS.name}}-db {{ARGS.name}}

# Redis
ssh dokku@{{ARGS.server}} redis:create {{ARGS.name}}-redis
ssh dokku@{{ARGS.server}} redis:link {{ARGS.name}}-redis {{ARGS.name}}
```

### 6. Git Remote

Configure local git to deploy:

```bash
git remote add dokku dokku@{{ARGS.server}}:{{ARGS.name}}
```

## Output

```markdown
## Dokku App Created

**App**: {{ARGS.name}}
**Server**: {{ARGS.server}}

### Configuration
| Setting | Value |
|---------|-------|
| Domain | {{#if domain}}{{ARGS.domain}}{{else}}{{ARGS.name}}.{{ARGS.server}}{{/if}} |
| SSL | {{#if domain}}Let's Encrypt{{else}}Default{{/if}} |

### Environment Variables Set
- [List of vars without values]

### Services Linked
- [Database, Redis, etc. if applicable]

### Deploy Command
```bash
git push dokku main
```

### Next Steps
- [ ] Review environment variables
- [ ] Push first deployment
- [ ] Verify DNS (if custom domain)
- [ ] Test application
```
