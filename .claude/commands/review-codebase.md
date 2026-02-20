---
description: Comprehensive codebase review (architecture, quality, security)
---

Run the doyaken skill: review-codebase

```bash
doyaken skill review-codebase $ARGUMENTS
```

If doyaken is not available, apply this methodology:

---

# Comprehensive Codebase Review

You are performing a comprehensive review of the codebase.

## Context

Project: {{DOYAKEN_PROJECT}}
Review scope: {{ARGS.scope}}
Path: {{ARGS.path}}
## Review Methodology

{{include:library/review.md}}

## Scope-Specific Instructions

{{#if scope == "full"}}
### Full Codebase Review

Perform a complete review covering all areas:

1. **Architecture Review**
{{include:library/review-architecture.md}}

2. **Code Quality**
{{include:library/quality.md}}

3. **Security Audit**
{{include:library/review-security.md}}

4. **Performance Analysis**
{{include:library/review-performance.md}}

5. **Documentation Review**
Check README, API docs, inline comments, and architecture docs.

{{/if}}

{{#if scope == "security"}}
### Security-Focused Review
{{include:library/review-security.md}}
{{/if}}

{{#if scope == "performance"}}
### Performance-Focused Review
{{include:library/review-performance.md}}
{{/if}}

{{#if scope == "quality"}}
### Code Quality Review
{{include:library/quality.md}}
{{include:library/review-debt.md}}
{{/if}}

## Process

### 1. Explore the Codebase

- Understand the project structure
- Identify key modules and their responsibilities
- Map dependencies between components
- Note the technology stack

### 2. Systematic Review

For the scope selected, methodically review:
- Each major module/directory
- Configuration and setup
- Entry points and APIs
- Data handling and storage

### 3. Document Findings

Use the findings ledger format:

| ID | Severity | Category | Location | Issue | Recommendation |
|----|----------|----------|----------|-------|----------------|
| 1 | [severity] | [category] | file:line | [issue] | [fix] |

Severity: blocker, high, medium, low, nit
Category: correctness, security, performance, maintainability, architecture, docs

### 4. Document Follow-Up Items

For each high or blocker severity finding, document it in the findings ledger with:
- Clear description of the issue
- Location (file:line)
- Recommended fix
- Priority based on severity

## Output

Provide a structured report:

```
## Codebase Review Report

### Summary
- Scope: {{ARGS.scope}}
- Files reviewed: [count]
- Findings: [blocker: X, high: Y, medium: Z, low: W]

### Architecture Overview
[Brief description of the codebase structure]

### Key Findings

#### Blockers
[List any blocking issues that must be fixed]

#### High Priority
[List high severity issues]

#### Medium Priority
[List medium severity issues]

#### Low Priority / Nice to Have
[List low severity improvements]

### Strengths
[What the codebase does well]

### Recommendations
[Prioritized list of improvements]

### Follow-Up Items
[List of items requiring further attention]
```
