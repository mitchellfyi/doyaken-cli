# Vendor Prompts

Vendor-specific prompt libraries that extend doyaken with specialized knowledge and tooling.

## Structure

```
vendors/
├── figma/               # Design-to-code, design systems, accessibility
├── nextjs/              # App Router, data fetching, performance
├── react/               # Components, hooks, state management
├── rails/               # Patterns, API, performance
├── redis/               # Data structures, caching, patterns
├── vercel/              # Vercel deployment, Next.js optimization
├── github/              # GitHub issues, PRs, code review
├── github-actions/      # CI/CD workflows, optimization
├── dokku/               # PaaS deployment, plugins
├── digitalocean/        # Droplets, App Platform, databases
├── supabase/            # Database, auth, storage, RLS
├── postgres/            # Query optimization, schema design
├── aws/                 # AWS services, Lambda, CDK (future)
├── gcp/                 # Google Cloud Platform (future)
└── ...
```

## Namespacing

Vendor prompts are namespaced to avoid conflicts with core library prompts.

### Include Syntax

```markdown
{{include:vendors/vercel/react-best-practices.md}}
{{include:vendors/aws/lambda-patterns.md}}
```

### Resolution Order

1. Project: `.doyaken/prompts/vendors/vercel/react-best-practices.md`
2. Global: `$DOYAKEN_HOME/prompts/vendors/vercel/react-best-practices.md`

## Creating Vendor Prompts

1. Create directory: `prompts/vendors/<vendor>/`
2. Add README.md documenting the vendor library
3. Create prompt files following library conventions
4. Create corresponding skills in `skills/vendors/<vendor>/`
5. Add MCP config template in `templates/mcp/<vendor>.json`

## Vendor Libraries

| Vendor | Description | MCP Server | Status |
|--------|-------------|------------|--------|
| [figma](figma/) | Design-to-code, design systems | `https://api.figma.com/mcp` | Active |
| [nextjs](nextjs/) | App Router, data fetching | - | Active |
| [react](react/) | Components, hooks, state | - | Active |
| [rails](rails/) | Patterns, API, performance | - | Active |
| [redis](redis/) | Caching, data structures | Local MCP | Active |
| [vercel](vercel/) | Next.js, React, deployment | `https://mcp.vercel.com` | Active |
| [github](github/) | Issues, PRs, code review | `https://api.githubcopilot.com/mcp/` | Active |
| [github-actions](github-actions/) | CI/CD workflows | - | Active |
| [dokku](dokku/) | PaaS deployment | - | Active |
| [digitalocean](digitalocean/) | Cloud infrastructure | `https://*.mcp.digitalocean.com/mcp` | Active |
| [supabase](supabase/) | Database, auth, storage | `https://mcp.supabase.com/mcp` | Active |
| [postgres](postgres/) | Database optimization | - | Active |

## Best Practices

- Vendor prompts should be **self-contained** and copy-pastable
- Include **references** to official documentation
- Provide **activation triggers** so AI knows when to apply them
- Keep content **current** with vendor's latest practices
- Add **MCP integration** when available

## See Also

- [Library prompts](../library/) - Core prompt modules
- [Skills vendors](../../skills/vendors/) - Vendor-specific skills
- [MCP templates](../../templates/mcp/) - MCP server configs
