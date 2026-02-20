# Test Suite

This directory contains the test suite for doyaken-cli using [Bats](https://github.com/bats-core/bats-core).

## Running Tests

```bash
# Run all tests
npm run test

# Run specific test file
bats test/unit/core.bats

# Run tests matching a pattern
bats test/unit/core.bats --filter "session"
```

## Directory Structure

```
test/
├── unit/                  # Unit tests
│   ├── core.bats          # Core workflow functions
│   └── core_functions.sh  # Test harness with extracted functions
├── integration/           # Integration tests
│   └── workflow.bats      # End-to-end workflow tests
├── mocks/                 # Mock agent CLIs
│   ├── claude             # Mock Claude CLI
│   ├── codex              # Mock Codex CLI
│   └── gemini             # Mock Gemini CLI
├── test_helper.bash       # Common setup and utilities
└── run-bats.sh            # Test runner script
```

## Mock Agent CLIs

The `test/mocks/` directory contains mock implementations of agent CLIs that simulate real behavior without making API calls.

### Using Mocks

Add the mocks directory to PATH before the real CLI:

```bash
export PATH="$PROJECT_ROOT/test/mocks:$PATH"
```

### Mock Environment Variables

Control mock behavior with environment variables:

| Variable | Description | Default |
|----------|-------------|---------|
| `MOCK_EXIT_CODE` | Exit code to return | `0` |
| `MOCK_RATE_LIMIT` | Set to `1` to simulate rate limit (429) | - |
| `MOCK_TIMEOUT` | Set to `1` to exit with code 124 | - |
| `MOCK_DELAY` | Seconds to sleep before responding | - |
| `MOCK_OUTPUT` | Custom output to return | - |

### Example

```bash
# Simulate rate limit
MOCK_RATE_LIMIT=1 ./test/mocks/claude -p "test"

# Simulate timeout
MOCK_TIMEOUT=1 ./test/mocks/claude -p "test"

# Custom output and exit code
MOCK_OUTPUT="custom response" MOCK_EXIT_CODE=1 ./test/mocks/claude -p "test"
```

## Test Helpers

The `test_helper.bash` file provides utilities for test setup.

### Test Environment Setup

```bash
# Set up isolated test environment
setup_core_test_env

# Creates:
# - $DOYAKEN_PROJECT/.doyaken/state
# - $DOYAKEN_PROJECT/.doyaken/logs
```

### Mock Project Creation

```bash
# Create a mock project with manifest
create_mock_project "$TEST_TEMP_DIR/project"
```

## Writing Tests

### Test Pattern (AAA)

Follow the Arrange-Act-Assert pattern:

```bash
@test "session: save creates file with correct content" {
  # Arrange
  _setup_core_test

  # Act
  save_session "session-123" "running"

  # Assert
  local session_file="$STATE_DIR/session-test-worker"
  [ -f "$session_file" ]
  grep -q "SESSION_ID=\"session-123\"" "$session_file"
}
```

### Test Isolation

Each test runs in an isolated temporary directory:

- `setup()` creates `$TEST_TEMP_DIR`
- `teardown()` removes `$TEST_TEMP_DIR`
- Use `$TEST_TEMP_DIR` for all test artifacts

### Cross-Platform Compatibility

Handle macOS vs Linux differences:

```bash
# Date arithmetic
if date -v-4H &>/dev/null; then
  # macOS
  stale_time=$(date -v-4H '+%Y-%m-%d %H:%M:%S')
else
  # Linux
  stale_time=$(date -d '4 hours ago' '+%Y-%m-%d %H:%M:%S')
fi
```

## Test Categories

### Unit Tests (`test/unit/`)

Test individual functions in isolation:

- Model fallback (opus -> sonnet, gpt-5 -> o4-mini)
- Session state (save, load, clear, resume)
- Health checks (status tracking, consecutive failures)
- Prompt file resolution and include processing
- Verification gates and retry logic

### Integration Tests (`test/integration/`)

Test complete workflows:

- Single-shot prompt execution
- Verification gate pass/fail cycles
- Failure recovery and interrupt handling
- Phase resume after crash
