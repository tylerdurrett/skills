#!/usr/bin/env node
/**
 * Authenticated screenshot tool for the Iterator TV dev app.
 *
 * Handles login, navigation, and screenshot capture in a single browser
 * session.
 *
 * Usage:
 *   node app-screenshot.mjs --url <page-url> --output <file-path> [options]
 *
 * Options:
 *   --url         Full URL or path (e.g. /home/dev-team/projects/...)
 *   --output      Screenshot output path (required)
 *   --email       Login email        (default: test@iterator.tv)
 *   --password    Login password      (default: testingpassword)
 *   --base-url    App base URL        (default: auto-detected from .env.local)
 *   --width       Viewport width      (default: 1920)
 *   --height      Viewport height     (default: 1080)
 *   --format      Image format        (default: jpeg)
 *   --quality     JPEG quality 0-100  (default: 80)
 *   --wait        Extra wait ms after page load (default: 2000)
 *   --timeout     Navigation timeout ms (default: 20000)
 *   --selector    CSS selector to screenshot instead of full page
 *   --full-page   Capture full scrollable page (default: false)
 *   --no-login    Skip login, navigate directly
 *   --light       Use light mode (default is dark mode)
 */
import puppeteer from 'puppeteer';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

function parseArgs(argv) {
  const args = {};
  for (let i = 0; i < argv.length; i++) {
    if (argv[i].startsWith('--')) {
      const key = argv[i].slice(2);
      const next = argv[i + 1];
      if (next && !next.startsWith('--')) {
        args[key] = next;
        i++;
      } else {
        args[key] = 'true';
      }
    }
  }
  return args;
}

/** Read PORT from apps/web/.env.local, walking up from the script location. */
function detectBaseUrl() {
  // Walk up from the skill scripts dir to find the project root
  let dir = __dirname;
  for (let i = 0; i < 10; i++) {
    const envPath = path.join(dir, 'apps', 'web', '.env.local');
    if (fs.existsSync(envPath)) {
      const content = fs.readFileSync(envPath, 'utf8');
      const match = content.match(/^PORT=(\d+)/m);
      if (match) return `http://localhost:${match[1]}`;
    }
    dir = path.dirname(dir);
  }
  return 'http://localhost:7200';
}

function output(data) {
  console.log(JSON.stringify(data, null, 2));
}

async function run() {
  const args = parseArgs(process.argv.slice(2));

  if (!args.url) {
    output({ success: false, error: '--url is required' });
    process.exit(1);
  }
  if (!args.output) {
    output({ success: false, error: '--output is required' });
    process.exit(1);
  }

  const baseUrl = args['base-url'] || detectBaseUrl();
  const email = args.email || 'test@iterator.tv';
  const password = args.password || 'testingpassword';
  const width = parseInt(args.width || '1920');
  const height = parseInt(args.height || '1080');
  const format = args.format || 'jpeg';
  const quality = parseInt(args.quality || '80');
  const extraWait = parseInt(args.wait || '2000');
  const timeout = parseInt(args.timeout || '20000');
  const skipLogin = args['no-login'] === 'true';
  const fullPage = args['full-page'] === 'true';
  const lightMode = args.light === 'true';

  // Resolve URL: if it starts with / treat as path, otherwise use as-is
  const targetUrl = args.url.startsWith('http')
    ? args.url
    : `${baseUrl}${args.url.startsWith('/') ? '' : '/'}${args.url}`;

  const browser = await puppeteer.launch({
    headless: true,
    args: ['--no-sandbox', '--disable-setuid-sandbox', '--disable-dev-shm-usage'],
  });

  try {
    const page = await browser.newPage();
    await page.setViewport({ width, height });
    await page.emulateMediaFeatures([
      { name: 'prefers-color-scheme', value: lightMode ? 'light' : 'dark' },
    ]);

    if (!skipLogin) {
      // Navigate to sign-in page
      await page.goto(`${baseUrl}/auth/sign-in`, {
        waitUntil: 'networkidle2',
        timeout,
      });

      // Fill credentials using keyboard typing (works with React forms)
      await page.waitForSelector('input[name="email"]', { visible: true, timeout: 10000 });
      await page.type('input[name="email"]', email, { delay: 20 });
      await page.type('input[name="password"]', password, { delay: 20 });

      // Submit and wait for redirect
      await page.click('button[type="submit"]');
      await page.waitForNavigation({ waitUntil: 'networkidle2', timeout }).catch(() => {});

      // Verify login succeeded (should not still be on sign-in)
      if (page.url().includes('/auth/sign-in')) {
        output({ success: false, error: 'Login failed - still on sign-in page', url: page.url() });
        process.exit(1);
      }
    }

    // Navigate to target page
    await page.goto(targetUrl, { waitUntil: 'networkidle2', timeout });

    // Extra wait for client-side rendering
    if (extraWait > 0) {
      await new Promise((r) => setTimeout(r, extraWait));
    }

    // Ensure output directory exists
    const outputDir = path.dirname(path.resolve(args.output));
    if (!fs.existsSync(outputDir)) {
      fs.mkdirSync(outputDir, { recursive: true });
    }

    // Take screenshot
    const screenshotOptions = {
      path: args.output,
      type: format,
      fullPage,
    };
    if (format === 'jpeg') screenshotOptions.quality = quality;

    if (args.selector) {
      const el = await page.waitForSelector(args.selector, { visible: true, timeout: 5000 });
      await el.screenshot(screenshotOptions);
    } else {
      await page.screenshot(screenshotOptions);
    }

    const stats = fs.statSync(args.output);

    output({
      success: true,
      output: path.resolve(args.output),
      size: stats.size,
      url: page.url(),
      viewport: { width, height },
      loggedIn: !skipLogin,
    });
  } finally {
    await browser.close();
  }
}

run().catch((err) => {
  output({ success: false, error: err.message });
  process.exit(1);
});
