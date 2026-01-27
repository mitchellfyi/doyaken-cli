# npm Publishing Guide

## Current Setup

The package `@doyaken/doyaken` is published to npm automatically when you push a version tag.

**Published locations:**
- npm: https://www.npmjs.com/package/@doyaken/doyaken
- GitHub Releases: https://github.com/mitchellfyi/doyaken-cli/releases

## How to Publish a New Version

1. Update version in `package.json`
2. Commit the change
3. Create and push a tag:
   ```bash
   git tag v0.x.x
   git push origin v0.x.x
   ```
4. The GitHub Action will automatically:
   - Run validation checks
   - Publish to npm
   - Create a GitHub Release

## Required Secrets

Add these to GitHub repo settings (Settings → Secrets → Actions):

| Secret | Description |
|--------|-------------|
| `NPM_TOKEN` | npm automation token with publish access |

### Creating an npm Token

1. Go to https://www.npmjs.com/settings/YOUR_USERNAME/tokens
2. Click **Generate New Token** → **Granular Access Token**
3. Configure:
   - Token name: `github-actions`
   - Expiration: as needed
   - Packages: `@doyaken/doyaken` or "All packages"
   - Permissions: **Read and write**
4. Copy token and add as `NPM_TOKEN` secret in GitHub

## TODO: Enable GitHub Packages

GitHub Packages requires the npm scope (`@doyaken`) to match the GitHub owner/org name. Currently the repo is under `mitchellfyi`, so GitHub Packages won't work.

### Steps to Enable

- [ ] Create `doyaken` organization on GitHub
  - Go to https://github.com/organizations/new
  - Create organization named `doyaken`

- [ ] Transfer the repository
  - Go to repo Settings → Danger Zone → Transfer ownership
  - Transfer to the `doyaken` organization

- [ ] Update workflow to publish to GitHub Packages
  - Add `packages: write` permission
  - Add GitHub Packages publish step:
    ```yaml
    - name: Setup Node.js for GitHub Packages
      uses: actions/setup-node@v4
      with:
        node-version: 20
        registry-url: 'https://npm.pkg.github.com'
        scope: '@doyaken'

    - name: Publish to GitHub Packages
      run: npm publish --access public
      env:
        NODE_AUTH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
    ```

- [ ] Update package.json repository URLs to new org
  ```json
  "repository": {
    "type": "git",
    "url": "git+https://github.com/doyaken/doyaken-cli.git"
  }
  ```

- [ ] Verify package appears at https://github.com/orgs/doyaken/packages

## Troubleshooting

### Error: Two-factor authentication required
Use a **Granular Access Token** or **Automation** token instead of a classic token.

### Error: Repository URL mismatch (provenance)
The `repository.url` in package.json must match the actual GitHub repo URL.

### Error: owner not found (GitHub Packages)
The package scope must match the GitHub owner. Create a matching org or use your username as scope.
