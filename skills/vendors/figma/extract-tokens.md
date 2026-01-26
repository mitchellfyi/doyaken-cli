---
name: figma:extract-tokens
description: Extract design tokens from Figma variables
requires:
  - figma
args:
  - name: file
    description: Figma file ID or URL
    default: ""
  - name: output
    description: Output format (css, json, tailwind)
    default: "css"
---

# Extract Design Tokens

You are extracting design tokens from a Figma file.

## Context

Project: {{DOYAKEN_PROJECT}}
File: {{ARGS.file}}
Output Format: {{ARGS.output}}

## Process

### 1. Fetch Variables

Use Figma MCP to get:
- Color variables
- Number variables (spacing, sizing)
- Typography styles
- Effect styles (shadows)
- Variable modes (light/dark)

### 2. Organize Tokens

{{include:vendors/figma/design-systems.md}}

Categories:
- **Primitives**: Raw color/number values
- **Semantic**: Purpose-based tokens (primary, background)
- **Component**: Component-specific tokens

### 3. Generate Output

{{#if output == "css"}}
**CSS Custom Properties**

```css
:root {
  /* Primitives */
  --color-blue-500: #3B82F6;

  /* Semantic */
  --color-primary: var(--color-blue-500);
}

[data-theme="dark"] {
  --color-primary: var(--color-blue-400);
}
```

{{else if output == "json"}}
**Design Tokens JSON**

```json
{
  "color": {
    "primary": { "value": "#3B82F6" }
  }
}
```

{{else if output == "tailwind"}}
**Tailwind Config**

```js
module.exports = {
  theme: {
    extend: {
      colors: {
        primary: 'var(--color-primary)',
      }
    }
  }
}
```
{{/if}}

## Output

```markdown
## Design Tokens Extracted

**File**: {{ARGS.file}}
**Format**: {{ARGS.output}}

### Token Summary
| Category | Count |
|----------|-------|
| Colors | [count] |
| Spacing | [count] |
| Typography | [count] |

### Modes/Themes
- [List of variable modes]

### Generated Files
- tokens.{{ARGS.output}}

### Usage
[Instructions for using the tokens]
```
