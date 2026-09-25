---
name: how-to-use
description: Show the project's user manual: how the workflow flows, what skills are available, and where to start. Static reference; same content every invocation. Use when the user says "how do I use this", "show me the manual", "what skills are there", "how does this all work", "where do I start", or otherwise asks for an overview of the system.
---

# How to Use

Print the user manual for the project's skill ecosystem.

This skill is **static**: the output is the same every invocation. It does not survey local state, fetch from the issue tracker, or read the working tree. The job here is documentation; `/triage` with no arguments is the skill that reads state. For the longer-form canonical version of this overview see [docs/agents/README.md](../../../docs/agents/README.md); this skill prints the inline-readable digest.

## Hard rules

- **Print the report below verbatim.** Do not modify, summarize, expand, or interpolate. The whole point is predictability; same answer every time.
- **Do not run survey commands.** No `gh`, no `git`, no file listings. The skill is offline.
- **Do not invoke other skills.** Mention them as text; never run them.
- **Do not preface the output** with phrases like "Here's the manual" or "Sure, let me explain." Just print the report.

## The report

```
This project ships work through a small recursive loop, where each step
is a slash command. The same shape applies whether you're landing a
one-line fix or a multi-month initiative.

## The hierarchy

Five tiers, top to bottom. Bigger tiers contain smaller tiers.

- **Initiative** (`size:initiative` issue): a directed effort toward an
  outcome. Groups multiple features.
- **Feature** (`size:feature` issue): a meaningful unit of user-facing
  value. Has its own integration branch.
- **Slice** (`size:slice` issue): a vertical, demoable cut of a feature.
  Contains multiple tasks. Has its own integration branch when
  multi-task.
- **Task** (`size:task` issue): one PR's worth of work. The leaf.
- **PR**: the actual code change, opened against the parent's
  integration branch.

Every lifecycle issue on the tracker is a **spec**, regardless of tier;
the size label is what tells you which tier it sits at. A slice can sit
under a feature (typical) or stand alone as an orphan; behavior is
identical. Wayfinder maps and tickets are pre-spec decision work outside
this hierarchy.

## The loop

**Optionally before the loop**, for a foggy, multi-session idea:

- **`/wayfinder`** maps the fog into decision tickets, each sized to one
  100K-token agent session, and resolves them with supporting skills such
  as **`/research`**, **`/grilling`**, **`/domain-modeling`**, and
  **`/prototype`**. Once the map is clear, it hands off to `/to-spec`.

**Once at the top**, per idea:

1. **`/grill-with-docs`** interviews you about the idea, weighing it
   against `CONTEXT.md` and the project's ADRs. Sharpens vocabulary,
   surfaces gaps, updates docs inline as decisions resolve.
2. **`/to-spec`** captures the conversation as a spec on the tracker,
   sized at one of the four tiers. The size call is the skill's best
   guess, stated inline so you can override. Parent linkage is inferred
   from context. Specs land with `needs-triage`.

**Per tier**, recursively, until everything bottoms out as tasks:

3. **`/triage`** verifies the spec's size (may change it), declares the
   integration branch for features and slices, seeds the sticky progress
   comment for initiatives, applies the next state label, clears
   `needs-triage`.
4. **`/decompose`** produces children one tier smaller. Initiative
   produces features; feature produces slices; slice produces tasks.
   Tier-aware: one skill covers all three.
5. **`/check`** is a fast single-agent sanity check on the decomposition
   you just produced. **`/audit`** is the heavier multi-agent version
   with write-back; reach for it when the cost of a flawed decomposition
   is high. Both are optional but recommended.

**Per task**, once a leaf is ready:

6. **`/easy-auto`** implements the task end-to-end on a branch off its
   parent's integration branch, then opens a PR for review. It can also
   take a whole slice in one run.
7. **`/ship`** lands the PR, closes the task, prunes the local branch.

**Per parent**, once all its children are closed:

- Run **`/ship`** on the slice to promote its integration branch onto
  the feature's branch. Intermediate; not user-visible yet.
- Run **`/ship`** on the feature to promote its branch onto `main`.
  This is the production-visible moment.
- Initiatives close manually; the maintainer decides when the
  Definition of done is met.

The recursion is the point: the triage → decompose → check trio runs
once per tier. Initiatives decompose into features, features into
slices, slices into tasks. Same primitives, different layer.

## The labels

Four orthogonal axes on every spec:

- **Size axis** (`size:initiative` / `size:feature` / `size:slice` /
  `size:task`): which tier the spec lives at. Absence means awaiting
  triage.
- **State axis** (`needs-triage` / `needs-info` / `needs-grilling` /
  `ready-for-agent` / `ready-for-human` / `deferred` / `wontfix`):
  where the spec sits in the triage workflow. `needs-grilling` is the
  one to know: synthesized children of `/decompose` land with it,
  waiting for a `/grill-with-docs` pass before they're ready to execute.
- **Lifecycle axis** (`in-progress` / closed): whether active work has
  begun. Set automatically by the lifecycle skills.
- **Category axis** (`bug` / `enhancement` / `cleanup`): optional, for
  filtering.

The mutually exclusive **`wayfinder:*`** labels classify pre-spec maps
and decision tickets separately; they are not a fifth lifecycle axis.

## Integration branches

Code flows up the hierarchy the same way the spec hierarchy flows down:

    main
     └── feature/issue-<F>-<slug>           created lazily on first task
          └── slice/issue-<S>-<slug>        created when the slice is multi-task
               └── <type>/issue-<T>-<slug>  task branch

Each task's PR targets its parent's integration branch. `/ship` walks
promotions up the tree.

## A few helpers

- **`/triage`** with no arguments surveys the tracker and recommends
  the single next thing to do. When you don't know where you are, run
  this first.
- **`/diagnose`** is a disciplined loop for tracking down a bug.
- **`/tdd`** is a red-green-refactor build loop for new code.
- **`/improve-codebase-architecture`** finds places the code wants to
  be cleaner.

## Where to start right now

- **You have work in progress:** run **`/triage`** with no arguments.
- **You have a foggy, multi-session idea:** run **`/wayfinder`**.
- **You have an idea brewing:** run **`/grill-with-docs`**.
- **You're not sure:** run **`/triage`** with no arguments.
```

## After printing

Stop. Do not add a closing remark, summary, or follow-up question. The user reads the manual and decides what to do next.
