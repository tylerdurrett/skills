# tdog skills

A library of [agent skills](https://github.com/vercel-labs/skills) for the way I (Tyler / [@tylerdurrett](https://github.com/tylerdurrett)) build software with AI coding agents. Straight from my dev environment.

## Install

```bash
npx skills@latest add tylerdurrett/skills
```

This uses the [`skills`](https://github.com/vercel-labs/skills) CLI by Vercel Labs. After running it, pick the skills you want and the agents you want them installed for (Claude Code, Cursor, Codex, etc.).

## First-time setup

Several of the engineering skills below (`triage`, `execute`, `ship`, `audit`, `decompose`, `status`, `recap`, `to-spec`, `defer`, `check`) assume a configured tracker, label vocabulary, integration-branch convention, and a `docs/agents/` directory in your repo. Run `setup-tdog-skills` once after install to scaffold all of that:

```
/setup-tdog-skills
```

It walks you through three decisions (issue tracker, triage label vocabulary, single- vs multi-context domain docs), writes the canonical docs under `docs/agents/`, drops in ADR-0008, and adds an `## Agent skills` block to your `CLAUDE.md` / `AGENTS.md`. The non-tracker skills (`tdd`, `diagnose`, `grill-me`, `code-simplifier`, `skill-creator`, etc.) work standalone and don't need it.

## The skills

### Per-repo setup

| Skill | What it does |
| --- | --- |
| [setup-tdog-skills](skills/setup-tdog-skills/) | Scaffold the `docs/agents/` directory, ADR-0008, and the `## Agent skills` memory block the workflow skills assume. Run once per repo. |

### Spec lifecycle (issue-tracker workflow)

A four-tier flow — initiative → feature → slice → task — that publishes specs to GitHub Issues, triages them, decomposes them, executes them on per-spec integration branches, and ships them back up the chain.

| Skill | What it does |
| --- | --- |
| [to-spec](skills/to-spec/) | Capture the current conversation as a sized spec (initiative / feature / slice / task) on the tracker. |
| [triage](skills/triage/) | Verify size, lay down per-tier bookkeeping, apply the next state label. Also surfaces what's most actionable across the queue. |
| [decompose](skills/decompose/) | Break a tier-bearing spec into native sub-issues one tier smaller. |
| [check](skills/check/) | Fast read-only sanity check on a decomposition before execution burns a session on a flawed plan. |
| [audit](skills/audit/) | Heavier multi-agent (Claude + Codex) version of `/check`, with writes back to the tracker on approval. |
| [execute](skills/execute/) | Implement a `size:task` end-to-end on a branch off the parent's integration branch and open the PR. |
| [ship](skills/ship/) | Tier-aware close-out: squash-merge tasks, promote slices/features upward, refuse initiatives (those close manually). |
| [defer](skills/defer/) | Capture out-of-scope cleanup findings as `cleanup`-labeled issues so they don't pollute the current PR. |
| [status](skills/status/) | Read-only walk of the tracker that recommends one next step. |
| [recap](skills/recap/) | Paste-ready stakeholder recap of recent activity (today / week / upcoming). |

### Project docs

| Skill | What it does |
| --- | --- |
| [north-star](skills/north-star/) | Maintain `docs/north-star.md` — the project's vision doc. |
| [roadmap-review](skills/roadmap-review/) | Maintain `docs/roadmap.md` — capacity-honest sequencing between the north star and epics. |
| [grill-with-docs](skills/grill-with-docs/) | Stress-test a plan against `CONTEXT.md` and `docs/adr/`, updating docs inline as decisions crystallise. |
| [improve-codebase-architecture](skills/improve-codebase-architecture/) | Find deepening opportunities informed by `CONTEXT.md` and ADRs. |
| [how-to-use](skills/how-to-use/) | Static user manual: how the workflow flows, what skills exist, where to start. |

### Coding workflow

| Skill | What it does |
| --- | --- |
| [tdd](skills/tdd/) | Red-green-refactor with integration-style tests. |
| [diagnose](skills/diagnose/) | Disciplined diagnosis loop for hard bugs and perf regressions. |
| [code-simplifier](skills/code-simplifier/) | Tighten recently-modified code without changing behaviour. |
| [grill-me](skills/grill-me/) | Stress-test a plan or design via relentless interview. |
| [zoom-out](skills/zoom-out/) | Reorient when you're lost in a section of code. |

### Skill authoring

| Skill | What it does |
| --- | --- |
| [skill-creator](skills/skill-creator/) | Guide for writing effective skills. |
| [write-a-skill](skills/write-a-skill/) | Scaffold a new skill with progressive disclosure and bundled resources. |

### Integrations & tools

| Skill | What it does |
| --- | --- |
| [ai-sdk](skills/ai-sdk/) | Build features with the Vercel AI SDK (`generateText`, `streamText`, agents, RAG). |
| [trigger-dev](skills/trigger-dev/) | Write and configure Trigger.dev v4 background tasks. |
| [chrome-devtools](skills/chrome-devtools/) | Browser automation, perf analysis, and debugging via Puppeteer. |
| [slack-notify](skills/slack-notify/) | Send messages to a configured Slack channel. |
| [app-screenshot](skills/app-screenshot/) | Authenticated screenshots of a local dev app for visual debugging. *(Iterator TV–specific; will be generalised.)* |
| [get-started](skills/get-started/) | macOS-friendly environment-setup walkthrough. *(Iterator TV–specific; will be generalised.)* |

## Credit

The install UX (`npx skills@latest add owner/repo`) is the [vercel-labs/skills](https://github.com/vercel-labs/skills) CLI. The "skills repo as a package" pattern is borrowed from [mattpocock/skills](https://github.com/mattpocock/skills), and several of the spec-lifecycle skills share lineage with his.

## Licence

MIT.
