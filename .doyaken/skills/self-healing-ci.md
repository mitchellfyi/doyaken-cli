---
name: self-healing-ci
description: Self-healing CI setup and management
args:
  - name: action
    description: Action to perform (status, test, disable, enable)
    default: "status"
---

# Self-Healing CI Management

Manage and monitor the automated self-healing CI system.

## Overview

{{include:library/self-healing-ci.md}}

## Context

Project: {{DOYAKEN_PROJECT}}
Action: {{ARGS.action}}

## Actions

### Status Check

Show current state of the self-healing CI system:

```bash
# Check if workflow exists
ls -la .github/workflows/self-healing-ci.yml

# List recent self-healing workflow runs
gh run list --workflow=self-healing-ci.yml --limit 10

# List open ci-fix issues
gh issue list --label "ci-fix" --label "automated" --state open

# List issues needing human intervention
gh issue list --label "needs-human" --state open
```

### Testing

Test the self-healing workflow by intentionally breaking CI:

**⚠️ WARNING: Only do this on a test branch first!**

```bash
# Create a test branch
git checkout -b test-self-healing

# Break a test intentionally
# Example: Add a failing assertion to a test file
echo '
test_deliberate_failure() {
  # This test will fail intentionally to trigger self-healing
  [ "1" = "2" ]
}' >> test/test-example.bats

# Commit and push
git add test/test-example.bats
git commit -m "test: intentional failure to test self-healing"
git push origin test-self-healing

# Merge to main to trigger self-healing (ONLY in test environments)
# gh pr create --title "Test self-healing" --body "Testing self-healing workflow"
# gh pr merge --squash
```

**After testing:**
1. Verify issue was created with `ci-fix` and `automated` labels
2. Verify issue is assigned to `@copilot`
3. Verify logs are included and truncated properly
4. Clean up: fix the test and close the issue

### Disable Self-Healing

Temporarily disable during major refactors:

```bash
# Rename workflow to disable
mv .github/workflows/self-healing-ci.yml .github/workflows/self-healing-ci.yml.disabled

git add .github/workflows/
git commit -m "chore: temporarily disable self-healing CI"
git push
```

### Enable Self-Healing

Re-enable after maintenance:

```bash
# Rename back to enable
mv .github/workflows/self-healing-ci.yml.disabled .github/workflows/self-healing-ci.yml

git add .github/workflows/
git commit -m "chore: re-enable self-healing CI"
git push
```

## Monitoring

### Success Metrics

Track these metrics to evaluate self-healing effectiveness:

```bash
# Count ci-fix issues created this month
gh issue list --label "ci-fix" --json createdAt,state --jq \
  "[.[] | select(.createdAt > \"$(date -v-1m +%Y-%m-%d)\")] | length"

# Count issues closed by Copilot (success)
gh issue list --label "ci-fix" --state closed --limit 100 --json closedBy,title

# Count issues needing human intervention (escalation)
gh issue list --label "needs-human" --json number,title

# Show average time to fix
gh issue list --label "ci-fix" --state closed --limit 20 --json createdAt,closedAt
```

### Health Indicators

| Indicator | Healthy | Needs Attention |
|-----------|---------|-----------------|
| **Issues per month** | 0-2 | 3+ |
| **Success rate** | >80% | <80% |
| **Human escalations** | <20% | >20% |
| **Time to fix** | <24 hours | >48 hours |
| **Recurring failures** | 0 | 2+ same failure |

### Alert Conditions

Consider investigating if:
- ✋ 5+ `ci-fix` issues created in one week
- ✋ 3+ issues with `needs-human` label
- ✋ Same failure type appearing repeatedly
- ✋ Self-healing workflow itself is failing

## Troubleshooting

### Issue Not Created

**Symptom:** CI failed on main but no issue was created.

**Check:**
1. Did workflow run? `gh run list --workflow=self-healing-ci.yml --limit 5`
2. Check workflow logs: `gh run view [RUN_ID] --log`
3. Verify branch was `main` (not `master` or feature branch)
4. Verify conclusion was `failure` (not `cancelled`)

