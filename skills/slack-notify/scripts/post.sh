#!/usr/bin/env bash
set -euo pipefail

# Usage: post.sh <channel-id> <message>
#        post.sh --check          (exits 0 if token exists, 1 if not)
# Reads SLACK_BOT_TOKEN from apps/web/.env.local (the canonical env file for this monorepo).
# Exit codes: 0 = posted OK (or token exists for --check), 1 = token missing, 2 = API failure

ENV_FILE="apps/web/.env.local"

# --check mode: just verify the token exists, don't post
if [ "${1:-}" = "--check" ]; then
  grep -q SLACK_BOT_TOKEN "$ENV_FILE" 2>/dev/null && exit 0 || exit 1
fi

CHANNEL="${1:?Usage: post.sh <channel-id> <message>}"
MESSAGE="${2:?Usage: post.sh <channel-id> <message>}"

TOKEN=$(grep SLACK_BOT_TOKEN "$ENV_FILE" 2>/dev/null | head -1 | cut -d '=' -f2-)
if [ -z "$TOKEN" ]; then
  echo "{\"ok\":false,\"error\":\"token_not_found\",\"detail\":\"SLACK_BOT_TOKEN not found in $ENV_FILE\"}" >&2
  exit 1
fi

PAYLOAD=$(jq -n --arg ch "$CHANNEL" --arg txt "$MESSAGE" '{channel: $ch, text: $txt}')

RESPONSE=$(curl -s -X POST https://slack.com/api/chat.postMessage \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "$PAYLOAD")

echo "$RESPONSE"

if echo "$RESPONSE" | jq -e '.ok' >/dev/null 2>&1; then
  exit 0
else
  exit 2
fi
