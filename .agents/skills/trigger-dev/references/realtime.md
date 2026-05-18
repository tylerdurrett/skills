# Trigger.dev Realtime (v4)

## Authentication

### Public access tokens (read-only)

```ts
import { auth } from "@trigger.dev/sdk";

const publicToken = await auth.createPublicToken({
  scopes: {
    read: {
      runs: ["run_123"],
      tasks: ["my-task"],
    },
  },
  expirationTime: "1h", // default: 15 min
});
```

### Trigger tokens (frontend, single-use)

```ts
const triggerToken = await auth.createTriggerPublicToken("my-task", {
  expirationTime: "30m",
});
```

## Backend Subscriptions

```ts
import { runs, tasks } from "@trigger.dev/sdk";

// Subscribe to specific run
const handle = await tasks.trigger("my-task", { data: "value" });
for await (const run of runs.subscribeToRun<typeof myTask>(handle.id)) {
  console.log(`Status: ${run.status}`);
  if (run.status === "COMPLETED") break;
}

// Subscribe by tag
for await (const run of runs.subscribeToRunsWithTag("user-123")) {
  console.log(`${run.id}: ${run.status}`);
}

// Subscribe to batch
for await (const run of runs.subscribeToBatch(batchId)) {
  console.log(`${run.id}: ${run.status}`);
}
```

## Realtime Streams v2

```ts
import { streams, InferStreamType } from "@trigger.dev/sdk";

// 1. Define stream (shared location)
export const aiStream = streams.define<string>({ id: "ai-output" });
export type AIStreamPart = InferStreamType<typeof aiStream>;

// 2. Pipe from task
export const streamingTask = task({
  id: "streaming-task",
  run: async (payload) => {
    const completion = await openai.chat.completions.create({
      model: "gpt-4",
      messages: [{ role: "user", content: payload.prompt }],
      stream: true,
    });
    const { waitUntilComplete } = aiStream.pipe(completion);
    await waitUntilComplete();
  },
});

// 3. Read from backend
const stream = await aiStream.read(runId, {
  timeoutInSeconds: 300,
  startIndex: 0,
});
for await (const chunk of stream) {
  console.log("Chunk:", chunk); // typed
}
```

## React Hooks

Install: `npm add @trigger.dev/react-hooks`

### Trigger tasks from frontend

```tsx
"use client";
import { useTaskTrigger, useRealtimeTaskTrigger } from "@trigger.dev/react-hooks";
import type { myTask } from "../trigger/tasks";

function Component({ accessToken }: { accessToken: string }) {
  // Basic trigger
  const { submit, handle, isLoading } = useTaskTrigger<typeof myTask>("my-task", {
    accessToken,
  });

  // Trigger with realtime updates
  const { submit: rtSubmit, run } = useRealtimeTaskTrigger<typeof myTask>("my-task", {
    accessToken,
  });

  return (
    <div>
      <button onClick={() => submit({ data: "value" })}>Trigger</button>
      {run && <div>Status: {run.status}</div>}
    </div>
  );
}
```

### Subscribe to runs

```tsx
"use client";
import { useRealtimeRun, useRealtimeRunsWithTag } from "@trigger.dev/react-hooks";
import type { myTask } from "../trigger/tasks";

function RunMonitor({ runId, accessToken }: { runId: string; accessToken: string }) {
  const { run, error } = useRealtimeRun<typeof myTask>(runId, {
    accessToken,
    onComplete: (run) => console.log("Done:", run.output),
  });

  const { runs } = useRealtimeRunsWithTag("user-123", { accessToken });

  if (error) return <div>Error: {error.message}</div>;
  if (!run) return <div>Loading...</div>;

  return (
    <div>
      <div>Status: {run.status}</div>
      <div>Progress: {run.metadata?.progress || 0}%</div>
    </div>
  );
}
```

### Stream consumption

```tsx
"use client";
import { useRealtimeStream } from "@trigger.dev/react-hooks";
import { aiStream } from "../trigger/streams";

function StreamViewer({ runId, accessToken }: { runId: string; accessToken: string }) {
  const { parts, error } = useRealtimeStream(aiStream, runId, {
    accessToken,
    throttleInMs: 50,
  });

  if (!parts) return <div>Loading...</div>;
  return <div>{parts.join("")}</div>;
}
```

### Wait tokens

```tsx
"use client";
import { useWaitToken } from "@trigger.dev/react-hooks";

function ApprovalButton({ tokenId, accessToken }: { tokenId: string; accessToken: string }) {
  const { complete } = useWaitToken(tokenId, { accessToken });
  return <button onClick={() => complete({ approved: true })}>Approve</button>;
}
```

### SWR hooks (fetch once)

```tsx
import { useRun } from "@trigger.dev/react-hooks";

const { run, error, isLoading } = useRun<typeof myTask>(runId, {
  accessToken,
  refreshInterval: 0, // disable polling
});
```

## Run Object Properties

- `id`, `status` (`QUEUED`, `EXECUTING`, `COMPLETED`, `FAILED`, `CANCELED`)
- `payload` (typed input), `output` (typed result)
- `metadata` (real-time updatable)
- `createdAt`, `updatedAt`, `costInCents`

## Best Practices

- Prefer realtime subscriptions over SWR polling
- Scope tokens to minimum required permissions
- Use `import type` for task references in hooks
- Frontend hooks auto-cleanup on unmount
