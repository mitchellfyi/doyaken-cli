# Vercel Skills

Executable skills for Vercel platform, Next.js, and React development.

## Available Skills

| Skill | Description | MCP Required |
|-------|-------------|--------------|
| `vercel:deploy` | Deploy to Vercel | Yes |
| `vercel:react-review` | Review React/Next.js code | No |
| `vercel:ui-audit` | Accessibility and UX audit | No |
| `vercel:perf-audit` | Next.js performance audit | No |

## Usage

### Running Skills

```bash
# Deploy to Vercel
doyaken skill vercel:deploy

# Review React code
doyaken skill vercel:react-review --path=src/components

# Audit UI accessibility
doyaken skill vercel:ui-audit --path=src/pages

# Performance audit
doyaken skill vercel:perf-audit
```

### In Workflows

```yaml
# .doyaken/manifest.yaml
skills:
  hooks:
    after-review:
      - vercel:react-review
    after-verify:
      - vercel:deploy
```

## MCP Integration

Enable Vercel MCP for deployment skills:

```yaml
# .doyaken/manifest.yaml
integrations:
  vercel:
    enabled: true
    team: "your-team"       # Optional
    project: "your-project" # Optional
```

Configure with:
```bash
doyaken mcp configure
```

This adds Vercel MCP to your Claude Code configuration:
```bash
claude mcp add --transport http vercel https://mcp.vercel.com
# Or project-specific:
claude mcp add --transport http vercel https://mcp.vercel.com/your-team/your-project
```

## Skill Details

### vercel:deploy

Deploys the current project to Vercel.

**Prerequisites:**
- Vercel MCP enabled and authenticated
- Project linked to Vercel (`vercel link`)

**Arguments:**
- `--prod`: Deploy to production (default: preview)
- `--message`: Deployment message

### vercel:react-review

Reviews React/Next.js code using Vercel's best practices.

**Checks:**
- Data fetching patterns (waterfalls, Server Components)
- Bundle size optimization (dynamic imports, tree-shaking)
- Rendering performance (memo, callbacks, keys)
- Server-side patterns (Server Actions, Edge Runtime)

### vercel:ui-audit

Comprehensive accessibility and UX audit.

**Checks:**
- Semantic HTML
- ARIA attributes
- Keyboard navigation
- Color contrast
- Form accessibility
- Animation safety

### vercel:perf-audit

Performance audit for Next.js applications.

**Checks:**
- Core Web Vitals optimization
- Image optimization
- Bundle analysis
- Caching strategies
- ISR/SSG usage

## See Also

- [Vercel Prompts](../../../prompts/vendors/vercel/)
- [MCP Configuration](../../../templates/mcp/vercel.json)
