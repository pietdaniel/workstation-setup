#!/usr/bin/env bash
# Setup a UV virtualenv with pyspark[connect] 3.5.5 for Spark Connect usage.
# Usage: bash scripts/setup_env.sh [venv_path]
# Default venv_path: .venv-spark

set -euo pipefail

VENV_PATH="${1:-.venv-spark}"
PYSPARK_VERSION="3.5.5"

# Check if uv is available
if ! command -v uv &> /dev/null; then
    echo "ERROR: 'uv' is not installed. Install it first: https://docs.astral.sh/uv/getting-started/installation/"
    exit 1
fi

# Fast path: skip if already set up
if [ -f "$VENV_PATH/bin/python" ]; then
    if "$VENV_PATH/bin/python" -c "import pyspark; assert pyspark.__version__ == '$PYSPARK_VERSION'" 2>/dev/null; then
        echo "Spark venv already set up at $VENV_PATH (pyspark==$PYSPARK_VERSION). Skipping."
        exit 0
    fi
fi

# Create venv if it doesn't exist
if [ ! -d "$VENV_PATH" ]; then
    echo "Creating virtualenv at $VENV_PATH ..."
    uv venv "$VENV_PATH"
fi

echo "Installing pyspark[connect]==$PYSPARK_VERSION ..."
# setuptools provides distutils (removed in Python 3.12+), required by pyspark 3.5.x
uv pip install --python "$VENV_PATH/bin/python" \
    "pyspark[connect]==$PYSPARK_VERSION" \
    setuptools \
    pandas \
    pyarrow

echo ""
echo "Setup complete. Activate with:"
echo "  source $VENV_PATH/bin/activate"
echo ""
echo "Or run scripts directly with:"
echo "  $VENV_PATH/bin/python <script.py>"
