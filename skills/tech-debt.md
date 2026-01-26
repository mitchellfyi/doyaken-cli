---
name: tech-debt
description: Technical debt assessment and prioritization
args:
  - name: path
    description: Path to assess
    default: "."
  - name: create-tasks
    description: Create tasks for debt items
    default: "true"
---

# Technical Debt Assessment

You are assessing technical debt in the codebase.

## Context

Project: {{DOYAKEN_PROJECT}}
Assessment path: {{ARGS.path}}
Create follow-up tasks: {{ARGS.create-tasks}}

## Assessment Framework

{{include:library/technical-debt.md}}

## Assessment Process

### 1. Automated Analysis

Run analysis tools:

```bash
# Code complexity
npx eslint . --format json | jq '[.[] | .messages[]] | length'  # JS
radon cc . -a -s  # Python

# Lines of code / file sizes
tokei .
find . -name "*.ts" -exec wc -l {} + | sort -n | tail -20

# TODO/FIXME comments
grep -rn "TODO\|FIXME\|HACK\|XXX" --include="*.{js,ts,py,go}" .

# Test coverage
npm test -- --coverage  # or pytest --cov
```

### 2. Code Debt Inventory

Search for:

- [ ] Duplicated code blocks (> 10 lines similar)
- [ ] Functions > 50 lines
- [ ] Files > 500 lines
- [ ] Cyclomatic complexity > 10
- [ ] Deep nesting > 3 levels
- [ ] God classes (classes with too many responsibilities)
- [ ] Dead code / unused exports
- [ ] Commented-out code
- [ ] Magic numbers/strings

### 3. Architecture Debt Inventory

Identify:

- [ ] Circular dependencies
- [ ] Tight coupling between modules
- [ ] Missing abstractions
- [ ] Leaky abstractions
- [ ] Inconsistent patterns across codebase

### 4. Test Debt Inventory

Assess:

- [ ] Overall test coverage percentage
- [ ] Critical paths without tests
- [ ] Flaky tests
- [ ] Tests without assertions
- [ ] Missing integration tests
- [ ] Test suite run time

### 5. Dependency Debt

Check:

```bash
# Outdated packages
npm outdated  # JavaScript
pip list --outdated  # Python

# Vulnerabilities
npm audit
pip-audit
```

### 6. Prioritize Findings

Use the Interest/Principal matrix:

| Debt Item | Interest Rate | Principal | Priority |
|-----------|---------------|-----------|----------|
| [item] | High/Med/Low | S/M/L | 1-5 |

**Interest Rate** = How much this slows development
**Principal** = Effort to fix

Focus on: High interest, small principal first (quick wins)

### 7. Create Tasks

{{#if create-tasks == "true"}}
Create tasks for high-priority debt:

- Priority 002: High interest debt
- Priority 003: Medium interest debt
- Priority 004: Low interest debt

Include "technical-debt" label in the task.
{{/if}}

## Output

```
## Technical Debt Assessment

### Summary
- Total debt items identified: [count]
- Quick wins: [count]
- Major refactors needed: [count]
- Estimated total cleanup: [rough estimate]

### Debt Inventory

#### Code Debt
| Location | Issue | Interest | Principal | Priority |
|----------|-------|----------|-----------|----------|
| file:line | [issue] | High/Med/Low | S/M/L | 1-5 |

#### Architecture Debt
| Area | Issue | Interest | Principal | Priority |
|------|-------|----------|-----------|----------|
| [module] | [issue] | High/Med/Low | S/M/L | 1-5 |

#### Test Debt
- Current coverage: [X]%
- Target coverage: [Y]%
- Flaky tests: [count]
- Missing test areas: [list]

#### Dependency Debt
| Dependency | Current | Latest | Risk |
|------------|---------|--------|------|
| [name] | [ver] | [ver] | High/Med/Low |

### Quick Wins
[Tasks that can be done quickly with high impact]

1. [debt item] - Est: [time]
2. [debt item] - Est: [time]
3. [debt item] - Est: [time]

### Recommended Roadmap

**Sprint 1 (Quick Wins):**
- [items]

**Sprint 2-3 (Medium Items):**
- [items]

**Future (Large Refactors):**
- [items]

### Debt Prevention

Recommendations to prevent future debt:
- [practice]
- [process]
- [tooling]

### Tasks Created
[List of task files created]
```
