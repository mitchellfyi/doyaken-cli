# Dokku Skills

Skills for deploying and managing applications on Dokku.

## Available Skills

| Skill | Description |
|-------|-------------|
| `dokku:deploy` | Deploy application to Dokku |
| `dokku:setup-app` | Create and configure a new Dokku app |
| `dokku:troubleshoot` | Diagnose and fix Dokku deployment issues |

## Usage

```bash
# Deploy to Dokku
doyaken skill dokku:deploy --app=myapp

# Setup new app
doyaken skill dokku:setup-app --name=myapp --domain=app.example.com

# Troubleshoot issues
doyaken skill dokku:troubleshoot --app=myapp
```

## Prerequisites

- SSH access to Dokku server
- Git remote configured: `git remote add dokku dokku@server:app`

## See Also

- [Dokku Prompts](../../../prompts/vendors/dokku/)
