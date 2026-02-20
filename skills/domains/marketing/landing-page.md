---
name: landing-page
description: Generate a landing page with hero, features, and CTA sections
args:
  - name: product
    description: Product or feature name
    required: true
  - name: style
    description: Visual style (minimal, bold, corporate)
    default: minimal
---

# Landing Page Generation

Create a landing page for **{{ARGS.product}}** with a **{{ARGS.style}}** visual style.

## Required Sections

1. **Hero** - Headline, subheadline, primary CTA button
2. **Features** - 3-4 feature cards with icons and descriptions
3. **Social Proof** - Testimonials or trust badges placeholder
4. **CTA** - Final call-to-action with email capture or sign-up

## Requirements

- Responsive layout (mobile-first)
- Semantic HTML with accessibility attributes
- Performance: lazy-load images, minimal JS
- SEO: meta tags, Open Graph, structured data
- Follow existing project styling conventions
