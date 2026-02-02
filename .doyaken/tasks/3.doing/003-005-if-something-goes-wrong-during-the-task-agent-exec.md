# Task: if something goes wrong during the task agent execution (dk run) and i re-run the comand, it does not always resume the previous session/task - it will just pick a new todo task.
sometimes there can be multiple tasks stuck in doing and when i run it it will exit due to no tasks to execute.
it should reliable resume tasks and/or pick tasks up in doing - even if they were left in a bad state, e.g. locked, assigned etc - or at least give the user the option to resume a doing tasks with a timeout of 60 seconds that defaults to yes 

## Metadata

| Field       | Value                                                  |
| ----------- | ------------------------------------------------------ |
| ID          | `003-005-if-something-goes-wrong-during-the-task-agent-exec`                                           |
| Status      | `doing`                                               |
| Priority    | `003` Medium                          |
| Created     | `2026-02-02 02:01`                                         |
| Started     | `2026-02-02 05:43`                                     |
| Completed   |                                                        |
| Blocked By  |                                                        |
| Blocks      |                                                        |
| Assigned To | `worker-1` |
| Assigned At | `2026-02-02 05:41` |

---

## Context

**Intent**: FIX

When `dk run` is re-executed after an interrupted task execution, it does not reliably resume the previous task. The current task selection logic has several gaps:

1. **`get_doing_task_for_agent()`** (core.sh:1780-1802) only returns tasks in `3.doing/` if they have a lock file matching OUR `AGENT_ID`. If the previous run used a different worker number, or if the lock was deleted but task remained in doing/, the task is ignored.

2. **`get_next_available_task()`** (core.sh:1804-1828) checks for "our" doing tasks first, but then ONLY looks in `2.todo/`. It never considers tasks in `3.doing/` that don't have our lock (orphaned tasks).

3. **Multiple tasks stuck in doing** - If several tasks end up in `3.doing/` (from different worker IDs, crashed sessions, or stale locks), the system may:
   - Skip them all because none match our agent ID
   - Find no tasks in `2.todo/` either
   - Result in "No available tasks" even though tasks exist

4. **Stale locks with valid tasks** - If a lock becomes stale but the task remains in `3.doing/`, the lock is cleaned up by `is_lock_stale()` but the task still isn't picked up because `get_next_available_task()` doesn't check `3.doing/` for tasks without locks.

**Root Cause**: The task selection logic assumes tasks in `3.doing/` always have valid locks from the current agent. It doesn't handle:
- Tasks orphaned by a different agent/worker
- Tasks left in doing after lock cleanup
- Manual movement of tasks into doing

---

## Acceptance Criteria

- [ ] `get_next_available_task()` checks `3.doing/` for orphaned tasks (no lock or stale lock) after checking `2.todo/`
- [ ] When orphaned tasks exist in `3.doing/`, user is prompted with 60-second timeout defaulting to "yes, resume"
- [ ] Orphaned task detection handles: no lock file, stale lock, lock from different agent
- [ ] User can skip orphaned task resume via `AGENT_NO_PROMPT=1` environment variable
- [ ] If user declines resume, task is moved back to `2.todo/` for later
- [ ] Log messages clearly indicate orphaned task detection and user choice
- [ ] Existing behavior preserved: if OUR lock exists, resume without prompting
- [ ] Quality gates pass
- [ ] Changes committed with task reference

---

## Plan

### Gap Analysis

| Criterion | Status | Gap |
|-----------|--------|-----|
| `get_next_available_task()` checks `3.doing/` for orphaned tasks | none | Function only checks `2.todo/` after checking our agent's doing tasks - needs new orphan detection |
| User prompted with 60-second timeout defaulting to "yes" | none | No prompt mechanism exists for orphaned task resumption - `read_with_timeout` exists in utils.sh but not wired up |
| Orphaned task detection (no lock, stale lock, different agent) | partial | `is_lock_stale()` and `is_task_locked()` exist - need to compose these for orphan detection |
| `AGENT_NO_PROMPT=1` env var skips prompts | none | Variable not defined - needs addition to config section |
| Declined tasks moved back to `2.todo/` | none | No mechanism exists - needs new function |
| Log messages for orphaned task detection | none | Needs new log messages |
| Existing behavior preserved (OUR lock resumes without prompt) | full | `get_doing_task_for_agent()` handles this correctly |
| Quality gates pass | pending | Will verify after implementation |
| Changes committed with task reference | pending | Will do after implementation |

