---
name: trino-exec
description: Run Trino SQL against the Rokt datalake (polaris_datalake, aws_legacy_datalake) without re-authenticating on every query. Use whenever a task needs ad-hoc Trino/datalake SQL — schema discovery, row counts, lineage queries, fill-rate checks, QA comparisons — instead of the Java `trino` CLI (which triggers a fresh SSO handshake per invocation). Triggers: trino query, run SQL against the lake, query polaris_datalake, query lake_txn/lake_rdn tables, datalake SELECT, information_schema lookup, trino auth loop, re-auth every query.
---

# trino-exec

Run Trino SQL with a **persistent OAuth2 token cache**. The Java `trino` CLI
holds its SSO token in process memory only, so every `trino --execute`
invocation performs a fresh OAuth handshake. This skill's runner uses the
Python client with the `external-authentication-token-cache` extra, which
persists the JWT in the macOS Keychain — the browser dance happens at most
once per token lifetime, across any number of runs and shell sessions.

## The one command

```bash
uv run ~/.config/opencode/skills/trino-exec/scripts/trino_exec.py -e "<SQL>"
```

`uv` resolves the dependencies from the script's inline PEP 723 header
(`trino[external-authentication-token-cache]`) into a cached venv — no
manual pip install, no repo virtualenv pollution. First run downloads
packages (~seconds); subsequent runs are instant.

## First-time auth (once per token lifetime)

On the very first query (or after token expiry) the script prints:

```
Open the following URL in browser for the external authentication:
https://trino-engine-1-g-us-west-2.roktinternal.com/oauth2/token/initiate/...
```

It also tries to open the browser automatically. **The human must complete
the SSO flow** — tell the user and wait. The script polls for up to ~5
minutes (`--auth-attempts 30`, ~10s each). After success the token is stored
in the Keychain and subsequent runs are silent.

Agent behavior: when you see the auth URL in output, surface it to the user,
ask them to complete SSO, and re-run only if the poll window expired.

## Usage

```bash
# Inline SQL (repeatable -e; each may hold multiple ;-separated statements)
uv run .../trino_exec.py -e "SELECT 1" -e "SELECT 2"

# Multiple statements in one invocation — one connection, zero extra auth
uv run .../trino_exec.py -e "SHOW CATALOGS; SHOW SCHEMAS IN polaris_datalake"

# From a file, or stdin
uv run .../trino_exec.py -f query.sql
echo "SELECT count(*) FROM system.runtime.nodes" | uv run .../trino_exec.py

# Output formats: csv (default), tsv, json, jsonl, table
uv run .../trino_exec.py -e "SHOW CATALOGS" --format table
uv run .../trino_exec.py -e "SELECT ..." --format json -o out.json

# Row cap (default 1000; stderr warns when truncated). 0 = unlimited.
uv run .../trino_exec.py -e "SELECT * FROM huge_table" --max-rows 50
uv run .../trino_exec.py -e "SELECT ..." --max-rows 0

# Catalog / schema defaults
uv run .../trino_exec.py --catalog aws_legacy_datalake -e "SHOW SCHEMAS"
uv run .../trino_exec.py --schema "lake_txn.ledger.enriched.primary" -e "SHOW TABLES"

# Session properties
uv run .../trino_exec.py --session-property query_max_run_time=10m -e "..."
```

### Flags reference

| Flag | Default | Notes |
|---|---|---|
| `-e/--execute SQL` | — | repeatable; multi-statement via `;` |
| `-f/--file PATH` | — | `-` = stdin |
| `--server URL` | `https://trino-engine-1-g-us-west-2.roktinternal.com` | env `TRINO_SERVER` |
| `--catalog NAME` | `polaris_datalake` | env `TRINO_CATALOG` |
| `--schema NAME` | none | quote-free here; quoting rules below apply inside SQL |
| `--user NAME` | **unset** | leave unset — see impersonation note |
| `--format` | `csv` | `csv` `tsv` `json` `jsonl` `table` |
| `--no-header` | off | csv/tsv/table |
| `--max-rows N` | 1000 | per statement; `0` = unlimited; truncation noted on stderr |
| `-o/--output PATH` | stdout | |
| `--session-property K=V` | — | repeatable |
| `-q/--quiet` | off | suppress per-statement stats on stderr |
| `--auth-attempts N` | 30 | ~10s each; only matters during first auth |
| `--clear-token-cache` | — | delete cached token from Keychain and exit |

