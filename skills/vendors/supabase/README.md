# Supabase Skills

Skills for managing Supabase projects using MCP.

## Available Skills

| Skill | Description |
|-------|-------------|
| `supabase:migrate` | Create and apply database migrations |
| `supabase:setup-auth` | Configure authentication |
| `supabase:generate-types` | Generate TypeScript types from schema |

## MCP Setup

```bash
# Add Supabase MCP
claude mcp add supabase https://mcp.supabase.com/mcp

# Project-scoped (recommended)
claude mcp add supabase 'https://mcp.supabase.com/mcp?project_ref=YOUR_PROJECT_REF'

# Read-only mode (for production)
claude mcp add supabase 'https://mcp.supabase.com/mcp?read_only=true'
```

## Usage

```bash
# Create migration
doyaken skill supabase:migrate --name=add_users_table

# Setup auth
doyaken skill supabase:setup-auth --provider=google

# Generate types
doyaken skill supabase:generate-types
```

## See Also

- [Supabase Prompts](../../../prompts/vendors/supabase/)
- [Supabase MCP Config](../../../templates/mcp/supabase.json)
