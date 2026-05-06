# Rokt Datalake Query Patterns

All tables in the datalake are **Apache Iceberg** tables. Always consider Iceberg metadata
tables and partition structure when planning queries.

## Step 0: ALWAYS Inspect Table First

**Before writing any data query, run these two commands:**

```bash
# 1. Table properties and partition info
.venv-spark/bin/python <skill_path>/scripts/run_query.py \
  --sql "DESCRIBE TABLE EXTENDED db.schema.table" --no-limit

# 2. Partition statistics (Iceberg metadata table)
.venv-spark/bin/python <skill_path>/scripts/run_query.py \
  --sql "SELECT partition, record_count, file_count FROM db.schema.table.partitions ORDER BY file_count DESC" --no-limit
```

From `DESCRIBE TABLE EXTENDED`, note:
- **Partition columns** — filter on these for efficient scans
- **write.target-file-size-bytes** — expected file size (default 512MB)
- **write.distribution-mode** — how data is distributed on write
- **Table location** — S3 path for the table data

## Schema Exploration

```bash
# List all databases
.venv-spark/bin/python <skill_path>/scripts/run_query.py --sql "SHOW DATABASES" --no-limit

# List tables in a database
.venv-spark/bin/python <skill_path>/scripts/run_query.py --sql "SHOW TABLES IN datalake.lake_rdn_enriched" --no-limit

# Describe a table's schema
.venv-spark/bin/python <skill_path>/scripts/run_query.py --sql "DESCRIBE TABLE datalake.lake_rdn_enriched.impression" --no-limit

# Extended table info (partitions, storage, properties)
.venv-spark/bin/python <skill_path>/scripts/run_query.py --sql "DESCRIBE TABLE EXTENDED datalake.lake_rdn_enriched.impression" --no-limit
```

## Table Stats via Iceberg Metadata Tables

When the user asks for table statistics (row counts, file counts, snapshot info), use
Iceberg metadata tables instead of scanning the full table. This is much faster.

```bash
# Quick table stats from .files metadata (no full table scan!)
.venv-spark/bin/python <skill_path>/scripts/run_query.py --sql "
  SELECT
    COUNT(*) AS total_files,
    SUM(record_count) AS total_records,
    SUM(file_size_in_bytes) AS total_bytes,
    ROUND(AVG(file_size_in_bytes) / 1048576, 2) AS avg_file_mb
  FROM db.schema.table.files
  WHERE content = 0
" --no-limit

# Partition-level stats from .partitions metadata
.venv-spark/bin/python <skill_path>/scripts/run_query.py --sql "
  SELECT partition, record_count, file_count
  FROM db.schema.table.partitions
  ORDER BY record_count DESC
" --no-limit

# Recent snapshots (shows write cadence and record growth)
.venv-spark/bin/python <skill_path>/scripts/run_query.py --sql "
  SELECT committed_at, snapshot_id, operation,
         summary['added-data-files'] AS added_files,
         summary['added-records'] AS added_records,
         summary['total-records'] AS total_records
  FROM db.schema.table.snapshots
  ORDER BY committed_at DESC
  LIMIT 20
" --no-limit

# Table version history
.venv-spark/bin/python <skill_path>/scripts/run_query.py --sql "
  SELECT * FROM db.schema.table.history
  ORDER BY made_current_at DESC
" --no-limit
```

## Time Travel

```bash
# Query table at a specific snapshot ID
.venv-spark/bin/python <skill_path>/scripts/run_query.py --sql "
  SELECT * FROM db.schema.table VERSION AS OF 1234567890 LIMIT 100
"

# Query table at a specific timestamp
.venv-spark/bin/python <skill_path>/scripts/run_query.py --sql "
  SELECT * FROM db.schema.table TIMESTAMP AS OF '2024-06-15 10:00:00' LIMIT 100
"
```

## Data Sampling

