# Supabase Prompts

Backend-as-a-Service with Supabase - Database, Auth, Storage, and Edge Functions.

## Prompt Library

| File | Description | Use When |
|------|-------------|----------|
| [database.md](database.md) | Database design and RLS | Schema design, security policies |
| [auth.md](auth.md) | Authentication patterns | User auth, OAuth, session management |
| [api.md](api.md) | API and Edge Functions | REST/GraphQL APIs, serverless functions |

## Usage

```markdown
{{include:vendors/supabase/database.md}}
```

## MCP Integration

Enable Supabase MCP:

```yaml
# .doyaken/manifest.yaml
integrations:
  supabase:
    enabled: true
    project_ref: "your-project-ref"  # Optional
```

MCP Server: `https://mcp.supabase.com/mcp`

```bash
# Claude Code setup
claude mcp add supabase https://mcp.supabase.com/mcp
```

## Skills

- `supabase:create-table` - Create database table with RLS
- `supabase:setup-auth` - Configure authentication
- `supabase:deploy-function` - Deploy Edge Function

## References

- [Supabase Documentation](https://supabase.com/docs)
- [Supabase MCP](https://supabase.com/docs/guides/getting-started/mcp)
