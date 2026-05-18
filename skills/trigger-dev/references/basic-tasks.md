# Trigger.dev Basic Tasks (v4)

## Defining Tasks

### `task` — unvalidated payload

```ts
import { task } from "@trigger.dev/sdk";

export const processData = task({
  id: "process-data",
  retry: {
    maxAttempts: 10,
    factor: 1.8,
    minTimeoutInMs: 500,
    maxTimeoutInMs: 30_000,
    randomize: false,
  },
  run: async (payload: { userId: string; data: any[] }) => {
    console.log(`Processing ${payload.data.length} items`);
    return { processed: payload.data.length };
  },
});
```

### `schemaTask` — Zod-validated payload

```ts
import { schemaTask } from "@trigger.dev/sdk";
import { z } from "zod";

export const validatedTask = schemaTask({
  id: "validated-task",
  schema: z.object({
    name: z.string(),
    age: z.number(),
    email: z.string().email(),
  }),
  run: async (payload) => {
    // payload is validated and typed automatically
    return { message: `Hello ${payload.name}` };
  },
});
```

## Triggering Tasks

### From backend code

```ts
import { tasks } from "@trigger.dev/sdk";
import type { processData } from "./trigger/tasks";

// Single trigger
const handle = await tasks.trigger<typeof processData>("process-data", {
  userId: "123",
  data: [{ id: 1 }, { id: 2 }],
});

// Batch trigger (up to 1,000 items, 3MB per payload)
const batchHandle = await tasks.batchTrigger<typeof processData>("process-data", [
  { payload: { userId: "123", data: [{ id: 1 }] } },
  { payload: { userId: "456", data: [{ id: 2 }] } },
]);
```

### Debounced triggering

Consolidate rapid triggers into a single execution:

```ts
await myTask.trigger(
  { userId: "123" },
  {
    debounce: {
      key: "user-123-update",  // unique key for debounce group
      delay: "5s",
    },
  }
);

// Trailing mode: use payload from LAST trigger
await myTask.trigger(
  { data: "latest-value" },
  {
    debounce: {
      key: "trailing-example",
      delay: "10s",
      mode: "trailing",  // default is "leading" (first payload)
    },
  }
);
```

### From inside tasks (child tasks)

`triggerAndWait()` returns a **Result** object, NOT the task output directly.

```ts
export const parentTask = task({
  id: "parent-task",
  run: async (payload) => {
    // Fire and forget
    const handle = await childTask.trigger({ data: "value" });

    // Wait for result — returns Result object
    const result = await childTask.triggerAndWait({ data: "value" });
    if (result.ok) {
      console.log("Output:", result.output); // actual return value
    } else {
      console.error("Failed:", result.error);
    }

    // Quick unwrap (throws on error)
    const output = await childTask.triggerAndWait({ data: "value" }).unwrap();

    // Batch wait
    const results = await childTask.batchTriggerAndWait([
      { payload: { data: "item1" } },
      { payload: { data: "item2" } },
    ]);
    for (const run of results) {
      if (run.ok) console.log("Success:", run.output);
    }
  },
});
```

> **NEVER** wrap `triggerAndWait` or `batchTriggerAndWait` in `Promise.all` or `Promise.allSettled` — not supported.

## Waits

```ts
import { wait } from "@trigger.dev/sdk";

// Duration-based
await wait.for({ seconds: 30 });
await wait.for({ minutes: 5 });
await wait.for({ hours: 1 });
await wait.for({ days: 1 });

// Until a specific date
await wait.until({ date: new Date("2024-12-25") });

// Wait for external token
await wait.forToken({
  token: "user-approval-token",
  timeoutInSeconds: 3600,
});
```

> **NEVER** wrap `wait` calls in `Promise.all` or `Promise.allSettled` — not supported.
> Waits > 5 seconds are automatically checkpointed (no compute cost).

## Key Rules

- Use `import type` for task references when triggering from backend
- `triggerAndWait()` returns `Result` with `.ok`, `.output`, `.error` — NOT direct output
- Idempotency keys take precedence over debounce settings
