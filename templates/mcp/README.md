# MCP Configuration Templates

Model Context Protocol (MCP) server configuration templates for various vendors.

## Available Templates

| Vendor | File | MCP Server | Description |
|--------|------|------------|-------------|
| Figma | [figma.json](figma.json) | Remote | Design-to-code, design context |
| Redis | [redis.json](redis.json) | Local | Data management, caching, queues |
| GitHub | [github.json](github.json) | Remote + Local | Issues, PRs, repositories, code |
| Vercel | [vercel.json](vercel.json) | Remote | Deployments, docs, projects |
| DigitalOcean | [digitalocean.json](digitalocean.json) | Remote + Local | Droplets, Apps, databases |
| Supabase | [supabase.json](supabase.json) | Remote | Database, auth, storage, functions |

## Usage

### Claude Code Setup

```bash
# Figma (OAuth)
claude mcp add figma --url https://api.figma.com/mcp

# Redis (Local)
claude mcp add redis --command 'npx -y @redis/mcp-redis'

# GitHub (OAuth)
claude mcp add github https://api.githubcopilot.com/mcp/

# Vercel
claude mcp add vercel https://mcp.vercel.com

# DigitalOcean
claude mcp add --transport http digitalocean-apps https://apps.mcp.digitalocean.com/mcp

# Supabase
claude mcp add supabase https://mcp.supabase.com/mcp

# Authenticate
/mcp
```

### Cursor/VS Code Setup

Add to `.cursor/mcp.json` or VS Code MCP settings:

```json
{
  "mcpServers": {
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "your-token"
      }
    },
    "vercel": {
      "url": "https://mcp.vercel.com"
    },
    "supabase": {
      "url": "https://mcp.supabase.com/mcp"
    }
  }
}
```

### doyaken Integration

Enable in `.doyaken/manifest.yaml`:

```yaml
integrations:
  github:
    enabled: true
    repo: "owner/repo"

  vercel:
    enabled: true
    team: "your-team"
    project: "your-project"

  digitalocean:
    enabled: true

  supabase:
    enabled: true
    project_ref: "your-project-ref"
```

Then run:
```bash
doyaken mcp configure
```

## Template Structure

Each template includes:

- **server**: Connection details (remote URL or local command)
- **tools**: Available MCP tools by category
- **setup**: Configuration examples for different clients
- **manifest**: doyaken integration settings

## Security Best Practices

1. **Never commit tokens** - Use environment variables
2. **Use scoped tokens** - Minimum required permissions
3. **Prefer OAuth** - When available (GitHub, Supabase)
4. **Project-specific access** - Scope to specific projects when possible
5. **Read-only mode** - Enable for production data (Supabase)

## Creating New Templates

```json
{
  "$schema": "...",
  "_comment": "Description",
  "_docs": "Documentation URL",

  "name": "vendor-name",
  "description": "What this MCP provides",

  "server": {
    "remote": {
      "url": "https://...",
      "transport": "http",
      "auth": "oauth|bearer|none"
    },
    "local": {
      "command": "npx",
      "args": ["@vendor/mcp"],
      "env": {}
    }
  },

  "tools": {
    "category": ["tool1", "tool2"]
  },

  "setup": {
    "claudeCode": { "command": "..." },
    "cursor": { "config": {} }
  },

  "manifest": {
    "integrations": {
      "vendor": {
        "enabled": true
      }
    }
  }
}
```

## References

- [Model Context Protocol](https://modelcontextprotocol.io/)
- [MCP Specification](https://spec.modelcontextprotocol.io/)
- [Official MCP Servers](https://github.com/modelcontextprotocol/servers)
