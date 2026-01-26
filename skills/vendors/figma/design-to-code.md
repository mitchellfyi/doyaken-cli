---
name: figma:design-to-code
description: Convert Figma frames to React/HTML code
requires:
  - figma
args:
  - name: frame
    description: Frame name or ID to convert
    default: ""
  - name: format
    description: Output format (react, html, tailwind)
    default: "react"
---

# Design to Code

You are converting a Figma design to production code using Figma MCP.

## Context

Project: {{DOYAKEN_PROJECT}}
Frame: {{ARGS.frame}}
Format: {{ARGS.format}}

## Process

### 1. Fetch Design Context

Use Figma MCP to get the frame data:

- Frame layout and structure
- Component instances
- Style references (colors, typography)
- Auto-layout settings
- Variables and tokens

### 2. Analyze Design

{{include:vendors/figma/design-to-code.md}}

Identify:
- Component boundaries
- Reusable patterns
- Interactive elements
- Responsive behavior

### 3. Generate Code

{{#if format == "react"}}
**React/TypeScript Output**

Generate:
- Functional components with TypeScript
- Props interfaces
- Tailwind CSS classes
- Semantic HTML structure

{{else if format == "html"}}
**HTML/CSS Output**

Generate:
- Semantic HTML5
- CSS custom properties for tokens
- BEM naming convention
- Responsive styles

{{else if format == "tailwind"}}
**Tailwind-First Output**

Generate:
- React components
- Tailwind utility classes
- Design system tokens as CSS variables
- Responsive variants

{{/if}}

### 4. Apply Best Practices

- Use semantic HTML elements
- Include ARIA labels where needed
- Use design system tokens
- Keep components focused

## Output

```markdown
## Generated Code

**Frame**: {{ARGS.frame}}
**Format**: {{ARGS.format}}
**Components**: [count]

### Files Created
- [List of files]

### Design Token Usage
| Token | Value | Usage |
|-------|-------|-------|
| --color-primary | #xxx | Buttons, links |

### Component Structure
```
[Component tree]
```

### Code
[Generated code blocks]

### Next Steps
- [ ] Review generated code
- [ ] Connect to existing components
- [ ] Add interactivity
- [ ] Test responsiveness
```
