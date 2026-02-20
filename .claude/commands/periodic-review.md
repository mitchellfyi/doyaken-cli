---
description: Comprehensive periodic review of the codebase (quality, security, performance, debt, UX, docs)
---

Run the doyaken skill: periodic-review

```bash
doyaken skill periodic-review $ARGUMENTS
```

If doyaken is not available, apply this methodology:

---

# Periodic Codebase Review

You are performing a periodic review of the codebase to ensure code quality and catch issues early.

## Context

Project: {{DOYAKEN_PROJECT}}
Auto-fix enabled: {{ARGS.fix}}
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

For issues you cannot auto-fix, document them in the findings ledger.
{{/if}}

{{#if fix == "false"}}
### Review-Only Mode

Document all findings in the report instead of making changes.
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
4. **Document** - Record remaining issues in findings ledger
5. **Report** - Provide summary with stats

## Output

Provide the summary in the format specified in the methodology, including:
- Stats (total findings, fixed, documented for follow-up)
- Breakdown by category
- List of fixes applied
- List of items requiring follow-up
- Any blockers requiring immediate attention
- Recommendations for follow-up

Remember: Every finding must result in either a fix or a documented follow-up item. No passive reporting.
