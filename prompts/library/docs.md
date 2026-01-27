# Documentation

## Principles

- **Write for the reader** - Not for yourself or the code
- **Keep it current** - Outdated docs are worse than no docs
- **Show, don't tell** - Examples are more useful than descriptions
- **Progressive disclosure** - Start simple, add detail as needed

## What to Document

### Always Document
- Public APIs
- Configuration options
- Non-obvious behaviour
- Security considerations
- Breaking changes

### Don't Document
- Self-explanatory code
- Implementation details that may change
- Every line of code
- TODOs (use issue tracker)

## Code Comments

**Good comments explain WHY:**
- Retry logic and its reasoning
- Security considerations
- Business rules or regulatory requirements

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

## Keeping Docs Current

- Update with code changes (same commit)
- Review docs in code review
- Delete stale docs

## Checklist

- [ ] Explains the "why", not just "what"
- [ ] Includes working examples
- [ ] Covers common use cases
- [ ] Documents error cases
- [ ] Uses consistent terminology
