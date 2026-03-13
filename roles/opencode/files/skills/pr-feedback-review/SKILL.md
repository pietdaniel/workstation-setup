---
name: pr-feedback-review
description: "Pull down all feedback from a GitHub PR and conduct a thorough analysis. For each piece of feedback, provide a summary and your assessment. Takes a PR URL or 'owner/repo#number' as input (e.g. 'https://github.com/ROKT/kube-configs/pull/2209' or 'ROKT/kube-configs#2209'). Use when asked to review, analyze, or respond to PR feedback."
---

# PR Feedback Review

## Overview

Analyze all feedback on a GitHub Pull Request: reviews, inline review comments, and general issue comments. For each piece of feedback, provide a concise summary and a technically grounded assessment.

## Input

The user provides a PR reference in one of these formats:
- Full URL: `https://github.com/{owner}/{repo}/pull/{number}`
- Short form: `{owner}/{repo}#{number}`
- Just a number (if in the repo): `#{number}` or `{number}`

## Step 1 — Parse the PR reference

Extract `owner`, `repo`, and `pr_number` from the input.

- Full URL: regex match `github\.com/([^/]+)/([^/]+)/pull/(\d+)`
- Short form: split on `#` and `/`
- Number only: use the current repo from `gh repo view --json nameWithOwner`

## Step 2 — Fetch all PR data (parallel)

Run ALL of the following `gh` commands in parallel:

```bash
# PR metadata (title, body, author, state, files changed)
gh pr view {number} --repo {owner}/{repo} --json title,body,state,author,files,additions,deletions,baseRefName,headRefName

# Reviews (approvals, change requests, comments with body text)
gh api repos/{owner}/{repo}/pulls/{number}/reviews --paginate

# Inline review comments (code-level feedback with diff context)
gh api repos/{owner}/{repo}/pulls/{number}/comments --paginate

# General PR comments (conversation-level)
gh api repos/{owner}/{repo}/issues/{number}/comments --paginate
```

## Step 3 — Filter to substantive feedback

Discard noise:
- Bot comments that are purely informational (e.g. CI status, "Codex has been enabled" boilerplate)
- Empty review bodies with no inline comments
- Duplicate comments (same user, same content)

Keep:
- Any review comment with a non-empty `body` that contains actionable feedback
- Inline review comments (these are always substantive)
- General comments that ask questions, raise concerns, or request changes
- Bot comments that contain specific code suggestions or bug reports (e.g. Codex P1/P2 findings)

## Step 4 — For each piece of feedback, analyze

For each substantive feedback item:

### 4a. Read the relevant code

If the comment references a specific file/line (inline review comment):
- Read the file at the referenced lines (with surrounding context, ~30 lines)
- Understand the diff hunk the comment is attached to

If the comment references a function/concept:
- Use grep/glob to find the relevant code
- Read enough context to understand the concern

### 4b. Validate the feedback

Determine if the feedback is:
- **Valid** — The concern is technically correct and should be addressed
- **Partially valid** — The concern has merit but is overstated or has caveats
- **Invalid** — The concern is incorrect based on the actual code behavior
- **Stylistic** — Not a bug, but a reasonable style/preference suggestion
- **Out of scope** — Valid concern but not related to this PR's changes

### 4c. Produce the analysis

For each feedback item, output:

```
## Feedback #{n} — {reviewer_name} ({priority_if_any})

**Location:** {file}:{line} (or "General comment")
**Summary:** {1-2 sentence summary of what the reviewer is saying}
**Assessment:** {Valid | Partially valid | Invalid | Stylistic | Out of scope}
**Analysis:** {Your technical reasoning — reference specific lines, variable values, control flow}
**Recommended action:** {What to do — fix, acknowledge, push back, or ignore}
```

## Step 5 — Produce final report

Output all analyzed feedback items in order of severity:
1. Valid bugs / issues first
2. Partially valid concerns
3. Stylistic suggestions
4. Invalid / out of scope items

End with a summary:
```
## Summary
- **Total feedback items:** {n}
- **Valid (should fix):** {n}
- **Partially valid (consider):** {n}
- **Invalid / out of scope:** {n}
- **Recommended next steps:** {list of concrete actions}
```

## Important Rules

- ALWAYS read the actual code before assessing feedback — never guess
- When feedback references bash/shell, pay special attention to variable scoping (local vs global, subshells, special variables like `SECONDS`, `PIPESTATUS`)
- When feedback references YAML, validate structure and indentation
- If a reviewer suggests a fix, evaluate whether the suggested fix is itself correct
- Be direct — if the reviewer is wrong, say so with evidence
- Be fair — if the reviewer found a real bug, acknowledge it clearly
- Do NOT dismiss bot feedback automatically — bots can find real bugs
