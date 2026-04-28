> **Note:** Phase 1 uses `--permission-mode bypassPermissions` with Claude calling
> `EnterPlanMode` as its first action. This audit is not active during plan mode —
> the quality checks are built into the /dkplan skill (Step 4: Plan Quality
> Checklist) and enforced before ExitPlanMode is called. This file is retained as
> reference documentation and as a fallback for manual stop-hook-based planning.

Before stopping, critically audit your plan:

1. COMPLETENESS — Does the plan cover every acceptance criterion from the ticket?
   - Re-read the ticket requirements. For each one, confirm there is a task that addresses it.
   - If any criterion is missing or only partially covered, add a task now.

2. EDGE CASES — Have you considered failure modes?
   - What happens when inputs are invalid, empty, or at boundary values?
   - What happens when external services are unavailable?
   - Are error messages helpful and specific?
   - If the plan doesn't account for these, add tasks or notes.

3. RESEARCH — Did the plan consider alternatives?
   - Were common pitfalls for the chosen approach researched?
   - Is there prior art in the codebase that was considered?
   - If the change is breaking, is a migration strategy documented?

4. DEPENDENCIES — Are tasks correctly ordered?
   - Would any task fail if run before another?
   - Are database migrations scheduled before code that depends on them?
   - Are shared types/interfaces created before consumers?

5. SCOPE — Is the plan minimal and focused?
   - Remove any task that isn't required by the acceptance criteria.
   - Don't plan for hypothetical future work.
   - If a task could be split, is it small enough to implement and test in one sitting?

6. RISKS — Are unknowns identified?
   - For each risk, is there a mitigation strategy or fallback?
   - Are there questions that need answers before implementation can start?

7. USER APPROVAL — Has the user explicitly approved this plan?
   - If the user hasn't responded yet, wait. Do not proceed without approval.

If you find gaps in any of the above, fix them and re-present the plan.

**Completion criteria** — all must be true before you stop:
- All acceptance criteria are covered by tasks
- Edge cases are accounted for
- The user has explicitly approved the plan

When all criteria are met, stop. The Stop hook will verify your work and provide completion instructions.
