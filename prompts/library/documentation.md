# Documentation Standards

## Principles

- **Write for the reader** - Not for yourself or the code
- **Keep it current** - Outdated docs are worse than no docs
- **Show, don't just tell** - Examples are more useful than descriptions
- **Progressive disclosure** - Start simple, add detail as needed

## What to Document

### Always Document
- Public APIs (functions, classes, modules)
- Configuration options
- Non-obvious behaviour or edge cases
- Security considerations
- Breaking changes

### Don't Document
- Self-explanatory code (`getName` doesn't need a comment)
- Implementation details that may change
- Every line of code
- TODOs (use issue tracker instead)

## Code Comments

### Good Comments
```javascript
// Retry logic handles transient network failures
// Max 3 attempts with exponential backoff (1s, 2s, 4s)
async function fetchWithRetry(url) { ... }

// SECURITY: Validate user ID to prevent IDOR attacks
// Users should only access their own records
if (record.userId !== currentUser.id) {
  throw new ForbiddenError();
}

// NOTE: Order matters here - tax must be calculated
// after discounts are applied per regulatory requirement
```

### Bad Comments
```javascript
// Increment counter
counter++;

// Get the user
const user = getUser();

// TODO: fix this later
// FIXME: sometimes breaks
```

## README Structure

```markdown
# Project Name

Brief description (1-2 sentences)

## Quick Start

Minimal steps to get running:
\`\`\`bash
npm install
npm start
\`\`\`

## Installation

Detailed installation instructions

## Usage

Common use cases with examples

## Configuration

Available options and what they do

## API Reference

(or link to API docs)

## Contributing

How to contribute

## License

License information
```

## API Documentation

### Function Docs
```javascript
/**
 * Calculates the total price including tax and discounts.
 *
 * @param {Object} options
 * @param {number} options.basePrice - Price before adjustments
 * @param {number} [options.discount=0] - Discount percentage (0-100)
 * @param {number} [options.taxRate=0.1] - Tax rate as decimal
 * @returns {number} Final price rounded to 2 decimal places
 * @throws {RangeError} If discount is not between 0 and 100
 *
 * @example
 * calculateTotal({ basePrice: 100, discount: 20, taxRate: 0.1 })
 * // Returns: 88.00
 */
function calculateTotal(options) { ... }
```

### REST API Docs
```markdown
## Create User

`POST /api/users`

Creates a new user account.

### Request
\`\`\`json
{
  "email": "user@example.com",
  "name": "John Doe"
}
\`\`\`

### Response
\`\`\`json
{
  "id": "usr_123",
  "email": "user@example.com",
  "name": "John Doe",
  "createdAt": "2024-01-15T10:30:00Z"
}
\`\`\`

### Errors
| Code | Description |
|------|-------------|
| 400 | Invalid email format |
| 409 | Email already exists |
```

## Changelog

### Format (Keep a Changelog)
```markdown
## [1.2.0] - 2024-01-15

### Added
- User authentication via OAuth

### Changed
- Improved error messages for validation failures

### Fixed
- Memory leak in connection pool

### Deprecated
- Old authentication method (use OAuth instead)

### Removed
- Support for Node.js 14

### Security
- Updated dependencies to patch CVE-2024-XXXX
```

## Architecture Documentation

### When to Write
- System design decisions
- Integration patterns
- Data flow diagrams
- Security architecture

### Format (ADR - Architecture Decision Records)
```markdown
# ADR-001: Use PostgreSQL for User Data

## Status
Accepted

## Context
We need a database for user data. Options considered:
- PostgreSQL
- MongoDB
- MySQL

## Decision
Use PostgreSQL because:
- Strong consistency guarantees
- Team expertise
- Complex queries needed

## Consequences
- Need to manage schema migrations
- Requires separate read replicas for scale
```

## Documentation Locations

| Type | Location |
|------|----------|
| API reference | Near the code (JSDoc, docstrings) |
| Getting started | README.md |
| Architecture | docs/architecture/ |
| Operations | docs/ops/ or runbooks/ |
| Changelog | CHANGELOG.md |
| Contributing | CONTRIBUTING.md |

## Keeping Docs Current

- **Update with code changes** - Same PR/commit
- **Review docs in code review** - Check they match implementation
- **Automate where possible** - Generate API docs from code
- **Periodic review** - Schedule quarterly doc audits
- **Delete stale docs** - Wrong info is worse than missing info

## Checklist

Before completing documentation:

- [ ] Explains the "why", not just "what"
- [ ] Includes working examples
- [ ] Covers common use cases
- [ ] Documents error cases
- [ ] Has been tested (examples actually work)
- [ ] Is findable (linked from appropriate places)
- [ ] Uses consistent terminology
