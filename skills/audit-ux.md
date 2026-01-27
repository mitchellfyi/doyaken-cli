---
name: audit-ux
description: User experience audit and improvement recommendations
args:
  - name: focus
    description: Focus area (full, onboarding, errors, help)
    default: "full"
  - name: create-tasks
    description: Create tasks for UX issues
    default: "true"
---

# UX Audit

You are performing a user experience audit of the project.

## Context

Project: {{DOYAKEN_PROJECT}}
Focus area: {{ARGS.focus}}
Create follow-up tasks: {{ARGS.create-tasks}}

## UX Review Framework

{{include:library/review-ux.md}}

## Audit Process

### 1. First Impressions

Experience the project as a new user:

- Read the README - is it clear?
- Follow getting started instructions
- Try the most basic operation
- Note any confusion or friction

**Questions to answer:**
- Can I understand what this does in 30 seconds?
- Can I install and run something in 5 minutes?
- Do I know what to do next?

### 2. Focus-Specific Audit

{{#if focus == "full"}}
#### Full UX Audit

**A. Onboarding Experience**
- Installation process
- First-run experience
- Tutorial/examples quality
- Time to first success

**B. Daily Use**
- Common workflow efficiency
- Command/feature discoverability
- Shortcuts and power-user features
- Customization options

**C. Help & Documentation**
- --help quality and completeness
- README clarity
- Examples and tutorials
- Troubleshooting resources

**D. Error Handling**
- Error message clarity
- Actionable guidance in errors
- Recovery options
- Debug/verbose modes
{{/if}}

{{#if focus == "onboarding"}}
#### Onboarding Focus

Test the new user journey:

1. **Discovery**: How does someone find this project?
2. **Installation**: Single command? Multiple steps?
3. **First Run**: What happens? Is it helpful?
4. **First Task**: Can they accomplish something useful?
5. **Learning**: How do they learn more?

Evaluate:
- [ ] Installation is one command (or clearly documented)
- [ ] First command gives useful output
- [ ] Examples are provided and work
- [ ] Next steps are clear
- [ ] Common errors during setup are handled
{{/if}}

{{#if focus == "errors"}}
#### Error Handling Focus

Find all error scenarios and evaluate messages:

1. Collect error messages from code
2. Trigger common errors
3. Evaluate each message:
   - Is it human-readable?
   - Does it explain what went wrong?
   - Does it suggest a fix?
   - Is relevant context included?

Error quality checklist:
- [ ] No stack traces shown to users by default
- [ ] Error includes what user can do
- [ ] Error codes for scripting/searching
- [ ] Verbose mode for debugging
{{/if}}

{{#if focus == "help"}}
#### Help & Documentation Focus

Audit all help surfaces:

1. **--help output**
   - Comprehensive command list
   - Clear descriptions
   - Examples included
   - Logical grouping

2. **README**
   - Clear project description
   - Installation instructions
   - Quick start guide
   - Link to full docs

3. **In-app guidance**
   - Contextual help
   - Suggestions on errors
   - Tips for common tasks
{{/if}}

### 3. Document Findings

For each UX issue:

```
### Issue: [Title]

**Severity**: Blocker / Major / Minor / Cosmetic
**Area**: Onboarding / Daily Use / Errors / Help / Performance
**Impact**: [User impact description]

**Current Experience**:
[What happens now]

**Expected Experience**:
[What should happen]

**Recommendation**:
[Specific improvement]
```

### 4. Create Tasks

{{#if create-tasks == "true"}}
Create tasks for improvements:

- Severity Blocker/Major: Priority 002
- Severity Minor: Priority 003
- Severity Cosmetic: Priority 004

Include "ux" label in tasks.
{{/if}}

## Output

```
## UX Audit Report

### Summary

**Project**: {{DOYAKEN_PROJECT}}
**Focus**: {{ARGS.focus}}
**Overall UX Score**: [1-10]

**Strengths**:
- [What works well]

**Areas for Improvement**:
- [What needs work]

### First Impressions

| Aspect | Score (1-5) | Notes |
|--------|-------------|-------|
| README clarity | | |
| Installation ease | | |
| First-run experience | | |
| Time to first success | | |
| Overall polish | | |

### Detailed Findings

#### Blockers
[Issues preventing users from succeeding]

#### Major Issues
[Significant friction points]

#### Minor Issues
[Small annoyances]

#### Cosmetic Issues
[Polish items]

### User Journey Analysis

**Journey: [Primary Use Case]**

| Step | Current UX | Friction | Recommendation |
|------|------------|----------|----------------|
| 1. [step] | [what happens] | [pain point] | [improvement] |
| 2. [step] | | | |

### Quick Wins

Easy improvements with high impact:

1. [improvement] - Effort: Low, Impact: High
2. [improvement] - Effort: Low, Impact: High
3. [improvement] - Effort: Low, Impact: High

### Recommendations

**Immediate (This Week)**:
1. [improvement]

**Short-term (This Month)**:
1. [improvement]

**Long-term (This Quarter)**:
1. [improvement]

### Tasks Created

[List of task files created]
```
