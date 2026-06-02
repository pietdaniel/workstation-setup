---
name: spark-connect
description: >-
  Query and manage Iceberg tables in the Rokt datalake via Spark Connect.
  Use when running Spark SQL queries, inspecting Iceberg table schemas,
  counting rows, creating or modifying tables, running compaction,
  performing data migrations, or working with datalake data. Also use
  when the user mentions Spark, PySpark, Iceberg, datalake, lake_*
  tables, or Spark Connect.
---

# Spark Connect — Rokt Datalake

## Quick Reference

Run queries via the helper script. **Always invoke with system `python3`** — the
script auto-bootstraps and re-execs itself inside a venv. Do **not** `source`
the venv first; that is unnecessary and easy to forget.

```bash
# SELECT — auto-appends LIMIT 1000 if no LIMIT present
python3 ~/.config/opencode/skills/spark-connect/query.py \
    --sql "SELECT * FROM datalake.lake_customerprofile_playground.customerprofile"

# SELECT with explicit row limit
python3 ~/.config/opencode/skills/spark-connect/query.py --limit 20 \
    --sql "SELECT * FROM datalake.lake_customerprofile_playground.customerprofile"

# SELECT with no auto-LIMIT (e.g. for full aggregations)
python3 ~/.config/opencode/skills/spark-connect/query.py --no-limit \
    --sql "SELECT COUNT(*) FROM datalake.lake_customerprofile_playground.customerprofile"

# Schema / discovery — SHOW / DESCRIBE / EXPLAIN skip LIMIT injection automatically
python3 ~/.config/opencode/skills/spark-connect/query.py \
    --sql "DESCRIBE TABLE datalake.lake_customerprofile_playground.customerprofile"

python3 ~/.config/opencode/skills/spark-connect/query.py \
    --sql "SHOW TABLES IN datalake.lake_customerprofile_playground"

# Read SQL from file
python3 ~/.config/opencode/skills/spark-connect/query.py --file query.sql

# Override output CSV location (default: /tmp/spark-results/spark_<ts>.csv)
python3 ~/.config/opencode/skills/spark-connect/query.py \
    --sql "SELECT ..." --output /tmp/my_results.csv
```

### Flags

| Flag | Meaning |
|------|---------|
| `--sql STR` | SQL string (mutually exclusive with `--file`) |
| `--file PATH` | Read SQL from a file |
| `--limit N` | Override the default auto-LIMIT (1000) for SELECTs |
| `--no-limit` | Disable auto-LIMIT entirely |
| `--output PATH` | Write CSV results to a specific path |

The script rejects mutating SQL (INSERT/UPDATE/DELETE/DDL). For writes, drop
into a custom PySpark script via `scripts/connect.py`.

### Venv bootstrap

First run creates `/tmp/spark-connect-venv` with
`pyspark[connect]==3.5.5`, `pandas`, `pyarrow`, `setuptools`. Subsequent runs
reuse it. Requires `uv` on PATH (`brew install uv`).

Override the venv location with `SPARK_CONNECT_VENV=/path/to/venv`.

### Common pitfalls (learned the hard way)

- **Don't `source` the venv manually.** Run `python3 query.py ...` with the
  system interpreter — it re-execs itself inside the venv. Activating first
  works but adds steps and obscures what's happening.
- **Don't append `LIMIT` to `SHOW` / `DESCRIBE` / `EXPLAIN`.** The script
  detects these and skips the LIMIT, but if you build SQL yourself remember
  these statements reject a trailing LIMIT at parse time.
- **Polaris dotted namespaces:** see "Table Naming Convention" below — getting
  this wrong yields confusing `EntityNotFoundException` or `TABLE_OR_VIEW_NOT_FOUND`
  errors.

## Endpoints

| Endpoint | URL |
|----------|-----|
| **Prod (us-west-2)** | `sc://spark-connect-us-west-2.roktinternal.com:15002/;use_ssl=true` |
| **Stage (us-west-2)** | `sc://spark-connect-us-west-2.stage.roktinternal.com:15002/;use_ssl=true` |
| **Spark UI (prod)** | `https://spark-connect-us-west-2.roktinternal.com:4040` |

