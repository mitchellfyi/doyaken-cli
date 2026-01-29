---
name: vercel:perf-audit
description: Next.js performance audit using Vercel best practices
args:
  - name: path
    description: Path to audit
    default: "."
  - name: depth
    description: Audit depth (quick, standard, deep)
    default: "standard"
---

# Next.js Performance Audit

You are performing a performance audit of a Next.js application using Vercel's best practices.

## Context

Project: {{DOYAKEN_PROJECT}}
Audit path: {{ARGS.path}}
Depth: {{ARGS.depth}}

## Performance Framework

{{include:vendors/vercel/react-best-practices.md}}

## Audit Process

### 1. Data Fetching Analysis (CRITICAL)

{{#if depth != "quick"}}
**Find all data fetching patterns:**

```bash
# Look for fetch patterns
grep -r "fetch\|axios\|useSWR\|useQuery\|getServerSideProps\|getStaticProps" --include="*.tsx" --include="*.ts"
```
{{/if}}

**Check for:**
- [ ] No fetch waterfalls (sequential awaits)
- [ ] Server Components used for data fetching
- [ ] Parallel data loading with Promise.all
- [ ] Proper use of Suspense boundaries
- [ ] React cache() for deduplication

### 2. Bundle Size Analysis (CRITICAL)

{{#if depth == "deep"}}
**Run bundle analysis:**

```bash
ANALYZE=true npm run build
# or
npx @next/bundle-analyzer
```
{{/if}}

**Check for:**
- [ ] Dynamic imports for heavy components
- [ ] Tree-shaking working (no full library imports)
- [ ] Code splitting by route
- [ ] No unnecessary client components

### 3. Server vs Client Components (HIGH)

**Audit component usage:**
- [ ] Server Components default (no unnecessary 'use client')
- [ ] 'use client' only for interactivity
- [ ] Server Actions for mutations
- [ ] Edge Runtime for global performance

### 4. Image Optimization (HIGH)

**Check image usage:**
- [ ] All images use next/image
- [ ] Proper width/height or fill
- [ ] sizes prop for responsive images
- [ ] priority for LCP images
- [ ] Lazy loading for below-fold

### 5. Caching Strategy (MEDIUM)

{{#if depth != "quick"}}
**Analyze caching:**
- [ ] Static pages use generateStaticParams
- [ ] Appropriate revalidate intervals
- [ ] On-demand revalidation for dynamic content
- [ ] Cache headers on API routes
{{/if}}

### 6. Rendering Performance (MEDIUM)

**Check React patterns:**
- [ ] useMemo for expensive computations
- [ ] useCallback for stable callbacks
- [ ] React.memo for expensive children
- [ ] Stable keys (not array indices)

{{#if depth == "deep"}}
### 7. Core Web Vitals Analysis (DEEP)

**Measure performance:**
- [ ] LCP (Largest Contentful Paint) < 2.5s
- [ ] FID (First Input Delay) < 100ms
- [ ] CLS (Cumulative Layout Shift) < 0.1
- [ ] TTFB (Time to First Byte) < 200ms
- [ ] INP (Interaction to Next Paint) < 200ms

**Tools:**
```bash
npx lighthouse https://your-site.vercel.app
npx unlighthouse --site https://your-site.vercel.app
```
{{/if}}

## Output

```
## Next.js Performance Audit Report

### Executive Summary
- Overall Score: [A/B/C/D/F]
- Critical Issues: [count]
- Estimated Impact: [performance improvement potential]

### Data Fetching ({{#if depth == "quick"}}Quick{{else}}Detailed{{/if}} Analysis)
**Status**: [Good/Needs Work/Critical]

Issues:
[List issues with locations]

Recommendations:
[Specific fixes]

### Bundle Size Analysis
**Status**: [Good/Needs Work/Critical]

Issues:
[List issues]

Recommendations:
[Specific fixes]

### Server/Client Component Usage
**Status**: [Good/Needs Work/Critical]

Issues:
[List unnecessary client components]

Recommendations:
[Components to convert to Server Components]

### Image Optimization
**Status**: [Good/Needs Work/Critical]

Issues:
[List image issues]

Recommendations:
[Specific fixes]

### Caching Strategy
**Status**: [Good/Needs Work/Critical]

[Analysis results]

{{#if depth == "deep"}}
### Core Web Vitals
| Metric | Value | Target | Status |
|--------|-------|--------|--------|
| LCP | ? | < 2.5s | ? |
| FID | ? | < 100ms | ? |
| CLS | ? | < 0.1 | ? |
| TTFB | ? | < 200ms | ? |
{{/if}}

### Action Plan

**Immediate Impact (CRITICAL):**
1. [High-impact fix]

**Short-term (HIGH):**
1. [Next priority fixes]

**Optimization (MEDIUM):**
1. [Additional optimizations]

### Verification Commands
```bash
# Bundle analysis
ANALYZE=true npm run build

# Performance testing
npx lighthouse https://your-site.vercel.app

# Vercel Analytics
# Check dashboard at vercel.com/[team]/[project]/analytics
```
```
