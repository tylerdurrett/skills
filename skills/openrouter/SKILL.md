---
name: openrouter
description: Where the OpenRouter API key lives and how to use it safely. Use when calling OpenRouter, generating images or text through OpenRouter, or when a task needs OPENROUTER_API_KEY.
---

# OpenRouter

The key is `OPENROUTER_API_KEY` in `.env` at the repo root. `.env` is gitignored; `.env.example` holds the placeholder. If you don't find those files, please ask the user to add them.

Never print, echo, log, or commit the key. Load it into the environment and reference it as `$OPENROUTER_API_KEY`.

## Quick start

```bash
set -a && . ./.env && set +a
curl -s https://openrouter.ai/api/v1/chat/completions \
  -H "Authorization: Bearer $OPENROUTER_API_KEY" -H "Content-Type: application/json" \
  -d '{"model":"<model-id>","messages":[{"role":"user","content":"Hello"}]}'
```

List available models (and which output images) with `GET https://openrouter.ai/api/v1/models`; check `architecture.output_modalities`.

## Images

Add `"modalities":["image","text"]` to the request and use an image-capable model. Images come back as base64 data URLs in `choices[0].message.images[].image_url.url`; decode and save to a file. Write generated images to the scratchpad unless the user names a location.
