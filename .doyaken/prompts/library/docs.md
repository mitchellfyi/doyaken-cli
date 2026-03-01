# Documentation

Documentation is updated in the same commit as the code change, not later.

**Priority order:** API docs > README > Architecture/config docs > Inline comments > Changelog

## Principles

- **Write for the reader** — not for yourself or the code
- **Keep it current** — outdated docs actively mislead; they're worse than no docs
- **Show, don't tell** — working examples over prose descriptions
- **Progressive disclosure** — start with the simplest use case, then cover advanced scenarios

## What to Document

### Always Document
- New public APIs and their usage (with examples)
- Changed behaviour (especially breaking changes)
- Configuration options (purpose, type, default value, valid range)
- Environment variables and their expected values
- Non-obvious business logic, security considerations, or architectural decisions
- Migration steps for breaking changes

### Don't Document
- Self-explanatory code
- Implementation details that will change
- Every line of code
- Anything the type system or test names already communicate

## Code Comments

Comments explain **WHY**, not **WHAT** — if the code needs a comment explaining what it does, simplify the code.

**Good comments explain WHY:**
- Retry logic and its reasoning
- Security considerations
- Business rules or regulatory requirements
- Trade-offs and constraints

**Bad comments state the obvious:**
- "Increment counter"
- "Get the user"
- "TODO: fix this later"

## Documentation Locations

| Type | Location |
|------|----------|
| API reference | Near the code |
| Getting started | README.md |
| Architecture | docs/architecture/ |
| Changelog | CHANGELOG.md |
| Config options | README or dedicated config docs |

## Keeping Docs Current

- Update with code changes (same commit)
- Review docs in code review
- Delete stale documentation — don't leave outdated instructions around
- Verify docs match the actual implementation by testing examples

## Checklist

- [ ] Explains the "why", not just "what"
- [ ] Includes working, tested examples
- [ ] Covers common use cases
- [ ] Documents error cases
- [ ] Uses consistent terminology
- [ ] Configuration options include type, default, and valid range
- [ ] Environment variables documented
- [ ] Breaking changes have migration guides
