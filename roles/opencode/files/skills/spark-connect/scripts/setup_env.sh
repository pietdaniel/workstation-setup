#!/usr/bin/env bash
# Set up a UV virtualenv and authentication for the Spark Connect gateway.
# Usage: bash scripts/setup_env.sh [venv_path]
# Default venv_path: $SPARK_CONNECT_VENV or /tmp/spark-connect-venv

set -euo pipefail

VENV_PATH="${1:-${SPARK_CONNECT_VENV:-/tmp/spark-connect-venv}}"
PYSPARK_VERSION="3.5.7"

# Check if uv is available
if ! command -v uv &> /dev/null; then
    echo "ERROR: 'uv' is not installed. Install it first: https://docs.astral.sh/uv/getting-started/installation/"
    exit 1
fi

# Set up the venv if needed. Do not exit early: authentication setup follows.
if [ -f "$VENV_PATH/bin/python" ]; then
    if "$VENV_PATH/bin/python" -c "import pyspark; assert pyspark.__version__ == '$PYSPARK_VERSION'" 2>/dev/null; then
        echo "Spark venv already set up at $VENV_PATH (pyspark==$PYSPARK_VERSION)."
        VENV_READY=true
    fi
fi

if [ "${VENV_READY:-false}" != true ]; then
    if [ ! -x "$VENV_PATH/bin/python" ]; then
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
fi

# Fetch the canonical login helper at the reviewed commit that introduced it.
SC_LOGIN_DEST="${SC_LOGIN:-$HOME/.sc/sc_login.py}"
if ! command -v gh &> /dev/null; then
    echo "ERROR: 'gh' is required to fetch sc_login.py from ROKT/spark-infra." >&2
    exit 1
fi

mkdir -p "$(dirname "$SC_LOGIN_DEST")"
SC_LOGIN_TMP="$(mktemp "${TMPDIR:-/tmp}/sc_login.XXXXXX")"
if gh api -X GET repos/ROKT/spark-infra/contents/apps/kyuubi-connect/client/sc_login.py \
    -f ref=246f4e344200bfd45b14fe647685803f33dd342e \
    -H 'Accept: application/vnd.github.raw' > "$SC_LOGIN_TMP" && [ -s "$SC_LOGIN_TMP" ]; then
    mv "$SC_LOGIN_TMP" "$SC_LOGIN_DEST"
else
    rm -f "$SC_LOGIN_TMP"
    echo "ERROR: failed to fetch sc_login.py from ROKT/spark-infra." >&2
    exit 1
fi

echo ""
echo "Setup complete. Log in once (later runs refresh silently):"
echo "  python3 $SC_LOGIN_DEST"
