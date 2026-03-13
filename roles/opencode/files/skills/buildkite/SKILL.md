---
name: buildkite
description: "Query the Buildkite REST API using BUILDKITE_TOKEN (bearer auth) against https://api.buildkite.com/v2. Use for investigating build failures, pulling build/job logs, listing pipelines, downloading artifacts, retrying jobs, and debugging CI issues."
---

# Buildkite

## Overview

Use the Buildkite REST API to investigate builds, pull logs, identify failures, download artifacts, and manage pipelines. Authentication is via the `BUILDKITE_TOKEN` environment variable as a Bearer token.

## Quick Start

```bash
curl -sS \
  -H "Authorization: Bearer $BUILDKITE_TOKEN" \
  "https://api.buildkite.com/v2/<endpoint>"
```

All endpoints use base URL `https://api.buildkite.com/v2`.

## URL Pattern Convention

Most endpoints follow this hierarchy:

```
/v2/organizations/{org.slug}/pipelines/{pipeline.slug}/builds/{build.number}/jobs/{job.id}
```

- `{org.slug}` -- Organization slug (e.g. `my-org`)
- `{pipeline.slug}` -- Pipeline slug (e.g. `my-pipeline`)
- `{build.number}` -- Build number (integer, NOT the UUID)
- `{job.id}` -- Job UUID

---

## API Reference

### Pipelines

| Operation | Method | Endpoint |
|-----------|--------|----------|
| List pipelines | `GET` | `/v2/organizations/{org}/pipelines` |
| Get a pipeline | `GET` | `/v2/organizations/{org}/pipelines/{pipeline}` |

### Builds

| Operation | Method | Endpoint | Scope |
|-----------|--------|----------|-------|
| List all builds | `GET` | `/v2/builds` | `read_builds` |
| List org builds | `GET` | `/v2/organizations/{org}/builds` | `read_builds` |
| List pipeline builds | `GET` | `/v2/organizations/{org}/pipelines/{pipeline}/builds` | `read_builds` |
| Get a build | `GET` | `/v2/organizations/{org}/pipelines/{pipeline}/builds/{number}` | `read_builds` |
| Create a build | `POST` | `/v2/organizations/{org}/pipelines/{pipeline}/builds` | `write_builds` |
| Cancel a build | `PUT` | `/v2/organizations/{org}/pipelines/{pipeline}/builds/{number}/cancel` | `write_builds` |
| Rebuild a build | `PUT` | `/v2/organizations/{org}/pipelines/{pipeline}/builds/{number}/rebuild` | `write_builds` |

#### Build Query Parameters

Use these on any list-builds endpoint:

| Parameter | Description | Example |
|-----------|-------------|---------|
| `state` | Filter by state. Values: `running`, `scheduled`, `passed`, `failing`, `failed`, `blocked`, `canceled`, `canceling`, `skipped`, `not_run`, `finished` (shortcut for passed+failed+blocked+canceled). Supports multiple: `?state[]=failed&state[]=canceled` | `?state=failed` |
| `branch` | Filter by branch. Supports wildcards: `?branch=*dev*`. Multiple: `?branch[]=main&branch[]=staging` | `?branch=main` |
| `commit` | Filter by full SHA | `?commit=abc123...` |
| `created_from` | Builds created on/after (ISO 8601) | `?created_from=2026-01-01T00:00:00Z` |
| `created_to` | Builds created before (ISO 8601) | `?created_to=2026-02-01T00:00:00Z` |
| `finished_from` | Builds finished on/after (ISO 8601) | `?finished_from=2026-01-01T00:00:00Z` |
| `creator` | Filter by user UUID | `?creator=<uuid>` |
| `meta_data` | Filter by meta-data | `?meta_data[key]=value` |
| `include_retried_jobs` | Include retried job executions | `?include_retried_jobs=true` |

Pipeline-specific additional params: `exclude_jobs=true`, `exclude_pipeline=true`.

#### Build States

- `creating` -- Build is being created
- `scheduled` -- Waiting for agents
- `running` -- Currently running
- `passed` -- All jobs passed
- `failing` -- Some jobs have failed, others still running
- `failed` -- Build finished with failures
- `blocked` -- Waiting on a block step
- `canceling` -- Being canceled
- `canceled` -- Has been canceled
- `skipped` -- Was skipped
- `not_run` -- Did not run

#### Build Response Key Fields

```
id, number, state, blocked, message, commit, branch, source,
web_url, created_at, started_at, finished_at, jobs[], pipeline{}, creator{}
```

Each `job` in `jobs[]` includes: `id`, `type`, `name`, `state`, `exit_status`, `command`, `web_url`, `log_url`, `raw_log_url`, `soft_failed`, `started_at`, `finished_at`, `agent{}`, `retried`, `retries_count`.

### Jobs

Base path: `/v2/organizations/{org}/pipelines/{pipeline}/builds/{number}/jobs/{job_id}`

