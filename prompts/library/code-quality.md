# Code Quality Principles

## Core Principles

### KISS (Keep It Simple, Stupid)
The simplest solution is usually the best. Complexity is the enemy of reliability.

- Prefer straightforward logic over clever tricks
- If code needs comments to explain, it's probably too complex
- Break complex functions into smaller, focused ones
- Avoid premature abstraction

**Ask:** "Is there a simpler way to do this?"

### YAGNI (You Aren't Gonna Need It)
Don't build features or abstractions until you actually need them.

- No speculative features
- No "just in case" parameters
- No unused abstractions
- Delete dead code immediately

**Ask:** "Do I need this right now?"

### DRY (Don't Repeat Yourself)
Every piece of knowledge should have a single, authoritative source.

- Extract repeated logic into functions
- Use constants for magic values
- Centralize configuration
- But: Don't over-DRY - some duplication is acceptable if it keeps code simple

**Ask:** "If this changes, how many places need updating?"

### SOLID Principles

| Principle | Meaning | Guideline |
|-----------|---------|-----------|
| **S**ingle Responsibility | One reason to change | Each function/class does one thing |
| **O**pen/Closed | Open for extension, closed for modification | Extend behavior without changing existing code |
| **L**iskov Substitution | Subtypes must be substitutable | Derived classes honor base class contracts |
| **I**nterface Segregation | No forced dependencies | Small, focused interfaces over large ones |
| **D**ependency Inversion | Depend on abstractions | High-level modules don't depend on low-level details |

## Code Quality Checklist

### Readability
- [ ] Names clearly describe intent (`getUserById` not `getData`)
- [ ] Functions are short (< 20 lines ideal, < 50 max)
- [ ] Nesting depth ≤ 3 levels
- [ ] No abbreviations except well-known ones (URL, ID, etc.)
- [ ] Consistent formatting (enforced by linter)

### Maintainability
- [ ] No hardcoded values (use constants/config)
- [ ] No magic numbers (use named constants)
- [ ] Clear separation of concerns
- [ ] Minimal dependencies between modules
- [ ] Easy to test in isolation

### Reliability
- [ ] All error paths handled
- [ ] No silent failures
- [ ] Defensive input validation at boundaries
- [ ] Graceful degradation where appropriate
- [ ] Timeouts on external calls

### Performance (only when measured)
- [ ] No premature optimization
- [ ] O(n²) or worse algorithms flagged
- [ ] Database queries optimized (no N+1)
- [ ] Appropriate caching where beneficial

## Anti-Patterns to Avoid

| Anti-Pattern | Problem | Better |
|--------------|---------|--------|
| **God Object** | One class does everything | Split into focused classes |
| **Spaghetti Code** | Tangled control flow | Clear structure, early returns |
| **Copy-Paste Programming** | Duplicated code everywhere | Extract shared logic |
| **Premature Optimization** | Complexity without measured need | Make it work, then profile |
| **Gold Plating** | Features nobody asked for | Stick to requirements |
| **Cargo Cult** | Patterns without understanding | Understand why before applying |
| **Stringly Typed** | Strings for everything | Use proper types/enums |
| **Boolean Blindness** | `doThing(true, false, true)` | Use named parameters or objects |

## Quality Gates

Every commit should pass:

```bash
# Lint - catch style and potential errors
npm run lint        # or: eslint, ruff, golint

# Type check - catch type errors
npm run typecheck   # or: tsc, mypy, go vet

# Test - verify behavior
npm run test        # unit + integration tests

# Build - ensure it compiles
npm run build       # if applicable
```

### Pre-commit Hook
```bash
#!/bin/bash
npm run lint && npm run typecheck && npm run test
```

### CI Pipeline
```yaml
# .github/workflows/ci.yml
name: CI
on: [push, pull_request]
jobs:
  quality:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
      - run: npm ci
      - run: npm run lint
      - run: npm run typecheck
      - run: npm run test
      - run: npm run build
```

## References

- [Clean Code by Robert Martin](https://www.oreilly.com/library/view/clean-code-a/9780136083238/)
- [SOLID Principles](https://en.wikipedia.org/wiki/SOLID)
- [The Pragmatic Programmer](https://pragprog.com/titles/tpp20/the-pragmatic-programmer-20th-anniversary-edition/)
- [Refactoring by Martin Fowler](https://refactoring.com/)
- [Code Complete by Steve McConnell](https://www.oreilly.com/library/view/code-complete-2nd/0735619670/)
