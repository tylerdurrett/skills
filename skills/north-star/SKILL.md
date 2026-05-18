---
name: north-star
description: Maintain `docs/north-star.md`, the project's vision/direction doc — seed it on first run, review and update it on subsequent runs. Use when the user wants to touch the project's direction doc.
---

# North Star

`docs/north-star.md` is the project's vision/direction doc — the spine the planning layer hangs off. The roadmap below it (`docs/roadmap.md`) is the capacity-honest sequencing of bets; epics and PRDs hang off the roadmap. The north star is what those layers are *for*.

This skill maintains that doc. It does **not** silently rewrite anything — every edit goes through a propose-then-apply gate.

The skill has two modes. The mode is decided automatically by whether `docs/north-star.md` already exists.

- **Init mode** — file missing. Walk the user through an interactive interview, capture verbatim answers, write the doc.
- **Review mode** — file present. Read it, survey recently shipped work via `gh`, propose targeted edits as a unified diff, apply on confirmation.

The two modes share a template (inlined below) and a fail-loudly posture: any I/O or `gh` failure surfaces a one-line note and stops; the skill never partially applies a write.

## Hard rules

- **Propose-then-apply, never silent rewrite.** In review mode, the skill must show the user the unified diff before any write. Apply only on explicit confirmation.
- **No external mirror.** `docs/north-star.md` is the canonical and only surface. No GH Discussion sync, no Linear, no second source of truth.
- **Fail loudly.** If the doc cannot be read, the file cannot be written, or `gh` returns an error, surface a one-line note prefixed `Loud:` (matching `/ship`'s convention for non-blocking failures) and stop. Do not continue with partial state.
- **Touch only `docs/north-star.md`.** The skill writes to no other file.
- **No sticky-comment marker.** Unlike `/to-spec` (and the `/triage` bookkeeping pass that follows it), this skill posts no `<!-- progress-comment:* -->` anchor — `docs/north-star.md` is itself the durable surface, so there's nothing on the tracker to anchor.

## Step 1: Decide mode

```bash
test -f docs/north-star.md && echo "review" || echo "init"
```

Branch on the result. Init mode goes to Step 2-init. Review mode goes to Step 2-review.

If `docs/` does not exist (impossible in this repo, but check), surface a `Loud:` note and stop.

## Init mode

### Step 2-init: Confirm first-time setup

Tell the user: `docs/north-star.md` does not exist. About to walk through an interview to seed it. Confirm before starting.

If they decline, stop.

### Step 3-init: Walk the template, one section at a time

Ask one question per section. Capture the user's answer verbatim into the corresponding blockquote, paragraph, or bullet list. Push back on vagueness — the heuristics below are stricter than the template's prose because a vague first fill compromises every future review.

Sections to interview, in order:

1. **§1 The One-Liner** — _"In one sentence a stranger would understand: what is this project?"_
   - Reject multi-sentence answers.
   - Reject pure jargon ("AI-native media-velocity platform") — ask what they'd say to a friend at a coffee shop.
   - If they cannot say it in one sentence, the template's own prompt applies: _"you don't understand it yet."_ Help them strip until it fits.

2. **§2 Why This Matters (to me)** — _"What's the personal reason you care enough to keep going when this gets hard? Not the pitch — the truth. Give me 1–3 bullets."_
   - If the answer sounds like a marketing line, ask: _"But why do **you** care?"_

3. **§3 Who It's For** — _"Name a real person or a sharp archetype. Not 'small business owners.' Not 'everyone.'"_
   - Quote a sharper bar back if they go generic: _"Solo bookkeepers running month-end close who keep losing the thread between their spreadsheet and the accounting system"_ — that's the bar. Adapt to whatever the project's actual user looks like.

4. **§4 The Vision** — _"What does the world look like when this is working? Two or three paragraphs max."_
   - Wall of text? Ask them to cut.
   - One line? Ask what's actually different in the world.

5. **§6 Open Questions** — _"What are 2–5 things you don't know yet? Naming them is half the work."_
   - Empty is allowed but flag it: any non-trivial project with zero open questions usually means the user hasn't sat with it long enough.

Sections **not** interviewed during init — seeded with the template's empty structure:

- **§5 What I've Learned** — empty. Review mode appends `## Week of YYYY-MM-DD` blocks with bullets the user dictates.
- **§7 Decisions Log** — empty table. Scoped to *non-architectural* direction/scope calls (architectural decisions live in `docs/adr/`). Review mode may add rows when the survey surfaces a direction call worth recording.

### Step 4-init: Set the header

- H1: `# <Project Name> — North Star` (the user supplies the project name; ask before writing if it isn't obvious from the conversation, CLAUDE.md, or the repo's README).
- `_Last reviewed: YYYY-MM-DD_` — today's date.
- `_Status: 🌱 shaping_` by default. Ask only if the user wants a different status from the menu (`🌱 shaping`, `🔨 building`, `🚀 shipping`, `🔄 iterating`, `❄️ paused`).

### Step 5-init: Write `docs/north-star.md`

Write the file using the template structure below, with interviewed sections populated and seeded sections empty. Italic prompt lines stay in place — they help future-you on weekly reviews and are part of the template, not scaffolding.

Tighten the template as you fill it in:

- **§2 bullets** — the template has three placeholders; keep only the ones the user filled in. Drop empty `-` lines.
- **§6 bullets** — the template has one placeholder; expand to as many `-` lines as the user gave (2–5).
- **§3 bullet** — same posture (one or more bullets, not the literal placeholder).
- **`_Status:_` line** — replace the full menu (`🌱 shaping / 🔨 building / 🚀 shipping / 🔄 iterating / ❄️ paused`) with the single chosen status. Do not write the menu line into the file.

After writing, surface a one-line confirmation: `Wrote docs/north-star.md (Last reviewed YYYY-MM-DD, Status <chosen>).` This mirrors review mode's terminal note.

Do not touch any other file. (No `AGENTS.md` substitution, no `README.md` edit — those are garage-door-up patterns that don't apply here.)

### Step 6-init: Read it back

Show the user their final §1 The One-Liner and §4 The Vision. Ask: _"Does the one-liner still feel true after writing it out?"_ A "no" is the most useful signal of the session — invite revision on the spot before stopping.

If they revise, write the revised file. If they confirm, stop.

End with one short pointer: _"Run `/north-star` again whenever you want to review — typically weekly. The skill will survey what shipped since the last review and propose a diff."_

## Review mode

### Step 2-review: Read the doc and parse last-reviewed

Read `docs/north-star.md` once and hold the contents in memory — Step 5-review reuses this buffer to build the unified diff. Do not re-read.

Parse the line matching `^_Last reviewed: (\d{4}-\d{2}-\d{2})_$`. If absent or malformed, surface a `Loud:` note and stop — the doc is corrupt; the user must repair the header by hand before the survey can run.

### Step 3-review: Survey recently shipped work

Issue all three queries in a single message as parallel Bash tool calls — the agent runtime parallelizes per-message tool calls, but a sequential block of `bash` lines reads as serial. The queries are independent; running them concurrently shaves the survey to one round-trip.

```bash
LAST=<parsed-date>
gh issue list --label "type:prd" --state closed --search "closed:>${LAST}" --json number,title,closedAt
gh issue list --label "type:epic" --state closed --search "closed:>${LAST}" --json number,title,closedAt
gh pr list --state merged --base main --search "merged:>${LAST} head:prd/" --json number,title,mergedAt,headRefName
```

Combine into a single chronological list. Surface to the user as short bullets:

```
Since YYYY-MM-DD:
- Closed PRDs: #<N> <title>, #<M> <title>
- Closed epics: #<N> <title>
- PRD-promotion PRs merged to main: #<#> <title> (head: prd/issue-<P>-<slug>)
```

If the survey returns nothing, tell the user there's been no shipped tracker work since the last review and ask whether they still want to do a sanity-check pass on §1 and §4 anyway. If they decline, stop without writing — `_Last reviewed:_` stays at its current date until there's actually something to review.

### Step 4-review: Interview the user on the shipped work

For each shipped item the user wants to record (this is itself a quick interview — the user may say "skip this one"):

- _"What did you take away from #<N>?"_

Capture each answer as a one-line bullet under a single weekly heading.

Then a sanity-check pass on the durable sections:

- Show §1 The One-Liner. Ask: _"Does this still feel true?"_
- Show §4 The Vision. Ask: _"Does this still feel true?"_

If the user wants to revise either, capture the revised text.

Ask once whether any of the surveyed work involved a non-architectural direction or scope call worth recording in §7 Decisions Log. If yes, capture: date (today), one-line decision, one-line "why."

### Step 5-review: Propose a unified diff

Stage the proposed edits in memory against the buffer from Step 2-review, then show the user the unified diff (`diff -u` shape) of the current `docs/north-star.md` versus the proposed version. Cover all changes:

- New `## Week of YYYY-MM-DD` block appended to **§5 What I've Learned** with the bullets captured in Step 4-review.
- Any new rows appended to the **§7 Decisions Log** table.
- Any revisions to **§1** or **§4** the user requested.
- Header line `_Last reviewed:_` bumped to today.

If Step 4-review captured no content edits at all (no shipped-item bullets, no §7 row, no §1/§4 revision), ask once whether to bump `_Last reviewed:_` alone or skip writing entirely. A date-only bump is a valid outcome — it records that the user *did* sit with the doc on this date and confirmed nothing needed to change.

Ask explicitly: _"Apply this diff?"_ Wait for confirmation.

### Step 6-review: Apply or discard

- **Confirmed:** write the new `docs/north-star.md` in a single overwrite. Do not partially apply. Surface a one-line note (`Updated docs/north-star.md. Last reviewed bumped to YYYY-MM-DD.`) and stop.
- **Declined:** discard the staged edits. Surface a one-line note (`No changes written. The doc on disk is unchanged.`) and stop.

A failed write surfaces a `Loud:` note with the error verbatim and stops — do not retry, do not partial-write.

## Inlined template

The template lives here, not in a separate file. When init mode writes `docs/north-star.md`, it uses this exact structure with the interviewed sections populated and the seeded sections empty.

```markdown
# <Project Name> — North Star

> **One doc. Living. Edit on review. This is the thing you come back to.**

_Last reviewed: YYYY-MM-DD_
_Status: 🌱 shaping / 🔨 building / 🚀 shipping / 🔄 iterating / ❄️ paused_

---

## 1. The One-Liner

_What is this, in one sentence a stranger would understand?_

> [Populated by init mode from the §1 interview.]

## 2. Why This Matters (to me)

_The personal reason. The thing that makes you care enough to keep going when it gets hard. Not the pitch — the truth._

- [Populated by init mode from the §2 interview.]
-
-

## 3. Who It's For

_Name a real person or a sharp archetype. "Small business owners" is not an answer. "Solo bookkeepers running month-end close who keep losing the thread between their spreadsheet and the accounting system" is._

- [Populated by init mode from the §3 interview.]

## 4. The Vision (the zoomed-out picture)

_What does the world look like when this is working? Paint it. Two or three paragraphs max. This is what you re-read when you're lost in the weeds._

[Populated by init mode from the §4 interview.]

## 5. What I've Learned

_Append-only. On each review, add 1–3 bullets. This is where the nourishing happens — it's the record of how your understanding is changing._

(Empty on init; review mode appends `## Week of YYYY-MM-DD` blocks here.)

## 6. Open Questions

_Things you don't know yet. It's fine. Naming them is half the work._

- [Populated by init mode from the §6 interview.]

## 7. Decisions Log

_Non-architectural direction and scope calls. Architectural decisions live in `docs/adr/`. When you make a real call here — what to drop, what to defer, what to commit to — drop it in this table with the date and a one-line "why." Future you will thank present you._

| Date | Decision | Why |
| ---- | -------- | --- |
|      |          |     |
```

## What this skill does NOT do

- It does not author the doc's content outside the interview — the user provides every word in init mode and every bullet/decision in review mode.
- It does not mirror the doc to a GH Discussion, Linear, or any other surface. `docs/north-star.md` is the only canonical source.
- It does not auto-schedule itself. The user invokes `/north-star` whenever they want a review (weekly is a sensible default cadence).
- It does not touch `docs/roadmap.md`, `docs/adr/`, or any other file. Roadmap maintenance is `/roadmap-review`'s job.
- It does not close, label, or comment on tracker issues. The survey is read-only.
- It does not retry failed writes or `gh` calls. Fail loudly, stop, let the user fix and re-invoke.

## Verification

Manual end-to-end checklist for this skill — what to run, what to inspect, what "correct" looks like.

### Init mode (file missing)

1. **Pre-condition.** `docs/north-star.md` does not exist.
2. **Run `/north-star`.** The skill confirms first-time setup, then walks the §1, §2, §3, §4, §6 interviews in order. It pushes back on vague answers (multi-sentence one-liners, marketing-tone "why", generic "everyone" audience).
3. **Inspect the written file:**
   - H1 is `# <Project Name> — North Star`, with the project name filled in.
   - `_Last reviewed:_` is today's date in `YYYY-MM-DD` format.
   - `_Status:_` line shows the *chosen single status* (e.g. `_Status: 🌱 shaping_`), not the full menu from the template.
   - Sections §1, §2, §3, §4, §6 contain the interviewed content verbatim.
   - Section §5 (**What I've Learned**) is empty under its header and italic prompt — no `## Week of` block yet.
   - Section §7 (**Decisions Log**) is the empty table from the template.
   - There is **no** Current Roadmap section.
   - There is **no** Public Thread section.
4. **No other files were touched.** `git status` shows only `docs/north-star.md` (and the skill files themselves, if this is the implementing PR).
5. **Read-back step.** The skill shows §1 and §4 and asks whether they still feel true. A "no" path lets the user revise on the spot.

### Review mode (file present)

1. **Pre-condition.** `docs/north-star.md` exists with a parseable `_Last reviewed: YYYY-MM-DD_` header.
2. **Run `/north-star`.** The skill parses the date, runs the three `gh` surveys (closed `type:prd`, closed `type:epic`, merged `prd/issue-*` PRs since the parsed date), and surfaces a short list.
3. **Interview pass.** The skill asks one question per shipped item ("what did you take away from #<N>?") and captures the answer. It then re-shows §1 and §4 for a sanity check.
4. **Diff proposal.** The skill shows a unified diff covering: appended **§5** weekly block, any new **§7** rows, any §1/§4 revisions, bumped `_Last reviewed:_`. The skill **does not write** before asking.
5. **Confirm path.** Confirming applies the diff in a single overwrite. The new `_Last reviewed:_` is today's date. No other file changes.
6. **Decline path.** Declining writes nothing. The doc on disk is byte-identical to before invocation.
7. **Empty-survey path.** With no shipped tracker work since the last review, the skill says so and offers a sanity-check-only pass on §1/§4. Declining stops cleanly with no write.

### Failure paths

- **Corrupt header.** `_Last reviewed:_` line missing or malformed → surface a `Loud:` note and stop. No survey runs, no write occurs.
- **`gh` failure.** Any of the three survey commands fails → surface a `Loud:` note with the error verbatim and stop. Do not continue with partial survey results.
- **Write failure.** Disk error during the final overwrite → surface a `Loud:` note with the error verbatim and stop. The doc may be in a corrupt state — the user repairs by hand or re-invokes after fixing the underlying cause.

If any step surfaces drift, fix the skill in a follow-up rather than the issue — the skill is the source of truth.
