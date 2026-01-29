---
name: test-user
description: Run manual user testing on the project
category: testing
---

# User Testing Skill

Simulate real user behavior to find usability issues and broken workflows.

## Usage

```bash
doyaken skill test-user
```

## What It Does

1. Picks a random user persona and starting state
2. Attempts common workflows as that user would
3. Documents friction, confusion, and failures
4. Reports findings with reproduction steps

## Methodology

{{include:library/test-user.md}}

## Execution

When invoked:

### 1. Determine Test Context

Roll for persona (pick randomly):
- **Careful Reader**: Reads help, follows instructions exactly
- **Impatient Clicker**: Skips docs, tries obvious commands
- **Explorer**: Pokes around, tries variations, tests limits

Roll for starting state:
- **Fresh**: No prior setup or data
- **Existing**: Project already configured with data
- **Partial**: Some setup done, some missing

### 2. Identify Entry Points

Find what a user would interact with:
- CLI commands
- Configuration files
- API endpoints
- UI elements

### 3. Run Test Scenarios

For each entry point, as the chosen persona:

**a) First Contact**
- Try the most obvious action
- Check what happens with no arguments
- Look at help/usage output

**b) Happy Path**
- Complete the primary workflow
- Note any friction or confusion
- Time the operation

**c) Error Path**
- Intentionally make mistakes
- Check error message quality
- Verify recovery options

**d) Edge Cases**
- Empty inputs
- Very long inputs
- Special characters
- Interruption mid-task

### 4. Document Findings

Create a test report with:
- Test session metadata
- Each scenario tested
- Issues found (with severity)
- Improvement suggestions

### 5. Create Tasks (Optional)

For significant issues found:
- Create doyaken tasks for fixes
- Include reproduction steps
- Prioritize by user impact

## Example Test Run

```markdown
## Test Session: 2024-01-15 14:30

### Persona: Impatient Clicker
### Starting State: Fresh install

### Test 1: Create first item
- **Goal**: Add something to the system
- **Steps**: Ran `app add` with no args
- **Expected**: Prompt for what to add
- **Actual**: Cryptic error "missing required field"
- **Result**: FRICTION
- **Notes**: Error should say which field and how to provide it

### Issues Found
| Severity | Description | Reproduction |
|----------|-------------|--------------|
| Medium | Unhelpful error on missing args | Run `app add` with no arguments |
| Low | No tab completion for commands | Try tab after `app ` |

### Suggestions
- Add interactive prompts for required fields
- Include examples in error messages
```

## Tips

- Don't assume knowledge the user wouldn't have
- Test in a clean environment when possible
- Document your actual confusion, not what "should" confuse users
- Small friction adds up - note everything
