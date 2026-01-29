---
name: nextjs:create-route
description: Create a new Next.js App Router route with best practices
args:
  - name: path
    description: Route path (e.g., /dashboard/settings)
    default: ""
  - name: type
    description: Route type (page, api, layout)
    default: "page"
  - name: dynamic
    description: Dynamic segment name (optional)
    default: ""
---

# Create Next.js Route

You are creating a new Next.js App Router route.

## Context

Project: {{DOYAKEN_PROJECT}}
Route Path: {{ARGS.path}}
Type: {{ARGS.type}}
Dynamic Segment: {{ARGS.dynamic}}

## Process

### 1. Analyze Requirements

Determine route structure:
- Static vs dynamic route
- Server or Client Component needed
- Data fetching requirements
- Layout needs

### 2. Create Route Files

{{include:vendors/nextjs/app-router.md}}

{{#if type == "page"}}
**Page Route**

Create in `app{{ARGS.path}}/`:
- `page.tsx` - Main page component
- `loading.tsx` - Loading state (if needed)
- `error.tsx` - Error boundary (if needed)

{{else if type == "api"}}
**API Route**

Create in `app{{ARGS.path}}/`:
- `route.ts` - API handler

{{else if type == "layout"}}
**Layout**

Create in `app{{ARGS.path}}/`:
- `layout.tsx` - Shared layout

{{/if}}

{{#if dynamic}}
Use dynamic segment: `[{{ARGS.dynamic}}]`
{{/if}}

### 3. Implement Pattern

**Server Component (Default)**
```tsx
export default async function Page() {
  const data = await fetchData();
  return <div>{/* content */}</div>;
}
```

**Client Component (If Needed)**
```tsx
'use client';
export default function Page() {
  const [state, setState] = useState();
  return <div>{/* interactive content */}</div>;
}
```

### 4. Add Metadata

```tsx
export const metadata = {
  title: 'Page Title',
  description: 'Page description',
};
```

## Output

```markdown
## Route Created

**Path**: {{ARGS.path}}
**Type**: {{ARGS.type}}

### Files Created
- `app{{ARGS.path}}/page.tsx`
- `app{{ARGS.path}}/loading.tsx`

### Route Info
- **Dynamic**: {{#if dynamic}}Yes ([{{ARGS.dynamic}}]){{else}}No{{/if}}
- **Component Type**: Server/Client
- **Data Fetching**: [method]

### Next Steps
- [ ] Implement page logic
- [ ] Add data fetching
- [ ] Create tests
```
