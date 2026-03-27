# Skill: Doyaken

Orchestrate the full ticket lifecycle from planning through completion.

## When to Use

- After the SessionStart hook has loaded context and confirmed readiness
- When the user says "doyaken", "start", "go", "begin work", or invokes `/doyaken`

## Lifecycle

The `dk` wrapper runs each phase as a separate Claude Code session, auto-advancing between them. Each phase has an audit loop that critically reviews the work before allowing completion.

### Phase 1: Plan

1. Run `/dkplan` — gather context from the configured tracker (see doyaken.md § Integrations), draft implementation plan, create tasks.
2. **[STOP]** Present the plan to the user. Wait for approval.
3. If the user requests changes, revise and re-present.
4. Output `PHASE_1_COMPLETE` when the user approves.

### Phase 2: Implement

1. Run `/dkimplement` — work through tasks with TDD discipline.
2. **[STOP]** if ambiguous requirements, scope changes, or blocked dependencies arise.
3. The `/dkimplement` skill automatically runs `/dkreview` after all tasks are done.
4. The audit loop re-runs `/dkreview` until it returns PASS with zero findings.
5. Output `PHASE_2_COMPLETE` when self-review passes and manual review finds no issues.

### Phase 3: Verify & Commit

1. Run `/dkverify` — format, lint, typecheck, generate, test.
2. Fix any failures. Re-run until all green (max 3 retries per check).
3. Run `/dkcommit` — atomic conventional commits, push to origin.
4. Output `PHASE_3_COMPLETE` when all checks pass and code is pushed.

### Phase 4: PR

1. Run `/dkpr` — generate PR description, update tracker if available.
2. **[STOP]** Present the PR to the user. Wait for approval to mark ready.
3. On approval: mark ready, request automated reviews if configured.
4. Output `PHASE_4_COMPLETE` when the user approves.

### Phase 5: Complete

1. Monitoring loops are already running (launched by `/dkpr` in Phase 4):
   - `/loop 2m /dkwatchci` — checking CI status, fixing failures
   - `/loop 5m /dkwatchpr` — checking review comments, addressing feedback
2. **[STOP]** if a loop escalates (CI failures after 3 attempts, architectural review comments, secrets scan).
3. When both loops complete, run `/dkcomplete` — verify all green, update tracker to Done (if available), print summary.
4. Output `DOYAKEN_TICKET_COMPLETE` when everything is verified.

## Resuming

If the session is interrupted, `dk 999` or `dk --resume` picks up from the saved phase. Phase tracking is handled by the `dk` shell wrapper (see `dk.sh` `__dk_run_phases`), which persists the current phase number in `~/.claude/.doyaken-phases/<session_id>.phase`. The wrapper is responsible for advancing phases and re-launching Claude with the correct phase message and audit prompt.

As a fallback (e.g., when running `/doyaken` interactively without the wrapper), the agent can infer the correct phase by checking current state:

1. **Check for existing PR**: `gh pr view --json state,isDraft,statusCheckRollup`
   - No PR → Phase 1 (Plan)
   - Draft PR, no commits → Phase 1 (Plan)
   - Draft PR with implementation commits → Phase 3 (Verify & Commit)
   - Ready PR with failing CI → Phase 5 (Complete — monitor and fix)
   - Ready PR with all checks green → Phase 5 (Complete — finalize)

2. **Check task list**: If tasks exist from a prior `/dkplan`, offer to resume from the first incomplete task rather than re-planning.

3. **Check ticket state** (if tracker configured):
   - In progress → work underway
   - In review → monitor
   - Done/closed → nothing to do
   - If no tracker: infer from PR and git state above.

## Decision Points Summary

| Phase | Trigger | Action |
|-------|---------|--------|
| 1 | Plan ready | Present plan, wait for approval |
| 2 | Ambiguous requirement | Present options, ask user to choose |
| 2 | Scope change needed | Explain impact, ask approval |
| 4 | PR ready for review | Present summary, ask user to confirm |
| 5 | CI secrets scan failure | Cancel all loops, alert immediately |
| 5 | 3 failed CI fix attempts | Cancel loops, escalate with details |
| 5 | Architectural review comment | Cancel loops, escalate to user |

## Autonomous Mode (Phase Audit Loops)

When the session is started with `DOYAKEN_LOOP_ACTIVE=1` (set automatically by `dk`), a Stop hook prevents premature exit and injects a phase-specific audit prompt. Each phase has its own quality criteria — the loop continues until the audit is satisfied. This enables quality-gated autonomous execution:

- If `/dkverify` fails → fix and retry automatically
- If `/dkreview` finds issues → fix and re-review automatically
- If CI fails → fix and re-push automatically
- If reviews have comments → address and re-push automatically

The loop continues until:
1. **Completion promise**: Output `DOYAKEN_TICKET_COMPLETE` when ALL of these are true:
   - All tasks completed
   - PR merged or approved with all checks green
   - All review comments addressed
   - Ticket updated to Done (if tracker configured)
2. **Max iterations reached** (default: 30) — safety net to prevent runaway costs
3. **User interrupts** — the user can always take over

### When to output the completion promise

Only output `DOYAKEN_TICKET_COMPLETE` when you have verified:
- `gh pr view --json state,mergedAt,statusCheckRollup` shows all checks passed
- No unresolved review threads
- Ticket state is "Done" or "Closed" (if tracker configured)

### Escalation in autonomous mode

Even in autonomous mode, STOP and escalate to the user for:
- Secrets scan failures (never auto-fix)
- Architectural review comments (need human judgement)
- 3+ failed attempts at the same fix
- Scope changes that affect other tickets

## Notes

- The user can interrupt at any point and the agent should gracefully stop.
- Each phase naturally flows into the next — no manual invocation needed after `/doyaken`.
- The agent should provide brief status updates at phase transitions (e.g., "Plan approved. Starting implementation...").
- Keep the configured ticket tracker updated throughout (see doyaken.md § Integrations). If no tracker is configured, the conversation and PR serve as the record.
