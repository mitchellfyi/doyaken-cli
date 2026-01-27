---
description: Run the 8-phase task workflow
---

Run the doyaken skill: workflow

```bash
doyaken skill workflow $ARGUMENTS
```

If doyaken is not available, apply this methodology:

---

# 8-Phase Task Workflow

Execute the doyaken 8-phase workflow on a task.

## Context

Task: {{ARGS.task}}
Phases: {{ARGS.phases}}
Project: {{DOYAKEN_PROJECT}}

## Phases

The workflow consists of 8 sequential phases:

| Phase | Name | Purpose | Timeout |
|-------|------|---------|---------|
| 0 | EXPAND | Expand brief prompt into full task specification | 2min |
| 1 | TRIAGE | Validate task, check dependencies | 2min |
| 2 | PLAN | Gap analysis, detailed planning | 5min |
| 3 | IMPLEMENT | Execute the plan, write code | 30min |
| 4 | TEST | Run tests, add coverage | 10min |
| 5 | DOCS | Sync documentation | 5min |
| 6 | REVIEW | Code review, create follow-ups | 10min |
| 7 | VERIFY | Verify task management, commit | 3min |

## CLI Usage

```bash
# Run workflow on next available task
doyaken run 1

# Create and run a single task
doyaken task "your task description"

# Run specific number of tasks
doyaken run 5
```

## Manual Workflow

If running manually, follow these phases in sequence:

### Phase 0: EXPAND

Expand a brief task description into a full specification:
- Clarify requirements
- Identify acceptance criteria
- Define scope (in/out)

### Phase 1: TRIAGE

Validate the task is ready:
- [ ] Dependencies available
- [ ] Requirements clear
- [ ] Scope reasonable
- [ ] Not blocked

### Phase 2: PLAN

Create detailed implementation plan:
- Gap analysis (current vs target state)
- Step-by-step approach
- Risk identification

### Phase 3: IMPLEMENT

Execute the plan:
- Write code following quality standards
- Commit frequently with clear messages
- Handle errors appropriately

### Phase 4: TEST

Ensure quality:
- Run existing tests
- Add tests for new functionality
- Verify edge cases

### Phase 5: DOCS

Update documentation:
- README if needed
- API docs if applicable
- Code comments for complex logic

### Phase 6: REVIEW

Self-review:
- Code quality check
- Security review
- Create follow-up tasks if needed

### Phase 7: VERIFY

Finalize:
- All tests passing
- Quality gates pass
- Changes committed
- Task marked complete

## Quality Standards

Apply these standards throughout:

{{include:library/quality.md}}

## Output

After completing the workflow, provide a summary:

```
## Workflow Summary

Task: [task description]
Status: [completed/blocked/needs-review]

### Phases Completed
- [x] EXPAND
- [x] TRIAGE
- [x] PLAN
- [x] IMPLEMENT
- [x] TEST
- [x] DOCS
- [x] REVIEW
- [x] VERIFY

### Changes Made
- [list of files changed]

### Tests
- [test status]

### Follow-up Tasks
- [any new tasks created]
```
