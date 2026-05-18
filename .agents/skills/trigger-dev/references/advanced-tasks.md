# Trigger.dev Advanced Tasks (v4)

## Tags

```ts
import { task, tags } from "@trigger.dev/sdk";

export const processUser = task({
  id: "process-user",
  run: async (payload: { userId: string }) => {
    await tags.add(`user_${payload.userId}`);
    return { processed: true };
  },
});

// Trigger with tags
await processUser.trigger(
  { userId: "123" },
  { tags: ["priority", "user_123"] } // max 10 tags, 1-64 chars each
);

// Subscribe to tagged runs
for await (const run of runs.subscribeToRunsWithTag("user_123")) {
  console.log(`${run.id}: ${run.status}`);
}
```

Tags don't propagate to child tasks automatically.

## Batch Triggering v2

- Max 1,000 items per batch, 3MB per payload
- Payloads > 512KB auto-offload to object storage

```ts
const runs = await myTask.batchTrigger([
  { payload: { userId: "user-1" } },
  { payload: { userId: "user-2" } },
]);

// With per-item options
const batchHandle = await myTask.batchTrigger([
  {
    payload: { userId: "123" },
    options: { idempotencyKey: "user-123-batch", tags: ["priority"] },
  },
]);
```

## Concurrency & Queues

```ts
import { task, queue } from "@trigger.dev/sdk";

// Shared queue
const emailQueue = queue({
  name: "email-processing",
  concurrencyLimit: 5,
});

// Task-level concurrency
export const sequential = task({
  id: "sequential-task",
  queue: { concurrencyLimit: 1 },
  run: async (payload) => { /* one at a time */ },
});

// Per-user concurrency (dynamic queue)
await childTask.trigger(payload, {
  queue: { name: `user-${payload.userId}`, concurrencyLimit: 2 },
});

// Shared queue reference
export const emailTask = task({
  id: "send-email",
  queue: emailQueue,
  run: async (payload: { to: string }) => { /* send */ },
});
```

## Error Handling & Retries

```ts
import { task, retry, AbortTaskRunError } from "@trigger.dev/sdk";

export const resilientTask = task({
  id: "resilient-task",
  retry: {
    maxAttempts: 10,
    factor: 1.8,
    minTimeoutInMs: 500,
    maxTimeoutInMs: 30_000,
    randomize: false,
  },
  catchError: async ({ error, ctx }) => {
    if (error.code === "FATAL_ERROR") {
      throw new AbortTaskRunError("Cannot retry");
    }
    return { retryAt: new Date(Date.now() + 60000) }; // retry in 1 min
  },
  run: async (payload) => {
    // Retry specific operations
    const result = await retry.onThrow(
      async () => unstableApiCall(payload),
      { maxAttempts: 3 }
    );

    // Conditional HTTP retries
    const response = await retry.fetch("https://api.example.com", {
      retry: {
        maxAttempts: 5,
        condition: (response, error) =>
          response?.status === 429 || response?.status >= 500,
      },
    });

    return result;
  },
});
```

## Machines

```ts
export const heavyTask = task({
  id: "heavy-computation",
  machine: { preset: "large-2x" },
  maxDuration: 1800, // 30 min
  run: async (payload) => { /* ... */ },
});

// Override at trigger time
await heavyTask.trigger(payload, { machine: { preset: "medium-1x" } });
```

| Preset | vCPU | RAM |
|--------|------|-----|
| `micro` | 0.25 | 0.25 GB |
| `small-1x` | 0.5 | 0.5 GB (default) |
| `small-2x` | 1 | 1 GB |
| `medium-1x` | 1 | 2 GB |
| `medium-2x` | 2 | 4 GB |
| `large-1x` | 4 | 8 GB |
| `large-2x` | 8 | 16 GB |

## Idempotency

```ts
import { idempotencyKeys } from "@trigger.dev/sdk";

// Scoped to current task run (stable across retries)
const key = await idempotencyKeys.create(`payment-${payload.orderId}`);

await chargeCustomer.trigger(payload, {
  idempotencyKey: key,
  idempotencyKeyTTL: "24h",
});
```

## Metadata & Progress

```ts
import { metadata } from "@trigger.dev/sdk";

// Set/update metadata
metadata.set("progress", 0).set("status", "starting");
metadata.increment("processedItems", 1);
metadata.append("logs", `Processed item ${i}`);

// From child task, update parent/root
metadata.parent.set("childStatus", "processing");
metadata.root.increment("childrenCompleted", 1);
```

## Logging

```ts
import { logger } from "@trigger.dev/sdk";

logger.info("Started", { userId: payload.userId });
logger.debug("Details", { data });
logger.error("Failed", { error: error.message });

// Custom trace span
const user = await logger.trace("fetch-user", async (span) => {
  span.setAttribute("user.id", payload.userId);
  return await database.findUser(payload.userId);
});
```

## Hidden Tasks

Tasks not exported from their file are hidden (not visible in dashboard) but usable internally:

```ts
const internalProcessor = task({
  id: "internal-processor",
  run: async (payload: { data: string }) => {
    return { processed: payload.data.toUpperCase() };
  },
});

export const publicWorkflow = task({
  id: "public-workflow",
  run: async (payload: { input: string }) => {
    const result = await internalProcessor.triggerAndWait({ data: payload.input });
    if (result.ok) return { output: result.output.processed };
    throw new Error("Internal processing failed");
  },
});
```
