---
name: buildkite
description: "Interact with Buildkite via the `bk` CLI (preferred) or the REST API (fallback). Investigate build failures, pull job logs, list pipelines/builds, retry jobs, create builds, download artifacts, unblock steps, and debug CI issues. IMPORTANT: Always load this skill when the user shares a buildkite.com URL."
---

# Buildkite

## Overview

Two ways to interact with Buildkite, in order of preference:

1. **`bk` CLI** (v3.27+, installed at `/opt/homebrew/bin/bk`) — use for everything it supports.
2. **REST API** (`https://api.buildkite.com/v2` via `curl`) — fallback for endpoints the CLI doesn't cover (e.g. annotations, job env vars) or when `bk` is unavailable.

## Authentication

Both methods use the `BUILDKITE_TOKEN` environment variable, already available in the shell.

**CLI** — requires two env vars. Always set them as inline prefixes (do NOT export globally):

```bash
BUILDKITE_API_TOKEN=$BUILDKITE_TOKEN BUILDKITE_ORGANIZATION_SLUG=rokt bk <command>
```

- The default org slug is `rokt`.
- For brevity, all CLI examples below omit the env prefix. Always include it when running commands.

**REST API** — bearer auth:

```bash
curl -sS -H "Authorization: Bearer $BUILDKITE_TOKEN" \
  "https://api.buildkite.com/v2/<endpoint>"
```

Token scopes needed: `read_builds`, `read_build_logs`, `read_artifacts`, `read_job_env`, `write_builds` (for mutations).

## Parsing Build URLs

Given `https://buildkite.com/{org}/{pipeline}/builds/{number}#job-uuid`:

- **org** = `rokt` (usually)
- **pipeline** = the pipeline slug
- **build number** = integer after `/builds/` (NOT the build UUID)
- **fragment after `#`** = usually the job UUID (use for `bk job log`, `bk job retry`, etc.). If it doesn't resolve, fetch the build and find the job by name/step key in `jobs[]`.

---

## CLI Global Flags

| Flag | Description |
|------|-------------|
| `-h, --help` | Context-sensitive help |
| `-y, --yes` | Skip confirmation prompts |
| `--no-input` | Disable interactive prompts |
| `-q, --quiet` | Suppress progress output |
| `--no-pager` | Disable pager for text output |
| `--debug` | Enable debug output for REST API calls |
| `-o, --output` | Output format: `json`, `yaml`, `text` (where supported) |

---

## CLI Command Reference

### Builds

#### `bk build view [<build-number>]`
View build information. If build number is omitted, shows most recent build on current branch.

```bash
bk build view 17025 -p upsells-dd-terraform      # specific build
bk build view -p my-pipeline                     # most recent on current branch
bk build view -b main -p my-pipeline             # filter by branch
bk build view --mine -p my-pipeline              # your most recent build
bk build view -w 429 -p my-pipeline              # open in browser
bk build view 17025 -p my-pipeline -o json       # JSON output
```

Key flags: `-p/--pipeline`, `-b/--branch`, `-u/--user`, `--mine`, `-w/--web`, `-o/--output`

#### `bk build list`
List builds with filtering.

```bash
bk build list -p my-pipeline                                        # recent (default 50)
bk build list -p my-pipeline --state failed --branch main --since 24h
bk build list -p my-pipeline --duration ">20m"                      # long builds
bk build list -p my-pipeline --creator alice@company.com
bk build list -p my-pipeline --commit abc123def456
bk build list -p my-pipeline --message deploy
bk build list -p my-pipeline --meta-data env=production
bk build list -p my-pipeline --limit 500
bk build list -p my-pipeline --state failed -o json
```

Server-side filters (fast): `--pipeline`, `--since`, `--until`, `--state`, `--branch`, `--creator`, `--commit`, `--meta-data`
Client-side filters: `--duration`, `--message`

#### `bk build create`
Create (trigger) a new build.

```bash
bk build create -p my-pipeline                        # default branch
bk build create -p my-pipeline -b feature-x -c abc123 # branch/commit
bk build create -p my-pipeline -e "FOO=BAR" -e "BAZ=QUX"
bk build create -p my-pipeline -M "env=production"    # metadata
bk build create -p my-pipeline -m "Deploy v2.3.1"     # message
bk build create -p my-pipeline -w                     # open in browser
```

#### `bk build cancel <build-number>`

```bash
bk build cancel 123 -p my-pipeline
```

#### `bk build rebuild [<build-number>]`

```bash
bk build rebuild 123 -p my-pipeline
bk build rebuild -b main -p my-pipeline   # most recent on branch
```

#### `bk build watch [<build-number>]`
Watch a build's progress in real-time.

```bash
bk build watch 429 -p my-pipeline
bk build watch --interval 5 -p my-pipeline
```

#### `bk build download [<build-number>]`
Download build resources/artifacts.

```bash
bk build download 123 -p my-pipeline
```

### Jobs

