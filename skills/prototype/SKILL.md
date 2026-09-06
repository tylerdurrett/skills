---
name: prototype
description: Build and archive a throwaway prototype to answer a design question, then preserve the runnable winner as an immutable reference for a production spec. Use when the user wants to sanity-check whether a state model or logic feels right, or explore what a UI should look like.
---

# Prototype

A prototype is **throwaway code that answers a question**. The question decides the shape.

## Pick a branch

Identify which question is being answered — from the user's prompt, the surrounding code, or by asking if the user is around:

- **"Does this logic / state model feel right?"** → [LOGIC.md](LOGIC.md). Build a tiny interactive terminal app that pushes the state machine through cases that are hard to reason about on paper.
- **"What should this look like?"** → [UI.md](UI.md). Generate several radically different UI variations on a single route, switchable via a URL search param and a floating bottom bar.

The two branches produce very different artifacts — getting this wrong wastes the whole prototype. If the question is genuinely ambiguous and the user isn't reachable, default to whichever branch better matches the surrounding code (a backend module → logic; a page or component → UI) and state the assumption at the top of the prototype.

## Rules that apply to both

1. **Use a dedicated prototype branch.** Branch from the clean code baseline being explored; when an existing spec is in scope, resolve its baseline using [the repository's integration-branch workflow](../../../docs/agents/README.md#integration-branches). Name the branch `prototype/issue-<N>-<slug>` when an issue exists, otherwise `prototype/<slug>`. Never commit prototype code onto `main` or an integration branch.
2. **Make throwaway status obvious.** Locate the prototype close to the module or page it explores, but name it so nobody mistakes it for production. Obey the project's existing routing and layout conventions.
3. **Provide one compatible run command.** Use the host project's existing runtime and task tooling without adding a package manager or weakening its dependency policy.
4. **Keep state in memory by default.** If the question explicitly involves persistence, use a scratch database or a clearly disposable local file.
5. **Skip production polish.** Add no automated tests, broad error handling, or speculative abstractions. Manually exercise the question the prototype exists to answer.
6. **Surface the state.** After every action (logic) or variant switch (UI), print or render the full relevant state.

## Decide and archive

Do not implement production code during the prototype workflow.

1. Let the user drive the prototype and choose the answer. If the answer combines pieces of multiple UI variants, assemble those pieces into one runnable `Winner` variant before archiving so a later agent does not have to reconstruct the decision from prose.
2. Commit and push the complete runnable prototype on its dedicated branch. Do not open a PR or merge it. Record the immutable commit SHA and GitHub tree URL; the branch remains as a durable primary source even though its code is disposable.
3. Capture a compact handoff in the conversation:
   - question and verdict;
   - immutable prototype URL and commit SHA;
   - winning component, file, scenario, URL parameter, and run command as applicable;
   - **must preserve** behavior or design decisions;
   - **not authoritative** prototype details such as component boundaries, error handling, and implementation shortcuts.
4. Add screenshots or other evidence only when they preserve important information that is difficult to reproduce from the runnable source. They are never routine output.

When another workflow coordinates the prototype, return this handoff to the caller without mutating tracker or other state it owns or starting the production workflow. The artifact alone does not answer the question: report the explicit human verdict, or state that it remains pending.

## Return to the production workflow

Carry the handoff into `/grill-with-docs` when domain or system decisions remain unresolved; otherwise carry it directly into `/to-spec`. The resulting spec must retain the immutable prototype reference and the must-preserve/not-authoritative distinction instead of compressing the prototype into prose. Continue through `/triage`, then the appropriate execution driver such as `/easy-auto` or `/auto-feature`.

Production agents must inspect and, when useful, run the archived winner before planning. Treat it as behavioral and design evidence, not merge-ready code: reimplement the decision under normal production testing and review standards rather than cherry-picking the prototype. Record durable rationale according to [the repository's domain-documentation contract](../../../docs/agents/domain.md).
