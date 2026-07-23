"""Authentication and connection settings for the Spark Connect gateway."""

import os
import subprocess
import sys


SPARK_CONNECT_HOST = os.environ.get(
    "SPARK_CONNECT_HOST", "spark-connect-gateway-us-west-2.roktinternal.com"
)
SPARK_CONNECT_PORT = os.environ.get("SPARK_CONNECT_PORT", "15003")


def gateway_token() -> str:
    """Return a fresh Google ID token without exposing it in logs."""
    token = os.environ.get("SPARK_CONNECT_TOKEN")
    if token:
        return token

    sc_login = os.path.expanduser(os.environ.get("SC_LOGIN", "~/.sc/sc_login.py"))
    if not os.path.exists(sc_login):
        raise SystemExit(
            "ERROR: Spark Connect gateway login is not configured. Run:\n"
            "  bash ~/.config/opencode/skills/spark-connect/scripts/setup_env.sh\n"
            "  python3 ~/.sc/sc_login.py\n"
            "Then retry the query. Alternatively set SPARK_CONNECT_TOKEN or SC_LOGIN."
        )

    result = subprocess.run(
        [sys.executable, sc_login, "--print"], capture_output=True, text=True
    )
    if result.returncode != 0:
        detail = result.stderr.strip()
        raise SystemExit(
            f"ERROR: sc_login failed (exit {result.returncode}). "
            f"Run: python3 {sc_login}\n{detail}"
        )

    token = result.stdout.strip()
    if not token:
        raise SystemExit(
            f"ERROR: sc_login returned an empty token. Run: python3 {sc_login}"
        )
    return token


def spark_connect_url() -> str:
    """Build an authenticated gateway URL, honoring a full URL override."""
    override = os.environ.get("SPARK_CONNECT_URL")
    if override:
        return override
    return (
        f"sc://{SPARK_CONNECT_HOST}:{SPARK_CONNECT_PORT}/;"
        f"use_ssl=true;token={gateway_token()}"
    )


def endpoint_description() -> str:
    """Return a safe endpoint description that cannot leak a token."""
    if os.environ.get("SPARK_CONNECT_URL"):
        return "custom SPARK_CONNECT_URL (credentials hidden)"
    return f"sc://{SPARK_CONNECT_HOST}:{SPARK_CONNECT_PORT}/ (authenticated gateway)"