#### `bk job log <job-id>`
Get logs for a specific job. The most important command for debugging failures.

```bash
bk job log 019c9b53-9ae0-41ab-a55a-73e103cd98aa -p upsells-dd-terraform -b 17025

# Strip timestamps, disable pager, tail for the error
bk job log <job-id> -p my-pipeline -b 123 --no-timestamps --no-pager 2>&1 | tail -50
```

Key flags: `-p/--pipeline`, `-b/--build-number` (required), `--no-timestamps`

#### `bk job list`

```bash
bk job list -p my-pipeline --state failed
bk job list -p my-pipeline --state running --queue test-queue
bk job list -p my-pipeline --duration ">10m"
bk job list -p my-pipeline --since 1h
bk job list -p my-pipeline --order-by duration
```

#### `bk job retry <job-id>`

```bash
bk job retry 019c9b53-9ae0-41ab-a55a-73e103cd98aa
```

#### `bk job cancel <job-id>`

```bash
bk job cancel <job-id> -p my-pipeline -b 123
```

#### `bk job unblock <job-id>`

```bash
bk job unblock <job-id>
bk job unblock <job-id> --data '{"field": "value"}'
```

### Pipelines

```bash
bk pipeline list                          # all pipelines
bk pipeline list --name upsells           # partial match, case insensitive
bk pipeline list --repo upsells-dd-terraform
bk pipeline list --limit 500
bk pipeline view upsells-dd-terraform
bk pipeline view my-org/my-pipeline -o json
bk pipeline view my-pipeline -w           # open in browser
```

### Artifacts

```bash
bk artifacts list 429 -p my-pipeline                    # all artifacts for a build
bk artifacts list 429 -p my-pipeline --job <job-uuid>   # for a specific job
bk artifacts download <artifact-id>                     # download by UUID
```

### Agents

```bash
bk agent list
bk agent list --state running          # or: idle
bk agent list --hostname my-server-01
bk agent list --tags queue=default --tags os=linux   # AND logic
bk agent view <agent>
bk agent pause <agent-id>
bk agent resume <agent-id>
bk agent stop [<agents>...]
```

### Raw API Access

#### `bk api [<endpoint>]`
Direct API access for endpoints not covered by other commands. Endpoint paths are relative to the org.

```bash
bk api /pipelines/my-pipeline/builds/420
bk api --method POST /pipelines --data '{"name": "My Pipeline"}'
bk api --method PUT /clusters/CLUSTER_UUID --data '{"name": "Updated"}'
bk api -H "Accept: text/plain" /pipelines/my-pipeline/builds/123/jobs/<id>/log
bk api --analytics /suites             # Test Engine endpoints
bk api --file query.graphql            # GraphQL from file
```

### Other Commands

| Command | Description |
|---------|-------------|
| `bk whoami` | Print current user and organization |
| `bk use [<org>]` | Select an organization |
| `bk org list` | List configured organizations |
| `bk config list` / `get` / `set` | Manage configuration values |
| `bk version` | Print CLI version |

---

## REST API Fallback

Base URL `https://api.buildkite.com/v2`. Most endpoints follow:

```
/v2/organizations/{org.slug}/pipelines/{pipeline.slug}/builds/{build.number}/jobs/{job.id}
```

Use the REST API directly (or via `bk api`) for things the CLI lacks:

### Annotations (not in CLI)

Rich-text messages attached to builds — often contain test failure summaries or deployment info.

```bash
curl -sS -H "Authorization: Bearer $BUILDKITE_TOKEN" \
  "https://api.buildkite.com/v2/organizations/{org}/pipelines/{pipeline}/builds/{number}/annotations" | jq .
```

Response includes `id`, `context`, `style` (success/info/warning/error), `body_html`, `created_at`.

### Job Environment Variables (not in CLI)

```bash
curl -sS -H "Authorization: Bearer $BUILDKITE_TOKEN" \
  "https://api.buildkite.com/v2/organizations/{org}/pipelines/{pipeline}/builds/{number}/jobs/{job_id}/env" \
  | jq '.env'
```

### Job Logs (raw)

```bash
# JSON (content, size, header_times)
curl -sS -H "Authorization: Bearer $BUILDKITE_TOKEN" \
  ".../builds/{number}/jobs/{job_id}/log" | jq -r '.content'

# Plain text via Accept header or .txt extension
curl -sS -H "Authorization: Bearer $BUILDKITE_TOKEN" -H "Accept: text/plain" \
  ".../builds/{number}/jobs/{job_id}/log"
```

### Build Query Parameters (list endpoints)