**Common causes:**
- Workflow file syntax error
- Insufficient permissions
- CI workflow name mismatch (must be "CI")
- Feature branch failure (self-healing only works on main)

### Duplicate Issues Created

**Symptom:** Multiple open `ci-fix` issues exist.

**Check:**
- Are they both labeled with `ci-fix` AND `automated`?
- Are they from the same workflow or different workflows?

**Fix:**
1. Close duplicate manually
2. Review the duplicate detection logic in workflow
3. Ensure both labels are being queried correctly

### Logs Truncated Too Much

**Symptom:** Issue created but logs don't show the actual error.

**Solution:**
Adjust truncation in `.github/workflows/self-healing-ci.yml`:

```yaml
# Current: tail -n 200
# Increase to: tail -n 300 or tail -n 500
gh api "/repos/${{ github.repository }}/actions/jobs/$JOB_ID/logs" \
  | tail -n 300 >> "$LOGS_FILE"
```

Note: GitHub issue body limit is 65,536 characters. Balance detail vs. limit.

### Escalation Not Working

**Symptom:** More than 3 automation comments but no `needs-human` label.

**Check:**
- Count comments manually: `gh issue view [NUMBER] --json comments`
- Filter by author: `.comments[] | select(.author.login == "github-actions[bot]")`

**Common cause:** Comment counting logic may need adjustment if comment format changed.

## Best Practices

### Use Self-Healing As a Safety Net

Don't rely on self-healing as primary quality control:
1. Write thorough tests locally
2. Run CI on feature branches
3. Use code review and branch protection
4. Fix issues before merging to main

Self-healing should be **rare**. If it's triggering often, fix the underlying process.

### Review Auto-Fixes

Even when Copilot successfully fixes an issue:
1. Review the PR before merging
2. Understand what broke and why
3. Consider if tests need improvement
4. Update documentation if behavior changed

### Regular Maintenance

Monthly checklist:
- [ ] Review closed `ci-fix` issues
- [ ] Check for `needs-human` issues
- [ ] Review metrics (success rate, time to fix)
- [ ] Update workflow if action versions changed
- [ ] Clean up stale issues

### Documentation

Keep team informed:
- Document known limitations
- Share self-healing metrics in retrospectives
- Update runbooks when patterns emerge
- Train team on when to disable/enable

## Advanced Configuration

### Customize Log Truncation

Edit `.github/workflows/self-healing-ci.yml`:

```yaml
# Per-job line limit (default: 200)
tail -n 200

# Total size limit (default: 60000 bytes)
if [ "$LOG_SIZE" -gt 60000 ]; then
```

### Adjust Escalation Threshold

Edit `.github/workflows/self-healing-ci.yml`:

```yaml
# Current: 3 comments before escalation
elif [ "$COMMENT_COUNT" -ge 3 ]; then

# Change to 5 for more retry attempts
elif [ "$COMMENT_COUNT" -ge 5 ]; then
```

### Customize Issue Template

Edit the issue body template in workflow for project-specific guidance:

```yaml
ISSUE_BODY=$(cat <<'EOF'
## CI Failure — Auto-generated

[Add project-specific context here]

...
EOF
)
```

## Output

```
## Self-Healing CI Status

### Current State
- Workflow: [enabled/disabled]
- Open ci-fix issues: [count]
- Needs human: [count]

### Recent Activity
- Last triggered: [timestamp]
- Last issue created: [timestamp]
- Last successful fix: [timestamp]

### Metrics (Last 30 Days)
- Total issues: [count]
- Success rate: [percentage]
- Avg time to fix: [hours]
- Human escalations: [count]

### Health: [HEALTHY / NEEDS ATTENTION]

[Recommendations based on metrics]
```

## Related Skills

- `ci-fix` - Manual CI failure diagnosis and fix
- `check-quality` - Run all quality checks locally
- `audit-deps` - Check for dependency vulnerabilities
