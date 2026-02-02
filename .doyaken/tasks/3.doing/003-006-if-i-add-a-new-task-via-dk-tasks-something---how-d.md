# Task: Dynamic Task Priority Evaluation in Expand/Triage Phases

## Metadata

| Field       | Value                                                  |
| ----------- | ------------------------------------------------------ |
| ID          | `003-006-if-i-add-a-new-task-via-dk-tasks-something---how-d`                                           |
| Status      | `doing`                                               |
| Priority    | `003` Medium                          |
| Created     | `2026-02-02 02:01`                                         |
| Started     | `2026-02-02 05:52`                                     |
| Completed   |                                                        |
| Blocked By  |                                                        |
| Blocks      |                                                        |
| Assigned To | `worker-2` |
| Assigned At | `2026-02-02 05:59` |

---

## Context

**Intent**: IMPROVE

Currently, when a task is created via `dk tasks new`, it is automatically assigned priority `003` (Medium). This priority is embedded in the task filename (e.g., `003-001-my-task.md`) and never re-evaluated.

**Problem**: Tasks may need different priorities based on:
1. The actual urgency/importance revealed during expansion
2. Comparison with other tasks in the backlog
3. Dependencies or blocking relationships with higher-priority work

**Current Behavior**:
- `dk tasks new` → Priority `003` (Medium) hardcoded in `.doyaken/lib/cli.sh:776-802`
- `dk task "prompt"` → Priority `002` (High) for immediate execution
- Task selection in `get_next_available_task()` uses alphabetical sort (which effectively prioritizes by number)
- Neither EXPAND (phase 0) nor TRIAGE (phase 1) evaluates or adjusts priority

**Desired Behavior**:
1. New tasks could be created with a provisional/unknown priority
2. EXPAND phase should recommend a priority based on task classification
3. TRIAGE phase should compare against other tasks in backlog and:
   - Confirm or adjust the task's priority
   - If a higher-priority task exists, defer current task back to `2.todo/` and switch
4. Task filenames may need renaming when priority changes

---

## Acceptance Criteria

- [ ] EXPAND phase (`0-expand.md`) includes priority recommendation logic
- [ ] TRIAGE phase (`1-triage.md`) compares task priority against backlog
- [ ] If higher-priority tasks exist in `2.todo/`, agent defers current task and switches
- [ ] Task file rename mechanism exists when priority changes (update filename prefix)
- [ ] CLI helper function to rename task file when priority changes
- [ ] Documentation updated to explain dynamic priority behavior
- [ ] Tests written and passing (if applicable)
- [ ] Quality gates pass
- [ ] Changes committed with task reference

---

## Plan

(To be filled in during planning phase)

---

## Work Log

### 2026-02-02 02:01 - Created

- Task created via CLI

### 2026-02-02 05:52 - Task Expanded

- Intent: IMPROVE
- Scope: Modify EXPAND and TRIAGE phases to evaluate/compare priority dynamically
- Key files:
  - `.doyaken/prompts/phases/0-expand.md` - Add priority recommendation
  - `.doyaken/prompts/phases/1-triage.md` - Add backlog comparison and deferral logic
  - `.doyaken/lib/cli.sh` - Helper to rename task files on priority change
  - `.doyaken/lib/core.sh` - Task deferral/switch logic
- Complexity: Medium - Phase prompt changes are straightforward; file renaming needs care

### 2026-02-02 05:54 - Triage Complete

Quality gates:
- Lint: `scripts/lint.sh` (shellcheck)
- Types: N/A (shell scripts)
- Tests: `scripts/test.sh`
- Build: N/A (shell scripts, no compilation)
- Combined: `scripts/check-all.sh`

Task validation:
- Context: clear
- Criteria: specific (8 acceptance criteria)
- Dependencies: none

Complexity:
- Files: few (4 key files: 2 phase prompts, 2 lib scripts)
- Risk: medium (file renaming has race condition risk, mitigated by file locking)

Backlog check:
- `001-001-security-revoke-npm-token.md` in `3.doing/` (Critical) - waiting on user action (manual NPM token revocation), unassigned, agent work complete
- `003-006-quality-set-log-permissions.md` in `2.todo/` (Medium) - same priority
- `003-007-the-task-runner-workflow...` in `2.todo/` (Medium) - same priority

Ready: yes - task is well-defined, key files exist, no blockers

### 2026-02-02 05:56 - Triage Complete

Quality gates:
- Lint: `scripts/lint.sh` (shellcheck)
- Types: N/A (shell scripts)
- Tests: `scripts/test.sh`
- Build: N/A (shell scripts, no compilation)
- Combined: `scripts/check-all.sh`

Task validation:
- Context: clear
- Criteria: specific (8 acceptance criteria with testable checkboxes)
- Dependencies: none

Complexity:
- Files: few (4 key files)
- Risk: medium (file renaming needs care, mitigated by file locking)

Backlog check:
- `001-001-security-revoke-npm-token.md` in `3.doing/` (Critical) - blocked on user action, unassigned
- `003-005-if-something-goes-wrong...` in `3.doing/` (Medium) - in progress by worker-1
- `003-006-quality-set-log-permissions.md` in `2.todo/` (Medium) - available
- `003-007-the-task-runner-workflow...` in `2.todo/` (Medium) - available

No higher-priority unblocked tasks available. Proceeding with this task.

Ready: yes

---

## Notes

**In Scope:**
- Modify EXPAND phase to recommend priority based on intent/urgency
- Modify TRIAGE phase to compare against backlog and defer if needed
- Add CLI helper to rename task file when priority changes
- Add task deferral logic (move from `3.doing/` back to `2.todo/`)

**Out of Scope:**
- Automatic priority escalation over time
- Complex dependency graph analysis
- UI/dashboard for priority visualization
- Changing the core task ID format (keep `PPP-SSS-slug`)

**Assumptions:**
- Priority renaming preserves the sequence number and slug
- Agents can detect and handle renamed files gracefully
- Only one priority change per task lifecycle (during initial triage)

**Edge Cases:**
- Task already has explicit priority set by user → respect it, don't override
- All tasks in backlog are same or lower priority → proceed normally
- Task rename fails (file locked, permissions) → log error, don't crash
- Circular deferral (unlikely) → each agent picks alphabetically first available

**Risks:**
- **File rename race condition**: Two agents renaming same file
  - Mitigation: Use file locking during rename
- **Breaking existing task references**: Commits may reference old task ID
  - Mitigation: Log both old and new IDs in work log
- **Scope creep**: Adding too much intelligence to priority logic
  - Mitigation: Keep heuristics simple (compare numeric prefix only)

---

## Links

- `.doyaken/lib/cli.sh:776-802` - Task creation with default priority
- `.doyaken/lib/core.sh:1478-1502` - Task selection logic
- `.doyaken/prompts/phases/0-expand.md` - EXPAND phase definition
- `.doyaken/prompts/phases/1-triage.md` - TRIAGE phase definition

