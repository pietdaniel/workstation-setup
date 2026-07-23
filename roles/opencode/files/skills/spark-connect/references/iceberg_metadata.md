# Iceberg Metadata Tables Reference

Tables in the datalake are Apache Iceberg tables. Iceberg exposes metadata via virtual tables
appended to the table name with a dot suffix.

## Syntax

```sql
SELECT * FROM <catalog>.<database>.<table>.<metadata_table>
-- Example:
SELECT * FROM aws_legacy_datalake.lake_rdn_enriched.impression.snapshots
```

## Metadata Tables

### .snapshots

Committed table versions. Use to find snapshot IDs for time travel.

| Column | Type | Description |
|--------|------|-------------|
| committed_at | timestamp | When snapshot was committed |
| snapshot_id | long | Unique snapshot identifier |
| parent_id | long | Parent snapshot ID (null for first) |
| operation | string | append, overwrite, replace, delete |
| manifest_list | string | Path to manifest list file |
| summary | map<string,string> | Snapshot summary (added-records, total-records, etc.) |

```sql
-- Recent snapshots with record counts
SELECT committed_at, snapshot_id, operation,
       summary['added-data-files'] AS added_files,
       summary['added-records'] AS added_records,
       summary['total-records'] AS total_records
FROM db.schema.table.snapshots
ORDER BY committed_at DESC
LIMIT 20
```

### .history

Table version history — which snapshot was current at each point in time.

| Column | Type | Description |
|--------|------|-------------|
| made_current_at | timestamp | When this snapshot became current |
| snapshot_id | long | Snapshot ID |
| parent_id | long | Parent snapshot ID |
| is_current_ancestor | boolean | Whether this is an ancestor of the current snapshot |

### .files

Data files in the **current snapshot**. Essential for diagnosing small file problems.

| Column | Type | Description |
|--------|------|-------------|
| content | int | 0=data, 1=position deletes, 2=equality deletes |
| file_path | string | Full path to the data file |
| file_format | string | PARQUET, ORC, AVRO |
| spec_id | int | Partition spec ID |
| partition | struct | Partition values |
| record_count | long | Number of records in file |
| file_size_in_bytes | long | File size |
| column_sizes | map<int,long> | Size per column ID |
| value_counts | map<int,long> | Non-null value counts per column |
| null_value_counts | map<int,long> | Null counts per column |
| nan_value_counts | map<int,long> | NaN counts per column |
| lower_bounds | map<int,binary> | Column lower bounds |
| upper_bounds | map<int,binary> | Column upper bounds |
| sort_order_id | int | Sort order ID |

```sql
-- Small file diagnostic: file size distribution
SELECT
  COUNT(*) AS total_files,
  SUM(file_size_in_bytes) AS total_bytes,
  AVG(file_size_in_bytes) AS avg_file_bytes,
  MIN(file_size_in_bytes) AS min_file_bytes,
  MAX(file_size_in_bytes) AS max_file_bytes,
  percentile_approx(file_size_in_bytes, 0.5) AS median_file_bytes,
  SUM(CASE WHEN file_size_in_bytes < 8388608 THEN 1 ELSE 0 END) AS small_files_under_8mb,
  SUM(CASE WHEN file_size_in_bytes < 1048576 THEN 1 ELSE 0 END) AS tiny_files_under_1mb
FROM db.schema.table.files
WHERE content = 0
```

### .manifests

Manifest files that organize groups of data files.

| Column | Type | Description |
|--------|------|-------------|
| path | string | Manifest file path |
| length | long | Manifest file length |
| partition_spec_id | int | Partition spec ID |
| added_snapshot_id | long | Snapshot that added this manifest |
| added_data_files_count | int | Data files added |
| existing_data_files_count | int | Existing data files |
| deleted_data_files_count | int | Data files deleted |
| added_rows_count | long | Rows added |
| existing_rows_count | long | Existing rows |
| deleted_rows_count | long | Rows deleted |
| partition_summaries | array<struct> | Partition field summaries |

### .partitions

Partition-level aggregated statistics.

| Column | Type | Description |
|--------|------|-------------|
| partition | struct | Partition values |
| record_count | long | Records in partition |
| file_count | int | Files in partition |
| spec_id | int | Partition spec ID |

```sql
-- Partition stats: find hot/cold partitions
SELECT partition, record_count, file_count,
       record_count / file_count AS avg_records_per_file
FROM db.schema.table.partitions
ORDER BY file_count DESC
LIMIT 50
```

### .metadata_log_entries

Log of metadata file changes.

| Column | Type | Description |
|--------|------|-------------|
| timestamp | timestamp | When metadata was written |
| file | string | Metadata file path |
| latest_snapshot_id | long | Latest snapshot at that point |
| latest_schema_id | int | Latest schema ID |
| latest_sequence_number | long | Latest sequence number |

### .refs

Named references (branches and tags) to snapshots.

| Column | Type | Description |
|--------|------|-------------|
| name | string | Reference name (e.g., "main") |
| type | string | BRANCH or TAG |
| snapshot_id | long | Referenced snapshot ID |
| max_ref_age_in_ms | long | Max ref age |
| min_snapshots_to_keep | int | Min snapshots to retain |
| max_snapshot_age_in_ms | long | Max snapshot age |

### .entries

Detailed manifest entries (data file tracking within manifests).

| Column | Type | Description |
|--------|------|-------------|
| status | int | 0=EXISTING, 1=ADDED, 2=DELETED |
| snapshot_id | long | Snapshot ID for this entry |
| sequence_number | long | Sequence number |
| file_sequence_number | long | File sequence number |
| data_file | struct | Full data file metadata (same fields as .files) |

### .all_data_files / .all_delete_files / .all_entries / .all_manifests

Same schema as their non-prefixed counterparts, but span **all snapshots** (not just current).
Use these when investigating historical file accumulation or orphaned files.

## Time Travel

```sql
-- By snapshot ID (from .snapshots table)
SELECT * FROM db.schema.table VERSION AS OF 1234567890

-- By timestamp
SELECT * FROM db.schema.table TIMESTAMP AS OF '2024-06-15 10:00:00'

-- Combine with metadata tables
SELECT * FROM db.schema.table.files VERSION AS OF 1234567890
```

## Key Table Properties

Inspect table properties to understand partitioning and configuration:

```sql
-- Show all table properties
DESCRIBE TABLE EXTENDED db.schema.table

-- Key properties to look for:
-- write.target-file-size-bytes    (default: 536870912 = 512MB)
-- write.distribution-mode         (none | hash | range)
-- write.parquet.compression-codec (default: zstd)
-- history.expire.max-snapshot-age-ms
-- history.expire.min-snapshots-to-keep
```

## Small File Diagnostic Queries

### Per-partition file size analysis

```sql
SELECT
  partition,
  COUNT(*) AS file_count,
  SUM(file_size_in_bytes) AS total_bytes,
  ROUND(AVG(file_size_in_bytes) / 1048576, 2) AS avg_mb,
  SUM(CASE WHEN file_size_in_bytes < 8388608 THEN 1 ELSE 0 END) AS small_files
FROM db.schema.table.files
WHERE content = 0
GROUP BY partition
HAVING COUNT(*) > 10
ORDER BY small_files DESC
LIMIT 30
```

### File size histogram

```sql
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
```
