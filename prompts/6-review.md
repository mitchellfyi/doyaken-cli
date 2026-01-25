# Phase 6: REVIEW (Final Quality Gate)

You are performing final review for task {{TASK_ID}}.

## Mindset

- Review like you will own this code for 2 years
- Prefer boring code - minimize cleverness
- Assume edge cases exist until disproven
- If unsure, verify in the repo - don't invent behaviour

## 1) Build a Findings Ledger

Create a structured list of issues found:

```
| ID | Severity | Category | Location | Issue | Fix |
|----|----------|----------|----------|-------|-----|
| 1  | blocker  | correctness | file:line | [what's wrong] | [how to fix] |
```

**Severity levels:**
- **blocker**: Bugs, data loss, auth bypass, crashes
- **high**: Security issues, significant correctness problems
- **medium**: Performance issues, maintainability concerns
- **low**: Style, minor improvements
- **nit**: Trivial (only after everything else)

**Categories:**
- correctness, security, performance, reliability, maintainability, tests, docs

## 2) Multi-Pass Review

Don't stop after one pass. Review explicitly in multiple passes:

### Pass A: Intent & Correctness
- What does this change claim to do?
- Trace the happy path
- Trace at least 3 failure/edge paths
- Look for: silent failures, wrong defaults, partial writes, missing error handling

### Pass B: Design & Complexity
- Does it fit the existing codebase patterns?
- Could this be simpler?
- Are there unnecessary abstractions?
- Can a new developer understand it quickly?

### Pass C: Security (OWASP lens)
- Input validation (injection, XSS)
- Auth/authz checks on sensitive operations
- No hardcoded secrets or credentials
- Proper error messages (no stack traces to users)
- Rate limiting where appropriate

### Pass D: Performance & Reliability
- Obvious N+1 queries or expensive loops?
- Timeouts/retries for external calls?
- Concurrency hazards or race conditions?

### Pass E: Tests & Documentation
- Do tests cover behaviour and edge cases?
- Do docs match implementation?
- Is error output helpful for debugging?

## 3) Fix Issues (Highest Severity First)

For each finding:
1. Implement the smallest correct fix
2. Add/update tests if behaviour changed
3. Verify fix works
4. Commit atomically

## 4) Create Follow-up Tasks

For improvements that are out of scope:
- Create task files in `.doyaken/tasks/2.todo/`
- Priority 003 (Medium) for improvements
- Priority 004 (Low) for nice-to-haves
- Reference this task in the new task's context

## 5) Complete the Task

Only if ALL acceptance criteria are met:
- Check all acceptance criteria boxes
- Update status to `done`
- Set completed timestamp
- Move task file to `.doyaken/tasks/4.done/`

## Output

Update task Work Log:

```
### {{TIMESTAMP}} - Review Complete

Findings ledger:
- Blockers: [count] - all fixed
- High: [count] - all fixed
- Medium: [count] - [fixed/deferred to follow-up]
- Low: [count] - [fixed/deferred]

Review passes:
- A (Correctness): [pass/issues found]
- B (Design): [pass/issues found]
- C (Security): [pass/issues found]
- D (Performance): [pass/issues found]
- E (Tests/Docs): [pass/issues found]

Verification:
- All quality gates: [pass/fail]
- All criteria met: [yes/no]

Follow-up tasks:
- [task-id]: [description]

Final status: [COMPLETE/INCOMPLETE - reason]
```

## Rules

- Fix blockers and high severity issues immediately
- Create tasks for medium/low improvements (don't scope creep)
- Be honest about what's done vs remaining
- If task cannot be completed, explain why and leave in 3.doing/

Task file: {{TASK_FILE}}
Recent commits: {{RECENT_COMMITS}}
