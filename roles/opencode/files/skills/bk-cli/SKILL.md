---
name: bk-cli
description: "Use the `bk` CLI (v3.27+) to interact with Buildkite. Investigate build failures, pull job logs, list pipelines/builds, retry jobs, create builds, download artifacts, and debug CI issues. Prefer this over raw curl/API calls when the `bk` binary is available. IMPORTANT: Always load this skill when the user shares a buildkite.com URL."
---

# Buildkite CLI (`bk`)

## Overview

The `bk` CLI is a local Buildkite client installed at `/opt/homebrew/bin/bk`. Use it instead of raw REST API calls for investigating builds, pulling logs, managing pipelines, and debugging CI failures.

## Authentication

The `bk` CLI requires two environment variables. Always set them as inline prefixes (do NOT export globally):

```bash
BUILDKITE_API_TOKEN=$BUILDKITE_TOKEN BUILDKITE_ORGANIZATION_SLUG=rokt bk <command>
```

- `BUILDKITE_TOKEN` is already available in the shell environment.
- The default org slug is `rokt`.

For brevity in this document, all examples omit the env prefix. Always include it when running commands.

## Global Flags

| Flag | Description |
|------|-------------|
| `-h, --help` | Context-sensitive help |
| `-y, --yes` | Skip confirmation prompts |
| `--no-input` | Disable interactive prompts |
| `-q, --quiet` | Suppress progress output |
| `--no-pager` | Disable pager for text output |
| `--debug` | Enable debug output for REST API calls |
| `-o, --output` | Output format: `json`, `yaml`, `text` (where supported) |

## Parsing Build URLs

Given a Buildkite URL like:
```
https://buildkite.com/{org}/{pipeline}/builds/{number}#job-uuid
```
Extract:
- **org** = `rokt` (usually)
- **pipeline** = the pipeline slug
- **build number** = integer after `/builds/`
- **job UUID** = fragment after `#` (use for `bk job log`, `bk job retry`, etc.)

---

## Command Reference

### Builds

#### `bk build view [<build-number>]`
View build information. If build number is omitted, shows most recent build on current branch.

```bash
# View specific build
bk build view 17025 -p upsells-dd-terraform

# View most recent build for current branch
bk build view -p my-pipeline

# Filter by branch
bk build view -b main -p my-pipeline

# Filter by user
bk build view -u "alice" -p my-pipeline

# View your own most recent build
bk build view --mine -p my-pipeline

# Open in browser
bk build view -w 429 -p my-pipeline

# JSON output
bk build view 17025 -p my-pipeline -o json
```

Key flags: `-p/--pipeline`, `-b/--branch`, `-u/--user`, `--mine`, `-w/--web`, `-o/--output`

#### `bk build list`
List builds with filtering. Supports server-side and client-side filters.

```bash
# List recent builds (default 50)
bk build list -p my-pipeline

# Failed builds on main in the last 24h
bk build list -p my-pipeline --state failed --branch main --since 24h

# Builds longer than 20 minutes
bk build list -p my-pipeline --duration ">20m"

# Builds by a specific user
bk build list -p my-pipeline --creator alice@company.com

# Filter by commit SHA
bk build list -p my-pipeline --commit abc123def456

# Filter by message content
bk build list -p my-pipeline --message deploy

# Filter by metadata
bk build list -p my-pipeline --meta-data env=production

# Get more results
bk build list -p my-pipeline --limit 500

# JSON output
bk build list -p my-pipeline --state failed -o json
```

Server-side filters (fast): `--pipeline`, `--since`, `--until`, `--state`, `--branch`, `--creator`, `--commit`, `--meta-data`
Client-side filters: `--duration`, `--message`

#### `bk build create`
Create (trigger) a new build.

```bash
# Create build on default branch
bk build create -p my-pipeline

# Create build on specific branch/commit
bk build create -p my-pipeline -b feature-x -c abc123

# With environment variables
bk build create -p my-pipeline -e "FOO=BAR" -e "BAZ=QUX"

# With metadata
bk build create -p my-pipeline -M "env=production"

# With a message
bk build create -p my-pipeline -m "Deploy v2.3.1"

# Open in browser after creation
bk build create -p my-pipeline -w
```

#### `bk build cancel <build-number>`
Cancel a running build.

```bash
bk build cancel 123 -p my-pipeline
```

#### `bk build rebuild [<build-number>]`
Rebuild a build. Omit number for most recent.

```bash
# Rebuild specific build
bk build rebuild 123 -p my-pipeline

# Rebuild most recent on a branch
bk build rebuild -b main -p my-pipeline

# Rebuild and open in browser
bk build rebuild 123 -p my-pipeline -w
```

#### `bk build watch [<build-number>]`
Watch a build's progress in real-time.

```bash
# Watch specific build
bk build watch 429 -p my-pipeline

# Watch most recent on a branch
bk build watch -b feature-x -p my-pipeline

# Custom polling interval (seconds)
bk build watch --interval 5 -p my-pipeline
```

#### `bk build download [<build-number>]`
Download build resources/artifacts.

```bash
bk build download 123 -p my-pipeline
bk build download -b main -p my-pipeline
```

---

### Jobs

#### `bk job log <job-id>`
Get logs for a specific job. This is the most important command for debugging failures.

```bash
# Get job logs
bk job log 019c9b53-9ae0-41ab-a55a-73e103cd98aa -p upsells-dd-terraform -b 17025

# Strip timestamps for cleaner output
bk job log <job-id> -p my-pipeline -b 123 --no-timestamps

# Pipe to search for errors
bk job log <job-id> -p my-pipeline -b 123 --no-timestamps --no-pager 2>&1 | tail -50
```

