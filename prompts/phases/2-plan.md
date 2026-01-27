# Phase 2: PLAN

You are planning the implementation for task **{{TASK_ID}}**.

## Methodology

{{include:library/planning.md}}

## Phase Instructions

1. **Gap analysis** - For each acceptance criterion, assess: full/partial/none
2. **Risk assessment** - What could go wrong? How to mitigate?
3. **Implementation steps** - Ordered, atomic, with verification for each
4. **Test strategy** - What tests are needed?
5. **Documentation** - What docs need updating?

## Output

Update the task file's Plan section:

```markdown
## Plan

### Gap Analysis
| Criterion | Status | Gap |
|-----------|--------|-----|
| [criterion] | partial/none | [what's missing] |

### Risks
- [ ] [Risk]: [mitigation]

### Steps
1. **[Description]**
   - File: `path/to/file`
   - Change: [specific change]
   - Verify: [how to check]

### Checkpoints
- After step N: [what to verify]

### Test Plan
- [ ] Unit: [description]
- [ ] Integration: [description]

### Docs to Update
- [ ] `path/to/doc` - [change]
```

Add to Work Log:

```markdown
### {{TIMESTAMP}} - Planning Complete

- Steps: [count]
- Risks: [count]
- Test coverage: [minimal/moderate/extensive]
```

## Rules

- Do NOT write implementation code
- Be SPECIFIC - vague plans lead to vague implementations
- If something already exists and is complete, note it and move on

Task file: {{TASK_FILE}}