Override with `SPARK_CONNECT_URL` env var.

## Available Catalogs

| Catalog | Type | Description |
|---------|------|-------------|
| `datalake` | AWS Glue | **Default.** Main datalake catalog |
| `trino` | AWS Glue | Trino-compatible catalog (prod only) |
| `iceberg` | AWS Glue | Identity builder catalog (prod only) |
| `polaris_datalake` | Polaris REST | Polaris catalog (stage & prod) |

## Table Naming Convention

### Glue catalogs (`datalake`, `trino`, `iceberg`)

Three-part names: `catalog.database.table`

```sql
SELECT * FROM datalake.lake_customerprofile_playground.customerprofile LIMIT 10
```

### Polaris catalog (`polaris_datalake`) — multi-level namespaces

Polaris namespaces are hierarchical and frequently contain dots in their
*displayed* name. Spark Connect resolves each segment as a separate namespace
level, so write them with bare dots (no quoting needed in Spark):

```sql
-- Real Rokt example: the namespace tree is
--   polaris_datalake
--     └── lake_txn
--         └── ledger
--             └── enriched
--                 └── primary
--                     ├── viewableimpression
--                     ├── pricedimpression
--                     └── ...
SELECT partnerId, COUNT(*)
FROM polaris_datalake.lake_txn.ledger.enriched.primary.viewableimpression
WHERE eventTime >= CURRENT_TIMESTAMP() - INTERVAL 3 HOURS
GROUP BY partnerId
```

Discover the tree with:

```sql
SHOW NAMESPACES IN polaris_datalake
SHOW NAMESPACES IN polaris_datalake.lake_txn
SHOW NAMESPACES IN polaris_datalake.lake_txn.ledger.enriched
SHOW TABLES     IN polaris_datalake.lake_txn.ledger.enriched.primary
```

### Trino (Superset) quoting differs

The same Polaris table addressed from **Trino** needs the namespace as one
quoted identifier — bare dots make Trino guess at catalog/schema/table split
and fail with `SYNTAX_ERROR`:

```sql
-- Spark Connect
FROM polaris_datalake.lake_txn.ledger.enriched.primary.viewableimpression

-- Trino / Superset (note the quoted namespace)
FROM polaris_datalake."lake_txn.ledger.enriched.primary".viewableimpression
```

See "Spark vs Trino dialect" below for the rest of the gotchas.

## Common Databases

| Database | Contents |
|----------|----------|
| `lake_customerprofile_playground` | Consumer profiles, feature store tables |
| `lake_trashbin` | Scratch/temp tables, session attributes |
| `lake_ca` | Capture attributes |
| `lake_selector` | Selector/experiment data |
| `lake_thirdpartydata` | Experian, third-party enrichment |

## Discovery Queries

```sql
-- List databases in a catalog
SHOW DATABASES IN datalake

-- List tables in a database
SHOW TABLES IN datalake.lake_customerprofile_playground

-- Describe table schema
DESCRIBE EXTENDED datalake.lake_customerprofile_playground.customerprofile

-- Iceberg metadata
SELECT * FROM datalake.lake_customerprofile_playground.customerprofile.snapshots ORDER BY committed_at DESC
SELECT * FROM datalake.lake_customerprofile_playground.customerprofile.files
SELECT * FROM datalake.lake_customerprofile_playground.customerprofile.history
```

## Write Operations

Spark Connect is **fully read-write**. All Iceberg DDL/DML is supported:

```sql
-- Create table (CTAS)
CREATE TABLE datalake.db.my_table USING iceberg AS SELECT * FROM source

-- Insert / Append
INSERT INTO datalake.db.my_table SELECT * FROM source

-- Update
UPDATE datalake.db.my_table SET col = value WHERE condition

-- Delete
DELETE FROM datalake.db.my_table WHERE condition

-- Compaction
CALL datalake.system.rewrite_data_files(table => 'datalake.db.table', strategy => 'sort', ...)

-- Alter
ALTER TABLE datalake.db.my_table ADD COLUMN new_col STRING
ALTER TABLE datalake.db.my_table WRITE ORDERED BY col1, col2
```