| Parameter | Description | Example |
|-----------|-------------|---------|
| `state` | `running`, `scheduled`, `passed`, `failing`, `failed`, `blocked`, `canceled`, `canceling`, `skipped`, `not_run`, `finished` (shortcut for passed+failed+blocked+canceled). Multiple: `?state[]=failed&state[]=canceled` | `?state=failed` |
| `branch` | Supports wildcards `?branch=*dev*` and multiple `?branch[]=main&branch[]=staging` | `?branch=main` |
| `commit` | Full SHA only | `?commit=abc123...` |
| `created_from` / `created_to` / `finished_from` | ISO 8601 timestamps | `?created_from=2026-01-01T00:00:00Z` |
| `creator` | User UUID | `?creator=<uuid>` |
| `meta_data` | | `?meta_data[key]=value` |
| `include_retried_jobs` | | `?include_retried_jobs=true` |

### Other REST endpoints

| Operation | Method | Endpoint |
|-----------|--------|----------|
| Cancel build | `PUT` | `.../builds/{number}/cancel` |
| Rebuild | `PUT` | `.../builds/{number}/rebuild` |
| Retry job | `PUT` | `.../jobs/{job_id}/retry` |
| Unblock job | `PUT` | `.../jobs/{job_id}/unblock` (body: `{"fields": {...}}`) |
| Reprioritize job | `PUT` | `.../jobs/{job_id}/reprioritize` |
| List/download artifacts | `GET` | `.../builds/{number}/artifacts` / `.../artifacts/{id}/download` (follow redirect with `-L`) |

REST notes:
- All list endpoints are **paginated**; check `Link` response headers.
- Rate limits apply; check response headers.

---

## Common Debugging Workflows

### 1. Investigate a Failed Build

```bash
# Step 1: View the build to see overall state and failed jobs
bk build view <number> -p <pipeline> -o json

# Step 2: Get the failed job's logs (last 50 lines usually have the error)
bk job log <job-id> -p <pipeline> -b <number> --no-timestamps --no-pager 2>&1 | tail -50

# Step 3: Search logs for errors
bk job log <job-id> -p <pipeline> -b <number> --no-timestamps --no-pager 2>&1 | grep -i "error\|failed\|fatal"

# Step 4: Check annotations for failure summaries (REST)
curl -sS -H "Authorization: Bearer $BUILDKITE_TOKEN" \
  "https://api.buildkite.com/v2/organizations/rokt/pipelines/<pipeline>/builds/<number>/annotations" | jq .

# Step 5: Check artifacts for test results
bk artifacts list <number> -p <pipeline>

# Step 6: Retry the failed job if it looks flaky
bk job retry <job-id>
```

### 2. Find Recent Failures

```bash
bk build list -p <pipeline> --state failed --since 24h
bk build list -p <pipeline> --state failed --branch main --since 7d
```

### 3. Monitor a Build in Progress

```bash
bk build watch <number> -p <pipeline>
```

### 4. Trigger a New Build

```bash
bk build create -p <pipeline> -b main -m "Triggered from CLI"
```

### 5. Bulk Operations with JSON Output

```bash
# Get all failed job IDs
bk job list -p <pipeline> --state failed --since 1h -o json | jq '.[].id'

# Retry all failed jobs (careful!)
bk job list -p <pipeline> --state failed --since 1h -o json \
  | jq -r '.[].id' \
  | xargs -I {} bk job retry {}
```

### General failure-diagnosis sequence

1. **Get the build** — overall state, identify jobs with `state == "failed"` or `timed_out`
2. **Read job logs** — search for errors, stack traces, assertion failures
3. **Check annotations** — often contain rendered test failure summaries
4. **Check artifacts** — JUnit XML, coverage reports
5. **Check env vars** — if the failure seems environment-related
6. **Check exit status** — non-zero `exit_status` on the job = failure
7. **Look for patterns** — compare recent builds on the same branch (flaky vs. regression)
8. **Retry or rebuild** as appropriate

---

## Build States

| State | Description |
|-------|-------------|
| `creating` | Build is being created |
| `scheduled` | Waiting for agents |
| `running` | Currently executing |
| `passed` | All jobs passed |
| `failing` | Some jobs failed, others still running |
| `failed` | Build finished with failures |
| `blocked` | Waiting on a block step (`state` retains last value, `blocked: true`) |
| `canceling` / `canceled` | Being / has been canceled |
| `skipped` | Was skipped |
| `not_run` | Did not run |

## Job States

`pending`, `waiting`, `scheduled`, `assigned`, `accepted`, `running`, `passed`, `failed`, `timed_out`, `timing_out`, `canceled`, `canceling`, `skipped`, `broken`, `blocked`, `unblocked`, `limited`, `expired`

## Tips

- Always use `--no-pager` when piping output or capturing in scripts.
- Use `-o json` for machine-readable output; pipe through `jq` for filtering.
- The `-p` flag accepts `{pipeline-slug}` or `{org}/{pipeline-slug}` format.
- `bk build view` without a number resolves the most recent build on the current branch (requires being in a git repo with a configured pipeline).
- For large logs, pipe `bk job log` through `tail`, `grep`, or redirect to a file.
- `bk build list` fetches 50 builds by default; use `--limit` to increase or `--no-limit` for all.
- Build `number` is an integer unique within a pipeline (not the UUID `id`).
