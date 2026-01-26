---
name: react:component-review
description: Review React components for best practices
args:
  - name: file
    description: Component file to review
    default: ""
  - name: thorough
    description: Include performance analysis
    default: "false"
---

# React Component Review

You are reviewing a React component for best practices.

## Context

Project: {{DOYAKEN_PROJECT}}
File: {{ARGS.file}}
Thorough: {{ARGS.thorough}}

## Review Process

### 1. Read Component

Read the component file and understand:
- Purpose and functionality
- Props interface
- State management
- Side effects

### 2. Check Best Practices

{{include:vendors/react/components.md}}

**Component Structure**
- [ ] Single responsibility
- [ ] Clear prop types
- [ ] Appropriate size
- [ ] Proper file organization

**Hooks Usage**
- [ ] Rules of hooks followed
- [ ] Dependencies correct
- [ ] Custom hooks for reuse
- [ ] No unnecessary effects

{{include:vendors/react/hooks.md}}

**State Management**
- [ ] Minimal state
- [ ] Appropriate lifting
- [ ] No derived state stored
- [ ] Proper context usage

{{include:vendors/react/state-management.md}}

{{#if thorough == "true"}}
### 3. Performance Analysis

- [ ] Unnecessary re-renders
- [ ] Memoization opportunities
- [ ] Large component trees
- [ ] Bundle impact
{{/if}}

### 4. Accessibility

- [ ] Semantic HTML
- [ ] ARIA attributes
- [ ] Keyboard navigation
- [ ] Focus management

## Output

```markdown
## Component Review: {{ARGS.file}}

### Summary
**Overall**: Good / Needs Work / Issues Found
**Complexity**: Low / Medium / High

### Strengths
- [What's done well]

### Issues

| Severity | Issue | Line | Suggestion |
|----------|-------|------|------------|
| High | [issue] | [line] | [fix] |
| Medium | [issue] | [line] | [fix] |

### Recommendations
1. [Priority fixes]

### Code Suggestions
```tsx
// Before
[current code]

// After
[improved code]
```

{{#if thorough == "true"}}
### Performance Notes
- [Re-render analysis]
- [Memoization opportunities]
{{/if}}
```
