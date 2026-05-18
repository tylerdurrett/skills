# Trigger.dev Scheduled Tasks (v4)

## Define a Scheduled Task

```ts
import { schedules } from "@trigger.dev/sdk";

export const dailyCleanup = schedules.task({
  id: "daily-cleanup",
  run: async (payload) => {
    payload.timestamp;      // Date — scheduled time (UTC)
    payload.lastTimestamp;   // Date | undefined
    payload.timezone;        // IANA string, e.g. "America/New_York"
    payload.scheduleId;      // string
    payload.externalId;      // string | undefined
    payload.upcoming;        // Date[]

    // Format in schedule's timezone
    payload.timestamp.toLocaleString("en-US", { timeZone: payload.timezone });
  },
});
```

Scheduled tasks need at least one schedule attached to run.

## Attach Schedules

### Declarative (syncs on dev/deploy)

```ts
schedules.task({
  id: "every-2h",
  cron: "0 */2 * * *", // UTC
  run: async () => {},
});

schedules.task({
  id: "tokyo-5am",
  cron: {
    pattern: "0 5 * * *",
    timezone: "Asia/Tokyo",
    environments: ["PRODUCTION", "STAGING"],
  },
  run: async () => {},
});
```

### Imperative (SDK or dashboard)

```ts
await schedules.create({
  task: task.id,
  cron: "0 0 * * *",
  timezone: "America/New_York",  // DST-aware
  externalId: "user_123",
  deduplicationKey: "user_123-daily", // updates existing if reused
});
```

### Dynamic / multi-tenant example

```ts
// trigger/reminder.ts
export const reminderTask = schedules.task({
  id: "todo-reminder",
  run: async (p) => {
    if (!p.externalId) throw new Error("externalId required");
    const user = await db.getUser(p.externalId);
    await sendReminderEmail(user);
  },
});

// API route
export async function POST(req: Request) {
  const data = await req.json();
  return Response.json(
    await schedules.create({
      task: reminderTask.id,
      cron: "0 8 * * *",
      timezone: data.timezone,
      externalId: data.userId,
      deduplicationKey: `${data.userId}-reminder`,
    })
  );
}
```

## Cron Syntax (no seconds)

```
* * * * *
| | | | └ day of week (0-7; 0/7=Sun; 1L-7L for last)
| | | └── month (1-12)
| | └──── day of month (1-31 or L for last)
| └────── hour (0-23)
└──────── minute (0-59)
```

## When Schedules Won't Trigger

- **Dev:** only when dev CLI is running
- **Staging/Production:** only for tasks in the latest deployment

## SDK Management

```ts
await schedules.retrieve(id);
await schedules.list();
await schedules.update(id, { cron: "0 0 1 * *", externalId: "ext" });
await schedules.deactivate(id);
await schedules.activate(id);
await schedules.del(id);
await schedules.timezones(); // list IANA timezones
```

## One-Off Future Runs

For single future executions, use the `delay` option on `trigger()` instead of schedules.
