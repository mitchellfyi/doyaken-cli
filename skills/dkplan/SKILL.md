# Skill: dkplan

Create an implementation plan from a ticket or user request.

## When to Use

- At the start of new work, after the SessionStart hook has confirmed readiness
- When asked to plan work for a feature, bug fix, or refactor

## Steps

### 1. Gather Context

Use the integrations configured in doyaken.md § Integrations. Skip any that are "not configured".

**Ticket tracker:**
- Read the ticket — title, description, acceptance criteria, relations, comments.
- If no tracker is configured: gather requirements from the user's request, branch name, and local documentation.

**Design tool** (if configured and ticket references design URLs):
- Fetch design context and screenshots for referenced designs.

**Error monitoring** (if configured and ticket relates to a bug):
- Search for related errors to understand the bug context and stack traces.

**Related work:**
- If the ticket has related/blocking issues, read those too.
- Check recent git history for related changes: `git log --oneline -20`

### 2. Understand the Codebase

1. Read the relevant `AGENTS.md`, `CLAUDE.md`, or `README.md` for each area affected.
2. Read any project-specific conventions or rules referenced in those files.
3. Explore affected code paths — identify files to modify, patterns to follow, similar features to reference.
4. Search for existing utilities, components, and helpers that can be reused.

**Understanding check** — before drafting the plan, answer these five questions (to yourself):

1. What is the exact input and output of this change?
2. What existing code will this interact with?
3. What are the failure modes?
4. What is explicitly out of scope?
5. What would a reviewer challenge about this approach?

If you cannot answer all five confidently, gather more context.

### 3. Draft the Plan

For non-trivial tickets (more than a config change, typo fix, or single-file edit), present **2-3 approaches** before detailing the chosen one:

#### Approach Options (non-trivial tickets only)

| Approach | Description | Pros | Cons |
|----------|-------------|------|------|
| **Minimal** | Smallest change that meets requirements | Fast, low risk, easy to review | May need follow-up work |
| **Balanced** | Clean implementation following existing patterns | Maintainable, idiomatic | Takes longer |
| **Comprehensive** | Full solution with edge cases, optimisations, extensibility | Complete, future-proof | Largest scope, longest review |

Present the approaches briefly (2-3 sentences each), then recommend one with reasoning. For trivial tickets, skip this and go straight to the task list.

**Research mandate** (non-trivial tickets): before finalizing the approach, search for common pitfalls related to the chosen technology or pattern. Check: official documentation, similar implementations in the codebase, known issues in dependencies you'll use.

#### Task List

1. Write a numbered list of discrete work items. Each item should be:
   - Small enough to implement and test in one sitting
   - Clear about which files will be modified
   - Clear about which acceptance criteria it addresses
2. Include tasks for tests, documentation updates, and generated code refresh where applicable.
3. Note any dependencies between tasks (e.g., "migration must come before entity").
4. Identify risks, unknowns, or decisions that need user input.
5. Classify each change as additive (safe), modification (potentially breaking), or removal (breaking). Note migration needs for breaking changes.

### 4. Plan Quality Checklist

Before presenting the plan, verify it against these quality gates:

1. **COMPLETENESS** — Does the plan cover every acceptance criterion? Re-read the ticket/prompt requirements. For each one, confirm there is a task that addresses it. If any criterion is missing or only partially covered, add a task.
2. **EDGE CASES** — Have you considered failure modes? What happens with invalid/empty/boundary inputs? What happens when external services are unavailable? Are error messages helpful?
3. **RESEARCH** — Were common pitfalls for the chosen approach checked? Is there prior art in the codebase? Is a migration strategy documented for breaking changes?
4. **DEPENDENCIES** — Are tasks correctly ordered? Would any task fail if run before another? Are shared types/interfaces created before consumers?
5. **SCOPE** — Is the plan minimal and focused? Remove any task not required by the acceptance criteria. Do not plan for hypothetical future work.
6. **RISKS** — Are unknowns identified? For each risk, is there a mitigation or fallback? Are there questions needing answers before implementation?

If any gate fails, fix the plan before proceeding.

### 5. Track Tasks

1. Call `TaskCreate` for each work item in the plan.
2. Store task IDs for tracking during implementation.

### 6. Update Ticket (if tracker configured)

Add the plan summary to the ticket via the configured tracker. If no tracker is configured, skip — the plan exists in the conversation and task list.

### 7. Present to User

**STOP and present the plan to the user.**

Include:
- The numbered plan with task descriptions
- Files that will be modified
- Any questions or decisions needed
- Risks or unknowns identified

When running in plan mode (e.g., via `dk` Phase 1 or `dkloop`), present the plan via `ExitPlanMode`. The user approves or rejects through the plan mode UI.

**Do not begin implementation until the user approves the plan.**

## Notes

- Keep plans minimal — only what's needed for the current ticket.
- Don't plan for hypothetical future work.
- If the ticket is small (e.g., a typo fix or config change), the plan can be a single task.
