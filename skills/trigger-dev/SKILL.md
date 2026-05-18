---
name: trigger-dev
description: 'Write and configure Trigger.dev v4 background tasks using @trigger.dev/sdk. Use when developers: (1) Create or modify Trigger.dev tasks (task, schemaTask, schedules.task), (2) Configure trigger.config.ts or build extensions, (3) Trigger tasks from backend or frontend code, (4) Implement queues, retries, debouncing, or concurrency, (5) Add realtime subscriptions or streaming, (6) Set up scheduled/cron tasks, (7) Use React hooks from @trigger.dev/react-hooks. Triggers on: "Trigger.dev", "trigger.dev task", "background job", "trigger.config", "schemaTask", "schedules.task", "triggerAndWait", "@trigger.dev/sdk", "cron task", "batch trigger".'
---

# Trigger.dev v4

## Critical Rules

- **MUST** use `@trigger.dev/sdk` — NEVER use deprecated `client.defineJob`
- `triggerAndWait()` returns a **Result** object (`{ ok, output, error }`) — NOT direct task output
- **NEVER** wrap `triggerAndWait`, `batchTriggerAndWait`, or `wait` calls in `Promise.all`/`Promise.allSettled`
- Use `import type` for task references when triggering from backend code
- Waits > 5 seconds are automatically checkpointed (no compute cost)

## Quick Reference

### Define a task

```ts
import { task } from "@trigger.dev/sdk";

export const myTask = task({
  id: "my-task",
  run: async (payload: { data: string }) => {
    return { result: payload.data };
  },
});
```

### Trigger from backend

```ts
import { tasks } from "@trigger.dev/sdk";
import type { myTask } from "./trigger/tasks";

const handle = await tasks.trigger<typeof myTask>("my-task", { data: "value" });
```

### Child task with result handling

```ts
const result = await childTask.triggerAndWait({ data: "value" });
if (result.ok) {
  console.log(result.output); // task return value
}

// Or quick unwrap (throws on error)
const output = await childTask.triggerAndWait({ data: "value" }).unwrap();
```

### Scheduled task

```ts
import { schedules } from "@trigger.dev/sdk";

export const dailyTask = schedules.task({
  id: "daily-task",
  cron: "0 0 * * *",
  run: async (payload) => {
    // payload.timestamp, payload.timezone, etc.
  },
});
```

## Detailed References

- [Basic Tasks](references/basic-tasks.md) — `task`, `schemaTask`, triggering, debounce, waits
- [Advanced Tasks](references/advanced-tasks.md) — tags, batch v2, queues, retries, machines, idempotency, metadata, logging
- [Configuration](references/config.md) — `trigger.config.ts`, build extensions (Prisma, Playwright, FFmpeg, etc.)
- [Scheduled Tasks](references/scheduled-tasks.md) — cron syntax, declarative/imperative schedules, multi-tenant patterns
- [Realtime](references/realtime.md) — subscriptions, streams v2, React hooks, auth tokens
