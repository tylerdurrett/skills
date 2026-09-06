# Issue tracker: GitHub

Specs (initiatives, features, slices, tasks) for this repo all live as GitHub issues on `<owner>/<repo>`. Use the `gh` CLI for all operations. `gh` resolves the repo automatically from `git remote -v` (the `origin` remote points at `<owner>/<repo>`).

For the canonical hierarchy and label vocabulary, see [triage-labels.md](triage-labels.md). At a glance: initiative → feature → slice → task → PR. Every lifecycle issue is a "spec" of some size; size determines which decomposition step applies next.

## Conventions

- **Create an issue**: `gh issue create --title "..." --body "..."`. Use a heredoc for multi-line bodies.
- **Read an issue**: `gh issue view <number> --comments`, filtering comments by `jq` and also fetching labels.
- **List issues**: `gh issue list --state open --json number,title,body,labels,comments --jq '[.[] | {number, title, body, labels: [.labels[].name], comments: [.comments[].body]}]'` with appropriate `--label` and `--state` filters.
- **Comment on an issue**: `gh issue comment <number> --body "..."`
- **Apply / remove labels**: `gh issue edit <number> --add-label "..."` / `--remove-label "..."`
- **Close**: `gh issue close <number> --comment "..."`

## When a skill says "publish to the issue tracker"

Create a GitHub issue.

## When a skill says "fetch the relevant ticket"

Run `gh issue view <number> --comments`.

## Sub-issues

GitHub supports native sub-issue links between a parent issue and its children. When a skill creates an issue that has a parent (any larger-sized spec on the tracker), it attaches the child as a native sub-issue of the parent so:

- The parent's **Sub-issues** panel renders the child.
- The parent's auto-rollup count reflects open/closed state across children.
- The child surfaces in searches qualified by parent (see below).

Each child has at most one parent. GitHub enforces this server-side. Re-attaching an already-attached child returns 422 with a body like `"Issue may not contain duplicate sub-issues and Sub issue may only have one parent"`.

### Attach a child as a native sub-issue

The REST endpoint expects the child's database `id` (numeric), not its human-facing `number`. Resolve the `id` first, then POST. The full procedure (call shape, loud-failure semantics, and the one-parent constraint) lives as a [sub-issue attach helper](../../.agents/skills/decompose/SKILL.md#sub-issue-attach-helper) in the `/decompose` skill. Other skills that link a child to a parent should reuse that helper rather than re-deriving the API contract.

### Search by parent

GitHub indexes the parent relationship as a search qualifier:

```bash
gh issue list --search "parent-issue:<owner>/<repo>#59"
```

This returns every child issue attached as a sub-issue of #59. Combine with `--state` filters as usual.

### When there is no parent

A skill that creates a top-level spec from a freeform conversation that doesn't reference an existing parent has no existing parent issue to attach to. In that case the skill skips the attach call entirely; there is nothing to link to. This is the documented no-parent path for orphan specs at any size.

## Wayfinding operations

Used only by `/wayfinder`. A map is one `wayfinder:map` issue; its tickets are native sub-issues carrying exactly one of `wayfinder:research`, `wayfinder:prototype`, `wayfinder:grilling`, or `wayfinder:task`. Do not add `size:*`, state-axis, or `in-progress` labels to these artifacts.

### Create and order

1. Create the map and tickets with `gh issue create`.
2. Attach each ticket with the [sub-issue helper](#attach-a-child-as-a-native-sub-issue).
3. Wire dependencies only after every issue has an id:

   ```bash
   blocker_id=$(gh api repos/<owner>/<repo>/issues/<blocker-number> --jq .id)
   gh api -X POST repos/<owner>/<repo>/issues/<blocked-number>/dependencies/blocked_by \
     -F issue_id="$blocker_id"
   ```

4. Native sub-issue order is the decision order. Read it with:

   ```bash
   gh api --paginate repos/<owner>/<repo>/issues/<map-number>/sub_issues
   ```

   Reorder when needed with `PATCH .../sub_issues/priority`, passing the ticket's database `sub_issue_id` and either `before_id` or `after_id`.

### Find and claim the frontier

The frontier is the map's open children with no open blockers or active claim token. Assignment is the coarse UI signal; claim-token comments are the concurrency authority. Walk native sub-issues in their returned order. For each candidate, inspect assignees/comments and:

```bash
gh api --paginate \
  repos/<owner>/<repo>/issues/<ticket-number>/dependencies/blocked_by \
  --jq '[.[] | select(.state == "open")] | length'
```

The first qualifying child is next. Any qualifying children may run concurrently, but every session must claim before work:

```bash
claim_token=$(uuidgen) # any fresh opaque high-entropy token
gh issue edit <ticket-number> --add-assignee "@me"
gh issue comment <ticket-number> --body "<!-- wayfinder-claim:$claim_token -->"
```

Immediately re-read all claim/release marker comments in creation order. A token is active when no later `<!-- wayfinder-release:<token> -->` exists; the earliest active claim wins. If yours loses, post `<!-- wayfinder-release:<your-token> -->`, leave the shared assignee untouched, and exit or choose another ticket. Only the winning token may start work.

### Recover stale claims

Do not steal an active token. Treat one as stale only after checking ticket comments/timeline, linked branch or artifact activity, and live agent coordination. If the map's Notes defines a timeout, honor it; otherwise ask the maintainer or prior claimant to confirm abandonment. Post a recovery explanation plus `<!-- wayfinder-release:<stale-token> -->`, then run the normal claim protocol. Remove an assignee only when no active claim token still depends on that login.

### Resolve

The `/wayfinder` coordinator is the sole owner of tracker writes. Workers return results; the coordinator:

1. Posts the full answer as a resolution comment.
2. Posts `<!-- wayfinder-release:<winning-token> -->` and closes the ticket.
3. Appends one linked gist to the map's `## Decisions so far`.
4. Creates and wires newly visible tickets, and clears graduated fog.

A prototype ticket stays open until the human records a verdict. Research workers never edit issues or the map. When the map is complete, `/to-spec` creates the sized spec and links it to the map in both directions; the spec is never attached as a native child because GitHub permits only one native parent and that relationship is reserved for the spec hierarchy.
