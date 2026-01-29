# Dokku Prompts

Self-hosted PaaS deployment with Dokku - the smallest PaaS implementation.

## Prompt Library

| File | Description | Use When |
|------|-------------|----------|
| [deployment.md](deployment.md) | Deployment workflows and configuration | Deploying applications |
| [plugins.md](plugins.md) | Database and service plugins | Setting up databases, Redis, etc. |
| [operations.md](operations.md) | Operations, SSL, domains, scaling | Managing production apps |

## Usage

```markdown
{{include:vendors/dokku/deployment.md}}
```

## Skills

- `dokku:deploy` - Deploy application to Dokku
- `dokku:setup-db` - Configure database plugin
- `dokku:ssl` - Setup Let's Encrypt SSL

## References

- [Dokku Documentation](https://dokku.com/docs/)
- [Dokku Plugins](https://dokku.com/docs/community/plugins/)