Key flags: `-p/--pipeline`, `-b/--build-number` (required), `--no-timestamps`

#### `bk job list`
List jobs with filtering.

```bash
# List recent jobs
bk job list -p my-pipeline

# Failed jobs
bk job list -p my-pipeline --state failed

# Running jobs on a queue
bk job list -p my-pipeline --state running --queue test-queue

# Jobs longer than 10 minutes
bk job list -p my-pipeline --duration ">10m"

# Jobs from the last hour
bk job list -p my-pipeline --since 1h

# Order by duration (longest first)
bk job list -p my-pipeline --order-by duration
```

#### `bk job retry <job-id>`
Retry a failed job.

```bash
bk job retry 019c9b53-9ae0-41ab-a55a-73e103cd98aa
```

#### `bk job cancel <job-id>`
Cancel a running job.

```bash
bk job cancel <job-id> -p my-pipeline -b 123
```

#### `bk job unblock <job-id>`
Unblock a blocked job (block step).

```bash
# Simple unblock
bk job unblock <job-id>

# Unblock with field data
bk job unblock <job-id> --data '{"field": "value"}'
```

---

### Pipelines

#### `bk pipeline list`
List pipelines.

```bash
# List all pipelines
bk pipeline list

# Filter by name (partial match, case insensitive)
bk pipeline list --name upsells

# Filter by repository
bk pipeline list --repo upsells-dd-terraform

# JSON output
bk pipeline list --name my-pipeline -o json

# More results
bk pipeline list --limit 500
```

#### `bk pipeline view [<pipeline>]`
View pipeline details.

```bash
bk pipeline view upsells-dd-terraform
bk pipeline view my-org/my-pipeline -o json
bk pipeline view my-pipeline -w  # open in browser
```

---

### Artifacts

#### `bk artifacts list [<build-number>]`
List artifacts for a build.

```bash
# List all artifacts for a build
bk artifacts list 429 -p my-pipeline

# List artifacts for a specific job
bk artifacts list 429 -p my-pipeline --job <job-uuid>
```

#### `bk artifacts download <artifact-id>`
Download a specific artifact by UUID.

---

### Agents

#### `bk agent list`
List agents with optional filtering.

```bash
# List all agents
bk agent list

# Running agents only
bk agent list --state running

# Idle agents
bk agent list --state idle

# Filter by hostname
bk agent list --hostname my-server-01

# Filter by tags
bk agent list --tags queue=default

# Multiple tag filters (AND logic)
bk agent list --tags queue=default --tags os=linux
```

#### `bk agent view <agent>`
View agent details.

#### `bk agent pause <agent-id>`
Pause an agent.

#### `bk agent resume <agent-id>`
Resume a paused agent.

#### `bk agent stop [<agents>...]`
Stop agents.

---

### Raw API Access

#### `bk api [<endpoint>]`
Direct API access for endpoints not covered by other commands.

```bash
# GET request
bk api /pipelines/my-pipeline/builds/420

# POST request
bk api --method POST /pipelines --data '{"name": "My Pipeline", ...}'

# PUT request
bk api --method PUT /clusters/CLUSTER_UUID --data '{"name": "Updated"}'

# Custom headers
bk api -H "Accept: text/plain" /pipelines/my-pipeline/builds/123/jobs/<id>/log

# Analytics/Test Engine endpoint
bk api --analytics /suites

# GraphQL from file
bk api --file query.graphql
```

---

### Other Commands

| Command | Description |
|---------|-------------|
| `bk whoami` | Print current user and organization |
| `bk use [<org>]` | Select an organization |
| `bk org list` | List configured organizations |
| `bk config list` | List configuration values |
| `bk config get <key>` | Get a config value |
| `bk config set <key> <value>` | Set a config value |
| `bk version` | Print CLI version |

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

# Step 4: Check artifacts for test results
bk artifacts list <number> -p <pipeline>

# Step 5: Retry the failed job if it looks flaky
bk job retry <job-id>
```

### 2. Find Recent Failures

```bash
# Failed builds in the last day
bk build list -p <pipeline> --state failed --since 24h

# Failed builds on main
bk build list -p <pipeline> --state failed --branch main --since 7d
```

### 3. Monitor a Build in Progress

```bash
# Watch real-time progress
bk build watch <number> -p <pipeline>

# Or poll manually
bk build view <number> -p <pipeline>
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

## Build States

| State | Description |
|-------|-------------|
| `creating` | Build is being created |
| `scheduled` | Waiting for agents |
| `running` | Currently executing |
| `passed` | All jobs passed |
| `failing` | Some jobs failed, others still running |
| `failed` | Build finished with failures |
| `blocked` | Waiting on a block step |
| `canceling` | Being canceled |
| `canceled` | Has been canceled |
| `skipped` | Was skipped |
| `not_run` | Did not run |

## Job States

`pending`, `waiting`, `scheduled`, `assigned`, `accepted`, `running`, `passed`, `failed`, `timed_out`, `timing_out`, `canceled`, `canceling`, `skipped`, `broken`, `blocked`, `unblocked`, `limited`, `expired`

## Tips

- Always use `--no-pager` when piping output or capturing in scripts.
- Use `-o json` for machine-readable output, pipe through `jq` for filtering.
- The `-p` flag accepts `{pipeline-slug}` or `{org}/{pipeline-slug}` format.
- `bk build view` without a number resolves the most recent build on the current branch (requires being in a git repo with a configured pipeline).
- For large logs, pipe `bk job log` through `tail`, `grep`, or redirect to a file.
- `bk build list` fetches 50 builds by default; use `--limit` to increase or `--no-limit` for all.
