---
name: app-screenshot
description: Take authenticated screenshots of the Iterator TV local dev app for visual debugging. Use when you need to see how a page looks in the browser, verify UI changes, debug layout issues, or capture the current state of any page in the app. Triggers on requests to "take a screenshot", "show me the page", "what does it look like", visual debugging, or verifying frontend changes.
---

# App Screenshot

Take authenticated screenshots of the local dev app. Handles login automatically so you can capture any page — including those behind auth — in a single command.

## Setup (first time only)

```bash
cd .claude/skills/app-screenshot/scripts && npm install
```

## Usage

Run from the **project root**:

```bash
# With a path (base URL auto-detected from apps/web/.env.local)
node .claude/skills/app-screenshot/scripts/app-screenshot.mjs \
  --url /home/dev-team/projects/abc123/videos/def456/timeline \
  --output _screenshots/2026-01-15/2026-01-15_143052_timeline.jpg

# With a full URL
node .claude/skills/app-screenshot/scripts/app-screenshot.mjs \
  --url http://localhost:7200/home/dashboard \
  --output _screenshots/2026-01-15/2026-01-15_143052_dashboard.jpg
```

### Screenshot Conventions

- **Directory**: `_screenshots/<YYYY-MM-DD>/` at project root
- **Filename**: `<YYYY-MM-DD>_<HHMMSS>_<slug>.jpg` — timestamp prevents overwrites
- **Format**: JPEG at quality 80 by default (good balance of size and clarity)
- **Viewport**: 1920x1080 by default
- **Color scheme**: Dark mode by default (pass `--light` for light mode)

Construct filenames with:
```bash
DATE_DIR=$(date +%Y-%m-%d)
FILENAME="${DATE_DIR}_$(date +%H%M%S)_<descriptive-slug>.jpg"
```

### Options

| Flag | Default | Description |
|------|---------|-------------|
| `--url` | (required) | Full URL or path starting with `/` |
| `--output` | (required) | Screenshot file path |
| `--email` | `test@iterator.tv` | Login email |
| `--password` | `testingpassword` | Login password |
| `--base-url` | auto-detected | Override app base URL |
| `--width` | `1920` | Viewport width |
| `--height` | `1080` | Viewport height |
| `--format` | `jpeg` | `jpeg` or `png` |
| `--quality` | `80` | JPEG quality (0-100) |
| `--wait` | `2000` | Extra ms to wait after page load |
| `--timeout` | `20000` | Navigation timeout ms |
| `--selector` | — | CSS selector to screenshot instead of full page |
| `--full-page` | `false` | Capture full scrollable page |
| `--no-login` | `false` | Skip login (for public pages) |
| `--light` | `false` | Use light mode (default is dark) |

### Output

JSON to stdout:
```json
{
  "success": true,
  "output": "/absolute/path/to/screenshot.jpg",
  "size": 184035,
  "url": "http://localhost:7200/home/...",
  "viewport": { "width": 1920, "height": 1080 },
  "loggedIn": true
}
```

After taking a screenshot, always read the output file with the Read tool to visually inspect it.

### Troubleshooting

- **"Cannot find package 'puppeteer'"** — Run `npm install` in `.claude/skills/app-screenshot/scripts/`
- **Login failed** — Verify dev server is running (`pnpm dev`) and credentials are correct
- **Blank/loading screenshot** — Increase `--wait` (e.g., `--wait 5000`) for heavy pages
- **Missing system libs (Linux/WSL)** — Install Chrome deps: `sudo apt-get install -y libnss3 libnspr4 libasound2t64 libatk1.0-0 libatk-bridge2.0-0 libcups2 libdrm2 libxkbcommon0 libxcomposite1 libxdamage1 libxfixes3 libxrandr2 libgbm1`
