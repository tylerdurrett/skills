# Trigger.dev Configuration (v4)

## trigger.config.ts

```ts
import { defineConfig } from "@trigger.dev/sdk";

export default defineConfig({
  project: "<project-ref>",
  dirs: ["./trigger"],
  runtime: "node",          // "node", "node-22", or "bun"
  logLevel: "info",

  retries: {
    enabledInDev: false,
    default: {
      maxAttempts: 3,
      minTimeoutInMs: 1000,
      maxTimeoutInMs: 10000,
      factor: 2,
      randomize: true,
    },
  },

  defaultMachine: "small-1x",
  maxDuration: 300,

  build: {
    autoDetectExternal: true,
    keepNames: true,
    minify: false,
    extensions: [],
  },

  // Global lifecycle hooks
  onStartAttempt: async ({ payload, ctx }) => {},
  onSuccess: async ({ payload, output, ctx }) => {},
  onFailure: async ({ payload, error, ctx }) => {},
});
```

## Build Extensions

### Prisma

```ts
import { prismaExtension } from "@trigger.dev/build/extensions/prisma";

extensions: [
  prismaExtension({
    schema: "prisma/schema.prisma",
    version: "5.19.0",
    migrate: true,
    directUrlEnvVarName: "DIRECT_DATABASE_URL",
    typedSql: true,
  }),
];
```

### Python

```ts
import { pythonExtension } from "@trigger.dev/build/extensions/python";

extensions: [
  pythonExtension({
    scripts: ["./python/**/*.py"],
    requirementsFile: "./requirements.txt",
    devPythonBinaryPath: ".venv/bin/python",
  }),
];

// In tasks:
const result = await python.runInline(`print("Hello")`);
const output = await python.runScript("./python/script.py", ["arg1"]);
```

### Playwright

```ts
import { playwright } from "@trigger.dev/build/extensions/playwright";

extensions: [
  playwright({ browsers: ["chromium"] }),
];
```

### Puppeteer

```ts
import { puppeteer } from "@trigger.dev/build/extensions/puppeteer";

extensions: [puppeteer()];
// Set env: PUPPETEER_EXECUTABLE_PATH="/usr/bin/google-chrome-stable"
```

### FFmpeg

```ts
import { ffmpeg } from "@trigger.dev/build/extensions/core";

extensions: [ffmpeg({ version: "7" })];
// Automatically sets FFMPEG_PATH and FFPROBE_PATH
```

### System Packages (apt-get)

```ts
import { aptGet } from "@trigger.dev/build/extensions/core";

extensions: [
  aptGet({ packages: ["ffmpeg", "imagemagick"] }),
];
```

### Additional NPM Packages (CLI tools only)

```ts
import { additionalPackages } from "@trigger.dev/build/extensions/core";

extensions: [
  additionalPackages({ packages: ["wrangler"] }),
];
```

### Additional Files

```ts
import { additionalFiles } from "@trigger.dev/build/extensions/core";

extensions: [
  additionalFiles({ files: ["wrangler.toml", "./assets/**"] }),
];
```

### Sync Environment Variables

```ts
import { syncEnvVars } from "@trigger.dev/build/extensions/core";

extensions: [
  syncEnvVars(async (ctx) => {
    return [
      { name: "SECRET_KEY", value: await getSecret(ctx.environment) },
      { name: "API_URL", value: ctx.environment === "prod" ? "api.prod.com" : "api.dev.com" },
    ];
  }),
];
```

### ESBuild Plugins

```ts
import { esbuildPlugin } from "@trigger.dev/build/extensions";
import { sentryEsbuildPlugin } from "@sentry/esbuild-plugin";

extensions: [
  esbuildPlugin(
    sentryEsbuildPlugin({ org: "...", project: "...", authToken: "..." }),
    { placement: "last", target: "deploy" }
  ),
];
```

### TypeScript Decorators (TypeORM)

```ts
import { emitDecoratorMetadata } from "@trigger.dev/build/extensions/typescript";

extensions: [emitDecoratorMetadata()];
```

## Custom Build Extensions

```ts
const customExtension = {
  name: "my-extension",
  externalsForTarget: (target) => ["some-native-module"],
  onBuildStart: async (context) => { /* register esbuild plugins */ },
  onBuildComplete: async (context, manifest) => {
    context.addLayer({
      id: "my-layer",
      files: [{ source: "./custom-file", destination: "/app/custom" }],
      commands: ["chmod +x /app/custom"],
    });
  },
};
```

## Telemetry

```ts
export default defineConfig({
  telemetry: {
    instrumentations: [new PrismaInstrumentation()],
    exporters: [customExporter],
  },
});
```

## Common Extension Combos

**Full-Stack Web App:**
```ts
extensions: [
  prismaExtension({ schema: "prisma/schema.prisma", migrate: true }),
  additionalFiles({ files: ["./public/**"] }),
  syncEnvVars(async (ctx) => [...]),
];
```

**Web Scraping:**
```ts
extensions: [
  playwright({ browsers: ["chromium"] }),
  additionalFiles({ files: ["./selectors.json"] }),
];
```

Extensions only affect deployment, not local development.
