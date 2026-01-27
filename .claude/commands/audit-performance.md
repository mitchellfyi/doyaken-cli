---
description: Performance analysis and optimization recommendations
---

Run the doyaken skill: audit-performance

```bash
doyaken skill audit-performance $ARGUMENTS
```

If doyaken is not available, apply this methodology:

---

# Performance Audit

You are performing a performance analysis of the codebase.

## Context

Project: {{DOYAKEN_PROJECT}}
Analysis path: {{ARGS.path}}
Create follow-up tasks: {{ARGS.create-tasks}}

## Performance Review Framework

{{include:library/review-performance.md}}

## Audit Process

### 1. Profile the Application

If possible, run profiling:

```bash
# Node.js
node --prof app.js
# Then analyze: node --prof-process isolate-*.log

# Python
python -m cProfile -o output.prof script.py
# Or use py-spy: py-spy record -o profile.svg -- python script.py

# Go
go test -bench=. -cpuprofile=cpu.out
go tool pprof cpu.out
```

### 2. Code Analysis

Look for common performance issues:

**Algorithmic Complexity:**
- [ ] Nested loops (O(n²) or worse)
- [ ] Repeated expensive operations in loops
- [ ] Missing memoization for recursive functions
- [ ] Inefficient data structure choices

**Database/IO:**
- [ ] N+1 query patterns
- [ ] Missing indexes on queried columns
- [ ] Unbounded queries (no LIMIT)
- [ ] Synchronous IO where async is possible
- [ ] Missing connection pooling

**Memory:**
- [ ] Large objects held in memory unnecessarily
- [ ] Memory leaks (unclosed resources, growing caches)
- [ ] Inefficient string concatenation
- [ ] Large arrays being copied

**Network:**
- [ ] Missing request batching
- [ ] No caching of repeated external calls
- [ ] Missing timeouts on external requests
- [ ] Blocking on external services

### 3. Measure Baselines

If applicable, establish baselines:

```
| Operation | Current | Target | Notes |
|-----------|---------|--------|-------|
| Startup time | [X]s | [Y]s | |
| [Common operation] | [X]ms | [Y]ms | |
| Memory usage | [X]MB | [Y]MB | |
| Bundle size | [X]KB | [Y]KB | |
```

### 4. Document Findings

For each issue:

```
### Issue: [Title]

**Severity**: Critical / High / Medium / Low
**Category**: Algorithm / Database / Memory / Network / Startup
**Location**: `file:line`

**Current Impact**:
- [Measured or estimated impact]
- [User-facing symptom]

**Root Cause**:
[Why this is slow]

**Recommendation**:
[How to fix]

**Expected Improvement**:
[Estimated gain]
```

### 5. Create Tasks

{{#if create-tasks == "true"}}
Create tasks for significant improvements:

- Priority 002 for high-impact, user-facing issues
- Priority 003 for moderate improvements
- Priority 004 for micro-optimizations

Task filename: `[priority]-XXX-perf-[slug].md`
{{/if}}

## Output

```
## Performance Audit Report

### Summary
- Scope: {{ARGS.path}}
- Date: [date]
- Critical issues: [count]
- Optimization opportunities: [count]

### Performance Profile

**Current State:**
- [Key metrics if available]

**Bottlenecks Identified:**
1. [Most impactful issue]
2. [Second most impactful]
3. [Third most impactful]

### Detailed Findings

#### Critical Performance Issues
[Issues causing significant user impact]

#### High-Impact Optimizations
[Changes that would noticeably improve performance]

#### Medium-Impact Optimizations
[Worthwhile improvements]

#### Micro-optimizations
[Small improvements, do if touching the code anyway]

### Recommendations

**Quick Wins (Low effort, high impact):**
1. [optimization]

**Medium-term Improvements:**
1. [optimization]

**Architectural Changes:**
1. [larger changes if needed]

### Benchmarking Suggestions

To measure improvements:
```bash
# [Commands to benchmark]
```

### Tasks Created
[List of task files created]
```
