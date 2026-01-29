# Documentation Review

## Mindset

- Documentation is the first impression for new developers
- Outdated docs are worse than no docs (they mislead)
- Examples are more valuable than descriptions
- Keep it concise - developers skim, not read

## Scope

### README.md

- [ ] Project purpose clear in first paragraph
- [ ] Quick start works (tested, not just written)
- [ ] Prerequisites listed and accurate
- [ ] Installation steps current
- [ ] Basic usage examples present
- [ ] Links to detailed docs if needed

### API Documentation

- [ ] All public endpoints documented
- [ ] Request/response examples for each
- [ ] Error codes and meanings
- [ ] Authentication explained
- [ ] Rate limits documented
- [ ] Versioning strategy clear

### Architecture Docs

- [ ] High-level system diagram exists
- [ ] Key components and their purpose
- [ ] Data flow explained
- [ ] External dependencies listed
- [ ] Deployment topology documented

### Code Comments

- [ ] Complex algorithms explained
- [ ] Non-obvious business logic documented
- [ ] TODO/FIXME items are actionable and dated
- [ ] No commented-out code
- [ ] No redundant comments (code should be self-documenting)

### Configuration

- [ ] All config options documented
- [ ] Default values explained
- [ ] Environment variables listed
- [ ] Secrets handling documented

## Common Issues

### Stale Documentation

- [ ] Version numbers match current release
- [ ] Deprecated features removed or marked
- [ ] Screenshots/examples match current UI
- [ ] File paths and structure accurate

### Missing Documentation

- [ ] New features documented
- [ ] Breaking changes in changelog
- [ ] Migration guides for major versions
- [ ] Troubleshooting section exists

### Quality Issues

- [ ] No broken links
- [ ] Consistent formatting
- [ ] Grammar and spelling correct
- [ ] Code examples are valid and tested

## Finding Format

```
### Finding: [Title]

**Severity**: High / Medium / Low
**Category**: missing | stale | incomplete | incorrect
**Location**: file:line or section

**Description**: [What is wrong or missing]
**Impact**: [How this affects users/developers]
**Remediation**: [Specific fix or addition needed]
```

## Priority Guide

1. **High**: Missing or incorrect installation/quick start
2. **High**: Wrong API documentation that would cause errors
3. **Medium**: Missing examples for complex features
4. **Medium**: Outdated screenshots or version numbers
5. **Low**: Typos and formatting issues
6. **Low**: Missing optional configuration docs
