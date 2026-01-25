# Implementation Planning

## Before Planning

Understand the current state thoroughly:

1. **Find ALL files** related to this domain
2. **Trace execution paths** for relevant functionality
3. **Understand architecture** and patterns in use
4. **Note conventions** (naming, structure, error handling)
5. **Check existing tests** - what's covered, what patterns are used?

## Gap Analysis

For EACH requirement or acceptance criterion, assess honestly:

| Criterion | Status | Gap Description |
|-----------|--------|-----------------|
| [criterion] | full / partial / none | [what's missing] |

- **Full**: Code exists and completely satisfies the criterion
- **Partial**: Code exists but is incomplete or needs modification
- **None**: Needs to be built from scratch

Be ruthlessly honest - "exists" is not the same as "done".

## Risk Assessment

Before starting implementation, identify potential problems:

### Technical Risks
- What could break existing functionality?
- Are there edge cases that need special handling?
- Any security considerations (auth, input validation)?
- Performance concerns (N+1 queries, expensive operations)?
- Concurrency or race condition risks?

### Scope Risks
- Is the requirement clear and unambiguous?
- Are there hidden dependencies?
- Could this grow larger than expected?
- Are there external dependencies that could block progress?

### Mitigation
For each risk, define:
- How to detect it early
- What to do if it materializes
- When to escalate or ask for help

## Creating the Plan

Break down into ordered steps. Each step should be:

- **Atomic**: Can be completed and verified independently
- **Ordered**: Dependencies between steps are clear
- **Specific**: Exact file, exact change, exact verification

### Step Format

```
Step N: [Brief Description]
  - File: path/to/file
  - Change: [specific modification]
  - Verify: [how to confirm this step is done]
  - Depends on: [previous steps, if any]
```

### Good Steps
- "Add validateEmail function to src/utils/validation.js"
- "Update UserService.create to call validateEmail before save"

### Bad Steps
- "Implement email validation" (too vague)
- "Fix the bug" (no specifics)
- "Refactor everything" (too broad)

## Test Strategy

Plan tests alongside implementation:

- **What tests exist** for related functionality?
- **What new tests are needed** for this change?
- **What edge cases** should be covered?
- **Where in the test pyramid?** (unit/integration/e2e)

## Checkpoints

Define verification points during implementation:

| After Step | Verify |
|------------|--------|
| Step 3 | Run existing tests - all should pass |
| Step 5 | New feature works for happy path |
| Step 7 | Edge cases handled correctly |
| Final | All tests pass, no regressions |

## Documentation Requirements

- What docs need updating?
- Any inline comments needed for complex logic?
- API documentation changes?
- README updates?

## Plan Template

```markdown
## Implementation Plan

### Gap Analysis
| Criterion | Status | Gap |
|-----------|--------|-----|
| [criterion 1] | partial | [what's missing] |
| [criterion 2] | none | [needs to be built] |

### Risks
- [ ] [Risk 1]: [mitigation strategy]
- [ ] [Risk 2]: [mitigation strategy]

### Steps
1. **[Description]**
   - File: `path/to/file`
   - Change: [specific change]
   - Verify: [how to check]

2. **[Description]**
   - File: `path/to/file`
   - Change: [specific change]
   - Verify: [how to check]

### Checkpoints
- After step N: [what to verify]

### Test Plan
- [ ] Unit: [test description]
- [ ] Integration: [test description]

### Docs to Update
- [ ] `path/to/doc` - [what to add/change]
```

## Planning Anti-Patterns

| Anti-Pattern | Problem | Better Approach |
|--------------|---------|-----------------|
| **Analysis paralysis** | Planning forever, never starting | Timebox planning, start with MVP |
| **Vague steps** | "Make it work" | Specific file + specific change |
| **No verification** | How do you know it's done? | Define done for each step |
| **Big bang** | One huge step | Break into smaller, verifiable steps |
| **Ignoring risks** | Surprised by problems | Identify and mitigate upfront |
