# Self-Healing CI

## Overview

Automated system that detects CI failures on the main branch and creates structured issues for autonomous fixing by AI coding agents.

This is a **safety net** for regressions and unexpected failures, NOT a replacement for proper CI practices.

## How It Works

1. **Detection**: The `self-healing-ci.yml` workflow triggers when CI fails on `main`
2. **Log Collection**: Fetches failure logs from failed jobs (last 200 lines per job)
3. **Issue Management**: Creates or updates a GitHub issue with:
   - Descriptive title with commit SHA
   - Link to failed workflow run
   - Clear fix instructions
   - Truncated failure logs
   - Assignment to `@copilot`
4. **Rate Limiting**: 
   - Prevents duplicate issues (only one open `ci-fix` issue at a time)
   - After 3 automated fix attempts, escalates with `needs-human` label
   - Never creates issues for self-healing workflow failures (prevents loops)

## When It Triggers

✅ **DOES trigger on:**
- CI failures on the `main` branch
- First occurrence (creates new issue)
- Subsequent failures (adds comment to existing issue)

❌ **Does NOT trigger on:**
- Feature branch failures (developer's responsibility)
- Cancelled workflows (only `failure` status)
- Successful CI runs
- Self-healing workflow failures (prevents infinite loops)

## Issue Format

The generated issue follows this template:

```markdown
## CI Failure — Auto-generated

The CI workflow failed on branch `main` at commit `<SHA>`.

**Failed run:** <URL>

## Task

Analyze the failure logs below and fix the code that is causing CI to fail.

**Rules:**
- Fix the root cause in the source code, tests, or configuration
- Do NOT skip, disable, or mark any tests as expected failures
- Do NOT add `continue-on-error` or any other workaround that masks the failure
- Run the full test suite locally before submitting your PR
- Keep your changes minimal and focused on the fix

## Failure Logs

<truncated logs from each failed job>
```

## Labels Used

| Label | Color | Purpose |
|-------|-------|---------|
| `ci-fix` | `#d73a4a` | Marks automated CI fix requests |
| `automated` | `#0e8a16` | Indicates automation-created issue |
| `needs-human` | `#e99695` | Escalation after 3 failed attempts |

Labels are automatically created if they don't exist.

## Rate Limiting & Safety

### Duplicate Prevention
- Only one open `ci-fix` + `automated` issue at a time
- New failures add comments to existing issue instead of creating duplicates
- Prevents issue spam from repeated CI failures

### Escalation to Human
After **3 automated comments** on the same issue:
1. Adds `needs-human` label
2. Stops adding more automation comments
3. Posts escalation message explaining the situation

This prevents infinite loops when the fix is complex or requires architectural changes.

### Loop Prevention
The workflow **never** triggers for failures in:
- `self-healing-ci.yml` itself
- Any workflow other than the main `CI` workflow

This prevents recursive issue creation.

## Workflow Permissions

Minimal permissions required:
```yaml
permissions:
  issues: write    # Create/update issues and labels
  actions: read    # Fetch workflow run details
  checks: read     # Access job logs
```

No repository write access needed — changes come through PRs like normal.

## Optional: Auto-Merge Setup

For true self-healing, you can add auto-merge when Copilot's fix passes CI.

**Requirements:**
- Second GitHub account or GitHub App (workflows can't approve their own PRs)
- Trigger on PRs from `copilot/**` branches
- Wait for CI to pass
- Only auto-approve if changes touch files related to original failure

**Trade-offs:**
- ✅ Faster recovery from CI failures
- ✅ Reduces manual review burden
- ❌ Requires additional GitHub account/app setup
- ❌ Potential for unexpected changes if not carefully scoped
- ❌ May bypass code review for subtle issues

**Recommendation:** Start without auto-merge. Let issues get created and reviewed manually first. Add auto-merge later once you trust the system.

## Testing the Workflow

### Test Case 1: Basic Failure Detection
1. Create a branch with a broken test
2. Merge to `main` (CI will fail)
3. Verify issue is created with:
   - Correct title format
   - Failure logs included
   - Assigned to `@copilot`
   - Has `ci-fix` and `automated` labels

### Test Case 2: Duplicate Prevention
1. Push another failing commit to `main` before first issue is fixed
2. Verify no new issue is created
3. Verify existing issue gets a new comment with updated logs

### Test Case 3: Human Escalation
1. Let CI fail 3 more times (triggering 3 comments on the issue)
2. On the 4th failure, verify:
   - No new comment is added
   - `needs-human` label is added
   - Escalation message is posted

### Test Case 4: Loop Prevention
1. If the self-healing workflow itself fails, verify:
   - No issue is created
   - No infinite loop occurs

## Integration with CI/CD

This workflow complements existing CI best practices:

1. **Primary Defense**: Proper testing, code review, branch protection
2. **Secondary Defense**: CI catches issues before merge
3. **Tertiary Defense**: Self-healing catches regressions on main

The self-healing system should fire **rarely**. If it's triggering often:
- Your CI may be flaky
- Tests may be insufficient
- Code review process needs strengthening
- Consider stricter branch protection rules

## Monitoring

Track self-healing effectiveness:
- Number of `ci-fix` issues created per month
- Success rate (issues closed by Copilot vs. needs-human)
- Time to fix (issue creation to PR merge)
- Recurrence rate (same failure happening multiple times)

If success rate is low or recurrence is high, the system may need tuning or the failures may be too complex for autonomous fixing.

## Limitations

**What self-healing CAN fix:**
- Broken tests due to code changes
- Dependency version conflicts
- Environment-specific issues
- Missing permissions or file modes
- Simple logic errors

**What self-healing CANNOT fix:**
- Architectural problems requiring design decisions
- Flaky tests with intermittent failures
- Infrastructure or external service issues
- Issues requiring human judgment or context
- Complex race conditions or timing issues

**When to disable:**
During major refactors or infrastructure changes, consider temporarily disabling the workflow to prevent noise.

## Maintenance

### Regular Reviews
- Check `needs-human` issues monthly
- Review auto-fix success patterns
- Update issue template if instructions are unclear
- Adjust log truncation if logs are insufficient

### Workflow Updates
- Keep action versions pinned and up to date
- Test changes to self-healing workflow in feature branches
- Never push self-healing changes directly to main (test first!)

### Label Cleanup
Periodically close or archive old `ci-fix` issues that were resolved but not properly closed.

## Related Resources

- `.github/workflows/self-healing-ci.yml` - Workflow implementation
- `.doyaken/prompts/library/ci.md` - CI best practices
- `.doyaken/skills/ci-fix.md` - Manual CI fix skill
- `CONTRIBUTING.md` - Development workflow and CI guidelines
