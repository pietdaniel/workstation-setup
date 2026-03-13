---
name: pr-review
description: "Review a GitHub PR for bugs, security issues, performance problems, and code quality. Checks out the branch, analyzes all changes using parallel specialized agents, and posts line-specific review comments. Takes a PR URL or 'owner/repo#number' as input (e.g. 'https://github.com/ROKT/garden/pull/8' or 'ROKT/garden#8'). Use when asked to review a PR, do a code review, or analyze PR changes."
---

# PR Review

## Overview

Perform a comprehensive code review of a GitHub Pull Request. Check out the branch locally, analyze all changes for security, correctness, performance, and reliability issues, then post line-specific review comments directly on the PR.

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

## Step 2 — Fetch PR metadata and diff (parallel)

Run ALL of the following in parallel:

```bash
# PR metadata
gh pr view {number} --repo {owner}/{repo} --json title,body,headRefName,baseRefName,state,author,url,additions,deletions,changedFiles

# Full diff
gh pr diff {number} --repo {owner}/{repo}
```

If the diff output is truncated (large PRs), note this and plan to read individual files after checkout.

## Step 3 — Checkout the PR branch

```bash
gh pr checkout {number} --repo {owner}/{repo}
```

This gives us local access to the full source for analysis.

## Step 4 — Plan the review using TodoWrite

Create a todo list to track progress. Typical items:
1. Categorize changed files by domain (backend, frontend, infra, tests, etc.)
2. Analyze each domain in parallel using Task agents
3. Consolidate findings
4. Post review comments

## Step 5 — Categorize changed files

From the PR metadata and diff, group the changed files into logical domains. Common groupings:

- **Backend code** — Go, Python, Java, Rust, etc. (handlers, services, storage, domain logic)
- **Frontend code** — React, Vue, Angular, etc. (components, pages, API clients)
- **Infrastructure** — Dockerfile, CI pipelines, Terraform, Kubernetes manifests
- **Configuration** — Config files, environment setup, build tools (Makefile, package.json)
- **Tests** — Unit tests, integration tests, test fixtures
- **Documentation** — READMEs, docs, comments

## Step 6 — Launch parallel analysis agents

Launch **one Task agent per domain** using `subagent_type: "general"`. Each agent should:

1. Read ALL changed files in its domain thoroughly
2. Analyze for issues across these categories:

### Security
- XSS (unescaped HTML output, unsanitized markdown, `javascript:` URLs in href)
- Injection (SQL injection, command injection, header injection, SSRF)
- Unbounded reads (`io.ReadAll`, `ReadAll` without `LimitReader`, no `MaxBytesReader`)
- Authentication/authorization gaps (unauthenticated endpoints, missing auth middleware)
- Path traversal (unvalidated file paths from user input)
- Secrets exposure (hardcoded keys, credentials in logs)

### Correctness
- Race conditions (shared mutable state between goroutines, unsynchronized field writes)
- Error handling gaps (swallowed errors, all errors mapped to wrong HTTP status, `_ = json.Unmarshal`)
- Nil pointer risks (interface nil wrapping, missing nil checks before method calls)
- Logic bugs (off-by-one, wrong operator, incorrect type assertions)
- Missing input validation (unvalidated enum casts from user input, negative pagination offsets)

### Performance
- Unbounded queries (no pagination limits, no max cap on user-supplied `size`/`limit`)
- N+1 query patterns
- Resource leaks (HTTP clients created per request instead of reused, `defer` in loops)
- Memory waste (unnecessary `[]byte` to `string` copies, triple-copy patterns)
- Missing connection pooling

### Reliability
- Missing panic recovery in fire-and-forget goroutines
- No error boundaries in React components
- Silent error swallowing (`.catch(() => {})`, `_ = err`)
- Missing loading/error states in UI

### Code Quality (lower priority, include only notable items)
- Inconsistent logging (mixing `log.Printf` and `slog`)
- Missing test coverage for new code paths
- Dead code or unused imports

### Agent prompt template

Each Task agent prompt MUST:
- List the exact file paths to read
- Specify what to look for (the categories above relevant to that domain)
- Request findings in this format:
  ```
  - File: {path}
  - Line: {number} (or function name)
  - Severity: Critical | High | Medium | Low
  - Category: Security | Correctness | Performance | Reliability | Code Quality
  - Description: {what the issue is}
  - Suggestion: {how to fix it, with code snippet if applicable}
  ```
- Ask the agent to return ALL findings sorted by severity

## Step 7 — Consolidate findings

After all Task agents return:

