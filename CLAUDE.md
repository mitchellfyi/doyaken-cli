# CLAUDE.md - Agent Operating Manual

This document is the single source of truth for autonomous agent operation in this repository.

## Quick Start

When prompted with "continue", "continue working", or similar:

```
1. Read this file completely
2. Execute the Operating Loop (Section A)
3. Complete quality gates after every major change
4. Commit with task reference when done
```

---

## A) Operating Loop

Execute this algorithm on every "continue working" run:

```
STEP 1: CHECK DOING (Your Task)
  - Look in .claude/tasks/doing/
  - Find task file assigned to YOU (check Assigned To field)
  - If found:
    - Read the task file
    - Resume work from the Work Log
    - Continue to STEP 4
  - If another agent's task is in doing/, skip it

STEP 2: PICK FROM TODO
  - Look in .claude/tasks/todo/
  - If task files exist:
    - Sort by priority (filename prefix: PPP-SSS-slug)
      - PPP = priority (001=critical, 002=high, 003=medium, 004=low)
      - SSS = sequence within priority
    - Check dependencies (blockedBy field)
    - Check assignment (skip if Assigned To is set to another agent)
    - Pick first unblocked, unassigned task
    - Update Assigned To with your agent ID
    - Update Assigned At with current timestamp
    - Move file from todo/ to doing/
    - Update status field in file to "doing"
    - Continue to STEP 4

STEP 3: CREATE NEW TASK
  - If todo/ is empty:
    - Read MISSION.md, README.md
    - Analyze current repo state (what exists, what's missing)
    - Identify the single most impactful next task
    - Create task file using template in _templates/task.md
    - Place in .claude/tasks/todo/
    - Move to doing/ immediately
    - Continue to STEP 4

STEP 4: EXECUTE TASK
  For the task in doing/:

  a) PLAN (Gap Analysis First!)
    - Read all relevant files INCLUDING existing implementations
    - Check each acceptance criterion against what exists
    - Identify GAPS: what's missing, incomplete, or needs improvement
    - Write implementation plan focusing on gaps
    - Identify files to create/modify
    - Identify tests needed
    - If something "exists" but is incomplete, plan the completion work

  b) IMPLEMENT
    - Make changes in small, reviewable chunks
    - Update Work Log after each significant action
    - Run quality gates after every major change (see Section D)

  c) TEST
    - Write tests for new functionality
    - Run existing tests to ensure no regressions
    - Update Work Log with test results

  d) REVIEW
    - Self-review the changes
    - Check for edge cases, security issues
    - Verify ALL acceptance criteria are met (not just "something exists")
    - If code partially exists, identify GAPS and IMPROVEMENTS needed

  e) COMPLETE (Only when ALL criteria met!)
    - Run final quality gates
    - Verify EVERY acceptance criterion checkbox can be checked
    - Do NOT mark done just because "code exists" - verify it meets spec
    - Update task status to "done"
    - Update completed timestamp
    - Add completion summary to Work Log
    - Clear Assigned To and Assigned At fields
    - Move file from doing/ to done/
    - Commit with message referencing task ID
    - Regenerate TASKBOARD.md

STEP 5: CONTINUE OR STOP
  - If more tasks remain and within run limit: go to STEP 1
  - If stopping: clear your assignment from any uncompleted tasks
  - Report summary
```

---

## B) Repo Discovery

### Auto-Detection Commands

Run these to discover what's available:

```bash
# Check for common project types
[ -f package.json ] && echo "Node project"
[ -f Gemfile ] && echo "Ruby project"
[ -f requirements.txt ] && echo "Python project"
[ -f go.mod ] && echo "Go project"
[ -f Cargo.toml ] && echo "Rust project"

# Check for CI
[ -f .github/workflows/*.yml ] && echo "GitHub Actions CI"
[ -f .gitlab-ci.yml ] && echo "GitLab CI"
[ -f Makefile ] && echo "Makefile available"
```

### Discovery Priority

1. Check for project-specific quality scripts (bin/quality, etc.)
2. Run language-specific linters and formatters
3. Run test suite
4. Check security tools if available

