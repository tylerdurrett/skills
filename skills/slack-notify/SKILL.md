---
name: slack-notify
description: Send a message to a configured Slack channel. Purely outbound notifications. Use when another skill or the user wants to post a Slack message, or when the user invokes /slack-notify.
disable-model-invocation: true
argument-hint: "[channel-key] message"
---

# Slack Notify

Send outbound notifications to Slack channels. Designed to be invoked by the user or by other skills.

## Arguments

`$ARGUMENTS` format: `[channel-key] message`

- **channel-key** — A friendly name mapped to a Slack channel ID in the config (e.g., `rfp`, `general`). If omitted, uses the `default` channel.
- **message** — The text to post. Can be multi-line.

## Setup Check

1. Read the channel config at [references/config.md](references/config.md).
2. Check if the Slack token is configured: `bash .claude/skills/slack-notify/scripts/post.sh --check`

If either check fails (no config entries or script exits non-zero), run the **First-Time Setup** flow below. Otherwise, skip to **Send Message**.

## First-Time Setup

Walk the user through these steps:

1. **Create a Slack App:**
   - Go to https://api.slack.com/apps → "Create New App" → "From scratch"
   - Name it anything (e.g., "Claude Notify"), pick the workspace
   - Under **OAuth & Permissions**, add Bot Token Scope: `chat:write`
   - Click "Install to Workspace" and copy the **Bot User OAuth Token** (`xoxb-...`)

2. **Store the token:**
   - Add `SLACK_BOT_TOKEN=xoxb-your-token-here` to `apps/web/.env.local` (the canonical env file for this monorepo — there is no root `.env.local`)
   - The root `.gitignore` matches `.env*.local` recursively, so `apps/web/.env.local` is already gitignored

3. **Configure channels:**
   - Ask the user which Slack channel(s) they want to post to
   - The user needs to **add the bot to each channel** in Slack (channel settings → Integrations → Add apps)
   - Get the channel ID: in Slack, right-click the channel name → "View channel details" → copy the ID at the bottom
   - Update [references/config.md](references/config.md) with the channel key, ID, and description

4. **Test:** Send a test message to confirm everything works.

## Send Message

1. **Read config** from [references/config.md](references/config.md) to get the channel ID for the requested key.
2. **Parse arguments:** Extract the channel key (first word, if it matches a key in the config) and the message (everything else). If no key matches, treat the entire argument as the message and use the `default` channel.
3. **Post to Slack** using the `post.sh` script (handles token reading and curl internally):
   ```bash
   bash .claude/skills/slack-notify/scripts/post.sh "<CHANNEL_ID>" "<MESSAGE>"
   ```
4. **Check response:** The script prints the Slack API JSON response to stdout. If `"ok": true`, confirm success. If `"ok": false`, report the `"error"` field to the user. Common errors are documented in [references/slack-api.md](references/slack-api.md).
   - Exit code `1` = token not found in `apps/web/.env.local` — run First-Time Setup
   - Exit code `2` = Slack API returned an error — check the JSON output

## Being Called by Other Skills

Other skills should invoke this skill via the Skill tool:
```
Skill: slack-notify, args: "rfp Your message here"
```
The calling skill is responsible for:
- Formatting the message text
- Choosing the right channel key

This skill handles everything else: config lookup, token access, posting, and error handling. If Slack is not configured and this was invoked by another skill (not the user), it will skip silently.

## Guardrails

- **Never expose the token** in output, logs, or committed files.
- **Never use the Read tool on `apps/web/.env.local` or any `.env.*` file.** Edit/Write to these paths are deny-listed in `.claude/settings.json`; the policy here is to also avoid Read so the token never enters the conversation transcript. The `post.sh` script handles token access internally — use it instead.
- **Always use `post.sh` to send messages** — never manually read the token or construct curl commands. The script handles token reading, JSON escaping, and posting in one deterministic step.
- **Don't trigger setup when called by another skill.** If Slack isn't configured and this was invoked programmatically, just skip. Only run setup when the user invokes `/slack-notify` directly.
