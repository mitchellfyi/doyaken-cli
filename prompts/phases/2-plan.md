# Phase 2: PLAN (Gap Analysis & Architecture)

You are planning the implementation for task {{TASK_ID}}.

## Planning Methodology

{{include:library/planning.md}}

## Quality Principles

When planning, ensure the implementation will follow these principles:

- **KISS** - Plan the simplest solution that works
- **YAGNI** - Don't plan features that aren't required
- **DRY** - Plan to reuse existing code where possible
- **SOLID** - Plan for maintainable, modular code

Consider quality gates in your plan:
- How will the code be tested?
- What types need to be correct?
- Are there security implications to audit?

## Phase-Specific Instructions

Read the task file thoroughly first: {{TASK_FILE}}

For this specific task:
1. Perform gap analysis against ALL acceptance criteria
2. Identify risks and create checkpoints
3. Create ordered implementation steps
4. Define test strategy
5. Note documentation requirements

## Output

Update the task file's Plan section:

```
### Implementation Plan (Generated {{TIMESTAMP}})

#### Gap Analysis
| Criterion | Status | Gap |
|-----------|--------|-----|
| [criterion 1] | partial | [what's missing] |
| [criterion 2] | none | [needs to be built] |

#### Risks
- [ ] [Risk 1]: [mitigation]
- [ ] [Risk 2]: [mitigation]

#### Implementation Steps
1. **[Description]**
   - File: `path/to/file`
   - Change: [specific change]
   - Verify: [how to check]

2. **[Description]**
   - File: `path/to/file`
   - Change: [specific change]
   - Verify: [how to check]

#### Checkpoints
- After step N: [what to verify]

#### Test Plan
- [ ] Unit: [test description]
- [ ] Integration: [test description]

#### Docs to Update
- [ ] `path/to/doc` - [what to add/change]
```

## Rules

- Do NOT write any implementation code
- Do NOT create or modify source files
- ONLY update the task file's Plan section
- Be SPECIFIC - vague plans lead to vague implementations
- If something already exists and is complete, note it and move on
- Flag risks early - better to know now than discover mid-implementation

Task file: {{TASK_FILE}}