1. Collect all findings into a single list
2. Deduplicate (same file + same line + same issue = one finding)
3. Sort by severity: Critical > High > Medium > Low
4. For large PRs, cap at ~15-20 most important findings for PR comments (avoid comment spam)
5. Verify each finding's line number is correct using `grep -n` on the actual file

## Step 8 — Verify line numbers are in the diff

For each finding you plan to comment on, verify the line is part of the PR diff. GitHub only allows review comments on lines that appear in diff hunks. Use `grep -n` to confirm exact line numbers.

Lines that are NOT in the diff cannot receive inline comments — mention these in the review body instead.

## Step 9 — Post the review

### 9a. Get the HEAD commit SHA

```bash
gh pr view {number} --repo {owner}/{repo} --json headRefOid --jq '.headRefOid'
```

### 9b. Post the review summary

```bash
gh api repos/{owner}/{repo}/pulls/{number}/reviews \
  --method POST \
  -f event="COMMENT" \
  -f body="{review_summary}"
```

The review summary should include:
- A brief overall assessment of the PR
- A severity breakdown table (Critical/High/Medium/Low counts)
- Mention of the most important issues to fix before merge
- Any findings that couldn't be posted as inline comments (lines not in diff)

### 9c. Post line-specific comments

For each finding where the line IS in the diff:

```bash
gh api repos/{owner}/{repo}/pulls/{number}/comments \
  --method POST \
  -f commit_id="{commit_sha}" \
  -f path="{file_path}" \
  -F line={line_number} \
  -f side="RIGHT" \
  -f body="{comment_body}"
```

Each comment body should follow this format:
```
**[{Severity}] {Short title}**

{Description of the issue — 2-4 sentences explaining the problem and its impact.}

**Suggestion:** {How to fix, with a code block if applicable}
```

### 9d. Handle comment failures gracefully

If a line comment fails with HTTP 422 (`could not be resolved`), the line is not in the diff. Move that finding into the review body comment instead. Do NOT retry or skip — the user should still see the feedback.

## Step 10 — Report back to the user

After posting, summarize what was done:
- Link to the PR
- Count of comments posted (Critical/High/Medium/Low breakdown)
- Any findings that couldn't be posted inline (with the details)

## Important Rules

### Do
- ALWAYS check out the branch and read the actual source — never review from diff alone
- ALWAYS use parallel Task agents for analysis — one per domain — to maximize throughput
- ALWAYS verify line numbers before posting comments
- ALWAYS use `grep -n` to confirm exact line numbers match the code
- ALWAYS post findings as line-specific comments, not just a wall of text
- Keep comment bodies concise — 2-4 sentences for the issue, plus a code suggestion
- Focus on bugs and security issues over style nits
- Be direct — state what the problem is and how to fix it
- Check for issues ACROSS files, not just within — e.g., a handler missing auth that other handlers have

### Do Not
- Do NOT post more than ~15-20 inline comments — focus on the most important findings
- Do NOT comment on pure style/formatting unless it's egregious
- Do NOT flag issues in unchanged lines unless they are security-critical
- Do NOT guess at line numbers — always verify
- Do NOT use `gh pr review --comment` for line-specific comments (it only supports a single body)
- Do NOT create any commits or modify any files — this is a read-only review
- Do NOT post duplicate comments if the skill is run multiple times (check existing comments first)

### Language-specific patterns to watch for

**Go:**
- `io.ReadAll` without `io.LimitReader` or `http.MaxBytesReader`
- `go func()` without `recover()`
- Shared `*struct` pointer between goroutine and caller (race condition)
- `interface{}` nil wrapping (non-nil interface containing nil pointer)
- `defer` inside loops
- `log.Printf` mixed with `slog` (inconsistent structured logging)

**TypeScript/React:**
- `dangerouslySetInnerHTML` or unsanitized markdown rendering
- `javascript:` protocol in `<a href>` from untrusted data
- Missing error boundaries
- `.catch(() => {})` silencing errors
- `as` type assertions without runtime validation
- `useEffect` dependency array issues (missing deps, derived values in deps)
- Array index as React `key` prop

**Python:**
- `os.system()` or `subprocess.call(shell=True)` with user input
- SQL string formatting instead of parameterized queries
- `pickle.loads()` on untrusted data
- Bare `except:` clauses

**Dockerfile:**
- Running as root without `USER` directive
- `COPY . .` before dependency install (cache busting)
- Missing `.dockerignore`
- `git describe` in build (fails on shallow clones)
- Wrong COPY paths from multi-stage builds

**CI/YAML:**
- Secrets in plain text
- Missing timeout on steps
- Duplicate work across steps (building the same thing twice)
