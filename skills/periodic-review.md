---
name: periodic-review
description: Comprehensive periodic review of the codebase (quality, security, performance, debt, UX, docs)
args:
  - name: fix
    description: Enable auto-fix mode for issues that can be automatically resolved
    default: "false"
  - name: create-tasks
    description: Create follow-up tasks for issues that require manual intervention
    default: "true"
  - name: scope
    description: Review scope (all, quality, security, performance, debt, ux, docs)
    default: "all"
---

# Periodic Codebase Review

You are performing a periodic review of the codebase. This review runs automatically after completing a threshold of tasks to ensure code quality and catch issues early.

## Context

Project: {{DOYAKEN_PROJECT}}
Auto-fix enabled: {{ARGS.fix}}
Create tasks: {{ARGS.create-tasks}}
Scope: {{ARGS.scope}}

## Review Methodology

{{include:library/review-all.md}}

## Execution Mode

{{#if fix == "true"}}
### Auto-Fix Mode Active

You MUST automatically fix issues where possible:
- Run formatters and linters
- Fix unused imports and variables
- Correct obvious typos
- Add missing error handling
- Update simple dependencies

For issues you cannot auto-fix, create tasks.
{{/if}}

{{#if fix == "false"}}
### Review-Only Mode

Document all findings but create tasks instead of making changes.
Each finding should result in a task in `.doyaken/tasks/2.todo/`.
{{/if}}

{{#if create-tasks == "false"}}
### No Task Creation

Do not create task files. Only report findings in the summary output.
{{/if}}

## Scope-Specific Instructions

{{#if scope == "all"}}
Execute the full review sequence as defined in the methodology.
{{/if}}

{{#if scope == "quality"}}
Focus only on code quality:
{{include:library/quality.md}}
{{/if}}

{{#if scope == "security"}}
Focus only on security:
{{include:library/review-security.md}}
{{/if}}

{{#if scope == "performance"}}
Focus only on performance:
{{include:library/review-performance.md}}
{{/if}}

{{#if scope == "debt"}}
Focus only on technical debt:
{{include:library/review-debt.md}}
{{/if}}

{{#if scope == "ux"}}
Focus only on UX:
{{include:library/review-ux.md}}
{{/if}}

{{#if scope == "docs"}}
Focus only on documentation:
{{include:library/review-docs.md}}
{{/if}}

## Process

1. **Explore** - Understand current codebase state
2. **Analyze** - Apply review methodology for scope
3. **Fix** - Auto-fix where possible (if enabled)
4. **Document** - Create tasks for remaining issues
5. **Report** - Provide summary with stats

## Output

Provide the summary in the format specified in the methodology, including:
- Stats (total findings, fixed, tasks created)
- Breakdown by category
- List of fixes applied
- List of tasks created
- Any blockers requiring immediate attention
- Recommendations for follow-up

Remember: Every finding must result in either a fix or a task. No passive reporting.
