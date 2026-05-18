---
name: roadmap-review
description: Maintain `docs/roadmap.md`, the project's capacity-honest sequencing of bets between the north star and `type:epic` issues — seed it on first run, review and update it on subsequent runs. Use when the user wants to touch the project's roadmap doc.
---

# Roadmap Review

`docs/roadmap.md` is the capacity-truth-telling layer between `docs/north-star.md` (unbounded vision) and `type:epic` issues (committed bodies of work). Its load-bearing function is the math of "given my bandwidth, here are my bets in order." The shape itself resists over-commitment: cap of 1 on `In flight`, 2–3 on `Next`, an unordered `Vibes backlog`, and an append-only `Shipped`.

This skill maintains that doc. It does **not** silently rewrite anything — every edit goes through a propose-then-apply gate.

The skill has two modes. The mode is decided automatically by whether `docs/roadmap.md` already exists.

- **Init mode** — file missing. Write the four-section skeleton, then run a single permissive seed pass (every section is skippable).
- **Review mode** — file present. Read it, run a full parallel `gh` survey, walk the four sections with targeted check-ins, propose targeted edits as a unified diff, apply on confirmation.

The two modes share a template (inlined below) and a fail-loudly posture: any I/O or `gh` failure surfaces a one-line note and stops; the skill never partially applies a write.

## Hard rules

