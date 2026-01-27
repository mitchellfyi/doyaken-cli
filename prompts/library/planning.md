# Planning

## Before Planning

Understand the current state:

1. **Find ALL files** related to this domain
2. **Trace execution paths** for relevant functionality
3. **Understand architecture** and patterns in use
4. **Note conventions** (naming, structure, error handling)
5. **Check existing tests** - what's covered?

## Gap Analysis

For EACH requirement, assess honestly:

| Criterion | Status | Gap |
|-----------|--------|-----|
| [criterion] | full / partial / none | [what's missing] |

- **Full**: Code exists and completely satisfies
- **Partial**: Exists but needs modification
- **None**: Needs to be built

Be ruthlessly honest - "exists" is not the same as "done".

## Risk Assessment

### Technical Risks
- What could break existing functionality?
- Edge cases needing special handling?
- Security considerations?
- Performance concerns?

### Scope Risks
- Is the requirement clear?
- Hidden dependencies?
- Could this grow larger than expected?

### Mitigation
For each risk: how to detect early, what to do if it happens.

## Creating the Plan

Each step should be:
- **Atomic**: Completed and verified independently
- **Ordered**: Dependencies are clear
- **Specific**: Exact file, exact change

### Step Format
```
Step N: [Brief Description]
  - File: path/to/file
  - Change: [specific modification]
  - Verify: [how to confirm]
```

## Checkpoints

Define verification points:

| After Step | Verify |
|------------|--------|
| Step N | [what to check] |

## Anti-Patterns

| Anti-Pattern | Better Approach |
|--------------|-----------------|
| **Analysis paralysis** | Timebox planning |
| **Vague steps** | Specific file + change |
| **No verification** | Define done for each step |
| **Big bang** | Smaller, verifiable steps |
| **Over-engineering** | Simplest solution |
