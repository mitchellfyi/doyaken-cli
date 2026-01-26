# GitHub Actions Optimization

Performance optimization techniques for faster, more efficient workflows.

## When to Apply

Activate this guide when:
- Workflows are running slowly
- Build times need reduction
- CI costs need optimization
- Improving developer experience

---

## 1. Caching Strategies

### Dependency Caching

```yaml
# Node.js - Built-in cache
- uses: actions/setup-node@v4
  with:
    node-version: '20'
    cache: 'npm'

# Custom cache with restore keys
- uses: actions/cache@v4
  with:
    path: |
      ~/.npm
      node_modules
    key: ${{ runner.os }}-node-${{ hashFiles('**/package-lock.json') }}
    restore-keys: |
      ${{ runner.os }}-node-
```

### Build Cache

```yaml
# Next.js build cache
- uses: actions/cache@v4
  with:
    path: |
      ${{ github.workspace }}/.next/cache
    key: ${{ runner.os }}-nextjs-${{ hashFiles('**/package-lock.json') }}-${{ hashFiles('**/*.js', '**/*.jsx', '**/*.ts', '**/*.tsx') }}
    restore-keys: |
      ${{ runner.os }}-nextjs-${{ hashFiles('**/package-lock.json') }}-

# Docker layer caching
- uses: docker/build-push-action@v5
  with:
    context: .
    cache-from: type=gha
    cache-to: type=gha,mode=max
```

### Turbo Cache

```yaml
# Turborepo remote cache
- uses: actions/cache@v4
  with:
    path: .turbo
    key: ${{ runner.os }}-turbo-${{ github.sha }}
    restore-keys: |
      ${{ runner.os }}-turbo-

- run: npx turbo build --cache-dir=.turbo
```

---

## 2. Parallelization

### Parallel Jobs

```yaml
jobs:
  # Run independently in parallel
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: npm run lint

  typecheck:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: npm run typecheck

  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: npm test

  # Wait for all parallel jobs
  build:
    needs: [lint, typecheck, test]
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: npm run build
```

### Matrix Builds

```yaml
jobs:
  test:
    strategy:
      fail-fast: false  # Don't cancel others if one fails
      matrix:
        shard: [1, 2, 3, 4]

    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: npm test -- --shard=${{ matrix.shard }}/4
```

### Test Sharding

```yaml
# Jest sharding
- run: npm test -- --shard=${{ matrix.shard }}/${{ strategy.job-total }}

# Playwright sharding
- run: npx playwright test --shard=${{ matrix.shard }}/${{ strategy.job-total }}

# Vitest sharding
- run: npx vitest --shard=${{ matrix.shard }}/${{ strategy.job-total }}
```

---

## 3. Selective Execution

### Path Filtering

```yaml
on:
  push:
    paths:
      - 'src/**'
      - 'package.json'
      - '.github/workflows/ci.yml'
    paths-ignore:
      - '**.md'
      - 'docs/**'
      - '.vscode/**'
```

### Changed Files Detection

```yaml
jobs:
  changes:
    runs-on: ubuntu-latest
    outputs:
      frontend: ${{ steps.changes.outputs.frontend }}
      backend: ${{ steps.changes.outputs.backend }}
    steps:
      - uses: actions/checkout@v4
      - uses: dorny/paths-filter@v3
        id: changes
        with:
          filters: |
            frontend:
              - 'apps/web/**'
              - 'packages/ui/**'
            backend:
              - 'apps/api/**'
              - 'packages/db/**'

  test-frontend:
    needs: changes
    if: needs.changes.outputs.frontend == 'true'
    runs-on: ubuntu-latest
    steps:
      - run: npm test --workspace=apps/web

  test-backend:
    needs: changes
    if: needs.changes.outputs.backend == 'true'
    runs-on: ubuntu-latest
    steps:
      - run: npm test --workspace=apps/api
```

### Skip CI

```yaml
jobs:
  build:
    if: |
      !contains(github.event.head_commit.message, '[skip ci]') &&
      !contains(github.event.head_commit.message, '[ci skip]')
```

---

## 4. Checkout Optimization

### Shallow Clone

```yaml
- uses: actions/checkout@v4
  with:
    fetch-depth: 1  # Shallow clone (default)

# For operations needing history
- uses: actions/checkout@v4
  with:
    fetch-depth: 0  # Full history (slow)

# For generating changelog (limited history)
- uses: actions/checkout@v4
  with:
    fetch-depth: 100
```

### Sparse Checkout

```yaml
- uses: actions/checkout@v4
  with:
    sparse-checkout: |
      src
      package.json
      tsconfig.json
    sparse-checkout-cone-mode: false
```

