---
name: graphite-stacked-prs
description: Create small, focused, stacked pull requests using the Graphite CLI. Use when the developer asks to create a PR, submit code for review, or split work into reviewable chunks. Enforces the principle that each PR handles exactly ONE concern and stays under 200 lines changed. Triggers on create PR, stacked PR, graphite, gt commands, split PR, submit for review, code submission, branch management.
group: workflow
---

# Graphite Stacked PRs

Create small, single-concern PRs stacked with Graphite CLI (`gt`).

## Preflight Check

Verify Graphite CLI is installed:

```bash
gt --version
```

If the command fails, stop and instruct the developer to install Graphite:

```bash
brew install withgraphite/tap/graphite   # macOS
# or: npm install -g @withgraphite/graphite-cli@stable
```

Then authenticate: visit https://app.graphite.com/activate, copy the token, run `gt auth --token <token>`.

Requires Git >= 2.38.0.

## When to Stack

Stack when **all** of these are true:

- **Sequential dependency:** PR2 meaningfully builds on PR1
- **Each PR stays small:** Reviewable on its own (one idea, one change)
- **You want parallelism:** Review starts while you build later slices
- **Base branch stays stable:** Not forced to merge a huge PR just to unblock

Stack **especially** for:

- **Large features split into slices** (UI → API → integration → cleanup)
- **Migrations** (schema → dual-write/backfill → switch reads → remove old)
- **Refactors + new behavior** (pure refactor first, behavior changes after)
- **Multi-owner adoption** (introduce contract → migrate consumers one by one → remove legacy)

## When NOT to Stack

- Work is **truly independent** — use separate PRs targeting main
- Each PR can't be understood **without reading the rest of the stack**
- High-churn area requiring **constant big rebases** (long-lived stack)
- **High-risk change** that must ship as one verified unit (rare; still try to slice with flags/tests)

## Core Principle

**One PR = One Concern.** Every PR in a stack must be:

- **Atomic:** One logical change; easy to revert
- **Low cognitive load:** Reviewer understands without reading 3 other PRs
- **Safe:** Can merge without breaking production (use feature flags, backwards compatibility)
- **Progressive:** Later PRs add value and remove temporary scaffolding

## Workflow

### 1. Plan the Stack

Before writing code, decompose the task into ordered single-concern PRs. List them bottom-to-top (base first).

**Size target:** < 200 lines changed per PR.

### 2. Sync Trunk

```bash
gt sync
```

### 3. Create Each PR as a Stacked Branch

For each concern, starting from the bottom of the stack:

```bash
gt create -am "concise description of the single concern"
```

Repeat for each layer. Each `gt create` automatically stacks on the current branch.

### 4. Modify Mid-Stack (if needed)

```bash
gt down              # navigate to the branch to fix
# make changes
gt modify -a         # amend, auto-restacks descendants
gt top               # return to top of stack
```

### 5. Submit the Stack

```bash
gt submit --stack    # push all branches, create/update PRs
```

### 6. After Review Feedback

```bash
gt checkout <branch>   # go to the branch with feedback
# make changes
gt modify -a           # amend and restack
gt submit --stack      # re-push updated stack
```

### 7. Keep in Sync

```bash
gt sync              # pull trunk, delete merged branches, restack
```

## PR Sizing Guide

| Lines Changed | Verdict                                                |
| ------------- | ------------------------------------------------------ |
| < 50          | Good - could potentially fold into an adjacent concern |
| 50-200        | Ideal                                                  |
| 200-400       | Consider splitting further                             |
| > 400         | Must split - find a concern boundary                   |

## Companion Files

- `references/cli_reference.md` -- Full Graphite CLI command cheatsheet with flags, shortcuts, and key command details
- `references/splitting_strategies.md` -- Splitting heuristics, concern categories, good/bad stack examples, and anti-patterns

## Quick Command Reference

| Action                | Command             |
| --------------------- | ------------------- |
| Create stacked branch | `gt c -am "msg"`    |
| Amend current branch  | `gt m -a`           |
| Submit full stack     | `gt submit --stack` |
| Navigate up/down      | `gt u` / `gt d`     |
| View stack            | `gt ls`             |
| Sync with trunk       | `gt sync`           |
| Undo last action      | `gt undo`           |
| Split a branch        | `gt split`          |
| Fold into parent      | `gt fold`           |
