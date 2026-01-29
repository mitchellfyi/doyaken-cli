---
name: figma:a11y-audit
description: Audit Figma designs for accessibility compliance
requires:
  - figma
args:
  - name: frame
    description: Frame name or ID to audit
    default: ""
  - name: level
    description: WCAG level (AA, AAA)
    default: "AA"
---

# Accessibility Audit

You are auditing a Figma design for accessibility compliance.

## Context

Project: {{DOYAKEN_PROJECT}}
Frame: {{ARGS.frame}}
WCAG Level: {{ARGS.level}}

## Audit Process

### 1. Fetch Design

Use Figma MCP to get:
- Frame structure
- Color values
- Typography settings
- Component states

### 2. Check Accessibility

{{include:vendors/figma/accessibility.md}}

**Color Contrast**
- Text contrast ratios
- UI component contrast
- Focus indicator visibility

**Typography**
- Minimum font sizes
- Line heights
- Line lengths

**Interactive Elements**
- Touch target sizes
- Focus states designed
- All states present

**Structure**
- Heading hierarchy
- Landmark regions
- Reading order

### 3. Generate Report

## Output

```markdown
## Accessibility Audit Report

**Frame**: {{ARGS.frame}}
**WCAG Level**: {{ARGS.level}}
**Status**: Pass / Fail

### Summary
- **Critical Issues**: [count]
- **Warnings**: [count]
- **Passed Checks**: [count]

### Issues Found

#### Critical
| Issue | Element | Guideline | Fix |
|-------|---------|-----------|-----|
| Low contrast | Button text | 1.4.3 | Increase to 4.5:1 |

#### Warnings
| Issue | Element | Guideline | Recommendation |
|-------|---------|-----------|----------------|
| Small text | Caption | 1.4.4 | Consider 14px minimum |

### Passed Checks
- [x] Color contrast on headings
- [x] Touch targets 44x44px
- [x] Focus states present

### Recommendations
1. [Prioritized fixes]

### References
- WCAG 2.1 {{ARGS.level}}
- [Specific guidelines cited]
```
