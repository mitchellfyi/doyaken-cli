# Technical Debt Assessment

## Mindset

- Technical debt is a tool, not inherently bad
- Distinguish deliberate debt (conscious trade-offs) from accidental debt (oversights)
- Prioritize by business impact, not just code smell severity
- Some debt is fine to keep - focus on high-interest debt

## Types of Technical Debt

### 1. Code Debt
- Duplicated code
- Complex/hard-to-understand code
- Dead code
- Inconsistent naming/style
- Missing error handling
- Magic numbers/strings

### 2. Architecture Debt
- Tight coupling between modules
- Missing abstractions
- Inappropriate patterns
- Circular dependencies
- God classes/modules

### 3. Test Debt
- Missing test coverage
- Flaky tests
- Slow test suite
- Tests that don't test behavior
- No integration tests

### 4. Documentation Debt
- Missing/outdated README
- No API documentation
- Undocumented complex logic
- Missing architecture decision records
- Stale comments

### 5. Dependency Debt
- Outdated dependencies
- Vulnerable dependencies
- Too many dependencies
- Deprecated API usage
- Missing dependency updates

### 6. Infrastructure Debt
- Manual deployment steps
- Missing CI/CD
- No monitoring/alerting
- Inconsistent environments
- Missing backups/disaster recovery

## Assessment Process

### 1. Code Analysis

Run automated tools:
```bash
# JavaScript/TypeScript
npx eslint . --format json
npx madge --circular .  # circular dependencies

# Python
ruff check . --output-format json
radon cc . -j  # cyclomatic complexity

# General
tokei .  # lines of code by language
```

### 2. Manual Review

Check for:
- TODO/FIXME/HACK comments
- Commented-out code
- Obvious code duplication
- Functions > 50 lines
- Files > 500 lines
- Deep nesting (> 3 levels)
- Complex conditionals

### 3. Test Coverage

```bash
# JavaScript
npm test -- --coverage

# Python
pytest --cov=. --cov-report=json

# Go
go test -coverprofile=coverage.out ./...
```

### 4. Dependency Audit

```bash
# JavaScript
npm audit
npm outdated

# Python
pip-audit
pip list --outdated

# General
dependabot/renovate reports
```

## Debt Categorization

### Interest Rate (How Much It Costs)

| Rate | Description | Examples |
|------|-------------|----------|
| **High** | Slows every change, causes bugs | Circular deps, no tests, god classes |
| **Medium** | Slows some changes | Duplication, outdated deps |
| **Low** | Minor friction | Style issues, minor complexity |

### Principal (Effort to Fix)

| Size | Description | Examples |
|------|-------------|----------|
| **Large** | Weeks/months | Architecture redesign |
| **Medium** | Days/weeks | Refactor module, add test coverage |
| **Small** | Hours/days | Fix linting, update dependency |

### Priority Matrix

```
                    High Interest
                         │
         ┌───────────────┼───────────────┐
         │   URGENT      │   STRATEGIC   │
         │  Fix ASAP     │  Plan & Fix   │
Small ───┼───────────────┼───────────────┼─── Large
Principal│   QUICK WIN   │   BACKLOG     │   Principal
         │  Fix when     │  Track, fix   │
         │  nearby       │  opportunist. │
         └───────────────┼───────────────┘
                         │
                    Low Interest
```

## Assessment Template

```
## Technical Debt Assessment

### Summary
- Total debt items: [count]
- High interest: [count]
- Quick wins: [count]
- Estimated cleanup effort: [hours/days]

### Code Debt

| Item | Location | Interest | Principal | Priority |
|------|----------|----------|-----------|----------|
| [issue] | [file:line] | High/Med/Low | S/M/L | [1-5] |

### Architecture Debt

| Item | Impact | Interest | Principal | Priority |
|------|--------|----------|-----------|----------|
| [issue] | [what it affects] | High/Med/Low | S/M/L | [1-5] |

### Test Debt

- Coverage: [percentage]
- Missing tests for: [critical paths]
- Flaky tests: [count]

### Dependency Debt

| Dependency | Current | Latest | Risk | Priority |
|------------|---------|--------|------|----------|
| [name] | [version] | [version] | High/Med/Low | [1-5] |

### Documentation Debt

- [ ] README accurate and complete
- [ ] API documentation exists
- [ ] Architecture documented
- [ ] Setup instructions work

### Recommendations

**Urgent (This Sprint)**
1. [high interest, small principal items]

**Plan (This Quarter)**
1. [high interest, larger principal items]

**Opportunistic (When Nearby)**
1. [medium interest items to fix when touching related code]

**Track (Future)**
1. [low priority items to keep on radar]
```

## Quick Wins Checklist

Easy fixes with high impact:

- [ ] Remove dead code and commented-out code
- [ ] Fix all linting errors
- [ ] Update dependencies with security vulnerabilities
- [ ] Add missing error handling to critical paths
- [ ] Document the most confusing function
- [ ] Extract the largest duplicated code block
- [ ] Add tests for the most critical untested function
