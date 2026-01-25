# Phase 2: PLAN (Gap Analysis & Architecture)

You are planning the implementation for task {{TASK_ID}}.

## 1) Read Existing Code (Thoroughly)

Before planning, understand the current state:

- Find ALL files related to this task's domain
- Trace the execution path for relevant functionality
- Understand current architecture and patterns
- Note coding conventions (naming, structure, error handling)
- Check existing tests - what's covered, what patterns are used?

## 2) Gap Analysis (CRITICAL)

For EACH acceptance criterion, assess:

| Criterion | Status | Gap Description |
|-----------|--------|-----------------|
| [criterion] | full / partial / none | [what's missing] |

- **Full**: Code exists and completely satisfies the criterion
- **Partial**: Code exists but is incomplete or needs modification
- **None**: Needs to be built from scratch

Be ruthlessly honest - "exists" is not the same as "done".

## 3) Identify Risks and Checkpoints

Before starting implementation, flag potential problems:

**Risks:**
- What could break existing functionality?
- Are there edge cases that need special handling?
- Any security considerations (auth, input validation, etc.)?
- Performance concerns (N+1 queries, expensive loops)?

**Checkpoints:** (points where you should verify before continuing)
- After modifying core logic → run tests
- After changing data model → verify migrations
- After changing API → check consumers

## 4) Create Detailed Plan

Break down into ordered steps. Each step should be:

- **Atomic**: Can be completed and verified independently
- **Ordered**: Dependencies are clear
- **Specific**: Exact file, exact change

```
Step 1: [Description]
  - File: path/to/file
  - Change: [specific change]
  - Verify: [how to verify this step]

Step 2: ...
```

## 5) Test Strategy

- What tests already exist?
- What new tests are needed?
- What edge cases should be covered?
- Where in the test pyramid? (unit/integration/e2e)

## 6) Documentation Requirements

- What docs need updating?
- Any inline comments needed for complex logic?
- API documentation changes?

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
