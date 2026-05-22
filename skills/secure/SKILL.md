---
name: secure
description: Harden the user's JavaScript package manager setup (npm + pnpm) against supply-chain attacks. Configures a 7-day install-delay (minimum-release-age), blocks exotic dependency sources (block-exotic-subdeps), and disables install-time scripts (ignore-scripts) at the correct config files for the user's actual tool versions. Detects npm/pnpm versions, install methods (incl. Corepack), and where config values are currently coming from; upgrades tools if the requested settings need a newer version; flags project-level configs that would override the global hardening. Cross-platform across macOS, Linux, and WSL. Use when the user says "/secure", "harden npm/pnpm", "supply chain protection", "lock down package installs", "protect against compromised packages", or otherwise signals they want defense against malicious npm/pnpm packages.
---

# Secure

Goal: turn on a small, well-understood set of supply-chain mitigations for npm and pnpm — at the _right_ config files for the user's actual tool versions — without breaking their existing setup. Tell the user the plan first, get approval, do the work, verify, leave them a bypass cheatsheet.

This skill installs persistent protections, not a one-shot scan. The protections are:

1. **7-day install delay** — refuse to install package versions newer than 7 days. Catches almost all malicious packages, which get pulled within days of being caught. **Units differ between tools**: pnpm's `minimum-release-age` is in **minutes** (so 7 days = `10080`); npm's `min-release-age` is in **days** (so 7 days = `7`). Do not copy one value into the other tool's config.
2. **`block-exotic-subdeps=true`** (pnpm-only) — refuse dependencies pulled from git URLs, tarballs, or file paths instead of the registry. Legitimate projects almost never need these.
3. **`ignore-scripts=true`** — disable install-time `preinstall`/`install`/`postinstall` scripts. Strong; will break a small number of packages that genuinely need build scripts.

## CRITICAL: do not rely on training data

Key names, version requirements, and config-file locations for npm and pnpm have shifted across releases and the on-disk reality contradicts published docs at times. **Before changing anything, fetch the current pages and verify against the user's installed versions.** Treat documented behavior and observed behavior as separate inputs — when they disagree, observed behavior wins for THIS user's system.

Pages to fetch with WebFetch when this skill runs:

- `https://pnpm.io/settings` — what keys exist, which file they live in, what versions added them
- `https://pnpm.io/cli/config` — the `pnpm config` command surface
- `https://docs.npmjs.com/cli/v11/using-npm/config` — npm's config keys (filter to the latest v11)

Do not trust the summaries below as authoritative — they are a _prior_ (last verified May 2026) to help you spot anomalies. Cross-check against the live pages and the installed tool.

### Prior knowledge (sanity-check against current docs)

