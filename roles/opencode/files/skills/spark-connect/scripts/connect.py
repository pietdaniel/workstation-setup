#!/usr/bin/env python3
"""
Spark Connect helper: create a remote SparkSession to Rokt's datalake.

Usage:
    from connect import get_spark_session
    spark = get_spark_session()
    spark.sql("SHOW DATABASES").show()
"""

from pyspark.sql import SparkSession

SPARK_CONNECT_HOST = "spark-connect-us-west-2.roktinternal.com"
SPARK_CONNECT_PORT = "15002"
SPARK_CONNECT_URL = f"sc://{SPARK_CONNECT_HOST}:{SPARK_CONNECT_PORT}/;use_ssl=true"


def get_spark_session() -> SparkSession:
    """Create and return a remote SparkSession via Spark Connect."""
    spark = SparkSession.builder.remote(SPARK_CONNECT_URL).getOrCreate()
    print(f"Connected to Spark Connect at {SPARK_CONNECT_HOST}:{SPARK_CONNECT_PORT}")
    print(f"Spark version: {spark.version}")
    return spark


if __name__ == "__main__":
    spark = get_spark_session()
    # Quick verification — Polaris catalog (preferred)
    print("\nVerification — Polaris catalog namespaces:")
    spark.sql("SHOW NAMESPACES IN polaris_datalake").show()
    # Legacy Glue catalog still available
    print("\nVerification — Glue catalog (legacy):")
    spark.sql("SHOW DATABASES IN datalake").show()