## Nested Struct Patterns

Datalake tables often store `ARRAY<STRUCT<...>>`. Use FILTER/TRANSFORM instead of EXPLODE:

```sql
SELECT
    sessionId,
    TRANSFORM(
        FILTER(objectData.attributes, x -> LOWER(x.name) LIKE '%email%'),
        x -> CONCAT(x.name, '=', COALESCE(x.value, 'NULL'))
    ) AS filtered
FROM table
WHERE SIZE(FILTER(objectData.attributes, x -> LOWER(x.name) LIKE '%email%')) > 0
LIMIT 10
```

## Key Tables

| Table | Catalog / namespace | Notes |
|-------|---------------------|-------|
| `customerprofile` | `datalake.lake_customerprofile_playground` | Production FeatureStore (610M+ rows) |
| `consumerprofile_run_*` | `datalake.lake_customerprofile_playground` | Per-run profile tables |
| `jinli_pivoted_canonicalizedcaptureattribute` | `datalake.lake_trashbin` | Session attributes (~25B+ rows) |
| `rainbow_emails` | `datalake.lake_customerprofile_playground` | Rainbow table emails |
| `priced_referral` | `polaris_datalake.lake_txn.transactions.silver.primary` | v4 silver priced-referral (Polaris/Iceberg); partitioned by `day(eventTime)` |
| `viewableimpression` | `polaris_datalake.lake_txn.ledger.enriched.primary` | Viewable impressions; partitioned by `day(eventTime)`. `advertiserId` is mostly NULL here — use `partnerId` for publisher account aggregation |
| `pricedimpression` | `polaris_datalake.lake_txn.ledger.enriched.primary` | Priced impressions; sibling of viewableimpression |

## Spark vs Trino dialect

The same datalake is queryable from Spark Connect **and** Trino (Superset).
A query that runs in Spark often will not run in Trino — translate before
pasting into Superset.

| Concept | Spark Connect | Trino / Superset |
|---------|---------------|------------------|
| Current time | `CURRENT_TIMESTAMP()` (parens OK) | `current_timestamp` (no parens — it's a reserved word, not a function) |
| Intervals | `INTERVAL 3 HOURS` | `INTERVAL '3' HOUR` (quoted number, singular unit) |
| Polaris namespace | `polaris_datalake.lake_txn.ledger.enriched.primary.tbl` | `polaris_datalake."lake_txn.ledger.enriched.primary".tbl` |
| JSON extract | `get_json_object(data, '$.rokt.txnShadow')` | `json_extract_scalar(data, '$["rokt.txnShadow"]')` (dot-keys need bracket notation) |
| Date parsing | `to_date('2024-01-01')` | `date '2024-01-01'` or `from_iso8601_date(...)` |
| String concat | `CONCAT(a, b)` or `a || b` | `a || b` (CONCAT also works but `||` is canonical) |

The user-visible failure mode is almost always
`TrinoUserError(... SYNTAX_ERROR ...)` at the timestamp or interval call site.

## Known Issues

- **DELTA_LENGTH_BYTE_ARRAY corruption:** Spark 3.5.5 corrupts low-cardinality strings from
  Go-written parquet. Vectorized reader is disabled server-side as workaround
  (`spark.sql.parquet.enableVectorizedReader=false`).
- **Arrow OOM on nested structs:** Use `.collect()` not `.toPandas()` when querying tables
  with `ARRAY<STRUCT<...>>` columns (only relevant for custom PySpark scripts, not this tool).
- **Session scope:** `USE catalog.database` is session-scoped. Always use fully-qualified
  table names in scripts.

## Cluster Resources

- **Driver:** 16 cores, 100GB Spark memory
- **Executors:** Up to 384 × (23 cores, 80GB each) with dynamic allocation
- **Idle timeout:** Executors reclaimed after 10s idle
- **Network:** Only accessible from SDP network (10.0.0.0/8)