- pnpm `minimum-release-age` (kebab-case in INI; `minimumReleaseAge` camelCase in YAML) — added in **pnpm 10.16**.
- pnpm `block-exotic-subdeps` (kebab; `blockExoticSubdeps` camelCase in YAML) — added in **pnpm 10.26**.
- npm `min-release-age` — recognized starting around **npm 11.14**. Older npm (e.g. 11.6) stores the value but emits `npm warn Unknown user config "min-release-age"` and does not enforce it.
- pnpm reads INI from a project `.npmrc`, the user `~/.npmrc`, and the global `~/.config/pnpm/rc` (per `pnpm config list`'s `globalconfig` pointer on Linux/WSL/macOS).
- pnpm's docs may claim `~/.config/pnpm/config.yaml` is the canonical global YAML file. Empirically, at pnpm 10.33.x the install resolver did **not** read keys from that YAML file — values added there had no effect, and `pnpm config set --global` wrote to `~/.config/pnpm/rc` (INI), not to the YAML file. Verify before relying on the YAML location.
- `pnpm config get <key>` reads INI sources only — if you want to see the merged effective config across all sources, use `pnpm config list` (or `--json`).

## Procedure

### 1. Tell the user what you're about to do, and wait for explicit approval

Before any detection commands, summarize in plain English (adapt to what they asked for). Cover:

- The three protections, what they do, what they trade off
- That you will detect their setup (versions, install methods, config sources) before suggesting changes
- That **if the system is already hardened** (correct versions + correct config + no overrides) you will report that and exit — no doc fetches, no changes, no further prompts. Re-running this skill is cheap.
- That you will fetch current docs to confirm key names and version requirements **only if changes are needed**
- That you may need to **upgrade** npm or pnpm if their version doesn't support the requested settings
- That you will **only** modify configuration files (no `npm install`, no `pnpm install`, no mutating commands)
- The bypass cheatsheet (see end of this skill) for when a legitimate fresh package gets blocked

Stop and wait for "approve" / "go" / similar. **Do not start running detection commands before approval** — even read-only commands feel intrusive when the user hasn't signed off.

### 2. Detect the environment

Run these once the user has approved. Group them into parallel calls where possible.

**Operating system & shell**:

```bash
uname -s                # Darwin / Linux
[ -f /proc/version ] && grep -qi microsoft /proc/version && echo "WSL detected"
echo "$SHELL"
```

This skill supports macOS, Linux, and WSL. If `uname -s` is anything else (e.g. native Windows via `MSYS_NT`/`MINGW`), tell the user the path conventions in this skill don't apply and stop.

**Tool versions and install methods**:

```bash
which pnpm; realpath "$(which pnpm)" 2>/dev/null
pnpm --version 2>&1
which npm; realpath "$(which npm)" 2>/dev/null
npm --version 2>&1
which corepack 2>/dev/null && corepack --version
node --version
```

How to read `realpath`:

- pnpm path ending in `corepack/dist/pnpm.js` → pnpm is a **Corepack shim**, not a standalone install. Upgrade path is `corepack install -g pnpm@<version>` (see step 4).
- pnpm path under `~/.local/share/pnpm/` or `/usr/local/bin/pnpm` etc. → standalone install (via pnpm's own installer or a package manager). Upgrade with `pnpm self-update` or the platform installer.
- npm path under nvm (`~/.nvm/versions/node/...`) → bundled with the active Node version. Upgrade with `npm install -g npm@latest`.

**Where is the config actually coming from**:

```bash
pnpm config list 2>&1                  # shows merged effective config + globalconfig path
pnpm config list --json 2>&1           # machine-readable form
npm config ls --long 2>&1 | head -200  # npm's merged view (look for "; overridden by user" lines)
npm config get globalconfig 2>&1
npm config get userconfig 2>&1
```

From `pnpm config list`, capture the `globalconfig` value — that is the path pnpm itself considers its canonical global INI file (typically `~/.config/pnpm/rc` on Linux/WSL/macOS).

**Check for stray `packageManager` pins above CWD** (Corepack walks up the directory tree looking for these and will pin pnpm to whatever it finds, defeating any "global" upgrade):

```bash
dir="$PWD"
while [ "$dir" != "/" ]; do
  if [ -f "$dir/package.json" ] && grep -q '"packageManager"' "$dir/package.json"; then
    echo "PIN FOUND: $dir/package.json"
    grep '"packageManager"' "$dir/package.json"
  fi
  dir="$(dirname "$dir")"
done
```

A pin at `~/package.json` is a common footgun — it silently pins every subdirectory of `~`. Flag it.

**Check the current project for overrides** (any of these would defeat the global hardening if it sets the same keys to weaker values):

```bash
# In the current project directory:
[ -f .npmrc ] && echo "--- ./.npmrc ---" && cat .npmrc
[ -f pnpm-workspace.yaml ] && echo "--- ./pnpm-workspace.yaml ---" && cat pnpm-workspace.yaml
[ -f package.json ] && grep -E '"(pnpm|packageManager)"' package.json
```

Specifically scan for: `minimum-release-age=0`, `min-release-age=0`, `block-exotic-subdeps=false`, `ignore-scripts=false`, or any `--config.*` overrides in script definitions. Report each one — they will silently undo what you're about to set at the global level.

**Decide if there's anything to do (idempotency check)**:

Compare detection results against the target state. If **all** of the following hold, the system is already hardened — report observed values to the user, quote the bypass cheatsheet from step 8, and **stop**. Do not fetch docs, do not propose changes, do not re-prompt.

- `pnpm --version` ≥ 10.26 (covers both `minimum-release-age` and `block-exotic-subdeps`)
- `npm --version` ≥ 11.14 (the version where `min-release-age` is recognized — verify against current docs only if this priors-based threshold is what's blocking exit)
- `pnpm config list` shows `minimum-release-age=10080` (or higher), `block-exotic-subdeps=true`, `ignore-scripts=true`
- `npm config get min-release-age` returns `7` (or higher — npm's unit is **days**, not minutes) **and** `npm config ls --long` emits no "Unknown user config" warning for it
- No project-level overrides found above that weaken any of these keys
- No stray `packageManager` pin that overrides the active pnpm

If **any** condition fails, continue to step 3 — but carry the passing conditions forward: in step 4, only propose changes for the parts that aren't already correct (don't rewrite `~/.config/pnpm/rc` if its keys already match; don't upgrade pnpm if it's already new enough).

### 3. Fetch current docs

Run WebFetch on the three URLs at the top of this skill. For each fetched page, extract:

1. The **exact key name(s)** for the three settings (kebab-case for INI, camelCase for YAML — both may be valid depending on the file).
2. The **minimum tool version** that supports each key, if listed.
3. The **canonical file location** the docs name for global config.

If a current doc claims a different key name, file location, or version threshold than the priors above, **trust the current doc** — the priors may be stale.

If a current doc says one thing but the user's installed tool behaves differently (e.g. you write to the documented YAML file and `pnpm config list` doesn't surface the value), **trust observed behavior** for this user's system and write to wherever the tool actually reads.

### 4. Propose the concrete changes; get specific approval

Now you have enough to propose a precise plan. Only include items where the detected state does **not** already match the target — keys that are already correct should be called out as "already set, skipping" rather than re-written. Show the user, in a small table:

- Which config files you will create or modify, with the exact lines being added or removed (omit files whose contents already match)
- Whether any tool upgrades are needed (npm version too old for `min-release-age`? pnpm too old for either key?) — skip upgrades for tools that are already new enough
- The order of operations (upgrade → write configs → verify)
- Any project-level overrides you found, with a separate offer to patch each one

If after filtering you have an empty plan (everything was already correct except for one trivial thing, etc.), state that explicitly rather than padding the plan with no-op rows.

Wait for explicit go-ahead before any write. If the user wants to skip the upgrades, honor that — apply only the settings their current versions actually enforce, and tell them which keys will sit as no-ops.

### 5. Upgrade tools if needed

Only run these if the user approved the upgrade in step 4.

**npm** (recognizes `min-release-age` from ~11.14):

```bash
npm install -g npm@latest
npm --version  # verify
```

**pnpm via Corepack** (covers `minimum-release-age` 10.16+ and `block-exotic-subdeps` 10.26+):

```bash
corepack install -g pnpm@10        # latest 10.x — safer than @latest
# (or pnpm@latest if the user explicitly wants the newest major)
pnpm --version                     # verify
```

If Corepack reports `Installing pnpm@X.Y.Z...` but `pnpm --version` still shows the OLD version: a `packageManager` field in some parent `package.json` is overriding the global. From step 2 you should already have its path. Two ways to resolve:

- **Preferred**: if the file is a stray (e.g. `~/package.json` someone created by running `corepack use` in their home dir), offer to remove **only the `packageManager` field** — leave any dependency block intact. After removal, pnpm follows Corepack's `lastKnownGood`.
- **If the file is a real project the user wants pinned**: offer to update the pin to the new version (with matching `+sha512.<hex>` integrity — fetch from `https://registry.npmjs.org/pnpm/<version>` and convert the base64 to hex).

Do not blindly delete `package.json` files or rewrite ones with real dependencies.

**Standalone pnpm install** (not via Corepack): `pnpm self-update` if available; otherwise use the platform installer the user originally used (Homebrew, the install script from pnpm.io, etc.). Do not try to convert standalone → Corepack; ask first.

### 6. Apply the settings

Use exactly the file locations and key names confirmed in step 3, **not** the priors below. The priors are a fallback when docs are unreachable.

**Default file layout (verify before writing)**:

| File                | Purpose                                                                 | Keys to set                                              |
| ------------------- | ----------------------------------------------------------------------- | -------------------------------------------------------- |
| `~/.config/pnpm/rc` | pnpm's canonical global INI (from `globalconfig` in step 2)             | `minimum-release-age=10080`, `block-exotic-subdeps=true` |
| `~/.npmrc`          | npm user-level INI (read by npm; also read by pnpm for backward-compat) | `min-release-age=7` (npm's unit is **days**, not minutes), `ignore-scripts=true` |

Notes:

- **Do not** put `minimum-release-age` or `block-exotic-subdeps` in `~/.npmrc` — npm reads `~/.npmrc` and will emit "Unknown user config" warnings for keys it doesn't recognize. Putting them in `~/.config/pnpm/rc` keeps them invisible to npm and silences the noise.
- **Do not** write to `~/.config/pnpm/config.yaml` unless you have verified via a yaml-only test key that the installed pnpm version actually reads it. At pnpm 10.33.x it does not.
- **Do not** use `Write` to overwrite a pre-existing file at these paths — use `Edit` for additive changes. If the user has other entries in `~/.npmrc` (auth tokens, custom registries, etc.) you will destroy them with an overwrite.
- If `ignore-scripts=true` would break a package the user genuinely needs to build at install time (e.g. native modules), warn them. They can either skip this key, or use pnpm's `onlyBuiltDependencies` allowlist in their project's `pnpm-workspace.yaml`.

**If the user accepted patching project-level overrides** (from step 2), edit those files too: remove or weaken the override lines you reported. Show the diff before each edit.

### 7. Verify

Read effective config back through each tool — and check for warnings (warnings are the signal that something is still wrong).

```bash
pnpm config list 2>&1 | grep -E "release-age|exotic|ignore-scripts"
npm config ls --long 2>&1 | grep -E "release-age|ignore-scripts"

# Warning check: any "Unknown user config" lines should be GONE
pnpm config get minimum-release-age 2>&1
npm config get min-release-age 2>&1
```

Expected after a clean run on a modern stack:

- `pnpm config list` shows `block-exotic-subdeps=true`, `ignore-scripts=true`, `minimum-release-age=10080` (minutes), and the npm-side `min-release-age=7` (days — since `~/.npmrc` is also read by pnpm)
- `npm config ls --long` shows `ignore-scripts = true` and `min-release-age = "7"`, each marked `; overridden by user` (with no "Unknown user config" warnings)
- Calling `pnpm config get` or `npm config get` for any of these keys returns the value with no warning

If any "Unknown user config" warning persists, the corresponding tool is too old for that key. Either upgrade (step 5) or remove the key from the file that tool reads.

### 8. Leave the user a bypass cheatsheet

These are the escape hatches for when protection blocks a legitimate install. Quote them verbatim at the end of the run so the user has them:

- **One-off install ignoring release-age**: `pnpm install --config.minimum-release-age=0` (pnpm) or `npm install --min-release-age=0` (npm)
- **One-off ignoring exotic-deps block**: `pnpm install --config.block-exotic-subdeps=false`
- **Run a script that's blocked by ignore-scripts**: `pnpm rebuild <pkg>` or use pnpm's `onlyBuiltDependencies` allowlist in `pnpm-workspace.yaml`
- **Permanent per-package allowlist** (pnpm): add `minimum-release-age-exclude[]=<pkg>` to `~/.config/pnpm/rc`

## Failure modes to avoid

- **Trusting docs over observed behavior.** If `pnpm config list` doesn't show a key you just wrote, the file location is wrong — don't argue with the tool.
- **Using `pnpm config get <key>` as the sole verification.** It reads INI only. Use `pnpm config list` for the merged view.
- **Overwriting `~/.npmrc` with `Write`.** Auth tokens and custom registries live here. Use `Edit` for additive changes.
- **Removing files that aren't yours.** `~/package.json`, `~/.config/pnpm/config.yaml`, stray `.npmrc` files — investigate before deleting. A `package.json` at `~` often holds the user's "global-ish" CLI installs.
- **Ignoring stray `packageManager` pins.** If you upgrade pnpm via Corepack and `pnpm --version` doesn't reflect it, a pin somewhere above CWD is overriding. Step 2 finds these; don't skip it.
- **Silently churning when the user has paused.** If the user says "wait" or "before we churn," stop and present findings — don't auto-pilot through the next step.
