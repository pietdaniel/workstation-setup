---
name: create-datadog-notebook
description: "Create Datadog investigation notebooks that build a clear narrative from APM, metrics, and logs. Use when asked to create a notebook, write up an incident, or document an investigation in Datadog. Enforces best practices: prefer graphs over tables, no preformatted text for tabular data, anchor every claim to a chart, build evidence from multiple telemetry sources."
---

# Create Datadog Notebook

A Datadog notebook is a **visual investigation document**, not a Markdown report. The reader scrolls through charts and reads short prose between them. Your job is to tell a story where every claim is anchored to a chart they can see and click through to in Datadog.

## Setup

Read the official widget reference before writing any cell:

```
datadog_get_widget_reference(widget_types=["timeseries", "note", "query_value", "query_table", "toplist"])
```

This returns the exact JSON shapes. Don't guess them.

## Hard rules

### 1. Prefer graphs over tables. Always.

If you find yourself typing a Markdown table with numbers in it, stop and replace it with a `timeseries` widget. The reader's brain is already trained to parse line charts at a glance. Tables of numbers in a notebook are unreadable.

**Exception:** small comparison tables (≤3 columns, ≤5 rows) summarizing things that are NOT numeric over time — e.g. "service A vs. service B endpoints", "before vs. after config values". For those, a markdown table is fine. Numeric data over time is **never** an exception.

### 2. Never use preformatted text (```` ``` ````) for tabular data.

Code fences in markdown notebooks render as monospaced text without column alignment. ASCII tables look broken. Use code fences ONLY for:

- Actual code (Go, SQL, YAML, shell)
- Stack traces (preserve indentation)
- Log lines (preserve format)
- Commit metadata (`git log` output)

If you're tempted to put a table in a code fence to "make it line up" — make it a chart instead.

### 3. One claim per chart.

Every chart should answer one specific question. The note cell directly above it states the question; the chart shows the answer. If a chart needs a paragraph of explanation, you're either showing too much or asking too vague a question.

Bad: *"Here are all the gateway metrics during the dip."* (chart with 12 series)
Good: *"Did gateway pod restarts spike?"* (chart with 1 series, clearly trending or flat)

### 4. Anchor everything to a chart or trace link.

No floating claims. Every "X happened at Y time" or "Z was elevated by Nx" must be visible in the chart immediately before or after the prose.

If you're citing a specific trace, include the trace deep link:
`https://<base_url>/apm/trace/<trace_id>`

If you're citing a specific log message, the prose should describe what to look for and the chart should be a `list_stream` widget OR a logs query in `query_table`.

### 5. Use APM, metrics, AND logs.

A complete investigation triangulates evidence from multiple sources:

- **Metrics** answer "how big" and "when" (rate, latency, count, error %)
- **APM** answers "what code path" and "why" (spans, stack traces, error.type, error.message)
- **Logs** answer "what exactly happened" (full message text, error patterns, correlation IDs)

If the notebook only has metrics, you don't know what the code was doing. If only APM, you don't know if it's broad or one user. If only logs, you don't know the magnitude. **Use all three.**

### 6. Lead with the answer, then the evidence.

Cell 1 is always a TL;DR with the conclusion. Then build evidence in order from highest signal to lowest. The reader who only reads the first cell should still walk away with the right answer.

### 7. Markdown formatting rules

- **No emoji** unless the user explicitly asks
- **American English** (transactions repo standard): "behavior" not "behaviour", "canceled" not "cancelled"
- **No deep heading nesting**: `#`, `##`, occasionally `###`. Never go deeper.
- **No bold-as-pseudo-heading**: if it deserves emphasis, make it a `###` heading
- **Inline code** for service names, metric names, error types, code identifiers: `` `transactions-gateway` ``, `` `rpc.grpc.status_code` ``, `` `*errors.errorString` ``
- **Bullets for lists, prose for narrative**. Don't bullet-point a story.

## Notebook structure

Use this skeleton for an investigation notebook. Adjust depth based on the investigation, but the order is fixed:

1. **Title** — `<thing> @ <date> <time UTC> — <one-line conclusion>`
2. **TL;DR cell** (markdown) — 3-5 sentences with the conclusion. Link out to the watchdog story / PR / runbook if relevant.
3. **Symptom chart** (timeseries) — the graph that originally got someone's attention. The "what". One series, full-width, clear marker on the inflection point.
4. **Symptom prose** (markdown, 1-3 sentences) — what the chart shows in plain English. Magnitude (e.g. "85k → 11k, an 87% drop"), duration ("from 13:11 to 13:18 UTC"), scope ("all four regions").
5. **Cause chart** (timeseries) — the graph that explains the symptom. This is the most important chart in the notebook. It must show the cause/effect relationship clearly. Markers on the same time axis as the symptom chart.
6. **Cause prose** — the mechanism. Three paragraphs maximum. Reference the chart above.
7. **Mechanism evidence** — APM trace excerpts, log patterns, error type aggregations. Each piece of evidence gets its own widget + 1-2 sentence note above. Use:
   - `timeseries` for time-shaped data
   - Code fence for stack traces (preserve indentation)
   - Code fence for log message patterns
   - Trace deep links for representative traces
8. **What we ruled out** (markdown) — bullets, one sentence each. Cite the chart that ruled it out (in this notebook or by URL).
9. **Recommendations** (markdown) — numbered list, each with a concrete action and an owner if known. Don't include items the team hasn't agreed to.

## Widget patterns for common evidence

