# Design Systems

Extracting and implementing design systems from Figma.

## When to Apply

Activate this guide when:
- Extracting design tokens from Figma
- Building a component library from designs
- Syncing Figma variables with code
- Creating a design system documentation

---

## 1. Design Tokens

### Extracting from Figma

Figma variables map to design tokens:

| Figma Concept | Token Type | CSS Custom Property |
|---------------|------------|---------------------|
| Color variables | Color | `--color-*` |
| Number variables | Spacing/Size | `--spacing-*`, `--size-*` |
| String variables | Font family | `--font-*` |
| Boolean variables | Feature flags | N/A |
| Modes | Themes | Data attributes |

### Token Structure

```typescript
// tokens/colors.ts
export const colors = {
  // Primitives (raw values)
  primitives: {
    blue: {
      50: '#EFF6FF',
      100: '#DBEAFE',
      500: '#3B82F6',
      600: '#2563EB',
      900: '#1E3A8A',
    },
    // ...
  },

  // Semantic (purpose-based)
  semantic: {
    primary: 'var(--color-blue-600)',
    primaryHover: 'var(--color-blue-700)',
    background: 'var(--color-white)',
    foreground: 'var(--color-gray-900)',
    muted: 'var(--color-gray-500)',
    border: 'var(--color-gray-200)',
  },
};
```

### CSS Variables

```css
/* tokens.css */
:root {
  /* Primitives */
  --color-blue-500: #3B82F6;
  --color-blue-600: #2563EB;

  /* Semantic - Light Mode */
  --color-primary: var(--color-blue-600);
  --color-background: #FFFFFF;
  --color-foreground: #111827;
}

[data-theme="dark"] {
  /* Semantic - Dark Mode */
  --color-primary: var(--color-blue-500);
  --color-background: #111827;
  --color-foreground: #F9FAFB;
}
```

---

## 2. Typography Scale

### Figma Text Styles to CSS

```css
/* From Figma text styles */
:root {
  /* Font families */
  --font-sans: 'Inter', system-ui, sans-serif;
  --font-mono: 'JetBrains Mono', monospace;

  /* Font sizes */
  --text-xs: 0.75rem;    /* 12px */
  --text-sm: 0.875rem;   /* 14px */
  --text-base: 1rem;     /* 16px */
  --text-lg: 1.125rem;   /* 18px */
  --text-xl: 1.25rem;    /* 20px */
  --text-2xl: 1.5rem;    /* 24px */
  --text-3xl: 1.875rem;  /* 30px */

  /* Line heights */
  --leading-tight: 1.25;
  --leading-normal: 1.5;
  --leading-relaxed: 1.75;

  /* Font weights */
  --font-normal: 400;
  --font-medium: 500;
  --font-semibold: 600;
  --font-bold: 700;
}

/* Typography classes */
.heading-1 {
  font-family: var(--font-sans);
  font-size: var(--text-3xl);
  font-weight: var(--font-bold);
  line-height: var(--leading-tight);
}

.body {
  font-family: var(--font-sans);
  font-size: var(--text-base);
  font-weight: var(--font-normal);
  line-height: var(--leading-normal);
}
```

---

## 3. Spacing System

### 4px/8px Grid

```css
:root {
  --spacing-0: 0;
  --spacing-1: 0.25rem;  /* 4px */
  --spacing-2: 0.5rem;   /* 8px */
  --spacing-3: 0.75rem;  /* 12px */
  --spacing-4: 1rem;     /* 16px */
  --spacing-5: 1.25rem;  /* 20px */
  --spacing-6: 1.5rem;   /* 24px */
  --spacing-8: 2rem;     /* 32px */
  --spacing-10: 2.5rem;  /* 40px */
  --spacing-12: 3rem;    /* 48px */
  --spacing-16: 4rem;    /* 64px */
}
```

---

## 4. Component Library

### Component Variants

Map Figma component variants to code:

```tsx
// Figma: Button with variants
// - Size: sm, md, lg
// - Variant: primary, secondary, ghost
// - State: default, hover, disabled

interface ButtonProps {
  size?: 'sm' | 'md' | 'lg';
  variant?: 'primary' | 'secondary' | 'ghost';
  disabled?: boolean;
  children: React.ReactNode;
}

const sizeClasses = {
  sm: 'px-3 py-1.5 text-sm',
  md: 'px-4 py-2 text-base',
  lg: 'px-6 py-3 text-lg',
};

const variantClasses = {
  primary: 'bg-primary text-white hover:bg-primary-hover',
  secondary: 'bg-secondary text-foreground hover:bg-secondary-hover',
  ghost: 'bg-transparent hover:bg-muted',
};

function Button({
  size = 'md',
  variant = 'primary',
  disabled,
  children
}: ButtonProps) {
  return (
    <button
      className={cn(
        'rounded-md font-medium transition-colors',
        sizeClasses[size],
        variantClasses[variant],
        disabled && 'opacity-50 cursor-not-allowed'
      )}
      disabled={disabled}
    >
      {children}
    </button>
  );
}
```

### Component Documentation

```tsx
/**
 * Button component following design system specifications.
 *
 * @figma https://figma.com/file/xxx/Design-System?node-id=1:234
 *
 * Variants:
 * - primary: Main call-to-action
 * - secondary: Secondary actions
 * - ghost: Tertiary/subtle actions
 */
```

---

## 5. Multi-Theme Support

### Figma Modes to CSS

```css
/* Light mode (default) */
:root {
  --surface-1: #FFFFFF;
  --surface-2: #F9FAFB;
  --text-primary: #111827;
  --text-secondary: #6B7280;
}

/* Dark mode */
[data-theme="dark"] {
  --surface-1: #1F2937;
  --surface-2: #111827;
  --text-primary: #F9FAFB;
  --text-secondary: #9CA3AF;
}

/* Brand theme */
[data-theme="brand"] {
  --surface-1: #1E3A8A;
  --surface-2: #1E40AF;
  --text-primary: #FFFFFF;
  --text-secondary: #BFDBFE;
}
```

## References

- [Figma Variables](https://help.figma.com/hc/en-us/articles/15339657135383-Guide-to-variables-in-Figma)
- [Design Tokens Format](https://design-tokens.github.io/community-group/format/)
