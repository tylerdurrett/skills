# ADR-0008 — Issues branch off their parent's integration branch

- **Date:** 2026-05-06
- **Status:** Accepted

## Context

`main` activity is intentionally kept low. Features, the most common
form of parent issue, already use a long-running integration branch
(`feature/issue-<N>-*`) that task PRs target, with the feature branch
itself merged to main only when the feature is done.

ADR-0007 introduces a third level (tasks under multi-task slices)
and consolidates the execution skills. To keep skill behavior uniform
across the hierarchy, the rule for which branch a given issue's work
lands on needs to be explicit. Without one, every skill rediscovers
the per-level branching question (and the auto-executor in #110 has to
encode it as conditional logic).

## Decision

**An issue's working branch is its parent's integration branch.** If
the parent has no integration branch, recurse upward. `main` is only
the fallback for issues with no parent (orphan issues), or for
top-level parents promoting upward at the end of their lifecycle.

Concretely:

| Issue kind              | Branches off                      |
| ----------------------- | --------------------------------- |
| Orphan issue            | `main`                            |
| Feature                 | `main` (feature branch is itself) |
| Slice (under a feature) | the feature's integration branch  |
| Task (under a slice)    | the slice's integration branch    |

The rule recurses cleanly: initiatives carry no integration branch, so
a feature that descends from an initiative still branches off `main`.

`Closes #N` on a PR essentially never auto-closes its referenced issue
under this rule, because almost every PR targets a non-default branch.
Skills that merge PRs (`/ship`) therefore always close the leaf
issue explicitly.

When all of a parent's children close, the parent's integration branch
is ready to promote upward to its own parent's branch. This is the
recursive shape captured in tier-aware `/ship`.

## Alternatives rejected

- **Always branch off main; rely on `Closes #N` auto-close.** Pushes
  too much activity onto main, contradicts the existing feature branch
  model, and removes the human review gate at parent-level promotion.
- **Per-skill ad-hoc branch selection.** Each skill picks its own
  parent branch via heuristics. Works in isolation but means every
  skill (and the controller loop in #110) re-derives the branching
  rule. Bound to drift.

## Consequences

**Positive:**

- One rule covers every skill, every level, and the controller loop.
  No per-case logic.
- Activity stays scoped to the parent branch until the parent is ready
  to promote. Reviewers see slice/feature-level diffs as coherent units.
- The recursive promotion pattern is expressible as a single skill
  (tier-aware `/ship`) that works at any depth.

**Negative / costs:**

- `Closes #N` auto-close is unavailable in the common case. Every
  merge skill must close its leaf explicitly. (Already true for the
  feature case today; the rule generalizes that asymmetry.)
- Long-running integration branches drift from `main` and require
  manual sync (already a known pattern for feature branches; same
  applies one level lower for slice branches).
