---
name: vercel:ui-audit
description: Accessibility and UX audit using Vercel web design guidelines
args:
  - name: path
    description: Path to audit
    default: "."
  - name: wcag-level
    description: WCAG conformance level (A, AA, AAA)
    default: "AA"
---

# UI Accessibility & UX Audit

You are performing a comprehensive accessibility and UX audit using Vercel's web design guidelines.

## Context

Project: {{DOYAKEN_PROJECT}}
Audit path: {{ARGS.path}}
WCAG Level: {{ARGS.wcag-level}}

## Audit Framework

{{include:vendors/vercel/web-design-guidelines.md}}

## Audit Process

### 1. Identify UI Components

Find all UI-related files:
- Components with visible elements
- Pages and layouts
- Forms and inputs
- Modals and dialogs
- Navigation elements

### 2. Semantic HTML Audit (CRITICAL)

Check each component for:

- [ ] Correct HTML elements (button vs div, nav vs div, etc.)
- [ ] Proper heading hierarchy (h1 > h2 > h3, no skipped levels)
- [ ] Landmark regions (header, main, nav, aside, footer)
- [ ] Lists for list content (ul/ol/li)
- [ ] Tables for tabular data (with headers)

### 3. ARIA & Accessibility Audit (CRITICAL)

- [ ] All interactive elements have accessible names
- [ ] aria-label/aria-labelledby used correctly
- [ ] aria-expanded for collapsible content
- [ ] aria-pressed for toggle buttons
- [ ] aria-live for dynamic content
- [ ] role attributes used appropriately

### 4. Keyboard Navigation Audit (CRITICAL)

- [ ] All interactive elements focusable
- [ ] Visible focus indicators (not removed!)
- [ ] Logical tab order
- [ ] No keyboard traps
- [ ] Skip links present
- [ ] Modal focus trapping works

### 5. Form Accessibility Audit (HIGH)

- [ ] All inputs have associated labels
- [ ] Error messages linked with aria-describedby
- [ ] Required fields indicated
- [ ] Form validation accessible
- [ ] Autocomplete attributes present

### 6. Color & Contrast Audit (HIGH)

- [ ] Text contrast meets {{ARGS.wcag-level}} (4.5:1 for AA)
- [ ] Large text contrast (3:1 minimum)
- [ ] UI component contrast (3:1)
- [ ] Information not conveyed by color alone
- [ ] Focus indicators visible against all backgrounds

### 7. Motion & Animation Audit (MEDIUM)

- [ ] prefers-reduced-motion respected
- [ ] No auto-playing animations
- [ ] Animations can be paused
- [ ] No vestibular-triggering motion

### 8. Responsive & Touch Audit (MEDIUM)

- [ ] Touch targets 44x44px minimum
- [ ] Zoom to 200% doesn't break layout
- [ ] No horizontal scrolling at 320px
- [ ] User zoom not disabled

## Output

```
## UI Accessibility & UX Audit Report

### Executive Summary
- WCAG {{ARGS.wcag-level}} Conformance: [Pass/Partial/Fail]
- Components audited: [count]
- Issues found: CRITICAL: X, HIGH: Y, MEDIUM: Z

### Critical Issues (Blocks accessibility)
[List critical issues with locations and fixes]

### High Priority Issues
[List high priority issues]

### Medium Priority Issues
[List medium priority issues]

### Compliant Patterns
[What's done well]

### Remediation Plan

**Immediate (1-2 days):**
1. [Critical fixes]

**Short-term (1 week):**
1. [High priority fixes]

**Ongoing:**
1. [Medium priority fixes]

### Testing Recommendations
- [ ] Test with keyboard only
- [ ] Test with screen reader (VoiceOver/NVDA)
- [ ] Test at 200% zoom
- [ ] Test with high contrast mode
- [ ] Run axe-core automated tests

### Resources
- [WCAG 2.1 Quick Reference](https://www.w3.org/WAI/WCAG21/quickref/)
- [A11y Project Checklist](https://www.a11yproject.com/checklist/)
```
