# Chaos Testing Methodology

## Purpose
Systematically stress-test the project by exploring edge cases, error paths, unexpected inputs, and platform compatibility issues.

## CRITICAL: Actually Execute Everything

**The #1 testing failure is not running code.** Unit tests alone miss:
- Runtime path issues
- Shell compatibility problems
- Environment-specific failures
- Integration breakages

**Rule: If you didn't run it, you didn't test it.**

## Test Categories

### 1. Platform & Shell Compatibility (CLI Tools)
This catches issues like bash 3.x vs 4.x syntax differences.

**Shell syntax validation:**
```bash
# Check for bash 4+ features that break on macOS
grep -r '\${[a-zA-Z_]*\^\^' lib/     # ${var^^} uppercase
grep -r '\${[a-zA-Z_]*,,' lib/       # ${var,,} lowercase
grep -r '\${![a-zA-Z_]*\[@\]}' lib/  # ${!array[@]} indirect
grep -r 'declare -A' lib/            # associative arrays
grep -r 'readarray\|mapfile' lib/    # bash 4+ builtins
grep -r '&>>' lib/                   # append redirect both
grep -r '\|&' lib/                   # pipe stderr
```

**Execution testing:**
```bash
# Test with macOS default bash
/bin/bash script.sh

# Test with explicit bash 3.2 if available
bash-3.2 script.sh 2>/dev/null || true

# Check shebang lines
grep -l '^#!/.*bash' **/*.sh | xargs head -1
```

**Required checks:**
- [ ] All scripts run on bash 3.2 (macOS default)
- [ ] All scripts run on bash 5.x (modern Linux)
- [ ] Shebang uses `/usr/bin/env bash` not `/bin/bash`
- [ ] No bash 4+ syntax without fallbacks

### 2. Input Validation
- Empty strings and null values
- Very long strings (1000+ chars)
- Unicode, emoji, RTL text
- Special characters: `<>'"&;|$(){}[]`
- Injection attempts: SQL, XSS, command injection
- Boundary values: 0, -1, MAX_INT, floats
- Paths with spaces: `/path/with spaces/file.txt`
- Paths with special chars: `/path/with-$pecial/file.txt`

### 3. Error Handling
- Missing required parameters
- Invalid file paths
- Network timeouts (if applicable)
- Malformed JSON/YAML/config
- Permission denied scenarios
- Out of memory / disk full edge cases

### 4. Concurrency & State
- Rapid repeated operations
- Parallel execution of same function
- Interrupted operations (Ctrl+C mid-task)
- Race conditions in shared state
- Stale cache/data scenarios

### 5. Configuration
- Missing config files
- Empty config files
- Invalid config values
- Environment variable overrides
- Default value fallbacks
- Conflicting settings

### 6. Integration Points
- API responses: empty, error, timeout
- File system: missing dirs, symlinks, permissions
- External dependencies unavailable (jq, yq, etc.)
- Version mismatches

### 7. CLI-Specific Testing
**Run every command path:**
```bash
# List all commands
dk help

# Test each with no args
dk init
dk version
dk upgrade
dk tasks
dk skills
dk run
# ... every command

# Test with --help
dk init --help
dk upgrade --help
# ... every command

# Test with invalid args
dk init --invalid-flag
dk upgrade --bad-option
# ... every command

# Test with edge case args
dk init ""
dk init "path with spaces"
dk init "../../../etc/passwd"
```

### 8. User Workflows (End-to-End)
Test complete journeys, not isolated commands:

```bash
# Fresh install workflow
rm -rf ~/.doyaken
npm install -g doyaken
dk version
dk init test-project
cd test-project
dk tasks
dk run 1

# Upgrade workflow
dk upgrade --check
dk upgrade --force
dk upgrade verify

# Recovery workflow
dk upgrade --rollback
dk upgrade list-backups
```

## Execution Process

1. **Static analysis first**: Run grep checks for known anti-patterns
2. **Execute every entry point**: Run all CLI commands with various inputs
3. **Follow user journeys**: Complete multi-step workflows end-to-end
4. **Stress test**: Rapid/parallel execution, interruption
5. **Document everything**: Log exact commands and outputs
6. **Fix before release**: No known failures in production

## Success Criteria
- No crashes on bad input (clean error messages)
- No security vulnerabilities exposed
- No data corruption or loss
- Consistent behavior across runs
- Graceful degradation when dependencies fail
- **Works on macOS default bash (3.2)**
- **Works on modern Linux bash (5.x)**

## Output Format

```markdown
## Chaos Test Run: [date]

### Platform Checks
| Check | Status | Notes |
|-------|--------|-------|
| Bash 3.2 syntax | PASS/FAIL | ... |
| All commands run | PASS/FAIL | ... |

### Command Testing
| Command | Args | Expected | Actual | Status |
|---------|------|----------|--------|--------|
| dk init | (none) | prompt or error | ... | PASS/FAIL |
| dk init | --help | show help | ... | PASS/FAIL |

### Workflow Testing
| Workflow | Steps | Result | Issues |
|----------|-------|--------|--------|
| Fresh install | 5 | PASS/FAIL | ... |

### Issues Found
| Severity | Description | Repro Steps |
|----------|-------------|-------------|
| CRITICAL | ... | ... |
```
