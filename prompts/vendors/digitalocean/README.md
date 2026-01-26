# DigitalOcean Prompts

Cloud infrastructure with DigitalOcean - Droplets, App Platform, and managed services.

## Prompt Library

| File | Description | Use When |
|------|-------------|----------|
| [droplets.md](droplets.md) | Droplet management and configuration | Server setup, scaling |
| [app-platform.md](app-platform.md) | App Platform deployment | PaaS deployments |
| [security.md](security.md) | Security best practices | Hardening infrastructure |

## Usage

```markdown
{{include:vendors/digitalocean/droplets.md}}
```

## MCP Integration

Enable DigitalOcean MCP:

```yaml
# .doyaken/manifest.yaml
integrations:
  digitalocean:
    enabled: true
```

Remote MCP endpoints:
- Apps: `https://apps.mcp.digitalocean.com/mcp`
- Droplets: `https://droplets.mcp.digitalocean.com/mcp`
- Databases: `https://databases.mcp.digitalocean.com/mcp`

## Skills

- `digitalocean:create-droplet` - Create new Droplet
- `digitalocean:deploy-app` - Deploy to App Platform
- `digitalocean:setup-firewall` - Configure Cloud Firewall

## References

- [DigitalOcean Documentation](https://docs.digitalocean.com/)
- [DigitalOcean MCP](https://docs.digitalocean.com/reference/mcp/)