---

## C) Task Lifecycle

### Task ID Format

```
PPP-SSS-slug.md

PPP = Priority (001-004)
  001 = Critical (blocking, security, broken)
  002 = High (important feature, significant bug)
  003 = Medium (normal work, improvements)
  004 = Low (nice-to-have, cleanup)

SSS = Sequence (001-999)
  Within same priority, lower = do first

slug = kebab-case description (max 50 chars)

Examples:
  001-001-fix-security-vulnerability.md
  002-001-add-user-authentication.md
  002-002-add-password-reset.md
  003-001-refactor-user-model.md
```

### Task States

```
.claude/tasks/
  todo/     <- Planned, ready to start (unassigned)
  doing/    <- In progress (assigned to an agent)
  done/     <- Completed with logs (unassigned)
  _templates/ <- Task file template
```

### Task Assignment (Parallel Support)

Each task has assignment metadata:

- **Assigned To**: Agent ID currently working on the task
- **Assigned At**: Timestamp when assignment started (refreshed every hour)

Rules for parallel operation:

1. Only pick up tasks where `Assigned To` is empty
2. Set `Assigned To` to your agent ID when starting
3. Clear `Assigned To` when completing or abandoning
4. If `Assigned At` is >3 hours old, the assignment is stale (can be claimed)
5. Long-running tasks refresh `Assigned At` every hour (heartbeat)

### Moving Tasks

When changing state, physically move the file:

```bash
# Pick up task
mv .claude/tasks/todo/003-001-example.md .claude/tasks/doing/

# Complete task
mv .claude/tasks/doing/003-001-example.md .claude/tasks/done/
```

---

## D) Quality Gates

### When to Run

Run quality checks after every "major change":

- Adding/modifying a file with significant logic
- Changing database schema
- Adding new dependencies
- Modifying configuration
- Before committing

### Quality Failure Protocol

If a quality check fails:

1. **STOP** - do not continue with more changes
2. **FIX** - address the failure immediately
3. **RE-RUN** - verify the fix resolves the issue
4. **LOG** - note the failure and fix in Work Log
5. **CONTINUE** - only after all checks pass

### Test Coverage Rules

- **New code**: Must have tests
- **Bug fixes**: Must have regression test
- **Modified code**: Existing tests must still pass
- **No tests exist**: Add tests for area being touched

---

## E) Commit Policy

### Commit Requirements

1. **All quality gates must pass** - never commit failing checks
2. **Task reference required** - include task ID in message
3. **Atomic commits** - one logical change per commit
4. **Working state** - app must work after commit

### Commit Message Format

```
<type>: <description>

[optional body]

Task: <task-id>
Co-Authored-By: Claude <noreply@anthropic.com>
```

Types:

- `feat`: New feature
- `fix`: Bug fix
- `refactor`: Code restructure without behavior change
- `test`: Adding/updating tests
- `docs`: Documentation only
- `style`: Formatting, no logic change
- `chore`: Maintenance, dependencies

### What NOT to Commit

- Broken tests
- Security vulnerabilities
- Debug code or console.log
- Commented-out code
- TODO comments without task reference
- Credentials or secrets
- Large binary files

---

## F) Failure Modes

### When Stuck

1. **Document the blocker** in task Work Log
2. **Identify the type**:
   - Missing information -> Add question to Notes
   - Technical limitation -> Research alternatives
   - Scope creep -> Split into subtasks
   - External dependency -> Create blocked task

3. **If blocked for > 3 attempts**:
   - Move task back to todo/ with blocker noted
   - Pick a different task
   - Leave clear handoff notes

### Scope Explosion

If a task grows beyond original estimate:

1. Complete the minimum viable version
2. Create follow-up tasks for additional scope
3. Commit what's done
4. Move to done with note about follow-ups

---

## G) Taskboard

### Generate Taskboard

Run `.claude/agent/scripts/taskboard.sh` to regenerate `TASKBOARD.md`:

```bash
.claude/agent/scripts/taskboard.sh
```

### Taskboard Location

