# GitHub Actions Workflows

Comprehensive guide to creating effective CI/CD workflows with GitHub Actions.

## When to Apply

Activate this guide when:
- Creating new CI/CD workflows
- Setting up automated testing
- Configuring deployment pipelines
- Building reusable workflows

---

## 1. Workflow Structure

### Basic Workflow

```yaml
name: CI

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

permissions:
  contents: read

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Build
        run: npm run build

      - name: Test
        run: npm test
```

### Trigger Events

```yaml
on:
  # Branch events
  push:
    branches: [main, 'release/**']
    paths:
      - 'src/**'
      - 'package.json'
    paths-ignore:
      - '**.md'
      - 'docs/**'

  pull_request:
    branches: [main]
    types: [opened, synchronize, reopened]

  # Manual trigger
  workflow_dispatch:
    inputs:
      environment:
        description: 'Deployment environment'
        required: true
        default: 'staging'
        type: choice
        options:
          - staging
          - production

  # Scheduled (cron)
  schedule:
    - cron: '0 0 * * 1'  # Every Monday at midnight

  # From other workflows
  workflow_call:
    inputs:
      node-version:
        required: false
        type: string
        default: '20'
    secrets:
      NPM_TOKEN:
        required: true

  # External events
  repository_dispatch:
    types: [deploy]
```

---

## 2. Job Configuration

### Job Dependencies

```yaml
jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: npm run lint

  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: npm test

  build:
    needs: [lint, test]  # Wait for both
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: npm run build

  deploy:
    needs: build
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    steps:
      - run: echo "Deploying..."
```

### Matrix Builds

```yaml
jobs:
  test:
    runs-on: ${{ matrix.os }}
    strategy:
      fail-fast: false
      matrix:
        os: [ubuntu-latest, windows-latest, macos-latest]
        node-version: [18, 20, 22]
        exclude:
          - os: windows-latest
            node-version: 18
        include:
          - os: ubuntu-latest
            node-version: 20
            coverage: true

    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js ${{ matrix.node-version }}
        uses: actions/setup-node@v4
        with:
          node-version: ${{ matrix.node-version }}

      - run: npm ci
      - run: npm test

      - name: Upload coverage
        if: matrix.coverage
        uses: codecov/codecov-action@v4
```

### Conditional Execution

```yaml
jobs:
  deploy:
    if: |
      github.event_name == 'push' &&
      github.ref == 'refs/heads/main' &&
      !contains(github.event.head_commit.message, '[skip ci]')

    steps:
      - name: Deploy to staging
        if: github.event.inputs.environment == 'staging'
        run: ./deploy.sh staging

      - name: Deploy to production
        if: github.event.inputs.environment == 'production'
        run: ./deploy.sh production
```

---

## 3. Reusable Workflows

### Creating a Reusable Workflow

```yaml
# .github/workflows/reusable-test.yml
name: Reusable Test Workflow

on:
  workflow_call:
    inputs:
      node-version:
        description: 'Node.js version'
        required: false
        type: string
        default: '20'
      working-directory:
        description: 'Working directory'
        required: false
        type: string
        default: '.'
    secrets:
      NPM_TOKEN:
        required: false
    outputs:
      coverage:
        description: 'Test coverage percentage'
        value: ${{ jobs.test.outputs.coverage }}

jobs:
  test:
    runs-on: ubuntu-latest
    outputs:
      coverage: ${{ steps.coverage.outputs.value }}

    defaults:
      run:
        working-directory: ${{ inputs.working-directory }}

    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-node@v4
        with:
          node-version: ${{ inputs.node-version }}
          cache: 'npm'

      - run: npm ci

      - run: npm test -- --coverage
        id: test

      - name: Extract coverage
        id: coverage
        run: echo "value=$(cat coverage/coverage-summary.json | jq '.total.lines.pct')" >> $GITHUB_OUTPUT
```

### Calling a Reusable Workflow

```yaml
# .github/workflows/ci.yml
name: CI

on:
  push:
    branches: [main]

jobs:
  test:
    uses: ./.github/workflows/reusable-test.yml
    with:
      node-version: '20'
    secrets:
      NPM_TOKEN: ${{ secrets.NPM_TOKEN }}

  report:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - run: echo "Coverage: ${{ needs.test.outputs.coverage }}%"
```

### Composite Actions

