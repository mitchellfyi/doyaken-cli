---
name: test-chaos
description: Run chaos monkey testing on the project codebase
category: testing
---

# Chaos Test Skill

Run comprehensive chaos testing on the current project to find edge cases, error handling issues, and potential vulnerabilities.

## Usage

```bash
doyaken skill test-chaos
```

## What It Does

1. Identifies testable entry points in the codebase
2. Generates edge case inputs for each entry point
3. Executes tests and captures results
4. Reports failures and unexpected behavior

## Methodology

{{include:library/test-chaos.md}}

## Execution

When invoked:

1. **Analyze the codebase**:
   - Find CLI commands, API endpoints, or main entry points
   - Identify input parameters and their types
   - Note any existing validation or error handling

2. **Generate test plan**:
   - List specific chaos inputs for each entry point
   - Prioritize security-sensitive areas
   - Include both valid edge cases and invalid inputs

3. **Execute tests**:
   - Run each test systematically
   - Capture stdout, stderr, exit codes
   - Note any crashes, hangs, or unexpected output

4. **Report findings**:
   - Create a summary of issues found
   - Categorize by severity (Critical/High/Medium/Low)
   - Suggest fixes where applicable

5. **Create tasks** (optional):
   - For each issue found, create a doyaken task
   - Include reproduction steps and expected behavior

## Example Chaos Inputs

```
# Strings
""
"   "
"a" * 10000
"<script>alert('xss')</script>"
"'; DROP TABLE users;--"
"$(rm -rf /)"
"hello\x00world"

# Numbers
0, -1, -999999999
999999999999999999
3.14159, -0.0001
NaN, Infinity

# Files
"/nonexistent/path"
"../../../etc/passwd"
"/dev/null"
"file with spaces.txt"
```

## Notes

- Run in a safe environment (not production)
- Some tests may require manual verification
- Focus on security-critical paths first
