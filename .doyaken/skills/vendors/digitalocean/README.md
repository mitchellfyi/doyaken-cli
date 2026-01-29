# DigitalOcean Skills

Skills for managing DigitalOcean infrastructure using MCP.

## Available Skills

| Skill | Description |
|-------|-------------|
| `digitalocean:deploy-app` | Deploy to App Platform |
| `digitalocean:manage-droplet` | Create and manage Droplets |
| `digitalocean:setup-database` | Setup managed database |

## MCP Setup

```bash
# Apps
claude mcp add --transport http digitalocean-apps https://apps.mcp.digitalocean.com/mcp

# Droplets
claude mcp add --transport http digitalocean-droplets https://droplets.mcp.digitalocean.com/mcp

# Databases
claude mcp add --transport http digitalocean-databases https://databases.mcp.digitalocean.com/mcp
```

## Usage

```bash
# Deploy to App Platform
doyaken skill digitalocean:deploy-app --name=myapp

# Create a Droplet
doyaken skill digitalocean:manage-droplet --action=create

# Setup database
doyaken skill digitalocean:setup-database --engine=postgres
```

## See Also

- [DigitalOcean Prompts](../../../prompts/vendors/digitalocean/)
- [DigitalOcean MCP Config](../../../templates/mcp/digitalocean.json)