| Operation | Method | Path Suffix | Scope |
|-----------|--------|-------------|-------|
| Retry a job | `PUT` | `/retry` | `write_builds` |
| Unblock a job | `PUT` | `/unblock` | `write_builds` |
| Get job log | `GET` | `/log` | `read_build_logs` |
| Delete job log | `DELETE` | `/log` | `write_build_logs` |
| Get job env vars | `GET` | `/env` | `read_job_env` |
| Reprioritize a job | `PUT` | `/reprioritize` | `write_builds` |

#### Job Log Response (JSON)

```json
{
  "url": "https://api.buildkite.com/v2/.../log",
  "content": "<log output as string>",
  "size": 12345,
  "header_times": [1234567890000000000]
}
```

Alternative formats via `Accept` header or URL extension:
- `text/plain` or `.txt` -- Raw log text
- `text/html` or `.html` -- HTML-rendered log

#### Job Environment Variables Response

```json
{
  "env": {
    "BUILDKITE": "true",
    "BUILDKITE_BRANCH": "main",
    "BUILDKITE_BUILD_NUMBER": "42",
    "BUILDKITE_COMMIT": "abc123...",
    ...
  }
}
```

#### Job States

`pending`, `waiting`, `scheduled`, `assigned`, `accepted`, `running`, `passed`, `failed`, `timed_out`, `timing_out`, `canceled`, `canceling`, `skipped`, `broken`, `blocked`, `unblocked`, `limited`, `expired`

### Annotations

| Operation | Method | Endpoint | Scope |
|-----------|--------|----------|-------|
| List annotations | `GET` | `/v2/organizations/{org}/pipelines/{pipeline}/builds/{number}/annotations` | `read_builds` |

Annotations are rich-text messages attached to builds (often contain test failure summaries, deployment info, etc.). Response includes `id`, `context`, `style` (success/info/warning/error), `body_html`, `created_at`.

### Artifacts

| Operation | Method | Endpoint | Scope |
|-----------|--------|----------|-------|
| List build artifacts | `GET` | `/v2/organizations/{org}/pipelines/{pipeline}/builds/{number}/artifacts` | `read_artifacts` |
| List job artifacts | `GET` | `/v2/organizations/{org}/pipelines/{pipeline}/builds/{number}/jobs/{job_id}/artifacts` | `read_artifacts` |
| Get an artifact | `GET` | `/v2/organizations/{org}/pipelines/{pipeline}/builds/{number}/artifacts/{artifact_id}` | `read_artifacts` |
| Download an artifact | `GET` | `/v2/organizations/{org}/pipelines/{pipeline}/builds/{number}/artifacts/{artifact_id}/download` | `read_artifacts` |
| Delete an artifact | `DELETE` | `/v2/organizations/{org}/pipelines/{pipeline}/builds/{number}/artifacts/{artifact_id}` | `write_artifacts` |

Artifact response includes: `id`, `job_id`, `path`, `filename`, `mime_type`, `file_size`, `sha1sum`, `download_url`, `state`.

### Agents

| Operation | Method | Endpoint |
|-----------|--------|----------|
| List agents | `GET` | `/v2/organizations/{org}/agents` |
| Get an agent | `GET` | `/v2/organizations/{org}/agents/{agent_id}` |

---

## Common Workflows

### 1. Investigate a Failed Build

When given a build URL like `https://buildkite.com/{org}/{pipeline}/builds/{number}`:

```bash
# Step 1: Get build details
curl -sS -H "Authorization: Bearer $BUILDKITE_TOKEN" \
  "https://api.buildkite.com/v2/organizations/{org}/pipelines/{pipeline}/builds/{number}" | jq .

# Step 2: Find failed jobs
curl -sS -H "Authorization: Bearer $BUILDKITE_TOKEN" \
  "https://api.buildkite.com/v2/organizations/{org}/pipelines/{pipeline}/builds/{number}" \
  | jq '.jobs[] | select(.state == "failed") | {id, name, state, exit_status, web_url}'

# Step 3: Get the log for a failed job
curl -sS -H "Authorization: Bearer $BUILDKITE_TOKEN" \
  "https://api.buildkite.com/v2/organizations/{org}/pipelines/{pipeline}/builds/{number}/jobs/{job_id}/log" \
  | jq -r '.content'

# Step 4: Check annotations for failure summaries
curl -sS -H "Authorization: Bearer $BUILDKITE_TOKEN" \
  "https://api.buildkite.com/v2/organizations/{org}/pipelines/{pipeline}/builds/{number}/annotations" | jq .
```

### 2. Find Recent Failures for a Pipeline

```bash
# List recent failed builds
curl -sS -H "Authorization: Bearer $BUILDKITE_TOKEN" \
  "https://api.buildkite.com/v2/organizations/{org}/pipelines/{pipeline}/builds?state=failed&branch=main" \
  | jq '.[] | {number, state, message, commit, web_url, finished_at}'
```

