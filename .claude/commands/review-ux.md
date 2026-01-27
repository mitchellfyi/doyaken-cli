---
description: Apply review-ux methodology
---

# UX Review

## Mindset

- You are not your user - validate assumptions
- First impressions matter enormously
- Frustration compounds - many small issues add up
- Good UX is invisible - users notice bad UX

## CLI-Specific UX Principles

### 1. Discoverability
- `--help` should be comprehensive and well-organized
- Commands should be guessable (conventional names)
- Autocomplete support where possible
- Suggest corrections for typos

### 2. Feedback
- Confirm actions ("Created file X")
- Progress for long operations
- Clear error messages with solutions
- Exit codes for scripting

### 3. Efficiency
- Sensible defaults (zero-config start)
- Short flags for common options
- Batch operations support
- Pipe-friendly output

### 4. Safety
- Confirm destructive operations
- Dry-run mode for risky commands
- Undo information where possible
- No silent failures

## UX Assessment Areas

### First-Run Experience

- [ ] Can users install in < 5 minutes?
- [ ] First command gives useful output?
- [ ] Clear next steps provided?
- [ ] Onboarding/tutorial available?
- [ ] Example use cases documented?

### Help & Documentation

- [ ] `--help` is clear and complete
- [ ] Commands are logically grouped
- [ ] Examples included in help text
- [ ] Man pages available (if applicable)
- [ ] README covers common scenarios

### Error Handling

- [ ] Errors are human-readable
- [ ] Errors suggest solutions
- [ ] Errors include relevant context
- [ ] Stack traces hidden by default
- [ ] Exit codes are meaningful

### Output & Formatting

- [ ] Output is parseable (JSON option)
- [ ] Output is readable (colors, formatting)
- [ ] Verbosity levels available
- [ ] Quiet mode for scripts
- [ ] Progress indicators for long tasks

### Configuration

- [ ] Works without config (sensible defaults)
- [ ] Config file location is discoverable
- [ ] Config options are documented
- [ ] Environment variables supported
- [ ] Config can be validated

### Common Tasks

For each common workflow:
- How many steps/commands required?
- Are there shortcuts for frequent operations?
- Is the happy path obvious?
- Are edge cases handled gracefully?

## UX Audit Checklist

### Installation
- [ ] Single-line install available
- [ ] Multiple package managers supported
- [ ] Version pinning possible
- [ ] Upgrade path is clear
- [ ] Uninstall is clean

### Getting Started
- [ ] `init` command (if applicable)
- [ ] Working example in < 2 minutes
- [ ] No unnecessary prerequisites
- [ ] Clear feedback on success

### Daily Use
- [ ] Most common task is easiest
- [ ] Tab completion works
- [ ] History/undo available
- [ ] Aliases/shortcuts documented

### Troubleshooting
- [ ] `doctor`/`check` command available
- [ ] Debug/verbose mode
- [ ] Logs are accessible
- [ ] Community support findable

## UX Issue Template

```
### Issue: [Title]

**Severity**: Blocker / Major / Minor / Cosmetic

**User Impact**: [What user experiences]

**Observed Behavior**: [What happens]

**Expected Behavior**: [What should happen]

**Reproduction Steps**:
1. [step 1]
2. [step 2]
3. [step 3]

**Affected User Segment**: [Who hits this]

**Suggested Fix**: [Proposed solution]
```

## Assessment Template

```
## UX Assessment Report

### Overview
- Project: [name]
- Type: [CLI/API/Web/etc.]
- Assessment date: [date]

### First Impressions Score

| Area | Score (1-5) | Notes |
|------|-------------|-------|
| Installation | | |
| First run | | |
| Documentation | | |
| Error messages | | |
| Overall polish | | |

### User Journey Analysis

**Journey: [Common Task Name]**

| Step | Current | Friction | Suggestion |
|------|---------|----------|------------|
| 1 | [what user does] | [pain point] | [improvement] |
| 2 | | | |

### Issues Found

| ID | Severity | Area | Issue | Fix |
|----|----------|------|-------|-----|
| 1 | Major | Onboarding | [issue] | [fix] |
| 2 | Minor | Help text | [issue] | [fix] |

### Strengths
- [what's working well]
- [good patterns observed]

### Priority Improvements

**High Impact / Quick Fix:**
1. [improvement 1]
2. [improvement 2]

**High Impact / More Effort:**
1. [improvement 1]
2. [improvement 2]

**Nice to Have:**
1. [improvement 1]
```

## UX Testing Prompts

Ask yourself (or real users):

1. **Can you explain what this does from the help text alone?**
2. **What would you type to [common task]?**
3. **This error appeared - what would you do next?**
4. **How would you learn about [less common feature]?**
5. **What's confusing or frustrating?**

## Quick Wins for CLI UX

- Add missing examples to `--help`
- Improve the worst error message
- Add colors for readability
- Add a progress spinner for slow commands
- Create an alias for the most common operation
- Add `--dry-run` to destructive commands
- Include "next steps" in success output
- Add command suggestions for typos

---

Apply this methodology to the current context. If given a specific file or code, analyze it according to these guidelines.
