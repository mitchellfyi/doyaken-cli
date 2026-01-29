# Web Design Guidelines

Comprehensive UI audit framework with 100+ rules covering accessibility, performance, and UX.

Based on [Vercel Agent Skills: web-design-guidelines](https://github.com/vercel-labs/agent-skills).

## When to Apply

Activate this guide when:
- "Review my UI"
- "Check accessibility"
- "Audit design"
- "Review UX"
- Building new user interfaces
- Preparing for accessibility compliance

---

## 1. Semantic HTML (CRITICAL)

### Use Correct Elements

```html
<!-- BAD -->
<div class="button" onclick="submit()">Submit</div>
<div class="heading">Page Title</div>
<div class="nav">
  <div class="link">Home</div>
</div>

<!-- GOOD -->
<button type="submit">Submit</button>
<h1>Page Title</h1>
<nav>
  <a href="/">Home</a>
</nav>
```

### Document Outline

```html
<!-- GOOD: Clear heading hierarchy -->
<h1>Product Catalog</h1>
  <h2>Electronics</h2>
    <h3>Phones</h3>
    <h3>Laptops</h3>
  <h2>Clothing</h2>
    <h3>Men's</h3>
    <h3>Women's</h3>

<!-- BAD: Skipped levels -->
<h1>Product Catalog</h1>
  <h4>Electronics</h4> <!-- Skipped h2, h3 -->
```

### Landmark Regions

```html
<header role="banner">
  <nav aria-label="Main navigation">...</nav>
</header>

<main>
  <article>
    <header>...</header>
    <section aria-labelledby="section-title">
      <h2 id="section-title">Section Title</h2>
    </section>
  </article>
  <aside aria-label="Related content">...</aside>
</main>

<footer role="contentinfo">...</footer>
```

---

## 2. ARIA and Accessibility (CRITICAL)

### Interactive Elements

```tsx
// Button with loading state
<button
  aria-busy={isLoading}
  aria-disabled={isLoading}
  disabled={isLoading}
>
  {isLoading ? 'Saving...' : 'Save'}
</button>

// Toggle button
<button
  aria-pressed={isActive}
  onClick={() => setIsActive(!isActive)}
>
  {isActive ? 'Enabled' : 'Disabled'}
</button>

// Expandable section
<button
  aria-expanded={isOpen}
  aria-controls="panel-content"
  onClick={() => setIsOpen(!isOpen)}
>
  Settings
</button>
<div id="panel-content" hidden={!isOpen}>
  Panel content...
</div>
```

### Forms

```tsx
// Label association
<label htmlFor="email">Email address</label>
<input
  id="email"
  type="email"
  aria-describedby="email-hint email-error"
  aria-invalid={hasError}
  required
/>
<span id="email-hint">We'll never share your email.</span>
{hasError && <span id="email-error" role="alert">Please enter a valid email.</span>}

// Fieldset for related inputs
<fieldset>
  <legend>Shipping Address</legend>
  <label htmlFor="street">Street</label>
  <input id="street" />
  <label htmlFor="city">City</label>
  <input id="city" />
</fieldset>
```

### Live Regions

```tsx
// Announcements
<div aria-live="polite" aria-atomic="true">
  {statusMessage}
</div>

// Urgent alerts
<div role="alert" aria-live="assertive">
  {errorMessage}
</div>

// Status updates (less intrusive)
<div role="status">
  {items.length} items in cart
</div>
```

### Images

```tsx
// Informative images
<img src="chart.png" alt="Sales increased 25% in Q4 2024" />

// Decorative images
<img src="decoration.svg" alt="" role="presentation" />

// Complex images
<figure>
  <img src="infographic.png" alt="Product comparison chart" aria-describedby="chart-desc" />
  <figcaption id="chart-desc">
    Detailed comparison of Product A vs Product B across 5 metrics...
  </figcaption>
</figure>
```

---

## 3. Keyboard Navigation (CRITICAL)

### Focus Management

```tsx
// Visible focus indicators (never remove!)
// In CSS:
:focus {
  outline: 2px solid #005fcc;
  outline-offset: 2px;
}

:focus:not(:focus-visible) {
  outline: none; /* Hide for mouse, show for keyboard */
}

:focus-visible {
  outline: 2px solid #005fcc;
  outline-offset: 2px;
}
```

### Tab Order

```tsx
// Natural tab order (don't use positive tabindex)
<button>First</button>
<button>Second</button>
<button>Third</button>

// Remove from tab order when hidden/disabled
<button tabIndex={isVisible ? 0 : -1}>
  Conditional Button
</button>

// Skip to content link
<a href="#main-content" className="skip-link">
  Skip to main content
</a>
```

### Keyboard Shortcuts

```tsx
// Modal trap focus
function Modal({ isOpen, onClose, children }) {
  const modalRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (isOpen) {
      // Focus first focusable element
      const focusable = modalRef.current?.querySelectorAll(
        'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])'
      );
      (focusable?.[0] as HTMLElement)?.focus();
    }
  }, [isOpen]);

  const handleKeyDown = (e: KeyboardEvent) => {
    if (e.key === 'Escape') onClose();
    // Trap focus within modal...
  };

  return (
    <div
      ref={modalRef}
      role="dialog"
      aria-modal="true"
      onKeyDown={handleKeyDown}
    >
      {children}
    </div>
  );
}
```

---

## 4. Color and Contrast (HIGH)

### Contrast Ratios

```css
/* WCAG AA Requirements:
   - Normal text: 4.5:1
   - Large text (18px+ or 14px+ bold): 3:1
   - UI components and graphics: 3:1
*/

/* GOOD */
.text-primary { color: #1a1a1a; } /* on white: 16:1 */
.text-secondary { color: #595959; } /* on white: 7:1 */
.text-muted { color: #767676; } /* on white: 4.5:1 */

/* BAD */
.text-light { color: #999999; } /* on white: 2.85:1 - FAIL */
```

### Don't Rely on Color Alone

```tsx
// BAD: Color-only status
<span style={{ color: 'red' }}>Error</span>
<span style={{ color: 'green' }}>Success</span>

// GOOD: Color + icon/text
<span className="text-red-600">
  <XCircleIcon aria-hidden="true" />
  Error: Invalid input
</span>
<span className="text-green-600">
  <CheckCircleIcon aria-hidden="true" />
  Success: Saved
</span>
```

### Focus Indicators

```css
/* Ensure focus is visible against all backgrounds */
.button:focus-visible {
  outline: 2px solid currentColor;
  outline-offset: 2px;
}

/* Or use a consistent focus ring */
*:focus-visible {
  outline: 3px solid #005fcc;
  outline-offset: 2px;
  border-radius: 2px;
}
```

---

## 5. Forms and Validation (HIGH)

### Clear Labels

```tsx
// Always use visible labels
<label htmlFor="search" className="sr-only">Search products</label>
<input id="search" type="search" placeholder="Search..." />

// Better: Visible label
<label htmlFor="search">Search products</label>
<input id="search" type="search" />
```

### Error Handling

```tsx
function FormField({ label, name, error, ...props }) {
  const id = useId();
  const errorId = `${id}-error`;

  return (
    <div>
      <label htmlFor={id}>{label}</label>
      <input
        id={id}
        name={name}
        aria-invalid={!!error}
        aria-describedby={error ? errorId : undefined}
        {...props}
      />
      {error && (
        <span id={errorId} role="alert" className="text-red-600">
          {error}
        </span>
      )}
    </div>
  );
}
```

### Input Types

```tsx
// Use correct input types for mobile keyboards and validation
<input type="email" autoComplete="email" />
<input type="tel" autoComplete="tel" />
<input type="url" />
<input type="number" inputMode="numeric" pattern="[0-9]*" />
<input type="date" />
<input type="search" />
```

### Autocomplete

```tsx
// Enable autofill for common fields
<input type="text" autoComplete="name" /> {/* Full name */}
<input type="email" autoComplete="email" />
<input type="tel" autoComplete="tel" />
<input type="text" autoComplete="address-line1" />
<input type="text" autoComplete="postal-code" />
<input type="text" autoComplete="cc-number" /> {/* Credit card */}
<input type="password" autoComplete="new-password" /> {/* Registration */}
<input type="password" autoComplete="current-password" /> {/* Login */}
```

---

## 6. Animation and Motion (MEDIUM)

### Respect User Preferences

```css
/* Reduce motion for users who prefer it */
@media (prefers-reduced-motion: reduce) {
  *,
  *::before,
  *::after {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
  }
}

/* Apply motion only when user hasn't disabled it */
@media (prefers-reduced-motion: no-preference) {
  .fade-in {
    animation: fadeIn 0.3s ease-out;
  }
}
```

```tsx
// React hook for motion preference
function useReducedMotion() {
  const [reducedMotion, setReducedMotion] = useState(false);

  useEffect(() => {
    const query = window.matchMedia('(prefers-reduced-motion: reduce)');
    setReducedMotion(query.matches);

    const handler = (e: MediaQueryListEvent) => setReducedMotion(e.matches);
    query.addEventListener('change', handler);
    return () => query.removeEventListener('change', handler);
  }, []);

  return reducedMotion;
}
```

### Safe Animations

```css
/* Avoid animations that can cause vestibular issues */
/* AVOID: Large movements, parallax, zooming, spinning */
/* SAFE: Fades, color changes, small transforms */

.safe-animation {
  transition: opacity 0.2s ease, transform 0.2s ease;
}

.safe-animation:hover {
  opacity: 0.9;
  transform: translateY(-2px); /* Small movement */
}
```

---

## 7. Responsive Design (MEDIUM)

### Touch Targets

```css
/* Minimum 44x44px for touch targets (WCAG) */
.button {
  min-height: 44px;
  min-width: 44px;
  padding: 12px 16px;
}

/* Adequate spacing between targets */
.nav-links a {
  padding: 12px;
  margin: 4px;
}
```

### Viewport and Zoom

```html
<!-- Allow user zoom (never disable!) -->
<meta name="viewport" content="width=device-width, initial-scale=1">

<!-- BAD: Prevents zoom -->
<meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no">
```

### Text Sizing

```css
/* Use relative units for text */
html {
  font-size: 100%; /* Respects user browser settings */
}

body {
  font-size: 1rem; /* 16px default */
  line-height: 1.5;
}

h1 { font-size: clamp(1.75rem, 4vw, 2.5rem); }
h2 { font-size: clamp(1.5rem, 3vw, 2rem); }

/* Ensure text can be resized up to 200% without loss */
```

---

## 8. Content and Language (MEDIUM)

### Page Titles

```tsx
// Unique, descriptive page titles
// app/products/[id]/page.tsx
export async function generateMetadata({ params }) {
  const product = await getProduct(params.id);
  return {
    title: `${product.name} | Your Store`,
    description: product.description.slice(0, 160),
  };
}
```

### Language

```html
<!-- Set language for screen readers -->
<html lang="en">

<!-- Mark language changes in content -->
<p>The French word <span lang="fr">bonjour</span> means hello.</p>
```

### Link Text

```tsx
// BAD: Vague link text
<a href="/pricing">Click here</a>
<a href="/docs">Read more</a>
<a href="/report.pdf">Download</a>

// GOOD: Descriptive link text
<a href="/pricing">View pricing plans</a>
<a href="/docs">Read the documentation</a>
<a href="/report.pdf">Download annual report (PDF, 2.3MB)</a>
```

---

## 9. Dark Mode (LOW)

### Color Tokens

```css
:root {
  --color-bg: #ffffff;
  --color-text: #1a1a1a;
  --color-text-muted: #595959;
  --color-border: #e5e5e5;
  --color-primary: #0066cc;
}

@media (prefers-color-scheme: dark) {
  :root {
    --color-bg: #121212;
    --color-text: #e5e5e5;
    --color-text-muted: #a3a3a3;
    --color-border: #2d2d2d;
    --color-primary: #66b3ff;
  }
}

/* Ensure contrast is maintained in both modes */
```

### Images in Dark Mode

```css
/* Invert/adjust images for dark mode if needed */
@media (prefers-color-scheme: dark) {
  img.logo {
    filter: invert(1) hue-rotate(180deg);
  }

  /* Or use different images */
  .logo-light { display: block; }
  .logo-dark { display: none; }
}

@media (prefers-color-scheme: dark) {
  .logo-light { display: none; }
  .logo-dark { display: block; }
}
```

---

## 10. Internationalization (LOW)

### RTL Support

```css
/* Use logical properties */
.card {
  margin-inline-start: 1rem; /* margin-left in LTR, margin-right in RTL */
  padding-inline: 1rem; /* padding-left and padding-right */
  border-inline-end: 1px solid var(--border); /* border-right in LTR */
}

/* Text alignment */
.text {
  text-align: start; /* left in LTR, right in RTL */
}
```

### Number and Date Formatting

```tsx
// Use Intl APIs
const formatter = new Intl.NumberFormat('en-US', {
  style: 'currency',
  currency: 'USD',
});
formatter.format(1234.56); // "$1,234.56"

const dateFormatter = new Intl.DateTimeFormat('en-US', {
  dateStyle: 'long',
});
dateFormatter.format(new Date()); // "January 26, 2026"
```

---

## Audit Checklist

### Quick Accessibility Audit

- [ ] All images have alt text (empty for decorative)
- [ ] Headings follow logical hierarchy (h1 > h2 > h3)
- [ ] All form inputs have associated labels
- [ ] Color contrast meets 4.5:1 for text
- [ ] Focus indicators are visible
- [ ] Page can be navigated by keyboard alone
- [ ] No content is conveyed by color alone
- [ ] Animations respect prefers-reduced-motion
- [ ] Touch targets are at least 44x44px
- [ ] Zoom to 200% doesn't break layout

### Tools

```bash
# Automated testing
npx axe-core-cli https://your-site.vercel.app
npx lighthouse https://your-site.vercel.app --only-categories=accessibility

# Manual testing
# - Navigate with keyboard only (Tab, Enter, Escape, Arrow keys)
# - Use screen reader (VoiceOver on Mac, NVDA on Windows)
# - Test with browser zoom at 200%
# - Test with high contrast mode
```

## References

- [WCAG 2.1 Guidelines](https://www.w3.org/WAI/WCAG21/quickref/)
- [WAI-ARIA Practices](https://www.w3.org/WAI/ARIA/apg/)
- [Inclusive Components](https://inclusive-components.design/)
- [A11y Project Checklist](https://www.a11yproject.com/checklist/)
