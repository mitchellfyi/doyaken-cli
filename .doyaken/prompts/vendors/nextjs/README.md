# Next.js Prompts

Next.js 15+ patterns, App Router best practices, and server-first architecture.

## Prompts

| Prompt | Description |
|--------|-------------|
| [app-router.md](app-router.md) | App Router patterns and conventions |
| [data-fetching.md](data-fetching.md) | Server-side data fetching patterns |
| [performance.md](performance.md) | Performance optimization techniques |

## When to Apply

Use these prompts when:
- Building Next.js applications (13+, App Router)
- Migrating from Pages Router to App Router
- Optimizing Next.js performance
- Implementing server-first patterns

## Key Concepts

### Server Components (Default)
Components render on the server by default - no client JavaScript shipped unless needed.

### Client Components
Add `"use client"` directive only when you need:
- Event handlers (onClick, onChange)
- Browser APIs (localStorage, window)
- Hooks (useState, useEffect, custom hooks)

### Rendering Strategies
- **Static**: Generated at build time
- **Dynamic**: Generated per request
- **Streaming**: Progressive rendering with Suspense

## References

- [Next.js Documentation](https://nextjs.org/docs)
- [App Router](https://nextjs.org/docs/app)
- [Production Checklist](https://nextjs.org/docs/app/guides/production-checklist)