### Symptom: throughput dropped
```json
{
  "type": "timeseries",
  "title": "<metric> dropped from <baseline> to <trough>",
  "requests": [{
    "response_format": "timeseries",
    "queries": [{ "name": "q1", "data_source": "metrics", "query": "sum:foo.bar{env:prod}.as_rate()" }],
    "formulas": [{ "formula": "q1" }],
    "display_type": "line",
    "style": { "palette": "dog_classic", "line_width": "thick" }
  }],
  "markers": [
    { "value": "y = 0", "display_type": "error dashed", "label": "incident start", "time": "<ISO8601>" },
    { "value": "y = 0", "display_type": "ok dashed",    "label": "recovery",       "time": "<ISO8601>" }
  ],
  "yaxis": { "include_zero": true }
}
```

### Cause: deploy correlation
```json
{
  "type": "timeseries",
  "title": "Two versions running simultaneously during the dip",
  "requests": [{
    "response_format": "timeseries",
    "queries": [{ "name": "v", "data_source": "metrics", "query": "sum:kubernetes.pods.running{kube_service:foo} by {version}" }],
    "formulas": [{ "formula": "v" }],
    "display_type": "area",
    "style": { "palette": "dog_classic" }
  }]
}
```

This is THE pattern for catching rolling-deploy-induced incidents. `pods.running by {version}` will show the old and new versions overlapping during the rollout window. Use it any time the symptom looks like brief, partial unavailability.

### Mechanism: error breakdown over time

Don't put gRPC status codes in a markdown table. Use a stacked `timeseries`:

```json
{
  "type": "timeseries",
  "title": "<service> client errors to <upstream> by gRPC status code",
  "requests": [{
    "response_format": "timeseries",
    "queries": [{
      "name": "errs",
      "data_source": "apm_dependency_stats",
      "query": "errors{service:foo,resource_name:\"...\"} by {grpc.code}"
    }],
    "formulas": [{ "formula": "errs" }],
    "display_type": "bars",
    "style": { "palette": "warm" }
  }]
}
```

If you can't find an APM dependency stat that splits by status code, fall back to **separate queries per code, one stacked-bar series each**. Don't fall back to a Markdown table.

### Stack traces and log lines

Use a `note` widget with a single fenced code block. Keep it tight (≤30 lines). For longer traces, link to the trace deep link in the Datadog UI:

```
[trace AZ34RM... in flamegraph](https://rokt.datadoghq.com/apm/trace/<trace_id>)
```

### Logs at the time of incident

Use `list_stream` with `event_type: logs` and a query scoped to the incident window:

```json
{
  "type": "list_stream",
  "title": "transactions-api errors during dip onset",
  "requests": [{
    "response_format": "event_list",
    "query": {
      "data_source": "logs_stream",
      "query_string": "service:transactions-api status:error env:prod \"gRPC call failed\"",
      "indexes": ["*"],
      "storage": "hot"
    },
    "columns": [
      { "field": "timestamp",        "width": "auto" },
      { "field": "host",             "width": "auto" },
      { "field": "@grpc_code",       "width": "auto" },
      { "field": "content",          "width": "auto" }
    ]
  }]
}
```

## Authoring workflow

1. **Investigate first.** Don't open the notebook authoring tool until you have the conclusion. The notebook is the writeup, not the workspace.
2. **Sketch the cell list.** Title → TL;DR → 3-6 evidence widgets → recommendations. Write it as a numbered list before generating any JSON.
3. **For each widget, write the question first.** The note cell above it. Then choose the widget that answers it.
4. **Build the JSON in one batch.** Use `datadog_create_datadog_notebook` with the full `cells` array. Don't iteratively append unless you're updating an existing notebook.
5. **Verify the queries.** Before submitting, mentally trace each query: does the metric exist? Does it have the right tags? Did it return data when you ran it during investigation? If you don't know, run it via `datadog_get_datadog_metric` first.
6. **Check the rendered notebook.** Open the URL after creation. Look for: missing data, illegible tables, code fences with non-code content, charts with too many series, missing markers.

## Common mistakes to avoid

- **Markdown tables of numeric time-series data** — always replace with a chart. The reader can't compare 12 numbers across rows.
- **Code fences for tables** — same problem, plus monospace doesn't fix alignment in notebook markdown.
- **Stacking too much in one chart** — if one chart has 4+ series with different y-axis scales, split it into multiple charts.
- **Showing only metrics** — without APM and logs, you have shape but no mechanism.
- **Speculation as conclusion** — if you ranked candidate causes "A most likely, B less likely", you didn't finish investigating. Either prove A or admit you don't know.
- **Burying the lede** — TL;DR must contain the answer. Don't make the reader scroll.
- **Time zones** — always use UTC in notebook prose. Convert from local time if needed and label clearly.
- **Adding placeholder/decoration cells** — empty markdown cells, decorative emoji, "thanks for reading" — strip them out.

## Self-review checklist

Before finalizing the notebook, verify:

- [ ] Title states the conclusion in one line
- [ ] TL;DR cell is the first cell
- [ ] Every numeric claim is anchored to a chart
- [ ] Zero markdown tables of numeric data
- [ ] Zero code fences containing non-code content
- [ ] Charts have markers on incident inflection points
- [ ] At least one APM piece of evidence (trace deep link, error.type aggregation, or span query)
- [ ] At least one logs piece of evidence (log pattern, list_stream, or sample log lines)
- [ ] At least one metrics piece of evidence (rate, count, or distribution chart)
- [ ] Recommendations section has concrete actions, not vague "investigate further"
- [ ] American English spelling throughout
- [ ] No emoji
