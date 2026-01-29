# Design to Code

Best practices for converting Figma designs to production code.

## When to Apply

Activate this guide when:
- Converting Figma frames to React/HTML components
- Implementing designs from a Figma file
- Using Figma MCP for code generation

---

## 1. Preparation

### Understand the Design Structure

Before generating code:

1. **Identify component boundaries**
   - Look for repeated patterns (cards, buttons, forms)
   - Note parent-child relationships
   - Identify shared styles

2. **Review design tokens**
   - Colors (primitives and semantic)
   - Typography scales
   - Spacing system
   - Border radii

3. **Check responsive behavior**
   - Auto-layout constraints
   - Min/max widths
   - Breakpoint variations

### Figma MCP Context

When using Figma MCP, request:

```
Get the design context for frame [frame-name] including:
- Layout structure
- Component instances
- Style references
- Auto-layout settings
```

---

## 2. Code Generation Patterns

### Component Structure

```tsx
// Match Figma layer hierarchy to component structure
// Figma: Card > CardHeader > Title, Subtitle
//        Card > CardContent > ...

interface CardProps {
  title: string;
  subtitle?: string;
  children: React.ReactNode;
}

function Card({ title, subtitle, children }: CardProps) {
  return (
    <div className="card">
      <header className="card-header">
        <h3 className="card-title">{title}</h3>
        {subtitle && <p className="card-subtitle">{subtitle}</p>}
      </header>
      <div className="card-content">
        {children}
      </div>
    </div>
  );
}
```

### Layout Translation

| Figma Auto-Layout | CSS/Tailwind |
|-------------------|--------------|
| Horizontal | `flex-row` / `flex` |
| Vertical | `flex-col` / `flex flex-direction: column` |
| Space between | `justify-between` |
| Packed (start) | `justify-start` |
| Gap: 16px | `gap-4` / `gap: 16px` |
| Padding: 24px | `p-6` / `padding: 24px` |
| Fill container | `flex-1` / `flex-grow: 1` |
| Hug contents | `w-fit` / `width: fit-content` |

### Style Mapping

```css
/* Map Figma styles to CSS variables */
:root {
  /* Colors from Figma */
  --color-primary: #0066FF;
  --color-primary-hover: #0052CC;

  /* Typography from Figma */
  --font-heading: 'Inter', sans-serif;
  --font-size-xl: 24px;
  --line-height-xl: 32px;

  /* Spacing from Figma */
  --spacing-sm: 8px;
  --spacing-md: 16px;
  --spacing-lg: 24px;
}
```

---

## 3. Common Patterns

### Responsive Images

```tsx
// Figma image with fill mode
<div className="aspect-video relative overflow-hidden">
  <img
    src={imageUrl}
    alt={alt}
    className="absolute inset-0 w-full h-full object-cover"
  />
</div>
```

### Text Truncation

```tsx
// Figma text with "Truncate text" enabled
<p className="line-clamp-2">
  {longText}
</p>
```

### Icon Integration

```tsx
// Figma icons as React components
import { IconName } from './icons';

// Or use icon library matching design system
import { ArrowRight } from 'lucide-react';
```

---

## 4. Quality Checklist

After code generation, verify:

- [ ] **Visual fidelity** - Matches design at target breakpoints
- [ ] **Interactions** - Hover, focus, active states implemented
- [ ] **Accessibility** - Semantic HTML, ARIA labels, focus management
- [ ] **Responsiveness** - Works across breakpoints
- [ ] **Performance** - Optimized images, minimal bundle impact
- [ ] **Tokens** - Uses design system tokens, not hard-coded values

---

## 5. Code Connect

When Code Connect is configured, generated code references existing components:

```tsx
// Instead of generating new code, reference existing:
import { Button } from '@/components/ui/button';

// With correct variant matching Figma component
<Button variant="primary" size="lg">
  Get Started
</Button>
```

## References

- [Design to Code with Figma MCP](https://www.builder.io/blog/figma-mcp-server)
- [Figma Code Connect](https://www.figma.com/developers/code-connect)
