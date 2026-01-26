---
name: github-actions:optimize
description: Optimize GitHub Actions workflow performance
args:
  - name: workflow
    description: Workflow file to optimize
    default: ""
---

# Optimize GitHub Actions Workflow

You are optimizing GitHub Actions workflows for better performance.

## Context

Project: {{DOYAKEN_PROJECT}}
Workflow: {{ARGS.workflow}}

## Optimization Process

### 1. Analyze Current Workflows

{{#if workflow}}
Read and analyze: `.github/workflows/{{ARGS.workflow}}`
{{else}}
Scan all workflows in `.github/workflows/`
{{/if}}

Measure current metrics:
- Total workflow duration
- Individual job durations
- Cache hit rates
- Billable minutes

### 2. Apply Optimizations

{{include:vendors/github-actions/optimization.md}}

**Key Optimization Areas:**

**Caching**
- Add/improve dependency caching
- Cache build outputs
- Use restore-keys for partial matches

**Parallelization**
- Split independent jobs
- Use matrix strategies
- Run tests in parallel

**Job Dependencies**
- Use `needs` to sequence properly
- Avoid unnecessary waiting
- Fail fast for critical paths

**Runner Selection**
- Use larger runners for heavy jobs
- Match runner to workload
- Consider self-hosted for frequent runs

**Step Optimization**
- Combine related steps
- Use composite actions
- Skip unnecessary steps with conditions

### 3. Security Audit

While optimizing, also check:

{{include:vendors/github-actions/security.md}}

### 4. Measure Improvement

Compare before/after:
- Workflow duration
- Billable time
- Cache efficiency

## Output

```markdown
## Workflow Optimization Report

**Workflows Analyzed**: [count]

### Optimizations Applied

| Workflow | Optimization | Impact |
|----------|--------------|--------|
| ci.yml | Added dependency caching | -2min |
| ci.yml | Parallelized test jobs | -3min |
| deploy.yml | Optimized Docker layer caching | -5min |

### Before/After

| Metric | Before | After | Change |
|--------|--------|-------|--------|
| CI Duration | 12min | 6min | -50% |
| Cache Hit Rate | 60% | 95% | +35% |
| Monthly Minutes | 500 | 250 | -50% |

### Changes Made
- [File]: [Description of changes]

### Recommendations
- [Additional improvements not yet applied]
```
