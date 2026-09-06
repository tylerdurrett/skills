---
name: grill-with-docs
description: Grilling session that challenges your plan against the existing domain model, sharpens terminology, and updates documentation (CONTEXT.md, ADRs) inline as decisions crystallise. Use when user wants to stress-test a plan against their project's language and documented decisions.
---

<what-to-do>

Use `/grilling` as the one-question-at-a-time interview primitive and `/domain-modeling` as the active documentation discipline. Interview me about every aspect of this technical plan until we reach shared understanding, resolving dependent decisions in order and recommending an answer to each question.

If a fact can be answered by exploring the codebase, explore instead of asking. Keep implementation and final publication on hold until the user confirms shared understanding; capture individually confirmed domain terms and qualifying decisions inline through `/domain-modeling`.

</what-to-do>

<supporting-info>

## Grilling an existing lifecycle spec

When invoked with an issue number (`/grill-with-docs <N>`), fetch its full body, comments, and labels. Grill the unresolved decisions and enrich that same issue as each answer resolves. Preserve leading metadata anchors and unrelated body content; never publish a duplicate spec.

Clear `needs-grilling` only after shared understanding is confirmed. Then recommend `/triage <N>` so the aligned issue can be rerouted.

## Closing the session

For freeform sessions only, when the plan is sharp, the terms are settled, and the user confirms shared understanding, drop one soft line:

> _Next step: `/to-spec`, capture this alignment as a spec on the tracker._

Don't drop it mid-grill or after a single resolved term. If the session is not resolved, don't say it.

</supporting-info>
