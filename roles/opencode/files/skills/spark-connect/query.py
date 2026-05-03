#!/usr/bin/env python3
"""
Spark Connect query runner — executes a read-only SQL query, writes results
to a local CSV via Apache Arrow, and prints a compact summary to stdout.

Usage:
    python run_query.py --sql "SELECT ..."
    python run_query.py --file query.sql
    python run_query.py --sql "SELECT ..." --limit 5000
    python run_query.py --sql "SELECT ..." --output /tmp/my_results.csv
"""

import argparse
import os
import re
import sys
import time
from datetime import datetime
from pathlib import Path

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------
SPARK_CONNECT_HOST = "spark-connect-us-west-2.roktinternal.com"
SPARK_CONNECT_PORT = "15002"
SPARK_CONNECT_URL = f"sc://{SPARK_CONNECT_HOST}:{SPARK_CONNECT_PORT}/;use_ssl=true"
SPARK_UI_URL = f"https://{SPARK_CONNECT_HOST}"

RESULTS_DIR = Path("/tmp/spark-results")
DEFAULT_LIMIT = 1000
PREVIEW_ROWS = 5

# SQL patterns that mutate data — reject immediately
_MUTATE_PATTERNS = re.compile(
    r"\b(INSERT\s+INTO|DELETE\s+FROM|UPDATE\s+\S+\s+SET|MERGE\s+INTO|"
    r"CREATE\s+(TABLE|DATABASE|VIEW|SCHEMA)|"
    r"DROP\s+(TABLE|DATABASE|VIEW|SCHEMA)|"
    r"ALTER\s+(TABLE|DATABASE)|TRUNCATE|RENAME)\b",
    re.IGNORECASE,
)


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
def _is_read_only(sql: str) -> bool:
    """Return True if the SQL is a safe read-only statement."""
    return _MUTATE_PATTERNS.search(sql) is None


def _has_limit(sql: str) -> bool:
    """Check whether the outermost query already contains a LIMIT clause."""
    # Strip trailing whitespace / semicolons
    stripped = sql.rstrip().rstrip(";").rstrip()
    return bool(re.search(r"\bLIMIT\s+\d+\s*$", stripped, re.IGNORECASE))


def _append_limit(sql: str, limit: int) -> str:
    """Append a LIMIT clause to the SQL if one is not already present."""
    stripped = sql.rstrip().rstrip(";").rstrip()
    return f"{stripped}\nLIMIT {limit}"


def _output_path(user_path: str | None) -> Path:
    """Determine the output CSV path."""
    if user_path:
        return Path(user_path)
    RESULTS_DIR.mkdir(parents=True, exist_ok=True)
    ts = datetime.now().strftime("%Y%m%d_%H%M%S")
    return RESULTS_DIR / f"spark_{ts}.csv"


def _print_summary(csv_path: Path, row_count: int, columns: list[str], preview_lines: list[str], elapsed: float, limit_added: bool):
    """Print a compact summary to stdout (this is what the agent reads)."""
    print("\n" + "=" * 60)
    print("SPARK QUERY COMPLETE")
    print("=" * 60)
    print(f"Rows returned : {row_count:,}")
    print(f"Columns ({len(columns)}): {', '.join(columns)}")
    print(f"Elapsed       : {elapsed:.1f}s")
    print(f"Output CSV    : {csv_path}")
    if limit_added:
        print(f"NOTE          : LIMIT {DEFAULT_LIMIT} was auto-applied (no LIMIT in original query)")
    print("-" * 60)
    print("Preview (first 5 rows):")
    print("-" * 60)
    for line in preview_lines:
        print(line)
    print("=" * 60)


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
def main():
    parser = argparse.ArgumentParser(description="Run a read-only Spark SQL query")
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--sql", help="SQL query string")
    group.add_argument("--file", help="Path to a .sql file")
    parser.add_argument("--limit", type=int, default=None, help=f"Override the default row limit (default: {DEFAULT_LIMIT})")
    parser.add_argument("--no-limit", action="store_true", help="Disable automatic LIMIT injection")
    parser.add_argument("--output", "-o", default=None, help="Output CSV path (default: /tmp/spark-results/spark_<ts>.csv)")
    args = parser.parse_args()

    # Read SQL
    if args.file:
        sql = Path(args.file).read_text().strip()
    else:
        sql = args.sql.strip()

    if not sql:
        print("ERROR: Empty SQL query.", file=sys.stderr)
        sys.exit(1)

    # --- SAFETY: read-only check ---
    if not _is_read_only(sql):
        print("REJECTED: Query contains mutating statements (INSERT/UPDATE/DELETE/DDL).", file=sys.stderr)
        print("Only read-only queries (SELECT, SHOW, DESCRIBE, EXPLAIN) are allowed.", file=sys.stderr)
        sys.exit(2)

    # --- LIMIT enforcement ---
    limit_added = False
    if not args.no_limit and not _has_limit(sql):
        limit = args.limit or DEFAULT_LIMIT
        sql = _append_limit(sql, limit)
        limit_added = True

    csv_path = _output_path(args.output)

    # --- Print Spark UI link immediately ---
    print(f"Spark Connect UI: {SPARK_UI_URL}")
    print(f"Connecting to   : {SPARK_CONNECT_URL}")
    print(f"Output will be  : {csv_path}")
    print("Executing query ...")
    sys.stdout.flush()

    # --- Connect & execute ---
    from pyspark.sql import SparkSession

    t0 = time.time()
    spark = SparkSession.builder.remote(SPARK_CONNECT_URL).getOrCreate()
    spark.conf.set("spark.sql.execution.arrow.pyspark.enabled", "true")
    # AQE tuning: prevent coalescing to too few partitions on CPU-heavy queries
    spark.conf.set("spark.sql.adaptive.advisoryPartitionSizeInBytes", "1m")
    spark.conf.set("spark.sql.adaptive.coalescePartitions.parallelismFirst", "true")

    df = spark.sql(sql)

    # Convert to Pandas via Arrow and write CSV
    pdf = df.toPandas()
    elapsed = time.time() - t0

    pdf.to_csv(str(csv_path), index=False)

    # Build preview
    columns = list(pdf.columns)
    row_count = len(pdf)
    preview = pdf.head(PREVIEW_ROWS).to_string(index=False)
    preview_lines = preview.split("\n")

    _print_summary(csv_path, row_count, columns, preview_lines, elapsed, limit_added)

    spark.stop()


if __name__ == "__main__":
    main()
