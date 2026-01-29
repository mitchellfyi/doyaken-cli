---
name: nextjs:optimize
description: Analyze and optimize Next.js application performance
args:
  - name: focus
    description: Optimization focus (bundle, images, fonts, all)
    default: "all"
---

# Next.js Performance Optimization

You are optimizing a Next.js application for better performance.

## Context

Project: {{DOYAKEN_PROJECT}}
Focus: {{ARGS.focus}}

## Optimization Process

### 1. Analyze Current State

Check current configuration:
- `next.config.js` settings
- Bundle size (run `ANALYZE=true npm run build`)
- Image optimization usage
- Font loading strategy

### 2. Apply Optimizations

{{include:vendors/nextjs/performance.md}}

{{#if focus == "bundle" || focus == "all"}}
**Bundle Optimization**

- Convert to Server Components where possible
- Use dynamic imports for heavy components
- Check for large dependencies
- Remove unused code

{{/if}}

{{#if focus == "images" || focus == "all"}}
**Image Optimization**

- Use `next/image` for all images
- Add proper `sizes` prop
- Use `priority` for LCP images
- Configure remote patterns

{{/if}}

{{#if focus == "fonts" || focus == "all"}}
**Font Optimization**

- Use `next/font` for all fonts
- Enable `display: swap`
- Subset fonts appropriately
- Preload critical fonts

{{/if}}

### 3. Configuration Updates

Update `next.config.js` with optimizations.

### 4. Verify Improvements

- Run Lighthouse audit
- Check Core Web Vitals
- Compare bundle sizes

## Output

```markdown
## Optimization Report

**Focus**: {{ARGS.focus}}

### Changes Made

| File | Change | Impact |
|------|--------|--------|
| [file] | [change] | [expected impact] |

### Bundle Analysis
- **Before**: [size]
- **After**: [size]
- **Reduction**: [%]

### Core Web Vitals (Expected)
| Metric | Before | After |
|--------|--------|-------|
| LCP | [time] | [time] |
| CLS | [score] | [score] |
| INP | [time] | [time] |

### Recommendations
- [Additional optimizations not applied]

### Next Steps
- [ ] Deploy and measure real metrics
- [ ] Set up monitoring
- [ ] Review analytics
```
