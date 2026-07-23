---
name: pr-feedback-review
description: "Pull down all feedback from a GitHub PR, analyze each item, REPLY to every comment on the PR with your reasoning, APPLY the warranted code changes, and PUSH the result. Takes a PR URL or 'owner/repo#number' as input (e.g. 'https://github.com/ROKT/kube-configs/pull/2209' or 'ROKT/kube-configs#2209'). Use when asked to review, analyze, respond to, or address PR feedback."
---

# PR Feedback Review

## Overview

Given a GitHub Pull Request, run the full feedback loop end-to-end:

1. Fetch all feedback (reviews, inline review comments, general comments).
2. Analyze each item — read the actual code, decide valid / invalid / etc.
3. **Reply on the PR to every substantive comment** with your thought
   process (accept + what you changed, or push back + why).
4. **Apply the warranted code changes** locally and validate them.
5. **Commit and push** so the PR is updated.
6. Report a summary back to the user.

This is NOT a read-only analysis. The default expectation is that you leave
a reply on every comment, make the changes that should be made, and push the
result. Do not stop at a written report.

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

Run ALL of the following `gh` commands in parallel. Capture the numeric
`id` of every review comment and issue comment — you need those IDs to post
threaded replies in Step 5.

```bash
# PR metadata (title, body, author, state, files changed, head branch)
gh pr view {number} --repo {owner}/{repo} --json title,body,state,author,files,additions,deletions,baseRefName,headRefName

# Reviews (approvals, change requests, comments with body text)
gh api repos/{owner}/{repo}/pulls/{number}/reviews --paginate

# Inline review comments (code-level feedback with diff context) — note each .id
gh api repos/{owner}/{repo}/pulls/{number}/comments --paginate

# General PR comments (conversation-level) — note each .id
gh api repos/{owner}/{repo}/issues/{number}/comments --paginate
```

Also confirm the local checkout is on the PR's head branch (or check it out)
before making changes in Step 4:

```bash
git fetch origin {headRefName} && git checkout {headRefName}
```

## Step 3 — Filter to substantive feedback

Discard pure noise (do NOT reply to these):
- CI/status boilerplate, "bot enabled" notices, security-scan "0 findings"
- Auto-generated walkthroughs / file-summary tables with no actionable ask
- Empty review bodies with no inline comments
- Exact-duplicate comments (same user, same content)

Keep (these each get analysis AND a reply):
- Any review comment whose `body` contains actionable feedback
- Every inline review comment
- General comments that ask a question, raise a concern, or request a change
- Bot comments with a specific code suggestion or bug report (Copilot,
  Devin, CodeRabbit, Codex P1/P2, etc.) — do not dismiss bots; they find
  real bugs

## Step 4 — For each item: analyze, then act

Work item by item. For each substantive item:

### 4a. Read the relevant code
- Inline comment → read the referenced file at the given lines (~30 lines of
  context) and understand the diff hunk.
- Concept/function reference → grep/glob to find it and read enough context.

### 4b. Validate the feedback
Classify it:
- **Valid** — technically correct, should be fixed.
- **Partially valid** — has merit but overstated or caveated.
- **Invalid** — incorrect given actual code behavior.
- **Stylistic** — not a bug, reasonable preference.
- **Out of scope** — valid but unrelated to this PR.

If a reviewer proposed a fix, evaluate whether that fix is itself correct
before adopting it. Watch for **stale** bot comments that reference an older
commit than the current head — verify against current code.

### 4c. Apply the change (when warranted)
- **Valid / Partially valid (agreed portion):** make the code change now.
- **Stylistic:** apply if cheap and consistent with the repo pattern;
  otherwise skip and explain in the reply.
- **Invalid / Out of scope:** make NO change; you will push back in the reply.

Keep edits surgical — every changed line must trace to a specific comment.
Record, per item, exactly what you changed (files/lines) so the reply and
commit message can reference it.

## Step 5 — Validate, commit, and push the changes

If any code changed:

1. Run the repo's validation for the changed files (e.g. `terraform fmt` +
   `terraform validate`, `go build`/`go test`, linters). Fix failures before
   pushing.
2. Inspect `git status --porcelain` and stage ONLY the intended paths
   (never `git add -A`). Confirm no stray/session files ride along.
3. Commit with a message that summarizes the review-driven changes, e.g.
   `chore(<area>): address PR review feedback` with a short bulleted body.
4. `git push` to update the PR. Capture the new commit SHA.

If nothing changed (all items invalid/out-of-scope/acknowledge-only), skip
the commit but still post replies in Step 6.

## Step 6 — Reply to EVERY substantive comment

Post a reply to each item from Step 3 documenting your thought process.
This is mandatory — every kept comment gets a response, whether you accepted
it or not.

Each reply states: (1) your assessment, (2) the reasoning, and (3) the
outcome — what you changed (reference the commit SHA) or why you did not.
Keep it concise and professional. For a fixed item, cite the commit; for a
push-back, give the evidence.

**Threaded reply to an inline review comment** (preferred — keeps it on the
thread), using the comment `id` captured in Step 2:

```bash
gh api --method POST \
  repos/{owner}/{repo}/pulls/{number}/comments/{comment_id}/replies \
  -f body="Assessment: <valid|partially valid|invalid|...>. <reasoning>. <what changed + SHA, or why not>."
```

**Reply to a review-level or general/issue comment** (no inline thread) —
post a PR-level comment that names the reviewer and references the point:

```bash
gh pr comment {number} --repo {owner}/{repo} \
  --body "@<reviewer> re: <topic> — <assessment + reasoning + outcome/SHA>."
```

Guidance for replies:
- Accepted → "Good catch — fixed in `<sha>`: <one-line what/why>."
- Partially → "Valid re X; the stated impact isn't accurate because <reason>.
  Aligned anyway in `<sha>` for <benefit>."
- Push back → "Not changing this: <evidence from the code>."
- Stylistic skip → "Reasonable, but skipping to stay consistent with
  <sibling pattern>; can do repo-wide separately."
- Stale bot comment → note it targeted an earlier commit and state current
  state.

## Step 7 — Final report to the user

Summarize what you did:

```
## Summary
- **Total feedback items:** {n}
- **Fixed:** {n}  (commit {sha})
- **Acknowledged / no change:** {n}
- **Pushed back (invalid/out of scope):** {n}
- **Replies posted:** {n}
- **Validation:** {fmt/validate/test results}
```

List each item briefly with its outcome and a link/anchor if useful.

## Important Rules

- This skill ENDS with replies posted and (if warranted) changes pushed —
  not with a written analysis. Do not stop early.
- Reply to every substantive comment, including bots, so there is an audit
  trail of the decision.
- ALWAYS read the actual code before assessing — never guess.
- Verify bot comments against the CURRENT head commit; they are often stale.
- When feedback references bash/shell, watch variable scoping (local vs
  global, subshells, special vars like `SECONDS`, `PIPESTATUS`).
- When feedback references YAML/HCL, validate structure and indentation.
- If a reviewer suggests a fix, verify the fix is itself correct before
  adopting it.
- Be direct — if the reviewer is wrong, say so with evidence in the reply.
- Be fair — if the reviewer found a real bug, acknowledge it and fix it.
- Never `git add -A` / `git commit -a`; stage explicit paths and verify with
  `git status` / `git show --stat` that only intended files are included.
- Run the repo's validation before pushing; fix failures first.