### Submodules

```yaml
# Only if needed
- uses: actions/checkout@v4
  with:
    submodules: 'recursive'  # Adds time
    # Or fetch specific submodule later
```

---

## 5. Dependency Installation

### Faster npm

```yaml
# Use npm ci (faster than npm install)
- run: npm ci

# Skip optional dependencies
- run: npm ci --omit=optional

# Production only
- run: npm ci --omit=dev
```

### pnpm/yarn

```yaml
# pnpm (faster, disk efficient)
- uses: pnpm/action-setup@v2
  with:
    version: 8
- uses: actions/setup-node@v4
  with:
    node-version: '20'
    cache: 'pnpm'
- run: pnpm install --frozen-lockfile

# Yarn
- uses: actions/setup-node@v4
  with:
    node-version: '20'
    cache: 'yarn'
- run: yarn install --immutable
```

---

## 6. Concurrency Control

### Cancel Redundant Runs

```yaml
concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true
```

### Smart Concurrency

```yaml
concurrency:
  # Don't cancel production deploys
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: ${{ github.ref != 'refs/heads/main' }}
```

### Queue Management

```yaml
concurrency:
  # One deploy at a time per environment
  group: deploy-${{ github.event.inputs.environment }}
  cancel-in-progress: false
```

---

## 7. Runner Selection

### Larger Runners

```yaml
jobs:
  build:
    # Standard runner
    runs-on: ubuntu-latest

  heavy-build:
    # Larger runner (GitHub Teams/Enterprise)
    runs-on: ubuntu-latest-4-cores
    # Or
    runs-on: ubuntu-latest-8-cores
```

### Self-Hosted Runners

```yaml
jobs:
  build:
    runs-on: [self-hosted, linux, x64]
    # Benefits: Faster, cached dependencies, custom tools
```

### ARM Runners

```yaml
jobs:
  build:
    runs-on: ubuntu-24.04-arm  # ARM runner (faster for ARM builds)
```

---

## 8. Workflow Structure

### Reusable Workflows

```yaml
# Avoid duplication with reusable workflows
jobs:
  test:
    uses: ./.github/workflows/reusable-test.yml
    with:
      node-version: '20'
```

### Composite Actions

```yaml
# .github/actions/setup/action.yml
runs:
  using: 'composite'
  steps:
    - uses: actions/setup-node@v4
      with:
        node-version: '20'
        cache: 'npm'
    - run: npm ci
      shell: bash
```

### Job Outputs

```yaml
jobs:
  setup:
    outputs:
      cache-key: ${{ steps.cache.outputs.cache-hit }}
    steps:
      - id: cache
        uses: actions/cache@v4

  build:
    needs: setup
    if: needs.setup.outputs.cache-key != 'true'
```

---

## 9. Metrics & Monitoring

### Workflow Timing

```yaml
- name: Start timer
  id: timer
  run: echo "start=$(date +%s)" >> $GITHUB_OUTPUT

- name: Build
  run: npm run build

- name: Report timing
  run: |
    END=$(date +%s)
    DURATION=$((END - ${{ steps.timer.outputs.start }}))
    echo "Build took $DURATION seconds"
```

### Job Summary

```yaml
- name: Write summary
  run: |
    echo "## Build Results" >> $GITHUB_STEP_SUMMARY
    echo "- Duration: ${{ steps.timer.outputs.duration }}s" >> $GITHUB_STEP_SUMMARY
    echo "- Cache hit: ${{ steps.cache.outputs.cache-hit }}" >> $GITHUB_STEP_SUMMARY
```

---

## Optimization Checklist

### Quick Wins

- [ ] Enable dependency caching
- [ ] Use shallow checkout (fetch-depth: 1)
- [ ] Cancel redundant workflow runs
- [ ] Use `npm ci` instead of `npm install`
- [ ] Run jobs in parallel where possible

### Medium Effort

- [ ] Implement test sharding
- [ ] Add path-based filtering
- [ ] Use composite actions for common steps
- [ ] Enable build caching (Next.js, Turbo, etc.)
- [ ] Review and remove unused steps

### Advanced

- [ ] Self-hosted runners for heavy workloads
- [ ] Sparse checkout for large repos
- [ ] Custom Docker images with pre-installed dependencies
- [ ] Distributed testing across multiple runners

## References

- [GitHub Actions Caching](https://docs.github.com/en/actions/using-workflows/caching-dependencies-to-speed-up-workflows)
- [Larger Runners](https://docs.github.com/en/actions/using-github-hosted-runners/about-larger-runners)
- [Self-Hosted Runners](https://docs.github.com/en/actions/hosting-your-own-runners)
