# Vercel Prompts

Specialized prompts for Vercel platform, Next.js applications, and React performance optimization.

Based on [Vercel Agent Skills](https://github.com/vercel-labs/agent-skills) - official best practices from Vercel.

## Prompt Library

| File | Description | Use When |
|------|-------------|----------|
| [react-best-practices.md](react-best-practices.md) | 40+ React/Next.js performance rules | Code reviews, component writing, performance optimization |
| [web-design-guidelines.md](web-design-guidelines.md) | 100+ accessibility and UX rules | UI audits, design reviews, accessibility checks |
| [deployment.md](deployment.md) | Vercel deployment patterns | Deploying apps, CI/CD setup, preview deployments |

## Usage

### In Skills

```markdown
---
name: my-nextjs-skill
requires:
  - vercel
---

{{include:vendors/vercel/react-best-practices.md}}

Now review this Next.js component...
```

### In Phases

```markdown
# Phase 6: REVIEW

{{include:library/code-review.md}}
{{include:vendors/vercel/react-best-practices.md}}
```

### Standalone

Copy the prompt content directly into any AI assistant.

## MCP Integration

Enable Vercel MCP for deployment and docs access:

```yaml
# .doyaken/manifest.yaml
integrations:
  vercel:
    enabled: true
    team: "your-team"       # Optional: team slug
    project: "your-project" # Optional: project slug
```

Then run:
```bash
doyaken mcp configure
```

## Skills

See [skills/vendors/vercel/](../../../skills/vendors/vercel/) for executable skills:

- `vercel:deploy` - Deploy to Vercel
- `vercel:react-review` - React code review with Vercel best practices
- `vercel:ui-audit` - Accessibility and UX audit
- `vercel:perf-audit` - Performance optimization audit

## References

- [Vercel Documentation](https://vercel.com/docs)
- [Next.js Documentation](https://nextjs.org/docs)
- [Vercel MCP](https://vercel.com/docs/mcp/vercel-mcp)
- [Vercel Agent Skills](https://github.com/vercel-labs/agent-skills)
