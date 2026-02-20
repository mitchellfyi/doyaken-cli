---
name: email-template
description: Generate an email template with responsive HTML layout
args:
  - name: type
    description: Email type (welcome, newsletter, transactional)
    required: true
  - name: subject
    description: Email subject line
    default: ""
---

# Email Template Generation

Create a **{{ARGS.type}}** email template.

## Requirements

1. Responsive HTML email layout (table-based for compatibility)
2. Inline CSS (no external stylesheets)
3. Dark mode support via media queries
4. Placeholder content with clear variable markers
5. Unsubscribe link and footer with company info
6. Preview text / preheader

## Compatibility

- Gmail, Outlook, Apple Mail, Yahoo Mail
- Mobile email clients (iOS Mail, Gmail app)
- Test with Litmus or Email on Acid guidelines

## Content Sections

- Header with logo placeholder
- Main content area
- CTA button (bulletproof button technique)
- Footer with social links and legal text
