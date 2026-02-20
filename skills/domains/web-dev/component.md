---
name: component
description: Generate a UI component with tests and documentation
args:
  - name: name
    description: Component name (PascalCase)
    required: true
  - name: framework
    description: UI framework to use
    default: react
---

# Component Generation

Create a new UI component named **{{ARGS.name}}** using **{{ARGS.framework}}**.

## Requirements

1. Create the component file with proper TypeScript types
2. Add unit tests covering key behaviors
3. Include a Storybook story or usage example
4. Follow existing project conventions for styling and file structure

## Component Structure

- Props interface with JSDoc comments
- Default export of the component
- Named exports for sub-components if applicable
- Error boundary handling where appropriate

## Quality Checklist

- [ ] Component renders without errors
- [ ] Props are properly typed
- [ ] Tests cover happy path and edge cases
- [ ] Accessibility: proper ARIA attributes, keyboard navigation
- [ ] Responsive design considerations
