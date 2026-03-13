---
name: fix-ci
description: "Identify and fix CI build failures for the current branch. Uses gh CLI to find the PR, extracts Buildkite build status, fetches failed job logs via the Buildkite API, diagnoses failures, and applies fixes to the local codebase. Use when CI is red and you need to understand and fix what's broken."
---

# Fix CI

## Overview

Automatically identify CI build failures for the current branch's PR, diagnose root causes from Buildkite job logs, and fix the issues in the local codebase.

## Prerequisites

- Requires `gh` CLI authenticated (`gh auth status`)
- Requires `BUILDKITE_TOKEN` environment variable set with a valid Buildkite API token
- Must be run from within a git repository on a feature branch with an open PR

## Step 1 -- Identify the branch and PR

Run these commands in parallel:

```bash
# Get the current branch
git branch --show-current

# Get the remote URL (to confirm the repo)
git remote get-url origin
```

Then find the PR for this branch:

```bash
gh pr list --head <branch> --json number,title,url,state,headRefName,statusCheckRollup --limit 5
```

If no PR is found, tell the user and stop. If multiple PRs exist, use the first open one.

## Step 2 -- Extract failed checks

From the `statusCheckRollup` array in the PR data, filter for entries where:
- `state` is `FAILURE` or `ERROR` (for `StatusContext` entries)
- `conclusion` is `FAILURE` (for `CheckRun` entries)

Each failed check has a `targetUrl` or `detailsUrl` pointing to a Buildkite build URL.

Parse the Buildkite URL to extract:
- `org_slug` (e.g. `rokt`)
- `pipeline_slug` (e.g. `consumer-context-cache`)
- `build_number` (e.g. `12770`)

URL format: `https://buildkite.com/{org}/{pipeline}/builds/{number}`

If there are NO failures, inform the user that CI is green and stop.

## Step 3 -- Fetch build details and failed jobs

For each unique failed build, fetch the build details:

```bash
curl -sS -H "Authorization: Bearer $BUILDKITE_TOKEN" \
  "https://api.buildkite.com/v2/organizations/{org}/pipelines/{pipeline}/builds/{number}"
```

From the response, extract failed jobs by filtering `jobs[]` where `state == "failed"`.

For each failed job, collect:
- `id` (job UUID)
- `name` (job label)
- `command` (what was run)
- `exit_status`
- `web_url`

If there are NO failed jobs (e.g. the overall build failed due to a dependency but individual jobs passed), check for `state == "timed_out"` or `state == "canceled"` jobs as well. Also check build annotations.

## Step 4 -- Fetch and analyze failure logs

For each failed job, fetch the log:

```bash
curl -sS -H "Authorization: Bearer $BUILDKITE_TOKEN" \
  "https://api.buildkite.com/v2/organizations/{org}/pipelines/{pipeline}/builds/{number}/jobs/{job_id}/log.txt"
```

Focus on the **tail end** of the log (last ~150 lines) as that's where failure messages appear. Also search for key error patterns:
- `FAIL` / `FAILED` / `Error` / `error:` / `panic:`
- `exit status` / `exit code`
- `make: ***` (Makefile failures)
- `--- FAIL:` (Go test failures)
- `go fmt` / `go vet` / `golint` (Go lint/format failures)
- `compilation failed` / `cannot find` / `undefined:`
- `timeout` / `timed out`

## Step 5 -- Diagnose the failure

Categorize the failure into one of these types and determine the fix:

### Formatting failures (`go fmt`, `gofmt`, prettier, eslint --fix)
- Run the formatter locally to identify which files need formatting
- Apply the formatting fix

### Lint failures (`go vet`, `golint`, `staticcheck`, eslint)
- Identify the specific lint errors from the log
- Read the offending files and fix the lint issues

### Compilation / build failures
- Identify missing imports, type errors, undefined references
- Read the relevant source files
- Fix the compilation errors

### Test failures
- Identify which tests failed and the failure messages
- Read the test files and the code under test
- Determine if the test expectation needs updating or if the code has a bug
- Fix accordingly

### Infrastructure / environment failures (Docker, network, flaky)
- If the failure is clearly infrastructure-related (Docker pull timeout, network errors, agent issues), inform the user that this is not a code issue
- Suggest retrying the build

## Step 6 -- Apply fixes

1. Make the necessary code changes using the Edit tool
2. Run the same checks locally if possible (e.g. `go fmt ./...`, `make test`, `make lint`) to verify the fix
3. Summarize what was wrong and what was fixed

## Step 7 -- Report

Present a summary to the user:

```
## CI Failure Report

**PR:** #{number} - {title}
**Build:** {pipeline} #{build_number}
**Failed Jobs:** {count}

### Failure 1: {job_name}
- **Type:** {formatting | lint | compilation | test | infrastructure}
- **Root Cause:** {description}
- **Fix Applied:** {description of changes}
- **Files Changed:** {list}

### Verification
- **Local check result:** {pass/fail}

### Next Steps
- {any remaining actions needed}
```

## Important Rules

- ALWAYS fetch and read the actual logs before diagnosing -- never guess the failure reason from job names alone
- When multiple jobs fail, they may share a root cause (e.g. a compilation error causes both build and test to fail) -- fix the root cause first
- If the fix requires changes the user should review (e.g. updating test expectations, changing logic), present the proposed changes and ask for confirmation before applying
- If a failure appears to be flaky (passed on retry, or the error is transient), say so clearly
- Do NOT retry builds automatically -- always ask the user first
- When running local verification, use the same commands the CI uses (check the Makefile or CI config)