### Risks

- [ ] **Race condition during prompt**: Another agent could claim task while user is being prompted → Mitigate by acquiring lock BEFORE prompting
- [ ] **Confusing UX**: User may not understand why old tasks appear → Clear log messages explaining the situation
- [ ] **Non-interactive environments**: CI/CD won't have terminal → Honor `AGENT_NO_PROMPT=1` and auto-resume
- [ ] **Multiple orphaned tasks**: If several orphans exist, which to pick? → Pick first alphabetically, same as todo selection

### Steps

1. **Add `AGENT_NO_PROMPT` env variable**
   - File: `lib/core.sh`
   - Change: Add `AGENT_NO_PROMPT="${AGENT_NO_PROMPT:-0}"` after line 675 (with other AGENT_ vars)
   - Verify: Variable is available in environment

2. **Create `find_orphaned_doing_task()` function**
   - File: `lib/core.sh`
   - Change: Add new function after `get_doing_task_for_agent()` (after line 1802) that:
     - Iterates through `3.doing/` tasks
     - Skips tasks with valid locks from current agent (already handled by `get_doing_task_for_agent`)
     - Returns first task that has: no lock file, stale lock (via `is_lock_stale`), or lock from different agent
   - Verify: Function returns orphaned task file path or empty

3. **Create `prompt_orphan_resume()` function**
   - File: `lib/core.sh`
   - Change: Add new function after `find_orphaned_doing_task()` that:
     - Uses `read_with_timeout` from utils.sh with 60s timeout
     - Defaults to "y" (yes, resume) on timeout
     - Returns 0 if user wants to resume, 1 if declined
     - Logs user choice clearly
   - Verify: Function prompts correctly with timeout

4. **Create `move_task_to_todo()` function**
   - File: `lib/core.sh`
   - Change: Add helper function to move a task from `3.doing/` back to `2.todo/`
     - Clears any existing lock for the task
     - Clears assignment metadata in task file
     - Moves file to `2.todo/`
     - Logs the move
   - Verify: Task appears in `2.todo/` with no lock

5. **Update `get_next_available_task()` to check orphans**
   - File: `lib/core.sh`
   - Change: Modify function (lines 1804-1828) to:
     - After checking `2.todo/` and finding nothing, call `find_orphaned_doing_task()`
     - If orphan found and `AGENT_NO_PROMPT=1`, auto-resume (acquire lock, return task)
     - If orphan found and interactive, call `prompt_orphan_resume()`
     - If user accepts: acquire lock, return task
     - If user declines: call `move_task_to_todo()`, continue searching
   - Verify: Orphaned tasks are detected and handled

6. **Add logging for orphan detection**
   - File: `lib/core.sh`
   - Change: Add clear log messages:
     - "Found orphaned task in doing: {task_id} (no lock / stale lock / locked by {other_agent})"
     - "Resuming orphaned task: {task_id}"
     - "Moving declined task back to todo: {task_id}"
   - Verify: Logs appear during orphan handling

7. **Update run_agent_iteration() if needed**
   - File: `lib/core.sh`
   - Change: May need to adjust how it handles tasks returned from `get_next_available_task()` that are already in `doing/` but weren't OUR lock (distinction between "our doing" vs "orphan doing")
   - Verify: Both resume paths (our lock vs orphan) work correctly

### Checkpoints

| After Step | Verify |
|------------|--------|
| Step 2 | `find_orphaned_doing_task` correctly identifies orphaned tasks in manual test |
| Step 4 | Task can be moved from `3.doing/` to `2.todo/` successfully |
| Step 5 | Full flow: orphan detected → prompt → resume OR decline → move to todo |
| Step 7 | `./scripts/lint.sh` passes, `./scripts/test.sh` passes |

### Test Plan

- [ ] Manual: Create task in `3.doing/` without lock → verify prompt appears
- [ ] Manual: Create task with stale lock (old timestamp) → verify detected as orphan
- [ ] Manual: Create task with lock from `worker-99` → verify detected as orphan
- [ ] Manual: Decline resume → verify task moved to `2.todo/`
- [ ] Manual: Accept resume → verify task continues normally
- [ ] Manual: Set `AGENT_NO_PROMPT=1` → verify auto-resume without prompt
- [ ] Manual: Let 60s timeout expire → verify defaults to resume
- [ ] Automated: `./scripts/test.sh` passes
- [ ] Automated: `./scripts/lint.sh` passes

