# Vendor Skills

Vendor-specific skills that provide specialized functionality for specific platforms and services.

## Structure

```
vendors/
├── figma/               # Design-to-code, design tokens
├── nextjs/              # Routes, optimization
├── react/               # Component review, refactoring
├── rails/               # API endpoints, service objects
├── redis/               # Caching, rate limiting
├── vercel/              # Vercel deployment, Next.js, React
├── github/              # GitHub PRs, issues, releases
├── github-actions/      # CI/CD workflow creation and optimization
├── dokku/               # PaaS deployment and management
├── digitalocean/        # Droplets, App Platform, databases
├── supabase/            # Database migrations, auth, types
├── postgres/            # Query optimization, schema review
├── aws/                 # AWS services (future)
├── gcp/                 # Google Cloud (future)
└── ...
```

## Namespacing

Vendor skills use a `vendor:skill` naming convention to avoid conflicts:

```bash
# Core skills (no prefix)
doyaken skill security-audit
doyaken skill code-review

# Vendor skills (vendor: prefix)
doyaken skill vercel:deploy
doyaken skill vercel:react-review
doyaken skill aws:lambda-deploy
```

## Using Vendor Skills

### Running Skills

```bash
# List all skills (includes vendor skills)
doyaken skills

# Run a vendor skill
doyaken skill vercel:deploy --prod=true

# Get skill info
doyaken skill info vercel:react-review
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

### In Custom Skills

```markdown
---
name: my-nextjs-workflow
requires:
  - vercel
---

First, review the React code:
{{include:vendors/vercel/react-best-practices.md}}

Then deploy:
Run the vercel:deploy skill when review passes.
```

## MCP Requirements

Many vendor skills require MCP server integration:

| Vendor | MCP Server | Setup |
|--------|------------|-------|
| Figma | `https://api.figma.com/mcp` | `claude mcp add figma --url https://api.figma.com/mcp` |
| Redis | Local | `claude mcp add redis --command 'npx -y @redis/mcp-redis'` |
| Vercel | `https://mcp.vercel.com` | `claude mcp add vercel https://mcp.vercel.com` |
| GitHub | `https://api.githubcopilot.com/mcp/` | `claude mcp add github https://api.githubcopilot.com/mcp/` |
| DigitalOcean | `https://*.mcp.digitalocean.com/mcp` | See [MCP template](../../templates/mcp/digitalocean.json) |
| Supabase | `https://mcp.supabase.com/mcp` | `claude mcp add supabase https://mcp.supabase.com/mcp` |

Enable in manifest:

```yaml
# .doyaken/manifest.yaml
integrations:
  vercel:
    enabled: true
```

## Available Vendors

| Vendor | Skills | MCP | Status |
|--------|--------|-----|--------|
| [figma](figma/) | design-to-code, extract-tokens, a11y-audit | Yes | Active |
| [nextjs](nextjs/) | create-route, optimize | No | Active |
| [react](react/) | component-review | No | Active |
| [rails](rails/) | api-endpoint, service-object | No | Active |
| [redis](redis/) | cache-setup, rate-limiter | Yes | Active |
| [vercel](vercel/) | deploy, react-review, ui-audit, perf-audit | Yes | Active |
| [github](github/) | pr-review, issue-triage, release | Yes | Active |
| [github-actions](github-actions/) | create-workflow, debug-workflow, optimize | No | Active |
| [dokku](dokku/) | deploy, setup-app, troubleshoot | No | Active |
| [digitalocean](digitalocean/) | deploy-app, manage-droplet, setup-database | Yes | Active |
| [supabase](supabase/) | migrate, setup-auth, generate-types | Yes | Active |
| [postgres](postgres/) | optimize-query, schema-review, health-check | No | Active |

## Creating Vendor Skills

1. Create directory: `skills/vendors/<vendor>/`
2. Add README.md with skill list
3. Create skill files with `vendor:` prefix in name
4. Add MCP config template to `templates/mcp/<vendor>.json`
5. Add corresponding prompts to `prompts/vendors/<vendor>/`

### Skill Template

```markdown
---
name: vendor:skill-name
description: What this skill does
requires:
  - vendor-mcp-server
args:
  - name: arg1
    description: Argument description
    default: "default-value"
---

# Skill Title

You are performing [task] using [vendor] tools.

## Context

Project: {{DOYAKEN_PROJECT}}
Argument: {{ARGS.arg1}}

## Instructions

{{include:vendors/vendor/relevant-prompt.md}}

[Skill-specific instructions]

## Output

[Expected output format]
```

## See Also

- [Vendor Prompts](../../prompts/vendors/)
- [MCP Templates](../../templates/mcp/)
- [Core Skills](../)