```yaml
# .github/actions/setup-project/action.yml
name: 'Setup Project'
description: 'Setup Node.js and install dependencies'

inputs:
  node-version:
    description: 'Node.js version'
    required: false
    default: '20'

runs:
  using: 'composite'
  steps:
    - name: Setup Node.js
      uses: actions/setup-node@v4
      with:
        node-version: ${{ inputs.node-version }}
        cache: 'npm'

    - name: Install dependencies
      run: npm ci
      shell: bash

    - name: Verify installation
      run: npm ls --depth=0
      shell: bash
```

---

## 4. Environment & Secrets

### Environments

```yaml
jobs:
  deploy-staging:
    runs-on: ubuntu-latest
    environment:
      name: staging
      url: https://staging.example.com

    steps:
      - run: ./deploy.sh
        env:
          API_URL: ${{ vars.API_URL }}
          API_KEY: ${{ secrets.API_KEY }}

  deploy-production:
    needs: deploy-staging
    runs-on: ubuntu-latest
    environment:
      name: production
      url: https://example.com

    steps:
      - run: ./deploy.sh
        env:
          API_URL: ${{ vars.API_URL }}
          API_KEY: ${{ secrets.API_KEY }}
```

### OIDC Authentication

```yaml
jobs:
  deploy:
    runs-on: ubuntu-latest
    permissions:
      id-token: write
      contents: read

    steps:
      - uses: actions/checkout@v4

      # AWS
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::123456789:role/github-actions
          aws-region: us-east-1

      # Azure
      - name: Azure login
        uses: azure/login@v2
        with:
          client-id: ${{ secrets.AZURE_CLIENT_ID }}
          tenant-id: ${{ secrets.AZURE_TENANT_ID }}
          subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}

      # GCP
      - name: GCP auth
        uses: google-github-actions/auth@v2
        with:
          workload_identity_provider: projects/123/locations/global/workloadIdentityPools/github/providers/github
          service_account: github-actions@project.iam.gserviceaccount.com
```

---

## 5. Artifacts & Caching

### Caching Dependencies

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      # Built-in cache with setup-node
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'

      # Custom caching
      - name: Cache build
        uses: actions/cache@v4
        with:
          path: |
            ~/.npm
            node_modules
            .next/cache
          key: ${{ runner.os }}-build-${{ hashFiles('**/package-lock.json') }}
          restore-keys: |
            ${{ runner.os }}-build-

      - run: npm ci
      - run: npm run build
```

### Sharing Artifacts

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: npm ci && npm run build

      - name: Upload build
        uses: actions/upload-artifact@v4
        with:
          name: build-output
          path: dist/
          retention-days: 1

  deploy:
    needs: build
    runs-on: ubuntu-latest
    steps:
      - name: Download build
        uses: actions/download-artifact@v4
        with:
          name: build-output
          path: dist/

      - run: ./deploy.sh dist/
```

---

## 6. Common Patterns

### CI Pipeline

```yaml
name: CI

on:
  push:
    branches: [main]
  pull_request:

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
      - run: npm ci
      - run: npm run lint

  typecheck:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
      - run: npm ci
      - run: npm run typecheck

  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
      - run: npm ci
      - run: npm test

  build:
    needs: [lint, typecheck, test]
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
      - run: npm ci
      - run: npm run build
```

### CD Pipeline

```yaml
name: CD

on:
  push:
    branches: [main]
  workflow_dispatch:
    inputs:
      environment:
        type: choice
        options: [staging, production]

jobs:
  deploy:
    runs-on: ubuntu-latest
    environment: ${{ github.event.inputs.environment || 'staging' }}

    steps:
      - uses: actions/checkout@v4

      - name: Deploy
        run: ./deploy.sh ${{ github.event.inputs.environment || 'staging' }}
        env:
          DEPLOY_TOKEN: ${{ secrets.DEPLOY_TOKEN }}
```

### Release Pipeline

```yaml
name: Release

on:
  push:
    tags:
      - 'v*'

jobs:
  release:
    runs-on: ubuntu-latest
    permissions:
      contents: write

    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          registry-url: 'https://registry.npmjs.org'

      - run: npm ci
      - run: npm run build
      - run: npm publish
        env:
          NODE_AUTH_TOKEN: ${{ secrets.NPM_TOKEN }}

      - name: Create Release
        uses: softprops/action-gh-release@v2
        with:
          generate_release_notes: true
```

## References

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Workflow Syntax](https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions)
- [Reusable Workflows](https://docs.github.com/en/actions/using-workflows/reusing-workflows)