`TASKBOARD.md` in repo root - human-readable overview of all tasks.

---

## H) Scripts

### bin/agent

Main entry point for **FULLY AUTONOMOUS + SELF-HEALING + PARALLEL** operation. Runs Claude in dangerous mode with all permissions bypassed and automatic recovery from failures.

```bash
# Run 5 tasks (default)
./bin/agent

# Run specific number of tasks
./bin/agent 3

# Run multiple agents in parallel
./bin/agent 5 &
./bin/agent 5 &
```

**Phase-Based Execution:**

| Phase | Timeout | Purpose |
|-------|---------|---------|
| 1. TRIAGE | 2min | Validate task, check dependencies |
| 2. PLAN | 5min | Gap analysis, detailed planning |
| 3. IMPLEMENT | 30min | Execute the plan, write code |
| 4. TEST | 10min | Run tests, add missing coverage |
| 5. DOCS | 5min | Sync documentation |
| 6. REVIEW | 5min | Code review, create follow-ups |
| 7. VERIFY | 2min | Verify task management |

---

## I) File Reference

```
.claude/
  agent/
    run.sh         <- Entry point
    lib/core.sh    <- Core logic
    prompts/       <- Phase prompts
    scripts/       <- Utility scripts
  tasks/
    todo/          <- Tasks ready to work
    doing/         <- Current tasks
    done/          <- Completed tasks
    _templates/    <- Task template
  logs/            <- Run logs
  state/           <- Session state
  locks/           <- Lock files

bin/
  agent            <- Main script

CLAUDE.md          <- This file
TASKBOARD.md       <- Generated overview
MISSION.md         <- Project goals
```

---

## J) Operating Principles

1. **Read before write** - Always understand context first
2. **Small changes** - Easier to review, easier to revert
3. **Test everything** - No untested code
4. **Log everything** - Future you (or another agent) will thank you
5. **Fail fast** - Don't continue on broken state
6. **Be autonomous** - Make decisions, don't wait for input
7. **Be reversible** - Prefer changes that can be undone
8. **Be transparent** - Document decisions and trade-offs
9. **Be thorough** - "Exists" != "Done". Check every criterion
10. **Add value** - Always leave code better than you found it

---

## K) Emergency Procedures

### Reset Stuck State

```bash
# Move any doing task back to todo
mv .claude/tasks/doing/*.md .claude/tasks/todo/ 2>/dev/null

# Clear all locks
rm -rf .claude/locks/*.lock 2>/dev/null

# Clear assignments in todo tasks
for f in .claude/tasks/todo/*.md; do
  sed -i '' 's/| Assigned To | .*/| Assigned To | |/' "$f" 2>/dev/null
  sed -i '' 's/| Assigned At | .*/| Assigned At | |/' "$f" 2>/dev/null
done

# Clear stale state files
rm -rf .claude/state/* 2>/dev/null
```

### Validate System

```bash
# Check folder structure
ls -la .claude/tasks/{todo,doing,done,_templates}

# Count tasks by state
echo "TODO: $(ls .claude/tasks/todo/*.md 2>/dev/null | wc -l)"
echo "DOING: $(ls .claude/tasks/doing/*.md 2>/dev/null | wc -l)"
echo "DONE: $(ls .claude/tasks/done/*.md 2>/dev/null | wc -l)"
```

---

## Quick Reference Card

```
CONTINUE WORKING LOOP:
  doing (mine)? -> resume it
  todo (unassigned)? -> pick highest priority unblocked
  empty? -> create from MISSION.md

COMMIT FORMAT:
  <type>: <description>
  Task: <task-id>
  Co-Authored-By: Claude <noreply@anthropic.com>

TASK PRIORITY:
  001 = Critical
  002 = High
  003 = Medium
  004 = Low

PARALLEL OPERATION:
  - Check Assigned To before picking task
  - Set Assigned To when starting
  - Clear Assigned To when done
  - Stale assignments (>3h) can be claimed

WHEN STUCK:
  1. Log it
  2. Try 3 times
  3. Move back to todo
  4. Pick something else
```
