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

Run queries via the helper script:

```bash
# Simple query
python3 ~/.pi/agent/skills/spark-connect/query.py "SELECT 1 as test"

# Query with row limit
python3 ~/.pi/agent/skills/spark-connect/query.py --limit 20 "SELECT * FROM datalake.lake_customerprofile_playground.customerprofile"

# Describe a table schema
python3 ~/.pi/agent/skills/spark-connect/query.py --schema "datalake.lake_customerprofile_playground.customerprofile"

# Count rows
python3 ~/.pi/agent/skills/spark-connect/query.py --count "datalake.lake_customerprofile_playground.customerprofile"

# Output as JSON (for programmatic use)
python3 ~/.pi/agent/skills/spark-connect/query.py --format json "SELECT * FROM table LIMIT 10"

# Output as CSV
python3 ~/.pi/agent/skills/spark-connect/query.py --format csv "SELECT * FROM table LIMIT 10"

# Read SQL from file
python3 ~/.pi/agent/skills/spark-connect/query.py --file query.sql

# Set up venv without running a query (first-time setup)
python3 ~/.pi/agent/skills/spark-connect/query.py --setup
```

The script auto-creates a Python venv with `pyspark[connect]==3.5.5` on first run.
Subsequent runs reuse the cached venv at `/tmp/spark-connect-venv`.

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

Three-part names: `catalog.database.table`

```sql
SELECT * FROM datalake.lake_customerprofile_playground.customerprofile LIMIT 10
```

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

| Table | Database | Notes |
|-------|----------|-------|
| `customerprofile` | `lake_customerprofile_playground` | Production FeatureStore (610M+ rows) |
| `consumerprofile_run_*` | `lake_customerprofile_playground` | Per-run profile tables |
| `jinli_pivoted_canonicalizedcaptureattribute` | `lake_trashbin` | Session attributes (~25B+ rows) |
| `rainbow_emails` | `lake_customerprofile_playground` | Rainbow table emails |

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

