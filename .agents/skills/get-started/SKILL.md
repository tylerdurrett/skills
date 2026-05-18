---
name: get-started
description: Check system dependencies and guide a new user through Iterator TV local development setup. Use when a user says "get started", "set up my environment", "check my setup", "what do I need to install", or needs help getting the app running locally for the first time. This skill is designed for non-technical users on macOS.
---

# Get Started

Guide a new (non-technical) user through setting up Iterator TV for local development on macOS.

## Step 1: Run the dependency check

Run the check script from the project root:

```bash
bash .claude/skills/get-started/scripts/check-deps.sh
```

Report results clearly: what passed, what failed, what has warnings.

## Step 2: Fix anything missing

For each FAIL or WARN, walk the user through the fix one at a time. Full install instructions are in `_docs/getting-started.md` under the **Prerequisites** section. Read that file for the exact commands.

Key installs (macOS with zsh):
- **Homebrew**: `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"` — user must follow the post-install instructions to add brew to PATH
- **Git**: `brew install git`
- **Docker Desktop**: Download from https://www.docker.com/products/docker-desktop/
- **nvm + Node 20**: `curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash` then close/reopen terminal, then `nvm install 20.10`
- **pnpm**: `npm install -g pnpm@10.19.0`
- **ngrok**: `brew install ngrok` — then they need to sign up at https://ngrok.com/signup, add their authtoken, and claim a free static domain. See `_docs/getting-started.md` for full ngrok setup steps.

After fixing each item, re-run the check script to confirm it passes before moving on.

## Step 3: First-time setup

Once all dependencies pass, walk through these steps (only needed once):

1. `pnpm install` — install project dependencies
2. Place the `.env.local` file at `apps/web/.env.local` (Tyler provides this)
3. `pnpm bump:config B --no-skip-worktree` — switch to Profile B (avoids macOS AirPlay port 7000 conflict)
4. Open Docker Desktop and wait for it to start
5. `pnpm db:start` — start the local database (slow first time, downloads Docker images)
6. `pnpm db:reset` — seed with test data

## Step 4: Start the app

```bash
pnpm dev
```

For video rendering, start ngrok in a separate terminal:

```bash
pnpm ngrok
```

Open **http://localhost:7100/auth/sign-in** and log in with:

| Email | Password |
|-------|----------|
| `test@iterator.tv` | `testingpassword` |

## Optional: Trigger.dev

Only needed if automations (background jobs, scheduled tasks) are required:

```bash
pnpm trigger:dev
```

## Reference

- Full setup guide: `_docs/getting-started.md`
- Fork/clone instructions: `_docs/fork-and-clone.md`
- Supabase Studio: http://localhost:28887
- Mailpit (dev emails): http://localhost:28888
