# Accessibility Review

Reviewing Figma designs for accessibility compliance.

## When to Apply

Activate this guide when:
- Reviewing designs before implementation
- Auditing existing designs for a11y
- Creating accessible component specifications
- Ensuring WCAG compliance

---

## 1. Color & Contrast

### Contrast Requirements

| Element | WCAG AA | WCAG AAA |
|---------|---------|----------|
| Normal text (< 18px) | 4.5:1 | 7:1 |
| Large text (≥ 18px bold, ≥ 24px) | 3:1 | 4.5:1 |
| UI components | 3:1 | N/A |
| Focus indicators | 3:1 | N/A |

### Checking in Figma

1. Use Figma's built-in contrast checker
2. Install plugins: "Contrast", "Stark"
3. Test all text/background combinations
4. Verify across all theme modes

### Common Issues

```
❌ Light gray text on white: #9CA3AF on #FFFFFF (2.6:1)
✓ Darker gray on white: #6B7280 on #FFFFFF (5.0:1)

❌ Primary button text: #FFFFFF on #60A5FA (2.4:1)
✓ Primary button text: #FFFFFF on #2563EB (4.6:1)
```

---

## 2. Typography

### Minimum Sizes

- Body text: 16px minimum
- Small text: 14px (use sparingly)
- Never below 12px for any content

### Line Height

- Body text: 1.5 minimum
- Headings: 1.2-1.3 acceptable

### Line Length

- Optimal: 50-75 characters per line
- Maximum: 80 characters

### Font Considerations

```
✓ Clear sans-serif fonts (Inter, Open Sans)
✓ Distinct character shapes (l, I, 1 easily distinguishable)
✓ Adequate letter spacing
✗ Decorative fonts for body text
✗ All-caps for long text
```

---

## 3. Interactive Elements

### Touch Targets

- Minimum: 44x44px (mobile)
- Recommended: 48x48px
- Spacing: 8px minimum between targets

### Focus States

Every interactive element needs visible focus:

```css
/* Required focus indicator */
.button:focus-visible {
  outline: 2px solid var(--color-focus);
  outline-offset: 2px;
}
```

### States to Design

| State | Purpose | Visual Treatment |
|-------|---------|------------------|
| Default | Normal appearance | Base styles |
| Hover | Mouse interaction | Subtle change |
| Focus | Keyboard navigation | High contrast outline |
| Active/Pressed | During interaction | Depressed appearance |
| Disabled | Unavailable | Reduced opacity + cursor |

---

## 4. Content Structure

### Heading Hierarchy

```
✓ Single H1 per page
✓ Sequential levels (H1 → H2 → H3)
✗ Skipping levels (H1 → H3)
✗ Using headings for styling only
```

### Landmarks

Ensure designs support semantic regions:

- Header (navigation)
- Main content area
- Sidebar (complementary)
- Footer

### Reading Order

Verify visual order matches DOM order:

1. Check Figma layer order
2. Ensure logical tab sequence
3. Verify mobile reflow order

---

## 5. Images & Media

### Alt Text Planning

| Image Type | Alt Text Approach |
|------------|-------------------|
| Informative | Describe content and purpose |
| Decorative | Empty alt="" |
| Functional (buttons) | Describe action |
| Complex (charts) | Brief alt + longer description |

### Icons

```tsx
// Icon with text - decorative
<Button>
  <Icon aria-hidden="true" />
  <span>Save</span>
</Button>

// Icon-only - needs label
<Button aria-label="Save">
  <Icon aria-hidden="true" />
</Button>
```

---

## 6. Forms

### Labels

- Every input needs a visible label
- Labels positioned above or to the left
- Required fields clearly marked

### Error States

```
✓ Error text near the field
✓ Color + icon/text (not color alone)
✓ Clear error message explaining fix
✓ 3:1 contrast for error indicators
```

### Validation Design

```tsx
// Accessible error pattern
<div className="form-field">
  <label htmlFor="email">
    Email <span aria-hidden="true">*</span>
    <span className="sr-only">(required)</span>
  </label>
  <input
    id="email"
    aria-describedby="email-error"
    aria-invalid="true"
  />
  <p id="email-error" className="error">
    Please enter a valid email address
  </p>
</div>
```

---

## 7. Motion & Animation

### Reduce Motion

Design alternatives for users who prefer reduced motion:

```css
@media (prefers-reduced-motion: reduce) {
  /* Remove or simplify animations */
  .animated {
    animation: none;
    transition: none;
  }
}
```

### Guidelines

- Avoid flashing content (3 flashes/second max)
- Provide pause controls for auto-playing content
- Keep animations under 5 seconds or provide stop
- Use subtle, purposeful motion

---

## 8. Accessibility Checklist

### Design Phase

- [ ] Color contrast meets WCAG AA (4.5:1 text, 3:1 UI)
- [ ] Focus states designed for all interactive elements
- [ ] Touch targets minimum 44x44px
- [ ] Heading hierarchy is logical
- [ ] Form labels and error states designed
- [ ] Icons have text labels or are decorative
- [ ] Motion has reduced-motion alternative

### Handoff Notes

Include in design specs:

- Alt text for images
- ARIA labels for icon buttons
- Heading levels
- Focus order if non-obvious
- Reduced motion behavior

## References

- [WCAG 2.1 Guidelines](https://www.w3.org/WAI/WCAG21/quickref/)
- [Figma Accessibility](https://www.figma.com/blog/design-for-everyone-with-these-accessibility-focused-plugins/)