### 3. Pull Job Logs as Plain Text

```bash
# Get raw log text (useful for parsing/searching)
curl -sS -H "Authorization: Bearer $BUILDKITE_TOKEN" \
  -H "Accept: text/plain" \
  "https://api.buildkite.com/v2/organizations/{org}/pipelines/{pipeline}/builds/{number}/jobs/{job_id}/log"
```

### 4. Download Build Artifacts

```bash
# List artifacts for a build
curl -sS -H "Authorization: Bearer $BUILDKITE_TOKEN" \
  "https://api.buildkite.com/v2/organizations/{org}/pipelines/{pipeline}/builds/{number}/artifacts" \
  | jq '.[] | {id, filename, file_size, path}'

# Download a specific artifact (follow redirect)
curl -sS -L -H "Authorization: Bearer $BUILDKITE_TOKEN" \
  "https://api.buildkite.com/v2/organizations/{org}/pipelines/{pipeline}/builds/{number}/artifacts/{artifact_id}/download" \
  -o output_file
```

### 5. Retry a Failed Job

```bash
curl -sS -X PUT -H "Authorization: Bearer $BUILDKITE_TOKEN" \
  "https://api.buildkite.com/v2/organizations/{org}/pipelines/{pipeline}/builds/{number}/jobs/{job_id}/retry"
```

### 6. Rebuild an Entire Build

```bash
curl -sS -X PUT -H "Authorization: Bearer $BUILDKITE_TOKEN" \
  "https://api.buildkite.com/v2/organizations/{org}/pipelines/{pipeline}/builds/{number}/rebuild"
```

### 7. Get Job Environment Variables

```bash
curl -sS -H "Authorization: Bearer $BUILDKITE_TOKEN" \
  "https://api.buildkite.com/v2/organizations/{org}/pipelines/{pipeline}/builds/{number}/jobs/{job_id}/env" \
  | jq '.env'
```

### 8. Find Builds by Commit SHA

```bash
curl -sS -H "Authorization: Bearer $BUILDKITE_TOKEN" \
  "https://api.buildkite.com/v2/organizations/{org}/pipelines/{pipeline}/builds?commit={full_sha}" \
  | jq '.[] | {number, state, branch, web_url}'
```

### 9. Check Currently Running Builds

```bash
curl -sS -H "Authorization: Bearer $BUILDKITE_TOKEN" \
  "https://api.buildkite.com/v2/organizations/{org}/builds?state[]=running&state[]=scheduled" \
  | jq '.[] | {pipeline: .pipeline.slug, number, branch, state, web_url}'
```

### 10. Unblock a Blocked Build

```bash
curl -sS -X PUT -H "Authorization: Bearer $BUILDKITE_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"fields": {"release-name": "v1.2.3"}}' \
  "https://api.buildkite.com/v2/organizations/{org}/pipelines/{pipeline}/builds/{number}/jobs/{job_id}/unblock"
```

---

## Debugging Workflow

When a user reports a build failure, follow this sequence:

1. **Get the build** -- Fetch the build by org/pipeline/number to see overall state
2. **Identify failed jobs** -- Filter `jobs[]` for `state == "failed"` or `state == "timed_out"`
3. **Read job logs** -- Pull log content for each failed job; search for error messages, stack traces, assertion failures
4. **Check annotations** -- Annotations often contain rendered test failure summaries or deployment status
5. **Check artifacts** -- Test result files (JUnit XML, coverage reports) may be uploaded as artifacts
6. **Check environment** -- If the failure seems environment-related, pull the job's env vars
7. **Check exit status** -- `exit_status` on the job indicates the process exit code (non-zero = failure)
8. **Look for patterns** -- Compare with recent builds on the same branch to identify flaky tests vs. real regressions
9. **Retry or rebuild** -- Retry individual failed jobs or rebuild the entire build if appropriate

## Parsing Build URLs

Given a Buildkite URL like `https://buildkite.com/my-org/my-pipeline/builds/123`:
- `org.slug` = `my-org`
- `pipeline.slug` = `my-pipeline`
- `build.number` = `123`

Given a job URL like `https://buildkite.com/my-org/my-pipeline/builds/123#step-uuid`:
- The fragment after `#` is a UI anchor, not the job UUID
- Fetch the build first, then find the job by name or step key in the `jobs[]` array

## Notes

- All list endpoints return **paginated** results. Check `Link` response headers for next/prev pages.
- Build `number` is an integer unique within a pipeline (not the UUID `id`).
- The `finished` state filter is a shortcut for `passed`, `failed`, `blocked`, `canceled`.
- When a build is blocked, `state` retains its last value and `blocked` is `true`.
- Rate limits apply; check response headers for rate limit status.
- Token scopes needed: `read_builds`, `read_build_logs`, `read_artifacts`, `read_job_env`, `write_builds` (for mutations).
