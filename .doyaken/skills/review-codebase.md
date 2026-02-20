---
name: review-codebase
description: Comprehensive codebase review (architecture, quality, security)
args:
  - name: scope
    description: What to review (full, security, performance, quality, path)
    default: "full"
  - name: path
    description: Path to review (for scope=path)
    default: "."
  - name: create-prompts
    description: Generate dk run prompts for findings
    default: "true"
---

# Comprehensive Codebase Review

You are performing a comprehensive review of the codebase.

## Context

Project: {{DOYAKEN_PROJECT}}
Review scope: {{ARGS.scope}}
Path: {{ARGS.path}}
Generate follow-up prompts: {{ARGS.create-prompts}}

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

### 4. Generate Follow-Up Prompts

{{#if create-prompts == "true"}}
For each high or blocker severity finding, generate a `dk run` prompt:

Include in each prompt:
- Clear description of the issue
- Location (file:line)
- Recommended fix
- Priority based on severity
{{/if}}

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

### Follow-Up Prompts
[List of dk run prompts for remaining issues, if any]
```
