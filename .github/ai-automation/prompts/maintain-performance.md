You are performing a scheduled maintenance review of **application performance**. Your goal is to find and fix performance issues that degrade user experience or waste resources.

## Phase 1: Review

1. Read `CLAUDE.md` and `AGENTS.md` for project conventions
2. Read `package.json` and `next.config.*` (or equivalent build config)
3. Scan source code for performance issues:
   - **Bundle size:** Large imports that could be tree-shaken or lazy-loaded (e.g., `import _ from 'lodash'` vs `import get from 'lodash/get'`)
   - **Images:** Unoptimized images, missing `width`/`height`, missing `next/image`, large assets in `public/`
   - **Rendering:** Components that re-render unnecessarily, missing `React.memo`, missing `useMemo`/`useCallback` for expensive computations
   - **Data fetching:** Waterfalls (sequential fetches that could be parallel), missing caching, overfetching
   - **Loading:** Missing code splitting, large client-side bundles, missing `dynamic()` imports
   - **API routes:** Slow operations that could be cached, missing streaming for large responses
   - **Database:** N+1 queries, missing indexes (if applicable), unbounded queries without pagination

## Phase 2: Fix

Fix performance problems:

- Replace barrel imports with specific imports (`import { x } from 'lib/x'` not `import { x } from 'lib'`)
- Add missing `loading.tsx` / `Suspense` boundaries for slow components
- Fix data fetching waterfalls (use `Promise.all` for independent fetches)
- Fix unbounded queries (add `limit`/`take` clauses)
- Remove unnecessary client-side JavaScript (`"use client"` where server components would work)

## Phase 3: Sync

Align performance patterns across the codebase:

- Ensure all images use the framework's image component consistently
- Ensure data fetching follows the same caching pattern everywhere
- Ensure heavy pages use code splitting consistently
- Ensure API responses use consistent pagination patterns

## Phase 4: Improve

Enhance existing performance:

- Add `dynamic(() => import(...))` for heavy components not needed on initial load
- Add `prefetch` to links for likely navigation targets
- Move expensive computations from render path to build time where possible
- Add `Cache-Control` headers to API routes that serve static-ish data
- Optimize database queries (select only needed fields, add includes/joins)

## Phase 5: Add

Fill performance gaps:

- Add missing `loading.tsx` skeletons for routes that fetch data
- Add missing `Suspense` boundaries around slow components
- Add missing caching for repeated API calls
- Add `rel="preload"` for critical resources (fonts, above-the-fold images)

## Instructions

1. Read `CLAUDE.md` and `AGENTS.md` first
2. Focus on `src/` — especially pages, API routes, and components
3. Work through Phases 1-5 in order
4. Run ALL quality gates before committing: `pnpm format`, `pnpm lint:fix`, `pnpm typecheck`, `pnpm test`, `pnpm build`
5. Commit changes with descriptive messages — group by phase where practical
6. Push to the current branch
7. Do NOT create a new PR — just push to this branch

## Rules

- Only optimize where there's a clear performance benefit — not premature optimization
- Do NOT add `React.memo` everywhere — only where re-renders are measurably expensive
- Do NOT break functionality for performance — correctness comes first
- Do NOT cache data that must be fresh (user-specific data, auth state)
- Keep changes focused — don't refactor non-performance code
- Prefer framework-native solutions (Next.js caching, ISR, SSG) over custom ones
- If a change requires profiling data you don't have, skip it and note it in a commit message