- **Propose-then-apply, never silent rewrite.** In review mode, the skill must show the user the unified diff before any write. Apply only on explicit confirmation.
- **No external mirror.** `docs/roadmap.md` is the canonical and only surface. No GH Discussion sync, no Linear, no second source of truth.
- **Fail loudly.** If the doc cannot be read, the file cannot be written, or `gh` returns an error, surface a one-line note prefixed `Loud:` (matching `/ship`'s convention) and stop. Do not continue with partial state.
- **Touch only `docs/roadmap.md`.** The skill writes to no other file. Tracker reads only — no labels, comments, or state changes on issues or PRs.
- **No sticky-comment marker.** Unlike `/to-spec` (and the `/triage` bookkeeping pass that follows it), this skill posts no `<!-- progress-comment:* -->` anchor — `docs/roadmap.md` is itself the durable surface, so there's nothing on the tracker to anchor.
- **Cap-of-1 on `In flight` is a soft warn, not a refusal.** If a second in-flight epic candidate would land in the proposed diff, surface a loud one-line warn ("the In-flight cap is 1; this would be a 2nd") and let the user override.
- **Edit scope is decided in the moment.** Prose, bullets, section membership, and ordering are all eligible for proposed edits — the agent and user negotiate scope during the review conversation, not via hardcoded rules. The only invariant is that nothing lands without the user confirming the diff.

## Step 1: Decide mode

```bash
test -f docs/roadmap.md && echo "review" || echo "init"
```

Branch on the result. Init mode goes to Step 2-init. Review mode goes to Step 2-review.

If `docs/` does not exist (impossible in this repo, but check), surface a `Loud:` note and stop.

## Init mode

### Step 2-init: Confirm first-time setup

Tell the user: `docs/roadmap.md` does not exist. About to write the four-section skeleton and run a single permissive seed pass. Confirm before starting.

If they decline, stop.

### Step 3-init: Write the skeleton

Write `docs/roadmap.md` using the inlined template below — H1, today's `_Last reviewed:_`, the placeholder italic preamble, and the four empty sections (`## In flight`, `## Next`, `## Vibes backlog`, `## Shipped`). Do not interview yet — get the file on disk so subsequent steps can edit it.

Surface a one-line note: `Wrote skeleton docs/roadmap.md (Last reviewed YYYY-MM-DD).`

### Step 4-init: Permissive seed pass

Walk the seedable sections in order. For each, ask one question and accept "skip" as a valid answer:

1. **`In flight`** — _"Is there a `type:epic` issue currently in flight you want to seed? If yes, give me the issue number (`#<N>`) and one-line title. Skip if not."_ Validate any provided number with `gh issue view <N> --json labels` to confirm it carries `type:epic`. If validation fails, surface a `Loud:` note and let the user re-answer or skip.
2. **`Next`** — _"Any 1–3 sequenced epics for `Next`? Issue numbers + titles, in order. Skip if not."_ Same validation as `In flight`.
3. **`Vibes backlog`** — _"Any hypothetical epics to seed? Plain bullets, no issue numbers. Skip if not."_

`Shipped` is not seeded by init mode; review mode populates it over time as epics close.

The user is **never expected to hand-author the file** — every section is skippable, and an empty doc is a valid outcome.

### Step 5-init: Apply the seed edits

If the user provided any seed content, propose a unified diff against the skeleton and ask explicitly: _"Apply these seed edits?"_ Wait for confirmation.

- **Confirmed:** write the populated `docs/roadmap.md` in a single overwrite. Surface `Updated docs/roadmap.md (seeded N entries).`
- **Declined:** the skeleton stays as-is. Surface `Skeleton stands. Run /roadmap-review whenever you want to seed or review.`
- **No seed input from any section:** skip the diff step. The skeleton is the final state. Surface `Skeleton stands; nothing to seed yet.`

End with one short pointer: _"Run `/roadmap-review` again whenever you want to review — typically slower than weekly. The skill will survey what's shipped since the last review and propose a diff."_

## Review mode

### Step 2-review: Read the doc and parse last-reviewed

Read `docs/roadmap.md` once and hold the contents in memory — Step 6-review reuses this buffer to build the unified diff. Do not re-read.

Parse the line matching `^_Last reviewed: (\d{4}-\d{2}-\d{2})_$`. If absent or malformed, surface a `Loud:` note and stop — the doc is corrupt; the user must repair the header by hand before the survey can run.

Also parse the In-flight bullet (if any) to extract the epic's `#<N>` for the In-flight survey query.

### Step 3-review: Run the parallel survey

Issue all queries in a single message as parallel Bash tool calls — the agent runtime parallelizes per-message tool calls, but a sequential block of `bash` lines reads as serial. Running them concurrently shaves the survey to one round-trip.

```bash
LAST=<parsed-date>
gh issue list --label "type:epic" --state closed --search "closed:>${LAST}" --json number,title,closedAt,stateReason
gh issue list --label "type:epic" --state open --json number,title,labels
gh issue list --label "type:prd" --state closed --search "closed:>${LAST}" --json number,title,closedAt
```

If an In-flight epic was parsed in Step 2-review, additionally fetch its body and comments so the scope-creep check has materialized-vs-candidate counts. Run this in the same parallel batch:

```bash
IF_EPIC=<parsed-issue-number>
gh issue view $IF_EPIC --json body,comments
```

Parse the `<!-- progress-comment:epic -->` sticky comment from the returned `comments` array (mirroring `/ship`'s parse): `- [ ] #<P> — <title>` rows are open materialized PRDs, `- [x] #<P> — <title>` rows are closed materialized PRDs. Cross-reference the open `#<P>` numbers against the `closed type:prd since LAST` survey to produce the "closed since last review" count for the In-flight epic. Parse the epic body's `## Candidate PRDs` section bullets to count remaining candidates.

Combine into a structured survey. Surface to the user as short bullets:

```
Since YYYY-MM-DD:
- Closed epics: #<N> <title> (reason: <completed|not_planned|null>), ...
- Closed PRDs: #<N> <title>, ...
- In-flight epic #<E> <title>:
    - Materialized: <M> PRDs in progress comment (<closed-since-LAST> closed since LAST)
    - Candidates remaining in body: <C>
- Open epics not anchored in roadmap: #<N> <title>, ...
- Roadmap entries with stale tracker state: <bullet>, ...
```

If the survey returns nothing AND there is no In-flight epic to status-check, tell the user there's been no shipped tracker work since the last review and ask whether they still want a sanity-check pass on the four sections. If they decline, stop without writing — `_Last reviewed:_` stays at its current date until there's actually something to review.

### Step 4-review: Walk the four sections with targeted check-ins

#### `## Shipped` — closed epics since last review

For each closed `type:epic` since the last-reviewed date, propose a default destination using the close-reason heuristic and **always confirm**:

- `stateReason == "completed"` → propose **move to `Shipped`** (preserve historical record).
- `stateReason == "not_planned"` (or carries `wontfix` label) → propose **drop entirely** (don't pollute `Shipped` with abandoned work).
- `stateReason == null` (older issues without a recorded reason) → propose **move to `Shipped`** as the record-preserving default and ask.

For each, ask the user to confirm or override. Capture the chosen destination. New `Shipped` rows are inserted at the top of the section (reverse-chronological — newest first).

#### `## In flight` — scope-creep check

If there is an in-flight epic, surface its progress-comment state (materialized PRDs vs. candidate bullets remaining in body) and recent PRD activity (closed since last review; new since last review). Ask: _"Still on track? Scope creeping?"_

The user may decide to move the epic to `Shipped`/`Next`/drop, narrow scope (which the user does manually on the epic itself; this skill doesn't touch the epic body), or leave it untouched — that's an in-conversation decision, not a hardcoded transition.

If `## In flight` is empty but the survey found a `type:epic` issue with `in-progress` label not anchored anywhere in the roadmap, flag it loudly here and let the conversation decide whether to add it.

If `## In flight` somehow has more than one bullet (existing drift, not a new addition), surface the loud cap-of-1 warn and let the user resolve in the diff.

#### `## Next` — reality check + reorder

Show the current `Next` entries. Ask: _"Still the right bets given what shipped? Reorder, drop, or add?"_

No special reorder UX — the agent and user negotiate the new order in the conversation, and the change shows up in the proposed diff. Adding new entries here (e.g. a Vibes-backlog item that has graduated) is fair game.

#### `## Vibes backlog` — staleness sweep + additions

Show the current entries. Walk them and ask whether each still feels current. For each, capture **keep**, **drop**, or **graduate** (graduate means: the user wants to convert this to a real `type:epic` issue via `/to-spec` — this skill does not run `/to-spec` itself, but it removes the bullet from the diff once the user confirms graduation, so `/to-spec`'s subsequent run lands cleanly).

After the sweep, ask: _"Anything new to seed?"_ Capture additions.

### Step 5-review: Drift detection (both directions)

During the section walks above, surface any roadmap↔tracker mismatch loudly. Drift never auto-resolves; the conversation decides.

- A `type:epic` issue with `in-progress` label but no entry anywhere in the roadmap → flag and offer to add it (`In flight` if the cap allows; otherwise the conversation decides where it lands).
- An `In flight` / `Next` entry whose referenced `#<N>` is closed on tracker → already covered by the Shipped/dropped check-in above.
- An `In flight` / `Next` entry whose referenced `#<N>` is open but **not** labeled `in-progress` (for `In flight`) → flag loudly; the bullet may need moving back to `Vibes backlog`, or the tracker label may be stale.

### Step 6-review: Propose a unified diff

Stage all proposed edits in memory against the buffer from Step 2-review. Show the user the unified diff (`diff -u` shape) of current vs. proposed `docs/roadmap.md`. Cover:

- Section additions, removals, and reorders captured in Step 4-review.
- `## Shipped` rows appended (newest at top) and corresponding removals from `In flight` / `Next`.
- Any prose preamble edits the conversation produced.
- Bumped `_Last reviewed:_` line to today.

If Step 4-review captured no content edits at all (no shipped/dropped destination changes, no `In flight` move, no `Next` reorder/add/drop, no `Vibes` mutation, no prose edit), ask once whether to bump `_Last reviewed:_` alone or skip writing entirely. A date-only bump is a valid outcome — it records that the user *did* sit with the doc on this date and confirmed nothing needed to change.

If the proposed diff would land a second bullet under `## In flight`, surface the loud cap-of-1 warn now and ask the user to confirm the override before continuing.

Ask explicitly: _"Apply this diff?"_ Wait for confirmation.

### Step 7-review: Apply or discard

- **Confirmed:** write the new `docs/roadmap.md` in a single overwrite. Do not partially apply. Surface `Updated docs/roadmap.md. Last reviewed bumped to YYYY-MM-DD.` and stop.
- **Declined:** discard the staged edits. Surface `No changes written. The doc on disk is unchanged.` and stop.

A failed write surfaces a `Loud:` note with the error verbatim and stops — do not retry, do not partial-write.

## Inlined template

The template lives here, not in a separate file. Init mode writes `docs/roadmap.md` using this exact structure with `_Last reviewed:_` set to today and the four sections empty under their italic prompts. The italic prompt under each H2 is part of the template — it helps future reviews and stays in the file.

```markdown
# Iterator TV — Roadmap

> **One doc. Living. Edit on review. The capacity-honest sequencing of bets between the north star and the epics.**

_Last reviewed: YYYY-MM-DD_

---

_Light prose framing the current strategic moment — the theme of the next several months, the epic in flight, the dependency chain in `Next`, anything sitting in `Vibes backlog` that's getting close to graduating. One paragraph. Replace this italic placeholder once you have something to say._

## In flight

_Cap: 1 epic. Multiple in-flight epics is the failure mode this structure exists to prevent. Format: `- #<N> — <title>`._

## Next

_Sequenced 2–3 epics. The order is the bet — top-most goes next. Format: `- #<N> — <title>`._

## Vibes backlog

_Unordered hypothetical epics. No issue numbers; plain bullets. Drop entries that no longer feel current; add entries when they appear. Format: `- <one-line description>` (or `- **<theme>:** <description>` if a theme prefix helps scannability)._

## Shipped

_Append-only, newest first. Populated by `/roadmap-review` as epics close with reason "completed". Format: `- #<N> — <title>`._
```

## What this skill does NOT do

- It does not author content beyond the user's input — every bullet, every prose edit, every reorder is the user's call. The skill structures the conversation and proposes the diff; the user owns the words.
- It does not enforce a cadence. The user invokes whenever they want a review.
- It does not refuse to break the cap-of-1 on `In flight`. It warns loudly and lets the user override.
- It does not mirror the doc to a GH Discussion, Linear, or any other surface.
- It does not auto-resolve drift between roadmap and tracker. Surfacing only.
- It does not graduate Vibes-backlog entries to `type:epic` issues. That is `/to-spec`'s job; this skill removes the bullet from the diff once the user confirms graduation, so a follow-up `/to-spec` run lands cleanly.
- It does not modify `/to-spec`, `/ship`, or any other skill.
- It does not touch `docs/north-star.md`, `docs/adr/`, or any tracker comment, label, or issue. Survey is read-only.
- It does not retry failed writes or `gh` calls. Fail loudly, stop, let the user fix and re-invoke.

## Verification

Manual end-to-end checklist for this skill — what to run, what to inspect, what "correct" looks like.

### Init mode (file missing)

1. **Pre-condition.** `docs/roadmap.md` does not exist.
2. **Run `/roadmap-review`.** The skill confirms first-time setup, writes the four-section skeleton, then walks the permissive seed pass.
3. **Inspect the written skeleton (after Step 3-init):**
   - H1 is `# Iterator TV — Roadmap`.
   - `_Last reviewed:_` is today's date in `YYYY-MM-DD` format.
   - **No** `_Status:_` line.
   - The italic placeholder preamble paragraph is present under the `---` divider.
   - Four sections in order: `## In flight`, `## Next`, `## Vibes backlog`, `## Shipped`. Each has its italic prompt and is otherwise empty.
4. **Permissive seed pass.** Each section accepts "skip" as a valid answer. Skipping every section results in the skeleton being the final state — no diff prompt, no second write.
5. **Seeded run.** Providing seed content for any section produces a unified diff. Confirming applies the diff in a single overwrite. Declining leaves the skeleton untouched.
6. **Issue-number validation.** Providing a non-`type:epic` issue number for `In flight` or `Next` surfaces a `Loud:` note and offers a re-answer or skip; it does not silently accept the invalid reference.
7. **No other files were touched.** `git status` shows only `docs/roadmap.md` (and the skill files themselves, if this is the implementing PR).

### Review mode (file present)

1. **Pre-condition.** `docs/roadmap.md` exists with a parseable `_Last reviewed: YYYY-MM-DD_` header.
2. **Run `/roadmap-review`.** The skill parses the date, runs the parallel `gh` surveys (closed epics + open epics + closed PRDs since LAST + In-flight epic body/comments + linked PRDs if applicable), surfaces the structured summary.
3. **Section walk.** The skill walks `Shipped` (closed-since-last-review epics with destination heuristic + confirm), `In flight` (scope-creep check), `Next` (reality check + reorder), `Vibes backlog` (staleness sweep + additions).
4. **Drift detection.** In-progress epic with no roadmap entry → flagged and offered for placement. In-flight bullet whose epic is closed or no longer `in-progress` → flagged. Resolution decided in conversation.
5. **Cap-of-1 warn.** If a proposed diff would land a second bullet under `## In flight`, the skill surfaces a loud warn before asking "Apply this diff?" and the user can override.
6. **Heuristic propose-then-confirm.** Closed epic with `stateReason == "completed"` → defaults to Shipped; `stateReason == "not_planned"` → defaults to drop; `stateReason == null` → defaults to Shipped. The user always confirms or overrides.
7. **Diff proposal.** The skill shows a unified diff covering all section edits and the bumped `_Last reviewed:_`. **Does not write** before asking.
8. **Confirm path.** Confirming applies the diff in a single overwrite. The new `_Last reviewed:_` is today's date. No other file changes.
9. **Decline path.** Declining writes nothing. The doc on disk is byte-identical to before invocation.
10. **Empty-survey path.** With no shipped tracker work and no In-flight epic to status-check, the skill says so and offers a sanity-check-only pass on the four sections. Declining stops cleanly with no write. A date-only `_Last reviewed:_` bump is a valid outcome when the user *did* sit with the doc but had nothing to change.

### Failure paths

- **Corrupt header.** `_Last reviewed:_` line missing or malformed → surface a `Loud:` note and stop. No survey runs, no write occurs.
- **`gh` failure.** Any survey command fails → surface a `Loud:` note with the error verbatim and stop. Do not continue with partial survey results.
- **Write failure.** Disk error during the final overwrite → surface a `Loud:` note with the error verbatim and stop. The doc may be in a corrupt state — the user repairs by hand or re-invokes after fixing the underlying cause.
- **Invalid seed reference (init mode).** Providing an issue number that isn't `type:epic` for `In flight`/`Next` surfaces a `Loud:` note and offers re-answer or skip. The skeleton remains untouched until valid input is captured.

If any step surfaces drift, fix the skill in a follow-up rather than the issue — the skill is the source of truth.
