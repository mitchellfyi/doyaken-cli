# Vercel Deployment

Patterns and best practices for deploying applications to Vercel.

Based on [Vercel Documentation](https://vercel.com/docs) and [Vercel Agent Skills](https://github.com/vercel-labs/agent-skills).

## When to Apply

Activate this guide when:
- "Deploy my app"
- "Push this live"
- "Set up CI/CD"
- "Configure preview deployments"
- Setting up a new Vercel project
- Troubleshooting deployments

---

## 1. Framework Detection

Vercel auto-detects 40+ frameworks from package.json:

| Framework | Detection | Build Command | Output |
|-----------|-----------|---------------|--------|
| Next.js | `next` in deps | `next build` | `.next` |
| Vite | `vite` in deps | `vite build` | `dist` |
| Remix | `@remix-run/*` | `remix build` | `build` |
| Astro | `astro` in deps | `astro build` | `dist` |
| SvelteKit | `@sveltejs/kit` | `vite build` | `.svelte-kit` |
| Nuxt | `nuxt` in deps | `nuxt build` | `.output` |
| Gatsby | `gatsby` in deps | `gatsby build` | `public` |
| Create React App | `react-scripts` | `react-scripts build` | `build` |

### Override Detection

```json
// vercel.json
{
  "framework": "nextjs",
  "buildCommand": "npm run custom-build",
  "outputDirectory": "custom-output"
}
```

---

## 2. Environment Variables

### Setting Variables

```bash
# Via CLI
vercel env add STRIPE_KEY production
vercel env add DATABASE_URL preview development

# Via Dashboard
# Project Settings > Environment Variables
```

### Environment Scopes

| Scope | When Used | Example |
|-------|-----------|---------|
| Production | Production deployments | `main` branch |
| Preview | Preview deployments | Feature branches |
| Development | Local `vercel dev` | Local development |

### Best Practices

```bash
# Production secrets
STRIPE_SECRET_KEY=sk_live_xxx     # Production only
DATABASE_URL=postgres://prod/db    # Production only

# Preview/Development
STRIPE_SECRET_KEY=sk_test_xxx     # Preview + Development
DATABASE_URL=postgres://staging/db # Preview + Development

# All environments
NEXT_PUBLIC_SITE_URL=https://example.com
```

### Accessing in Code

```typescript
// Server-side (secret)
const stripeKey = process.env.STRIPE_SECRET_KEY;

// Client-side (must be prefixed)
const siteUrl = process.env.NEXT_PUBLIC_SITE_URL;
```

---

## 3. Preview Deployments

Every push creates a unique preview URL:

```
https://project-git-feature-branch-team.vercel.app
```

### Preview URLs

| URL Pattern | Description |
|-------------|-------------|
| `project-git-branch-team.vercel.app` | Branch-based |
| `project-abc123-team.vercel.app` | Commit-based |
| `project.vercel.app` | Production |
| `custom-domain.com` | Custom domain |

### Branch Deployments

```json
// vercel.json
{
  "git": {
    "deploymentEnabled": {
      "main": true,
      "staging": true,
      "feature/*": true
    }
  }
}
```

### Protected Deployments

```json
// vercel.json
{
  "protection": {
    "enabled": true,
    "password": true
  }
}
```

---

## 4. Build Configuration

### vercel.json

```json
{
  "buildCommand": "npm run build",
  "outputDirectory": "dist",
  "installCommand": "npm ci",
  "framework": "nextjs",
  "regions": ["iad1", "sfo1"],
  "functions": {
    "api/**/*.ts": {
      "memory": 1024,
      "maxDuration": 10
    }
  },
  "rewrites": [
    { "source": "/api/:path*", "destination": "/api/:path*" }
  ],
  "redirects": [
    { "source": "/old-page", "destination": "/new-page", "permanent": true }
  ],
  "headers": [
    {
      "source": "/(.*)",
      "headers": [
        { "key": "X-Frame-Options", "value": "DENY" }
      ]
    }
  ]
}
```

### Ignoring Files

```
# .vercelignore
node_modules/
.git/
*.md
!README.md
tests/
coverage/
```

---

## 5. Serverless Functions

### API Routes (Next.js)

```typescript
// app/api/users/route.ts
export async function GET(request: Request) {
  const users = await db.users.findMany();
  return Response.json(users);
}

export async function POST(request: Request) {
  const body = await request.json();
  const user = await db.users.create({ data: body });
  return Response.json(user, { status: 201 });
}
```

### Standalone Functions

```typescript
// api/hello.ts (root api/ directory)
import type { VercelRequest, VercelResponse } from '@vercel/node';

export default function handler(req: VercelRequest, res: VercelResponse) {
  return res.json({ message: 'Hello!' });
}
```

### Function Configuration

```typescript
// app/api/slow/route.ts
export const maxDuration = 60; // 60 seconds
export const dynamic = 'force-dynamic';

export async function GET() {
  // Long-running operation
}
```

---

## 6. Edge Functions

### Edge Runtime

```typescript
// app/api/geo/route.ts
export const runtime = 'edge';

export async function GET(request: Request) {
  const country = request.headers.get('x-vercel-ip-country') || 'US';
  const city = request.headers.get('x-vercel-ip-city') || 'Unknown';

  return Response.json({ country, city });
}
```

### Middleware

```typescript
// middleware.ts (root)
import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

export function middleware(request: NextRequest) {
  // Auth check
  const token = request.cookies.get('token');
  if (!token && request.nextUrl.pathname.startsWith('/dashboard')) {
    return NextResponse.redirect(new URL('/login', request.url));
  }

  // Geo-based routing
  const country = request.geo?.country || 'US';
  if (country === 'DE') {
    return NextResponse.rewrite(new URL('/de' + request.nextUrl.pathname, request.url));
  }

  return NextResponse.next();
}

export const config = {
  matcher: ['/((?!api|_next/static|favicon.ico).*)'],
};
```

---

## 7. Caching and ISR

### Static Generation

```typescript
// app/posts/page.tsx
export default async function PostsPage() {
  const posts = await getPosts();
  return <PostList posts={posts} />;
}

// Regenerate every hour
export const revalidate = 3600;
```

### On-Demand Revalidation

```typescript
// app/api/revalidate/route.ts
import { revalidatePath, revalidateTag } from 'next/cache';

export async function POST(request: Request) {
  const { secret, path, tag } = await request.json();

  if (secret !== process.env.REVALIDATION_SECRET) {
    return Response.json({ error: 'Invalid secret' }, { status: 401 });
  }

  if (path) {
    revalidatePath(path);
  }

  if (tag) {
    revalidateTag(tag);
  }

  return Response.json({ revalidated: true, now: Date.now() });
}
```

### Cache Headers

```typescript
// app/api/data/route.ts
export async function GET() {
  const data = await fetchData();

  return Response.json(data, {
    headers: {
      'Cache-Control': 's-maxage=60, stale-while-revalidate=300',
    },
  });
}
```

---

## 8. Custom Domains

### Adding Domains

```bash
# Via CLI
vercel domains add example.com
vercel domains add www.example.com

# Verify DNS
vercel domains verify example.com
```

### DNS Configuration

| Type | Name | Value |
|------|------|-------|
| A | @ | 76.76.21.21 |
| CNAME | www | cname.vercel-dns.com |

### Redirects

```json
// vercel.json
{
  "redirects": [
    {
      "source": "/",
      "destination": "https://www.example.com",
      "permanent": true,
      "has": [{ "type": "host", "value": "example.com" }]
    }
  ]
}
```

---

## 9. Monorepo Support

### Turborepo

```json
// turbo.json
{
  "pipeline": {
    "build": {
      "dependsOn": ["^build"],
      "outputs": [".next/**", "dist/**"]
    }
  }
}
```

### Root Directory

```json
// vercel.json (at root)
{
  "projects": [
    {
      "name": "web",
      "rootDirectory": "apps/web"
    },
    {
      "name": "api",
      "rootDirectory": "apps/api"
    }
  ]
}
```

### Selective Builds

```json
// apps/web/vercel.json
{
  "ignoreCommand": "npx turbo-ignore"
}
```

---

## 10. Deployment Protection

### Password Protection

```bash
# Enable via CLI
vercel deploy --prod --protection=password

# Or via vercel.json
{
  "protection": {
    "enabled": true
  }
}
```

### Trusted IPs

```json
// vercel.json
{
  "protection": {
    "allowedIps": ["192.168.1.0/24", "10.0.0.1"]
  }
}
```

### Vercel Authentication

```json
// vercel.json
{
  "protection": {
    "vercel": {
      "enabled": true
    }
  }
}
```

---

## CLI Commands Reference

```bash
# Deploy
vercel                      # Preview deployment
vercel --prod               # Production deployment
vercel --prebuilt           # Deploy prebuilt output

# Environment
vercel env ls               # List env vars
vercel env add NAME         # Add env var
vercel env rm NAME          # Remove env var
vercel env pull .env.local  # Pull env vars to local file

# Domains
vercel domains ls           # List domains
vercel domains add DOMAIN   # Add domain
vercel domains rm DOMAIN    # Remove domain

# Project
vercel link                 # Link to project
vercel project ls           # List projects
vercel logs                 # View deployment logs
vercel inspect URL          # Inspect deployment

# Development
vercel dev                  # Local development
vercel build                # Local build
```

---

## Troubleshooting

### Build Failures

```bash
# Check build logs
vercel logs <deployment-url>

# Common issues:
# 1. Missing environment variables
# 2. Node version mismatch (check engines in package.json)
# 3. Dependencies not in package.json
# 4. Build command not found
```

### Function Errors

```bash
# Check function logs
vercel logs <deployment-url> --since 1h

# Common issues:
# 1. Timeout (increase maxDuration)
# 2. Memory exceeded (increase memory in vercel.json)
# 3. Cold starts (use edge runtime for low latency)
```

### Domain Issues

```bash
# Verify DNS
vercel domains verify <domain>

# Check propagation
dig <domain>
nslookup <domain>
```

## References

- [Vercel Documentation](https://vercel.com/docs)
- [Vercel CLI Reference](https://vercel.com/docs/cli)
- [Next.js on Vercel](https://vercel.com/docs/frameworks/nextjs)
- [Edge Functions](https://vercel.com/docs/functions/edge-functions)
- [Vercel MCP](https://vercel.com/docs/mcp/vercel-mcp)
