# Slack Web API — chat.postMessage

Minimal reference for the one endpoint this skill uses.

## Endpoint

```
POST https://slack.com/api/chat.postMessage
```

## Headers

```
Authorization: Bearer xoxb-your-bot-token
Content-Type: application/json
```

## Request Body

```json
{
  "channel": "C0123456789",
  "text": "Your message here"
}
```

- `channel` — Channel ID (starts with `C`), not the channel name.
- `text` — Plain text message. Supports Slack's mrkdwn format (see below).

## Response

Success:
```json
{ "ok": true, "channel": "C0123456789", "ts": "1234567890.123456" }
```

Failure:
```json
{ "ok": false, "error": "error_code" }
```

## Common Errors

| Error | Meaning | Fix |
|-------|---------|-----|
| `not_in_channel` | Bot hasn't been added to the channel | Add the bot app to the channel in Slack |
| `channel_not_found` | Bad channel ID or bot can't see it | Double-check the channel ID in config |
| `invalid_auth` | Bad or expired token | Regenerate the bot token |
| `token_revoked` | Token was revoked | Reinstall the app to the workspace |
| `no_text` | Empty message body | Ensure the message isn't blank |

## Slack mrkdwn Formatting

Slack uses its own lightweight markup (not standard Markdown):

- `*bold*` — Bold
- `_italic_` — Italic
- `~strikethrough~` — Strikethrough
- `` `code` `` — Inline code
- `\n` — Newline (in JSON string)
- `• ` — Bullet point (use the actual bullet character or `\u2022`)

Note: Slack does **not** support `#` headings or `[text](url)` links. Use `<url|text>` for links.
