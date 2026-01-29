# Chaos Testing Methodology

## Purpose
Systematically stress-test the project's codebase by exploring edge cases, error paths, and unexpected inputs.

## Test Categories

### 1. Input Validation
- Empty strings and null values
- Very long strings (1000+ chars)
- Unicode, emoji, RTL text
- Special characters: `<>'"&;|$(){}[]`
- Injection attempts: SQL, XSS, command injection
- Boundary values: 0, -1, MAX_INT, floats

### 2. Error Handling
- Missing required parameters
- Invalid file paths
- Network timeouts (if applicable)
- Malformed JSON/YAML/config
- Permission denied scenarios
- Out of memory / disk full edge cases

### 3. Concurrency & State
- Rapid repeated operations
- Parallel execution of same function
- Interrupted operations (partial writes)
- Race conditions in shared state
- Stale cache/data scenarios

### 4. Configuration
- Missing config files
- Empty config files
- Invalid config values
- Environment variable overrides
- Default value fallbacks

### 5. Integration Points
- API responses: empty, error, timeout
- File system: missing dirs, symlinks, permissions
- External dependencies unavailable
- Version mismatches

### 6. User Workflows
- Fresh install experience
- Upgrade from older version
- Multiple simultaneous users/sessions
- Undo/rollback operations

## Execution Process

1. **Identify entry points**: CLI commands, API endpoints, UI actions
2. **Map inputs**: What data does each accept?
3. **Generate chaos inputs**: Apply categories above to each input
4. **Execute systematically**: Run each chaos input, capture results
5. **Document failures**: Log crashes, unexpected behavior, poor error messages
6. **Prioritize fixes**: Security > Data loss > Crashes > UX

## Success Criteria
- No crashes on bad input (clean error messages)
- No security vulnerabilities exposed
- No data corruption or loss
- Consistent behavior across runs
- Graceful degradation when dependencies fail

## Output Format

Track results in a simple table:

| Test | Input | Expected | Actual | Status |
|------|-------|----------|--------|--------|
| ... | ... | ... | ... | PASS/FAIL |
