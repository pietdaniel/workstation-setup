---
name: get-review
description: "Request a PR review from teammates. Finds the PR for the current branch, identifies the owning team and GChat space via Cortex and gws, composes a review request message, and posts it after user confirmation. Use when asked to get a review, request a review, or post a PR for review."
---

# Get Review

## Overview

Automate requesting PR reviews by finding the right team, GChat channel, and team members, then posting a review request message. Always confirms with the user before sending anything.

## Prerequisites

- Requires `gh` CLI authenticated (`gh auth status`)
- Requires `gws` CLI authenticated (`gws auth status`)
- Must be run from within a git repository on a feature branch

## Step 1 -- Identify the PR

If the user provides a PR URL or number, use that. Otherwise, find the PR for the current branch:

```bash
# Get the current branch
git branch --show-current

# Find the PR
gh pr list --head <branch> --json number,title,url,state,headRefName,additions,deletions,changedFiles --limit 5
```

If no PR is found, tell the user and stop.

Extract the `owner` and `repo` from the remote URL or PR URL.

## Step 2 -- Get PR details

Fetch PR metadata to build a good review request message:

```bash
gh pr view <number> --repo <owner>/<repo> --json title,body,url,additions,deletions,changedFiles,headRefName,baseRefName,state
```

Build a short summary of the PR from this data. Keep it to 2-3 sentences max.

## Step 3 -- Identify the owning team

Look for team ownership in the repo's Cortex catalog:

```bash
# Check for .cortex/ directory in the repo root
ls .cortex/catalog/ 2>/dev/null

# Read the main service catalog file
cat .cortex/catalog/<service>.yaml
```

Extract the team name from `x-cortex-owners` (look for `name` field under `type: group`).

If no Cortex catalog is found, fall back to:
1. Check the repo's CODEOWNERS file
2. Ask the user which team owns this repo

## Step 4 -- Find the team's GChat space

Search for the team's GChat space using `gws`:

```bash
gws chat spaces list --page-all
```

Search the output for spaces matching the team name. Common naming patterns:
- `Engineering - {Team Name} (Public)`
- `Group - {Team Name}`
- `PRs - {Team Name}`
- `Team - {Team Name}`

Prefer spaces with these characteristics (in order):
1. A "PRs" space for the team (e.g., `PRs - Data Platform`) -- best for review requests
2. A public engineering space (e.g., `Engineering - Data Platform (Public)`)
3. A team group space (e.g., `Group - {Team Name}`)

Extract the space ID (format: `spaces/XXXX`).

If no matching space is found, ask the user which GChat space to post in.

## Step 5 -- Compose the review request message

Build a concise message with:
- A greeting and clear ask (review request)
- The PR URL (as a clickable link)
- A 1-2 sentence summary of what changed
- CI status if available (green/red)

Example format:
```
PR up for review: {PR title}

{PR URL}

{1-2 sentence summary of changes}. CI is {green/red} {checkmark/cross emoji}
```

Keep it short. Engineers skim chat messages -- the PR link and a brief summary are all they need.

## Step 6 -- Confirm with the user

Present the plan to the user before sending anything:

```
I'm ready to post a review request:

**Channel:** {space display name}
**Message:**
> {the message}

Should I go ahead and post this?
```

Use the question tool to get explicit confirmation. Do NOT send anything without the user's go-ahead.

## Step 7 -- Post the message

After user confirmation, send the message:

```bash
gws chat +send --space "{space_id}" --text "{message}"
```

Verify the send succeeded by checking for a valid response with a `name` field.

## Step 8 -- Report back

Tell the user:
- Where the message was posted (space name with a link if possible)
- Confirm it was sent successfully

## Important Rules

- NEVER send a message without explicit user confirmation
- Keep review request messages concise -- no walls of text
- If the team has both a "PRs" channel and a general channel, prefer the "PRs" channel
- If you cannot determine the team or channel, ask the user rather than guessing
- Do NOT DM individual team members unless the user specifically asks for it
- When the user provides a PR URL directly, skip Step 1 (branch detection) and parse the URL instead
- The `gws chat spaces list` output can be large; use grep/jq to filter rather than reading all pages manually