Per-statement stats (row count, elapsed, `query_id`) go to **stderr**, so
stdout stays clean for piping/CSV capture.

## Environment specifics (Rokt)

- **Server:** `https://trino-engine-1-g-us-west-2.roktinternal.com` (Trino
  engine 1-g, us-west-2). Override with `--server`/`TRINO_SERVER` for other
  engines.
- **Catalogs:** `polaris_datalake` (new-world Iceberg REST catalog),
  `aws_legacy_datalake` (Glue legacy), `hive_aws_legacy_datalake`,
  `external_storage_loader`, `rokt_aws_cost`, `system`.
- **Dotted Polaris schemas must be double-quoted in SQL:**
  `polaris_datalake."lake_txn.ledger.enriched.primary".conversion`
- `SHOW SCHEMAS ... LIKE` treats `_` and `.` as wildcards awkwardly; prefer
  `SELECT schema_name FROM <catalog>.information_schema.schemata WHERE schema_name LIKE '...'`.
- Always filter partition columns (`eventtime`, `dlqat`) and `LIMIT` — see
  the repo-local `ledger-data-query` skill for lake query patterns. This
  skill is the **execution mechanism**; that one is the **query cookbook**.

## Impersonation gotcha (do NOT pass --user)

The OAuth token already carries the principal (e.g. `daniel.piet`). If you
pass `--user` with anything else (e.g. `$(whoami)` → `rokt`), the server
rejects with:

```
Access Denied: User daniel.piet cannot impersonate user rokt
```

Leave `--user` unset — the server derives the user from the token. Only set
it if deliberately impersonating and the server's rules allow it. Note the
keyring cache key differs with/without user (`<host>` vs `<host>@<user>`),
so switching `--user` also switches which cached token is used.

## Token cache internals

- Storage: OS keyring (macOS Keychain). Service = `trino-engine-1-g-us-west-2.roktinternal.com`
  (or `<host>@<user>` if `--user` was set); username = `token`, with overflow
  shards `token__1..n` because Keychain caps entry size and JWTs are long.
- Expiry: when the JWT expires, the server returns 401, the client discards
  the cached token, and the browser flow triggers again — expected, not a bug.
- Force re-auth / fix a corrupt cache:
  ```bash
  uv run .../trino_exec.py --clear-token-cache
  ```
- The cache is shared with anything else using the trino Python client with
  `OAuth2Authentication` on the same host key (e.g.
  `rokt-flink/scripts/generate_ledger_fill_rates_xlsx.py`).

## Failure modes

| Symptom | Cause | Fix |
|---|---|---|
| `Exceeded max attempts while getting the token` | Human didn't finish browser SSO within the poll window | Re-run; ask user to complete SSO; raise `--auth-attempts` |
| `cannot impersonate user X` | `--user` mismatch with token principal | Drop `--user` |
| `401` loop / instant re-auth every run | Corrupt or expired-but-stuck keyring entry | `--clear-token-cache`, re-run |
| `keyring` errors in a headless/SSH session | No Keychain access | Run once in a local GUI session, or accept per-run auth |
| Slow first invocation | uv resolving deps | One-time; cached afterwards |
| `TrinoQueryError ... Schema ... does not exist` | Missed double quotes on dotted Polaris schema | Quote it: `"lake_txn.ledger.enriched.primary"` |

## When NOT to use this

- Heavy analytics that time out in Trino → use the `spark-connect` skill.
- Interactive multi-hour exploration where the user asked for a specific
  Trino MCP server → use that MCP.
- One-off queries where the Java CLI is already mid-session — fine to keep
  using it; this skill exists so **fresh processes** don't re-auth.
