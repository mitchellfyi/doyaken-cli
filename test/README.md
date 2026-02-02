# Test Suite

This directory contains the test suite for doyaken-cli using [Bats](https://github.com/bats-core/bats-core).

## Running Tests

```bash
# Run all tests
npm run test

# Run specific test file
bats test/unit/core.bats

# Run tests matching a pattern
bats test/unit/core.bats --filter "lock"
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

### Lock Management

```bash
# Create a lock file
create_test_lock "task-001" "agent-id" "$$"

# Create a stale lock (backdated 4 hours)
create_stale_lock "task-001"

# Wait for lock to appear/disappear
wait_for_lock "task-001" 5 "exists"   # Wait up to 5s for lock
wait_for_lock "task-001" 5 "gone"     # Wait up to 5s for removal
```

### Task Creation

```bash
# Create task in specific folder
create_test_task "003-001-my-task" "todo"
create_test_task "003-001-my-task" "doing" "# Custom content"
```

### Background Process Tracking

```bash
# Track background process for cleanup
track_background sleep 10

# Clean up all tracked processes (called in teardown)
cleanup_background_processes
```

### Test Environment Setup

```bash
# Set up isolated test environment
setup_core_test_env

# Creates:
# - $DOYAKEN_PROJECT/.doyaken/tasks/{1.blocked,2.todo,3.doing,4.done}
# - $DOYAKEN_PROJECT/.doyaken/locks
# - $DOYAKEN_PROJECT/.doyaken/state
# - $DOYAKEN_PROJECT/.doyaken/logs
```

## Writing Tests

### Test Pattern (AAA)

Follow the Arrange-Act-Assert pattern:

```bash
@test "lock: acquire creates lock file with correct content" {
  # Arrange
  setup_core_test_env
  source_core_functions
  local task_id="003-001-test-task"

  # Act
  acquire_lock "$task_id"

  # Assert
  [ -f "$LOCKS_DIR/${task_id}.lock" ]
  grep -q "AGENT_ID=\"$AGENT_ID\"" "$LOCKS_DIR/${task_id}.lock"
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

- Lock acquisition/release
- Stale lock detection
- Task selection
- Model fallback
- Session state
- Backoff calculation

### Integration Tests (`test/integration/`)

Test complete workflows:

- Task state transitions (todo → doing → done)
- Concurrent agent coordination
- Failure recovery
- Interrupted workflow resume