```bash
# Quick sample (auto-limited to 1000 rows)
.venv-spark/bin/python <skill_path>/scripts/run_query.py \
  --sql "SELECT * FROM datalake.lake_rdn_enriched.impression"

# With explicit limit
.venv-spark/bin/python <skill_path>/scripts/run_query.py \
  --sql "SELECT col1, col2, col3 FROM datalake.lake_rdn_enriched.impression LIMIT 100"
```

## Aggregation Patterns

```bash
# Group by with aggregation
.venv-spark/bin/python <skill_path>/scripts/run_query.py --sql "
  SELECT date_col, COUNT(*) as cnt, AVG(metric) as avg_metric
  FROM datalake.lake_rdn_enriched.impression
  WHERE date_col >= '2024-01-01'
  GROUP BY date_col
  ORDER BY date_col
"
```

## Performance Diagnostic: Small File Problem

When a user reports slow queries or table performance issues, **always run the small file
diagnostic first** using the `.files` metadata table. Small files (< 8MB) cause excessive
task overhead and slow scans.

```bash
# Step 1: File size distribution (overall)
.venv-spark/bin/python <skill_path>/scripts/run_query.py --sql "
  SELECT
    COUNT(*) AS total_files,
    SUM(file_size_in_bytes) AS total_bytes,
    ROUND(AVG(file_size_in_bytes) / 1048576, 2) AS avg_mb,
    ROUND(MIN(file_size_in_bytes) / 1048576, 2) AS min_mb,
    ROUND(MAX(file_size_in_bytes) / 1048576, 2) AS max_mb,
    SUM(CASE WHEN file_size_in_bytes < 8388608 THEN 1 ELSE 0 END) AS small_files_under_8mb,
    SUM(CASE WHEN file_size_in_bytes < 1048576 THEN 1 ELSE 0 END) AS tiny_files_under_1mb
  FROM db.schema.table.files
  WHERE content = 0
" --no-limit

# Step 2: File size histogram
.venv-spark/bin/python <skill_path>/scripts/run_query.py --sql "
  SELECT
    CASE
      WHEN file_size_in_bytes < 1048576 THEN '< 1 MB'
      WHEN file_size_in_bytes < 8388608 THEN '1-8 MB'
      WHEN file_size_in_bytes < 33554432 THEN '8-32 MB'
      WHEN file_size_in_bytes < 134217728 THEN '32-128 MB'
      WHEN file_size_in_bytes < 536870912 THEN '128-512 MB'
      ELSE '>= 512 MB'
    END AS size_bucket,
    COUNT(*) AS file_count,
    SUM(record_count) AS total_records
  FROM db.schema.table.files
  WHERE content = 0
  GROUP BY 1
  ORDER BY MIN(file_size_in_bytes)
" --no-limit

# Step 3: Per-partition file breakdown (find worst partitions)
.venv-spark/bin/python <skill_path>/scripts/run_query.py --sql "
  SELECT
    partition,
    COUNT(*) AS file_count,
    ROUND(SUM(file_size_in_bytes) / 1073741824, 2) AS total_gb,
    ROUND(AVG(file_size_in_bytes) / 1048576, 2) AS avg_mb,
    SUM(CASE WHEN file_size_in_bytes < 8388608 THEN 1 ELSE 0 END) AS small_files
  FROM db.schema.table.files
  WHERE content = 0
  GROUP BY partition
  HAVING COUNT(*) > 10
  ORDER BY small_files DESC
  LIMIT 30
" --no-limit
```

**Diagnosis guide:**
- `> 50%` files under 8MB = severe small file problem, recommend compaction
- `avg_mb < 32` = files much smaller than target, investigate write frequency
- Large `file_count` per partition with low `avg_mb` = partition too hot with frequent small writes

## Performance Diagnostic: AQE Coalescing Bottleneck

When a query with complex per-row operations (array lambdas, nested `filter()`, `transform()`,
`aggregate()`, UDFs) is slow despite producing few output rows, the problem is likely **AQE
coalescing post-shuffle partitions to 1**.

### How to Identify

Use `monitor_job.py --diagnose` — it detects this automatically. Manual signs:

1. A post-shuffle stage has **1-2 tasks** (visible in Spark UI or `--stages`)
2. The stage's shuffle read is small (< 256 MB) but execution time is long
3. The prior stage had many tasks and reduced data significantly
4. The query uses CPU-heavy operations: `filter()`, `transform()`, `element_at()`,
   `aggregate()` on array columns, or complex UDFs

### What Happens

```
AQE config: spark.sql.adaptive.coalescePartitions.enabled = true (default)
            spark.sql.adaptive.advisoryPartitionSizeInBytes = 64m-256m (default)

Stage pipeline:
  Stage A (scan):  131,944 tasks → 1.7 TB input → 7 GB shuffle write
  Stage B (agg):     4,096 tasks → 7 GB shuffle read → 84 MB shuffle write
  Stage C (final):       1 task  → 84 MB shuffle read, 1,572 records ← BOTTLENECK

AQE decision: 84 MB < advisoryPartitionSizeInBytes → coalesce to 1 partition
Problem: AQE optimizes for I/O, not CPU cost. 1,572 records with expensive
         per-row lambdas still takes minutes on a single core.
```

### Fix Options

**Option 1 — REPARTITION hint (recommended for one-off queries):**
```sql
WITH raw AS (
    SELECT /*+ REPARTITION(16) */
        sessionId,
        attributeCustomAudiences,
        ...
    FROM db.schema.table
    WHERE date_col >= '2024-01-01'
)
SELECT
    sessionId,
    -- expensive array operations here
    filter(attributeCustomAudiences, x -> x.field = 'value') AS filtered
FROM raw
```

Place the hint in the subquery/CTE that feeds the CPU-heavy stage. Choose N based
on the number of available cores (8-32 is usually good).

**Option 2 — Reduce advisory partition size (session-level, reusable):**
```sql
SET spark.sql.adaptive.advisoryPartitionSizeInBytes = 5m;

-- Now run your query normally — AQE will create ~17 partitions for 84 MB
SELECT ...
```

Good when you run multiple queries with the same pattern in one session.

**Option 3 — Disable AQE coalescing (session-level, blunt):**
```sql
SET spark.sql.adaptive.coalescePartitions.enabled = false;

-- All 4,096 shuffle partitions are preserved
SELECT ...
```

Use only when Options 1-2 don't apply. This keeps all shuffle partitions which
may waste resources on stages that genuinely benefit from coalescing.

### Decision Guide

| Scenario | Recommended Fix |
|----------|----------------|
| One-off query with complex transforms | `REPARTITION(16)` hint |
| Session with multiple similar queries | `advisoryPartitionSizeInBytes = 5m` |
| Unknown which stage is affected | `coalescePartitions.enabled = false` |
| Query returns many rows (not small output) | Not an AQE issue — look elsewhere |

## Post-Query Local Analysis

After a query writes its CSV, analyze further with Pandas:

```python
import pandas as pd

# Read the CSV output
pdf = pd.read_csv("/tmp/spark-results/spark_<timestamp>.csv")

# Basic stats
pdf.describe()

# Group by
pdf.groupby("col").agg({"metric": ["mean", "sum"]})
```

## Spark SQL Syntax Notes

This is **Spark SQL**, not Trino. Key differences:
- Use `STRING` instead of `VARCHAR` (or `VARCHAR(n)` with explicit length)
- Use `INTERVAL 7 MONTH` not `INTERVAL '7' MONTH`
- String literals use single quotes: `'value'`
- `date_trunc('month', col)` works the same
- `approx_percentile(col, 0.5)` works the same

## Tips

- **Always inspect table properties and partitions first** before writing queries
- Use Iceberg `.files` and `.snapshots` metadata tables for stats — avoid `COUNT(*)` full scans
- The runner auto-appends `LIMIT 1000` if your query has no LIMIT clause
- Use `--no-limit` for schema exploration and metadata table queries
- For large exports, use `--limit N` to control the result size
- Results are written to `/tmp/spark-results/` as CSV files
- Always aggregate in Spark first before pulling large datasets locally