### Docs to Update

- [ ] No external docs needed - behavior change is user-facing but self-explanatory via log messages

---

## Work Log

### 2026-02-02 02:01 - Created

- Task created via CLI

### 2026-02-02 - Task Expanded

- Intent: FIX
- Scope: Improve task selection logic to handle orphaned tasks in `3.doing/`
- Key files: `lib/core.sh` (lines 1780-1828, possibly cleanup section)
- Complexity: Medium

### 2026-02-02 05:43 - Triage Complete

Quality gates:
- Lint: `./scripts/lint.sh` (shellcheck)
- Types: N/A (shell scripts)
- Tests: `./scripts/test.sh`
- Build: N/A (no build step)
- All: `./scripts/check-all.sh`

Task validation:
- Context: clear - root cause well documented with line references
- Criteria: specific - 9 acceptance criteria, all testable
- Dependencies: none - no blockers

Complexity:
- Files: few - primarily `lib/core.sh`, may touch `lib/utils.sh`
- Risk: medium - affects task selection logic, core workflow

Ready: yes

### 2026-02-02 05:44 - Planning Complete

- Steps: 7
- Risks: 4 (race condition, UX confusion, non-interactive mode, multiple orphans)
- Test coverage: moderate (manual tests for each scenario + automated lint/test)
- Key insight: Reuse existing `is_lock_stale()` and `read_with_timeout()` functions
- Primary file: `lib/core.sh` (add ~60-80 lines)

### 2026-02-02 05:47 - Implementation Progress

Step 1: Add `AGENT_NO_PROMPT` env variable
- Files modified: `lib/core.sh` (line 676)
- Verification: pass

Step 2: Create `find_orphaned_doing_task()` function
- Files modified: `lib/core.sh` (lines 1804-1848)
- Verification: pass
- Function detects: no lock, stale lock, lock from different agent

Step 3-4: Create `prompt_orphan_resume()` and `move_task_to_todo()` functions
- Files modified: `lib/core.sh` (lines 1850-1939)
- Verification: pass
- Features:
  - 60-second timeout defaulting to "yes" (resume)
  - `AGENT_NO_PROMPT=1` skips prompt and auto-resumes
  - Non-interactive (no tty) auto-resumes
  - Clear log messages for user understanding
  - Declined tasks moved back to `2.todo/`

Step 5: Update `get_next_available_task()` to check orphans
- Files modified: `lib/core.sh` (lines 1941-2001)
- Verification: pass
- Order: our doing → todo → orphaned doing
- Recursive handling if user declines

Step 6: Update `run_agent_iteration()` for orphan tasks
- Files modified: `lib/core.sh` (line 2096-2097)
- Verification: pass
- Refresh assignment when resuming any doing task

Step 7: Quality gates
- `./scripts/lint.sh`: pass (0 errors, 5 pre-existing warnings)
- `./scripts/test.sh`: pass (88/88 tests)
- `./scripts/check-all.sh`: pass

---

## Notes

**In Scope:**
- Modify `get_next_available_task()` to find orphaned tasks in `3.doing/`
- Add user prompt with 60-second timeout when orphaned tasks found
- Add `AGENT_NO_PROMPT` env var to skip prompts
- Move declined tasks back to `2.todo/`

**Out of Scope:**
- Phase-level checkpointing (related but separate feature)
- Session resumption improvements (different mechanism)
- Multi-agent coordination changes

**Assumptions:**
- User has terminal access for prompts (can use `AGENT_NO_PROMPT=1` otherwise)
- Moving task back to `2.todo/` is acceptable when user declines resume

**Edge Cases:**
- Multiple orphaned tasks: prompt for the first one found (alphabetically)
- Task has assignment metadata but no lock: still considered orphaned
- Prompt times out: defaults to "yes" (resume)
- User running in non-interactive mode (CI): honor `AGENT_NO_PROMPT`

**Risks:**
- Race condition if another agent starts while user is being prompted → Mitigate by acquiring lock before prompting
- User confusion about why old tasks appear → Clear log messages explaining situation

---

## Links

