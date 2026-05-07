# UI Capture

Doyaken can capture visual evidence for browser-facing changes. The default path is automatic: if Phase 2 changes UI code, `/dkimplement` invokes `/dkuicapture` before review.

## What It Captures

- Desktop and mobile screenshots
- Playwright trace ZIPs
- WebM video for interactive flows
- Console, page, network, and HTTP error logs
- Metadata linking each artifact to the captured URL

Artifacts are written outside the repo:

```text
~/.claude/.doyaken-artifacts/ui/<session>/
```

Override with `DK_ARTIFACT_DIR`. These files are evidence, not source, and should not be committed.

## Setup

`dk install` and `dk init` install or repair the browser tooling:

- Playwright in `~/.claude/.doyaken-tools/ui-capture/`
- Playwright MCP for Claude and Codex when those CLIs are installed
- Chrome DevTools MCP for Claude and Codex when those CLIs are installed

Check status:

```bash
dk status
```

Repair manually:

```bash
bash "$DOYAKEN_DIR/bin/ui-capture.sh" --install-only
```

## Manual Capture

Start the app with the repo's normal dev command, then run:

```bash
bash "$DOYAKEN_DIR/bin/ui-capture.sh" \
  --url "http://127.0.0.1:3000" \
  --name "home-page" \
  --desktop \
  --mobile \
  --trace
```

For interactions, add `--video` and a flow file stored outside the repo:

```js
module.exports = async ({ page, screenshot }) => {
  await page.getByRole('button', { name: /open/i }).click();
  await screenshot('opened');
  await page.getByRole('button', { name: /save/i }).click();
  await screenshot('saved');
};
```

```bash
bash "$DOYAKEN_DIR/bin/ui-capture.sh" \
  --url "http://127.0.0.1:3000/settings" \
  --name "settings-flow" \
  --desktop \
  --mobile \
  --video \
  --trace \
  --flow "$HOME/.claude/.doyaken-artifacts/ui/manual/settings-flow.cjs"
```

The command prints absolute paths for the screenshots, traces, videos, metadata, and logs. Use those paths as markdown links in the Phase 2 evidence.

## Logs

Each run writes:

| File | Meaning |
|------|---------|
| `console-errors.log` | Browser console warnings/errors |
| `page-errors.log` | Unhandled page exceptions |
| `network-errors.log` | Failed requests |
| `http-errors.log` | HTTP responses with status 400+ |
| `metadata.json` | URLs, viewport names, and artifact paths |

Fix real runtime issues before Phase 2 completes. If an entry is expected or unrelated, note why in the evidence.

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| `Node.js, npm, and npx are required` | Install Node.js, then rerun `dk install` |
| MCP servers are incomplete | Run `bash "$DOYAKEN_DIR/bin/ui-capture.sh" --install-only` |
| App is not reachable | Start the dev server first and use the printed local URL |
| Video is missing | Pass `--video`; video files are written after the browser context closes |
| Trace will not open | Use Playwright Trace Viewer, or rerun with `--trace` if the ZIP is missing |
