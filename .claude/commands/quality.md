---
description: Apply quality methodology
---

# Code Quality

## Core Principles

### KISS (Keep It Simple)
The simplest solution is usually the best. Complexity is the enemy of reliability.

- Prefer straightforward logic over clever tricks
- If code needs comments to explain, it's probably too complex
- Break complex functions into smaller, focused ones
- Avoid premature abstraction

### YAGNI (You Aren't Gonna Need It)
Don't build features or abstractions until you actually need them.

- No speculative features
- No "just in case" parameters
- No unused abstractions
- Delete dead code immediately

### DRY (Don't Repeat Yourself)
Every piece of knowledge should have a single, authoritative source.

- Extract repeated logic into functions
- Use constants for magic values
- Centralize configuration
- But: Don't over-DRY - some duplication is acceptable if it keeps code simple

### SOLID Principles

| Principle | Meaning |
|-----------|---------|
| **S**ingle Responsibility | Each function/class does one thing |
| **O**pen/Closed | Extend behavior without changing existing code |
| **L**iskov Substitution | Derived classes honor base class contracts |
| **I**nterface Segregation | Small, focused interfaces over large ones |
| **D**ependency Inversion | Depend on abstractions, not details |

## Quality Checklist

### Readability
- [ ] Names clearly describe intent
- [ ] Functions are short (< 20 lines ideal)
- [ ] Nesting depth ≤ 3 levels
- [ ] Consistent formatting

### Maintainability
- [ ] No hardcoded values
- [ ] No magic numbers
- [ ] Clear separation of concerns
- [ ] Easy to test in isolation

### Reliability
- [ ] All error paths handled
- [ ] No silent failures
- [ ] Defensive input validation at boundaries
- [ ] Timeouts on external calls

## Anti-Patterns

| Anti-Pattern | Problem | Better |
|--------------|---------|--------|
| **God Object** | One class does everything | Split into focused classes |
| **Spaghetti Code** | Tangled control flow | Clear structure, early returns |
| **Copy-Paste** | Duplicated code | Extract shared logic |
| **Premature Optimization** | Complexity without need | Make it work, then profile |
| **Gold Plating** | Features nobody asked for | Stick to requirements |

## Quality Gates

Every change should pass the project's quality checks:

- **Lint** - catch style and potential errors
- **Type check** - catch type errors (if applicable)
- **Test** - verify behavior
- **Build** - ensure it compiles (if applicable)

Discover specific commands during triage by checking project configuration.

---

Apply this methodology to the current context. If given a specific file or code, analyze it according to these guidelines.
