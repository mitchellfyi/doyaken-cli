#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

function parseArgs(argv) {
  const options = {
    waitMs: 1000,
    desktop: false,
    mobile: false,
    video: false,
    trace: false,
  };

  for (let i = 0; i < argv.length; i += 1) {
    const arg = argv[i];
    switch (arg) {
      case '--url':
        options.url = argv[++i];
        break;
      case '--out':
        options.out = argv[++i];
        break;
      case '--name':
        options.name = argv[++i];
        break;
      case '--wait-ms':
        options.waitMs = Number(argv[++i]);
        break;
      case '--desktop':
        options.desktop = true;
        break;
      case '--mobile':
        options.mobile = true;
        break;
      case '--video':
        options.video = true;
        break;
      case '--trace':
        options.trace = true;
        break;
      case '--flow':
        options.flow = argv[++i];
        break;
      default:
        throw new Error(`Unknown argument: ${arg}`);
    }
  }

  if (!options.url) {
    throw new Error('Missing required --url');
  }
  if (!options.out) {
    throw new Error('Missing required --out');
  }
  if (!Number.isFinite(options.waitMs) || options.waitMs < 0) {
    throw new Error('--wait-ms must be a non-negative number');
  }
  if (!options.desktop && !options.mobile) {
    options.desktop = true;
    options.mobile = true;
  }

  return options;
}

function slugify(value) {
  return String(value || 'capture')
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '')
    .slice(0, 80) || 'capture';
}

function writeLines(filePath, lines) {
  fs.writeFileSync(filePath, `${lines.join('\n')}${lines.length ? '\n' : ''}`);
}

function playwrightModule() {
  const toolsDir = process.env.DX_UI_CAPTURE_TOOLS_DIR;
  if (!toolsDir) {
    throw new Error('DX_UI_CAPTURE_TOOLS_DIR is not set');
  }
  return require(path.join(toolsDir, 'node_modules', 'playwright'));
}

async function safeGoto(page, url) {
  try {
    await page.goto(url, { waitUntil: 'networkidle', timeout: 45000 });
  } catch (error) {
    if (!/networkidle|Navigation timeout/i.test(String(error && error.message))) {
      throw error;
    }
    await page.goto(url, { waitUntil: 'domcontentloaded', timeout: 45000 });
  }
}

async function runViewport({ browser, playwright, options, viewportName, viewport }) {
  const outDir = options.out;
  const videoDir = path.join(outDir, 'video', viewportName);
  const contextOptions = {
    viewport,
    deviceScaleFactor: 1,
    ignoreHTTPSErrors: true,
  };

  if (viewportName === 'mobile') {
    Object.assign(contextOptions, playwright.devices['iPhone 15']);
  }

  if (options.video) {
    fs.mkdirSync(videoDir, { recursive: true });
    contextOptions.recordVideo = {
      dir: videoDir,
      size: viewport,
    };
  }

  const context = await browser.newContext(contextOptions);
  const tracePath = path.join(outDir, `${viewportName}-trace.zip`);
  if (options.trace) {
    await context.tracing.start({ screenshots: true, snapshots: true, sources: true });
  }

  const page = await context.newPage();
  const consoleErrors = [];
  const pageErrors = [];
  const networkErrors = [];
  const responses = [];

  page.on('console', (message) => {
    if (['error', 'warning'].includes(message.type())) {
      consoleErrors.push(`[${message.type()}] ${message.text()}`);
    }
  });
  page.on('pageerror', (error) => pageErrors.push(error.stack || error.message || String(error)));
  page.on('requestfailed', (request) => {
    const failure = request.failure();
    networkErrors.push(`${request.method()} ${request.url()} :: ${failure ? failure.errorText : 'failed'}`);
  });
  page.on('response', (response) => {
    if (response.status() >= 400) {
      responses.push(`${response.status()} ${response.url()}`);
    }
  });

  await safeGoto(page, options.url);
  if (options.waitMs > 0) {
    await page.waitForTimeout(options.waitMs);
  }

  if (options.flow) {
    const flowPath = path.resolve(options.flow);
    const flow = require(flowPath);
    const runner = typeof flow === 'function' ? flow : flow.run;
    if (typeof runner !== 'function') {
      throw new Error(`Flow file must export a function or { run }; got ${flowPath}`);
    }
    await runner({
      page,
      context,
      viewportName,
      artifactsDir: outDir,
      screenshot: async (name) => {
        const screenshotPath = path.join(outDir, `${viewportName}-${slugify(name)}.png`);
        await page.screenshot({ path: screenshotPath, fullPage: true });
        return screenshotPath;
      },
    });
    if (options.waitMs > 0) {
      await page.waitForTimeout(options.waitMs);
    }
  }

  const screenshotPath = path.join(outDir, `${viewportName}.png`);
  await page.screenshot({ path: screenshotPath, fullPage: true });

  if (options.trace) {
    await context.tracing.stop({ path: tracePath });
  }

  await context.close();

  const videoFiles = options.video && fs.existsSync(videoDir)
    ? fs.readdirSync(videoDir).filter((file) => file.endsWith('.webm')).map((file) => path.join(videoDir, file))
    : [];

  return {
    viewport: viewportName,
    screenshot: screenshotPath,
    trace: options.trace ? tracePath : null,
    videos: videoFiles,
    consoleErrors,
    pageErrors,
    networkErrors,
    httpErrors: responses,
  };
}

async function main() {
  const options = parseArgs(process.argv.slice(2));
  fs.mkdirSync(options.out, { recursive: true });

  const playwright = playwrightModule();
  const browser = await playwright.chromium.launch({ headless: true });
  const results = [];

  try {
    if (options.desktop) {
      results.push(await runViewport({
        browser,
        playwright,
        options,
        viewportName: 'desktop',
        viewport: { width: 1440, height: 1000 },
      }));
    }
    if (options.mobile) {
      results.push(await runViewport({
        browser,
        playwright,
        options,
        viewportName: 'mobile',
        viewport: { width: 390, height: 844 },
      }));
    }
  } finally {
    await browser.close();
  }

  const metadata = {
    url: options.url,
    capturedAt: new Date().toISOString(),
    flow: options.flow ? path.resolve(options.flow) : null,
    results,
  };

  fs.writeFileSync(path.join(options.out, 'metadata.json'), JSON.stringify(metadata, null, 2));
  writeLines(path.join(options.out, 'console-errors.log'), results.flatMap((result) => result.consoleErrors.map((line) => `[${result.viewport}] ${line}`)));
  writeLines(path.join(options.out, 'page-errors.log'), results.flatMap((result) => result.pageErrors.map((line) => `[${result.viewport}] ${line}`)));
  writeLines(path.join(options.out, 'network-errors.log'), results.flatMap((result) => result.networkErrors.map((line) => `[${result.viewport}] ${line}`)));
  writeLines(path.join(options.out, 'http-errors.log'), results.flatMap((result) => result.httpErrors.map((line) => `[${result.viewport}] ${line}`)));

  const artifactLinks = [];
  for (const result of results) {
    artifactLinks.push(`${result.viewport} screenshot: ${result.screenshot}`);
    if (result.trace) {
      artifactLinks.push(`${result.viewport} trace: ${result.trace}`);
    }
    for (const video of result.videos) {
      artifactLinks.push(`${result.viewport} video: ${video}`);
    }
  }
  artifactLinks.push(`metadata: ${path.join(options.out, 'metadata.json')}`);
  artifactLinks.push(`logs: ${options.out}`);

  console.log(artifactLinks.join('\n'));
}

main().catch((error) => {
  console.error(error && error.stack ? error.stack : String(error));
  process.exit(1);
});
