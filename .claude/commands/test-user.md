---
description: Apply test-user methodology
---

# User Testing Methodology

## Purpose
Simulate real user behavior to find usability issues, broken workflows, and edge cases that automated tests miss.

## Philosophy
- Think like a user, not a developer
- Users don't read documentation first
- Users take unexpected paths
- Users make typos and mistakes
- Users get interrupted mid-task

## Test Categories

### 1. First-Time User Experience
- What happens with zero setup?
- Are error messages helpful?
- Is the happy path obvious?
- Can a user succeed without docs?

### 2. Common Workflows
- Complete the most frequent tasks end-to-end
- Don't skip steps a real user would take
- Note friction points and confusion
- Time how long things take

### 3. Recovery Scenarios
- What if the user cancels mid-operation?
- What if they close the terminal?
- What if they run the wrong command?
- Can they undo/recover from mistakes?

### 4. Exploration Behavior
- Try commands without arguments
- Use `--help` on everything
- Tab-complete where possible
- Try variations users might guess

### 5. Real Data
- Use realistic names and values
- Test with actual file sizes
- Include special characters users type
- Test with existing data present

## Execution Approach

### Random but Thorough
Pick randomly from each category but ensure coverage:

```
1. Roll for starting point:
   - Fresh install (40%)
   - Existing project (40%)
   - Partially configured (20%)

2. Roll for user persona:
   - Careful reader (20%)
   - Impatient clicker (40%)
   - Explorer/tinkerer (40%)

3. Roll for task complexity:
   - Single action (30%)
   - Multi-step workflow (50%)
   - Complex scenario (20%)
```

### Document Everything
For each test:
- Starting state
- Exact commands/actions taken
- What the user expected
- What actually happened
- Confusion points
- Suggestions

## Success Metrics
- User can complete task without external help
- Error messages lead to resolution
- No data loss on mistakes
- Consistent behavior across runs
- Reasonable response times

## Output Format

```markdown
## Test Session: [timestamp]

### Persona: [type]
### Starting State: [description]

### Test 1: [workflow name]
- **Goal**: What the user wants to accomplish
- **Steps taken**: Exact sequence
- **Expected**: What user thought would happen
- **Actual**: What happened
- **Result**: PASS / FRICTION / FAIL
- **Notes**: Observations

### Issues Found
| Severity | Description | Reproduction |
|----------|-------------|--------------|
| ... | ... | ... |

### Suggestions
- ...
```

---

Apply this methodology to the current context. If given a specific file or code, analyze it according to these guidelines.
