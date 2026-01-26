---
name: feature-discover
description: Research and discover the next best feature to build
args:
  - name: scope
    description: Discovery scope (full, competitors, gaps, ux)
    default: "full"
  - name: create-tasks
    description: Create feature tasks from findings
    default: "true"
---

# Feature Discovery

You are researching and identifying the best features to implement next.

## Context

Project: {{DOYAKEN_PROJECT}}
Discovery scope: {{ARGS.scope}}
Create follow-up tasks: {{ARGS.create-tasks}}

## Discovery Framework

{{include:library/feature-discovery.md}}

## Discovery Process

### 1. Understand Current State

First, understand what the project currently offers:

- Read README and documentation
- List current features and capabilities
- Identify the target user/use case
- Note the project's unique value proposition

### 2. Scope-Specific Research

{{#if scope == "full"}}
#### Full Discovery

**A. Competitor Analysis**
{{include:library/competitor-analysis.md}}

Research 3-5 similar projects:
- What features do they have that we don't?
- What are users complaining about with them?
- What's their roadmap/recent additions?

**B. Industry Trends**
- What new technologies could we leverage?
- What are emerging best practices?
- What's changing in user expectations?

**C. Gap Analysis**
- What's missing from our feature set?
- What do users work around?
- What would make the biggest impact?

**D. User Value Assessment**
- Which features would benefit most users?
- What would reduce friction the most?
- What could be a differentiator?
{{/if}}

{{#if scope == "competitors"}}
#### Competitor Analysis Focus
{{include:library/competitor-analysis.md}}

Deep dive into competitors:
1. Identify 3-5 direct competitors
2. Document their feature sets
3. Analyze user feedback about them
4. Find gaps and opportunities
{{/if}}

{{#if scope == "gaps"}}
#### Missing Features Analysis

Based on the project type, identify expected features:

1. Research standard features for this type of project
2. Check community expectations (awesome lists, discussions)
3. Review GitHub issues for feature requests
4. Check documentation for mentioned but unimplemented features
{{/if}}

{{#if scope == "ux"}}
#### UX Improvement Focus
{{include:library/ux-review.md}}

Focus on user experience:
1. First-run experience
2. Common workflows
3. Error handling and messages
4. Documentation and help
{{/if}}

### 3. Prioritize Findings

Use RICE scoring:
- **Reach**: How many users affected?
- **Impact**: How much value? (0.25-3)
- **Confidence**: How sure are we? (50-100%)
- **Effort**: Person-weeks to build

RICE = (Reach × Impact × Confidence) / Effort

### 4. Specify Top Features

For top 3-5 features, create specifications:

```
## Feature: [Name]

**Problem**: [What user pain point does this solve?]
**Solution**: [Brief description of the feature]
**User Value**: [Why users would want this]

**RICE Score**: [calculated]
- Reach: [estimate]
- Impact: [0.25-3]
- Confidence: [%]
- Effort: [person-weeks]

**User Stories**:
- As a [user], I want to [action] so that [benefit]

**Success Criteria**:
- [ ] [measurable outcome]

**Scope**:
- In: [what's included]
- Out: [what's NOT included]
```

### 5. Create Tasks

{{#if create-tasks == "true"}}
Create tasks for top features:

- Priority 002 for high-value features
- Priority 003 for nice-to-have features

Include in each task:
- Clear problem statement
- Proposed solution
- Acceptance criteria
- Links to research
{{/if}}

## Output

```
## Feature Discovery Report

### Executive Summary

**Project**: {{DOYAKEN_PROJECT}}
**Discovery Scope**: {{ARGS.scope}}

**Key Findings**:
- [Most important insight]
- [Second insight]
- [Third insight]

**Top Recommendations**:
1. [Feature recommendation with rationale]
2. [Feature recommendation with rationale]
3. [Feature recommendation with rationale]

### Research Findings

{{#if scope == "full" or scope == "competitors"}}
#### Competitor Landscape

| Competitor | Strengths | Weaknesses | Notable Features |
|------------|-----------|------------|------------------|
| [name] | [strengths] | [weaknesses] | [features we lack] |

#### Competitive Analysis
- What competitors do better: [list]
- What we do better: [list]
- Gaps in the market: [opportunities]
{{/if}}

{{#if scope == "full" or scope == "gaps"}}
#### Feature Gap Analysis

| Missing Feature | Priority | Effort | Impact |
|-----------------|----------|--------|--------|
| [feature] | P0/P1/P2 | S/M/L | High/Med/Low |
{{/if}}

{{#if scope == "full" or scope == "ux"}}
#### UX Improvement Opportunities

| Area | Issue | Suggested Improvement |
|------|-------|----------------------|
| [area] | [problem] | [solution] |
{{/if}}

### Recommended Roadmap

**Now (Next Sprint)**:
1. [feature] - [rationale]

**Next (This Quarter)**:
1. [feature] - [rationale]

**Later (This Year)**:
1. [feature] - [rationale]

### Feature Specifications

[Detailed specs for top 3-5 features using template above]

### Tasks Created

[List of task files created with brief descriptions]
```
