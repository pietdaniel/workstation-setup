#!/usr/bin/env python3
"""
Spark Connect helper: create a remote SparkSession to Rokt's datalake.

Usage:
    from connect import get_spark_session
    spark = get_spark_session()
    spark.sql("SHOW DATABASES").show()
"""

from gateway import endpoint_description, spark_connect_url
from pyspark.sql import SparkSession


def get_spark_session() -> SparkSession:
    """Create and return a remote SparkSession via Spark Connect."""
    spark = SparkSession.builder.remote(spark_connect_url()).getOrCreate()
    print(f"Connected to Spark Connect at {endpoint_description()}")
    print(f"Spark version: {spark.version}")
    return spark


if __name__ == "__main__":
    spark = get_spark_session()
    # Quick verification — Polaris catalog (preferred)
    print("\nVerification — Polaris catalog namespaces:")
    spark.sql("SHOW NAMESPACES IN polaris_datalake").show()
    # Legacy Glue catalog still available
    print("\nVerification — Glue catalog (legacy):")
    spark.sql("SHOW DATABASES IN aws_legacy_datalake").show()
