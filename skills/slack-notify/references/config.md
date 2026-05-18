# Slack Channel Config

Map friendly channel keys to Slack channel IDs. Other skills reference channels by key (e.g., `rfp`), so they never need to know the raw ID.

## Channels

| Key       | Channel ID  | Description                               |
| --------- | ----------- | ----------------------------------------- |
| `default` | C09D0S6GW14 | Fallback channel when no key is specified |
| `rfp`     | C0AKMA544LD | RFP opportunity alerts from /rfp-harvest  |

To find a channel ID: in Slack, right-click the channel name → "View channel details" → the ID is at the bottom of the dialog.

Remember to **add the bot to each channel** (channel settings → Integrations → Add apps) or posts will fail with `not_in_channel`.
