#!/usr/bin/env bash

# Wrapper script for dd_log_query.py
# Usage: ./ddlog.sh "query" --duration "15m" [--json] [--limit 100]

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd $SCRIPT_DIR
cd ./dd-log-query

# Run the Python script with uv, passing all arguments
uv run "dd_log_query.py" "$@"
