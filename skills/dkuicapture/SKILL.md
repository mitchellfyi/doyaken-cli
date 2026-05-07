---
name: "dkuicapture"
description: "Capture UI screenshots, Playwright traces, videos, and browser error logs for UI-affecting changes."
---

# Skill: dkuicapture

Capture visual evidence for UI work after implementation and before review.

## When to Use

- After `/dkimplement` finishes tasks that affect web UI, routes, components, styles, browser behavior, or user flows
- When a ticket asks for visual verification, screenshots, or video
- When debugging UI regressions with Playwright MCP or Chrome DevTools MCP

If the change does not affect UI, record `UI capture: N/A — no UI-affecting files changed` in the implementation evidence and stop.

## Artifact Rules

- Do **not** commit screenshots, videos, traces, generated flow scripts, or logs.
- Store artifacts only under Doyaken's artifact directory:
  - default: `~/.claude/.doyaken-artifacts/ui/<session>/`
  - override: `DK_ARTIFACT_DIR`
- Include absolute markdown links to the artifacts in the Phase 2 evidence table or final status.

## Steps

### 1. Ensure Tooling

Run the Doyaken bootstrap. It installs Playwright into Doyaken's tool cache and configures both Playwright MCP and Chrome DevTools MCP for Claude/Codex where the CLIs are available.

```bash
bash "${DOYAKEN_DIR:-$HOME/work/doyaken}/bin/ui-capture.sh" --install-only
```

If this fails because Node.js/npm/npx are missing or network install is blocked, stop and tell the user the exact prerequisite or command that failed. Otherwise, proceed without asking; Doyaken owns this tooling and keeps it outside the project repo.

### 2. Decide Whether UI Capture Is Required

Check changed files and the approved plan:

```bash
git diff --name-only
git diff --stat
```

Treat these as UI-affecting by default:

- Frontend source under directories such as `src/`, `app/`, `pages/`, `components/`, `routes/`, `views/`, `client/`, `web/`
- CSS, Sass, Tailwind, styled components, templates, Storybook stories
- Browser-side JS/TS/React/Vue/Svelte/Solid/Astro/Next/Remix changes
- API changes whose acceptance criteria include visible UI behavior

If only backend/CLI/docs/test-only files changed and no visible browser behavior is affected, record N/A.

### 3. Start the App

Use the project's existing commands. Prefer the package manager and scripts already in the repo:

- `npm run dev`, `pnpm dev`, `yarn dev`, `bun dev`
- `npm run start`, `pnpm start`, `yarn start`, `bun start`
- framework-specific scripts already present in `package.json`
- existing Storybook scripts if the changed UI is component-only

Run the server in the background, wait for the local URL to return a response, and stop the server after capture. Use a different port if the default is occupied.

### 4. Capture Screenshots and Traces

For each changed route or representative page, capture desktop, mobile, and a trace:

```bash
bash "${DOYAKEN_DIR:-$HOME/work/doyaken}/bin/ui-capture.sh" \
  --url "http://127.0.0.1:3000/path" \
  --name "ticket-route-name" \
  --desktop \
  --mobile \
  --trace
```

Inspect the generated logs:

- `console-errors.log`
- `page-errors.log`
- `network-errors.log`
- `http-errors.log`
- `metadata.json`

Fix real UI/runtime issues before Phase 2 completion. If a log entry is expected or unrelated, document why.

### 5. Capture Video for Interactive Flows

For changed flows involving clicks, forms, navigation, drag/drop, modals, menus, uploads, checkout, auth, onboarding, or other interactions, record video and trace.

Create the flow file inside the artifact directory, never in the repo:

```bash
source "${DOYAKEN_DIR:-$HOME/work/doyaken}/lib/common.sh"
session_id="${DOYAKEN_SESSION_ID:-$(dk_session_id)}"
flow_dir="$(dk_ui_capture_session_dir "$session_id")/flows"
mkdir -p "$flow_dir"
```

Flow file template:

```js
module.exports = async ({ page, screenshot }) => {
  await page.getByRole('button', { name: /open/i }).click();
  await screenshot('after-open');
  await page.getByRole('button', { name: /save/i }).click();
  await screenshot('after-save');
};
```

Then capture with video:

```bash
bash "${DOYAKEN_DIR:-$HOME/work/doyaken}/bin/ui-capture.sh" \
  --url "http://127.0.0.1:3000/path" \
  --name "flow-name" \
  --desktop \
  --mobile \
  --video \
  --trace \
  --flow "$flow_dir/flow-name.cjs"
```

The generated `.webm` files are the video evidence. The `.zip` traces can be opened with Playwright Trace Viewer.

### 6. Use MCP When Helpful

The bootstrap configures:

- Playwright MCP (`playwright`) for agent-controlled browser actions
- Chrome DevTools MCP (`chrome-devtools`) for console, network, performance, and live browser inspection

Use MCP tools when they are available in the session and they make debugging faster. The deterministic artifact command above remains the canonical evidence because it stores files in Doyaken's artifact directory.

### 7. Report Evidence

Report artifacts as absolute markdown links:

```markdown
UI capture:
- Desktop screenshot: [desktop.png](/absolute/path/to/desktop.png)
- Mobile screenshot: [mobile.png](/absolute/path/to/mobile.png)
- Video: [desktop video](/absolute/path/to/video.webm)
- Trace: [desktop trace](/absolute/path/to/desktop-trace.zip)
- Logs: [metadata.json](/absolute/path/to/metadata.json)
```

Do not mark UI capture complete unless screenshots exist and any required interactive-flow video exists.
