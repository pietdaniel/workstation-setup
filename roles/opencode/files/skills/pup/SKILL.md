---
name: pup
description: Query Datadog from the terminal with the `pup` CLI (the Datadog API CLI). Use to query time-series metrics, search logs and traces, inspect monitors/incidents/dashboards, and answer observability questions like "how many requests hit tag X" or "is metric Y firing". Prefer this over guessing metric/log values or telling the user to check Datadog themselves. Triggers on: Datadog, metric query, log search, APM traces, monitor status, "check the metric", "how many events", tag breakdown, blast radius from a metric.
---

# pup — Datadog API CLI

## Overview

`pup` is an authenticated CLI over the Datadog API. It queries metrics, logs,
traces, monitors, incidents, dashboards, SLOs, and more, and can ask Datadog
Bits AI in natural language. Output defaults to JSON, so pipe through `jq` (or
the built-in `--jq`) to extract values.

**When you have a question about production behavior that Datadog would answer,
use `pup` — do not guess metric/log values and do not punt to the user.**

## Prerequisites

- Binary installed: `which pup` (Homebrew: `/opt/homebrew/bin/pup`).
- Authenticated: `pup auth status`. Tokens auto-refresh; if it reports not
  authenticated, tell the user to run `pup auth login` and stop.

## Global flags worth knowing

- `-o, --output <json|table|yaml|csv>` — output format (default `json`; or set
  `$DD_OUTPUT` / `$PUP_OUTPUT`).
- `--jq <EXPR>` — filter output through jq before formatting (applied to the raw
  response). Handy but you can also pipe to a real `jq`.
- `--read-only` — block all write ops (create/update/delete). Use this whenever
  you only intend to read, as a safety belt.
- `-y, --yes` — auto-approve destructive ops. Do NOT use unless the user
  explicitly asked for the write.
- `--from` / `--to` — time ranges accept relative (`30m`, `1h`, `7d`, `30d`,
  `90d`, `now`), RFC3339, or Unix timestamps.

## When to use

- "How many requests had tag `mode:invalid`?" → `metrics query`
- "Is this metric emitting at all / what tag values exist?" → `metrics query ... by {tag}`
- "Blast radius of a behavior change" → sum the affected metric/tag over a window
- "Find the error logs for service X" → `logs search`
- "Is monitor / SLO / incident Z healthy?" → `monitors`, `slos`, `incidents`
- Natural-language exploration when you don't know the metric name → `bits`

## When NOT to use

- Reading source code, CI logs (use Buildkite tooling), or git — those have
  dedicated tools.
- Writing/mutating Datadog config (monitors, dashboards, downtimes) unless the
  user explicitly asked. Default to `--read-only`.

## Metrics — the most common task

```bash
# Basic time series
pup metrics query --query="avg:system.cpu.user{*}" --from="1h" --to="now"

# Count a specific tag value over 30 days
pup metrics query \
  --query="sum:transactions.api.shadow_header{mode:invalid}.as_count()" \
  --from="30d" --to="now"

# Break a metric down by a tag (discover which tag values have data)
pup metrics query \
  --query="sum:transactions.api.shadow_header{*} by {mode}.as_count()" \
  --from="7d" --to="now"

# Confirm a metric exists
pup metrics list --filter="transactions.api.shadow_header"
```

### CRITICAL: metrics query response shape

`pup metrics query` returns the Datadog **v1 time-series** shape, NOT
`.data.attributes...`. Points live at `.series[].pointlist`, each point being
`[epoch_millis, value]`. Empty `.series` (length 0) means **no data / the tag
was never emitted** in that window.

```bash
# Sum every point across all series → single scalar total for the window
pup metrics query --query="sum:METRIC{TAG}.as_count()" --from="30d" --to="now" \
  | jq '[.series[]?.pointlist[]?[1]] | add // 0'

# Is a tag value ever emitted? series_count 0 == never
pup metrics query --query="sum:METRIC{mode:invalid}.as_count()" --from="90d" --to="now" \
  | jq '{series_count: (.series|length), total: ([.series[]?.pointlist[]?[1]] | add // 0)}'

# Which tag values actually have data
pup metrics query --query="sum:METRIC{*} by {mode}.as_count()" --from="7d" --to="now" \
  | jq -r '.series[]? | .scope' | sort -u
```

Do NOT trust `.data.attributes.series` for `metrics query` — it is null there
and will make real data look empty. That confusion is the #1 mistake with this
command.

### Looping tag values for a clean breakdown

```bash
for m in invalid not_set cutover shadow; do
  total=$(pup metrics query --query="sum:transactions.api.shadow_header{mode:$m}.as_count()" \
    --from="30d" --to="now" | jq '[.series[]?.pointlist[]?[1]] | add // 0')
  printf "mode:%-8s 30d total = %s\n" "$m" "$total"
done
```

## Logs

```bash
pup logs search --query="service:transactions-api status:error" --from="1h" --to="now" --limit 50
# --sort asc|desc (default desc), --storage indexes|online-archives|flex
```

## Traces / APM

```bash
pup traces search --help      # search spans
pup apm --help                # services & entities
pup change-stories --help     # correlate deploys/changes with anomalies
```

## Monitors, incidents, SLOs, dashboards

```bash
pup monitors list --read-only
pup incidents list --read-only
pup slos list --read-only
pup dashboards list --read-only
```

## Natural language (when you don't know the metric name)

```bash
pup bits "how many transactions.api requests were rejected in the last day"
pup docs "how do I write a metrics query with a rollup"
```
Use `bits` to discover the right metric/tag, then switch to `metrics query` for
an exact, reproducible number.

## Workflow for "answer a number from Datadog"

1. `pup auth status` — confirm authenticated (auto-refreshes).
2. If unsure of the metric name: `pup metrics list --filter="<prefix>"` or `pup bits "..."`.
3. Discover tag values: `... {*} by {tag}` and inspect `.series[].scope`.
4. Query the exact tag/window with `.as_count()` and sum
   `.series[].pointlist[][1]`.
5. Report the number, the window, and note `series_count: 0` explicitly as
   "never emitted / zero" rather than "unknown".

## Gotchas

- `metrics query` is v1-shaped (`.series[].pointlist`); many other `pup`
  commands are v2-shaped (`.data...`). Check the actual JSON before writing jq.
- Empty series ≠ error. It means zero in that window. State that plainly.
- `.as_count()` gives request/event counts; without it you get per-second rates.
  Use `.as_count()` when the user asks "how many".
- Default `--from` is only `1h`. Always set an explicit window for historical
  questions.
- Pass `--read-only` on read tasks; never pass `-y` unless the user asked to
  mutate Datadog.
