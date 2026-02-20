---
name: periodic-review
description: Comprehensive periodic review of the codebase (quality, security, performance, debt, UX, docs)
args:
  - name: fix
    description: Auto-fix issues where possible (disable with fix=false to only report)
    default: "true"
  - name: create-prompts
    description: Generate dk run prompts for issues that require manual intervention
    default: "true"
  - name: scope
    description: Review scope (all, quality, security, performance, debt, ux, docs)
    default: "all"
---

# Periodic Codebase Review

You are performing a periodic review of the codebase to ensure code quality and catch issues early.

## Context

Project: {{DOYAKEN_PROJECT}}
Auto-fix enabled: {{ARGS.fix}}
Create prompts: {{ARGS.create-prompts}}
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

For issues you cannot auto-fix, generate `dk run` prompts to address them.
{{/if}}

{{#if fix == "false"}}
### Review-Only Mode

Document all findings and generate `dk run` prompts instead of making changes.
{{/if}}

{{#if create-prompts == "false"}}
### No Prompt Generation

Do not generate follow-up prompts. Only report findings in the summary output.
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
4. **Document** - Generate dk run prompts for remaining issues
5. **Report** - Provide summary with stats

## Output

Provide the summary in the format specified in the methodology, including:
- Stats (total findings, fixed, prompts generated)
- Breakdown by category
- List of fixes applied
- List of dk run prompts for remaining issues
- Any blockers requiring immediate attention
- Recommendations for follow-up

Remember: Every finding must result in either a fix or a dk run prompt. No passive reporting.
