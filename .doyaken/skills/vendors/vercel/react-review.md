---
name: vercel:react-review
description: Review React/Next.js code using Vercel best practices
args:
  - name: path
    description: Path to review
    default: "."
  - name: focus
    description: Focus area (performance, patterns, all)
    default: "all"
---

# React & Next.js Code Review

You are reviewing React/Next.js code using Vercel's official best practices.

## Context

Project: {{DOYAKEN_PROJECT}}
Review path: {{ARGS.path}}
Focus: {{ARGS.focus}}

## Review Framework

{{include:vendors/vercel/react-best-practices.md}}

## Review Process

### 1. Identify Code to Review

Find React/Next.js files:
- `*.tsx`, `*.jsx` - Components
- `app/**/page.tsx` - Pages (App Router)
- `pages/**/*.tsx` - Pages (Pages Router)
- `components/**/*` - Shared components
- `app/api/**/*` - API routes
- `middleware.ts` - Edge middleware

### 2. Apply Best Practices

{{#if focus == "performance" || focus == "all"}}
**Performance Review (CRITICAL/HIGH priority):**

- [ ] **Data Fetching**: No waterfalls? Using Promise.all or parallel Server Components?
- [ ] **Bundle Size**: Heavy components use dynamic import? Tree-shaking working?
- [ ] **Server Components**: Using Server Components where possible?
- [ ] **Rendering**: Proper use of memo/useMemo/useCallback?
- [ ] **Images**: Using next/image with proper sizing?
{{/if}}

{{#if focus == "patterns" || focus == "all"}}
**Pattern Review (MEDIUM/LOW priority):**

- [ ] **State Management**: State colocated? Not over-globalized?
- [ ] **Keys**: Using stable unique IDs, not array indices?
- [ ] **Error Boundaries**: Proper error handling?
- [ ] **Loading States**: Using Suspense boundaries?
- [ ] **TypeScript**: Proper types, no `any`?
{{/if}}

### 3. Document Findings

For each issue found:

```
### [Issue Title]

**Priority**: CRITICAL / HIGH / MEDIUM / LOW
**Category**: Data Fetching / Bundle Size / Rendering / Patterns
**Location**: `file:line`

**Current Code**:
```tsx
// problematic code
```

**Issue**: [What's wrong]

**Fix**:
```tsx
// corrected code
```

**Impact**: [Why this matters]
```

### 4. Summarize Recommendations

Group by priority and effort.

## Output

```
## React/Next.js Code Review

### Summary
- Files reviewed: [count]
- Issues found: CRITICAL: X, HIGH: Y, MEDIUM: Z, LOW: W
- Overall assessment: [brief assessment]

### Critical Issues (Fix Now)
[List critical issues]

### High Priority Issues
[List high priority issues]

### Medium Priority Issues
[List medium priority issues]

### Low Priority Improvements
[List low priority improvements]

### Positive Patterns Found
[What's done well]

### Recommended Actions
1. [Prioritized action items]
```
