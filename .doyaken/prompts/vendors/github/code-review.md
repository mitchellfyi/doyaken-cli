# GitHub Code Review

Comprehensive code review practices for GitHub pull requests.

## When to Apply

Activate this guide when:
- Reviewing pull requests
- Requesting code review
- Setting up review processes
- Training team on review practices

---

## 1. Review Process

### Multi-Pass Review Strategy

**Pass 1: High-Level Overview**
- Understand the PR purpose (read description first)
- Check file count and scope
- Verify PR size is manageable (< 400 lines ideal)
- Identify the main changes

**Pass 2: Architecture & Design**
- Does the approach make sense?
- Are there simpler alternatives?
- Does it fit existing patterns?
- Are there potential scalability issues?

**Pass 3: Implementation Details**
- Line-by-line code review
- Logic correctness
- Edge cases
- Error handling

**Pass 4: Quality & Polish**
- Code style consistency
- Naming clarity
- Documentation
- Test coverage

### Review Timing

```
PR Opened → First Review Within 24h
           ↓
Review Comments → Author Response Within 24h
           ↓
Re-review → Within 4h of Changes
           ↓
Approval → Merge Within 24h
```

---

## 2. What to Look For

### Critical Issues (Block Merge)

**Security:**
- [ ] No hardcoded secrets or credentials
- [ ] Input validation on user data
- [ ] SQL queries use parameterization
- [ ] No XSS vulnerabilities in output
- [ ] Authentication/authorization correct
- [ ] Sensitive data properly handled

**Correctness:**
- [ ] Logic matches requirements
- [ ] Edge cases handled
- [ ] Null/undefined checks present
- [ ] Race conditions addressed
- [ ] Resource cleanup (connections, files)

**Breaking Changes:**
- [ ] API compatibility maintained
- [ ] Database migrations reversible
- [ ] Configuration changes documented
- [ ] Deprecation warnings added

### Important Issues (Should Fix)

**Performance:**
- [ ] No N+1 query patterns
- [ ] Appropriate indexing
- [ ] No memory leaks
- [ ] Caching where beneficial
- [ ] Lazy loading for heavy resources

**Maintainability:**
- [ ] Code is readable
- [ ] Functions are focused (single responsibility)
- [ ] No deep nesting (> 3 levels)
- [ ] Magic numbers/strings extracted
- [ ] Complex logic commented

**Testing:**
- [ ] New code has tests
- [ ] Tests are meaningful (not just coverage)
- [ ] Edge cases tested
- [ ] Error paths tested

### Minor Issues (Nice to Fix)

**Style:**
- [ ] Consistent formatting
- [ ] Naming conventions followed
- [ ] Import organization
- [ ] Trailing whitespace

**Documentation:**
- [ ] JSDoc/docstrings present
- [ ] README updated if needed
- [ ] CHANGELOG entry added

---

## 3. Giving Feedback

### Comment Types

```markdown
# Required Change
🔴 **Required:** This needs null checking to prevent crashes.
```suggestion
if (user == null) {
  throw new Error('User not found');
}
```

# Suggestion
🟡 **Suggestion:** Consider extracting this to a helper function.

# Question
🔵 **Question:** What happens if this fails? Should we add retry logic?

# Nitpick
⚪ **Nit:** Typo in variable name: `recieve` → `receive`

# Praise
🟢 **Nice!** Clean solution using the builder pattern here.
```

### Effective Comment Writing

**Be Specific:**
```markdown
# Bad
This is confusing.

# Good
This function does three things: fetch, transform, and save.
Consider splitting into fetchUser(), transformUser(), saveUser().
```

**Explain Why:**
```markdown
# Bad
Don't use var.

# Good
Prefer `const` here since `userId` isn't reassigned.
This prevents accidental mutation and signals intent.
```

**Offer Solutions:**
```markdown
# Bad
This could be optimized.

# Good
This loop is O(n²). You could use a Map for O(n):
```suggestion
const userMap = new Map(users.map(u => [u.id, u]));
for (const order of orders) {
  const user = userMap.get(order.userId);
}
```
```

**Be Kind:**
```markdown
# Bad
This is wrong.

# Good
I think there might be an issue here - if `items` is empty,
this would throw. What do you think about adding a guard?
```

---

## 4. Requesting Review

### Making PRs Review-Friendly

**Keep PRs Small:**
- Aim for < 400 lines changed
- Single concern per PR
- Split large changes into series

**Write Good Descriptions:**
```markdown
## What
Brief summary of changes.

## Why
Context and motivation.

## How
Technical approach taken.

## Testing
How you verified it works.

## Screenshots
Visual changes if applicable.
```

**Self-Review First:**
- Review your own diff before requesting
- Add inline comments explaining non-obvious decisions
- Mark draft PRs until ready

**Guide Reviewers:**
```markdown
## Review Focus
Please pay special attention to:
- The caching strategy in `cache.ts`
- Error handling in the API layer
- Performance of the new query

No need to deeply review:
- Generated files in `/dist`
- Test fixtures
```

---

## 5. Review Decisions

### When to Approve

**Approve immediately if:**
- All tests pass
- No security concerns
- Code is clear and correct
- Changes match PR description
- Documentation updated

### When to Request Changes

**Block merge if:**
- Security vulnerability present
- Tests failing or missing
- Breaking change without migration
- Logic errors that would cause bugs
- Performance regression likely

### When to Comment Only

**Comment without blocking if:**
- Minor style suggestions
- Questions about approach
- Ideas for future improvement
- Educational feedback

---

## 6. GitHub-Specific Features

### Suggested Changes

```markdown
```suggestion
const result = items.filter(item => item.active);
```
```

### Review Summary

```markdown
## Summary

Overall this looks good! A few things to address:

### Must Fix
- [ ] Add null check in `processUser()`
- [ ] Fix race condition in `fetchData()`

### Should Consider
- [ ] Extract validation to separate function
- [ ] Add test for empty array case

### Optional
- [ ] Rename `tmp` to `temporaryResult`
```

### Batch Comments

Review the entire PR, then submit all comments together:
1. Add individual comments without submitting
2. Click "Review changes"
3. Write summary
4. Choose action (Approve/Request Changes/Comment)
5. Submit review

---

## 7. Review Etiquette

### For Reviewers

- Review within 24 hours
- Be constructive, not critical
- Assume good intent
- Ask questions rather than accuse
- Acknowledge good work
- Don't nitpick excessively

### For Authors

- Respond to all comments
- Don't take feedback personally
- Ask for clarification if needed
- Thank reviewers
- Re-request review after changes

### Handling Disagreements

```markdown
# If you disagree with feedback:

1. Understand the concern first
2. Explain your reasoning clearly
3. Provide evidence (benchmarks, docs)
4. Be open to compromise
5. Escalate to team lead if stuck

# Example response:
"I see your point about X. I chose this approach because [reason].
Would you be open to [alternative] as a middle ground?"
```

## References

- [GitHub Code Review](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/reviewing-changes-in-pull-requests)
- [Google Code Review Guidelines](https://google.github.io/eng-practices/review/)
- [Conventional Comments](https://conventionalcomments.org/)
