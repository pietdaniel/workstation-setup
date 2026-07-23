# /// script
# requires-python = ">=3.10"
# dependencies = [
#   "trino[external-authentication-token-cache]>=0.330.0",
# ]
# ///
"""Run Trino SQL with a persistent OAuth2 token cache (no re-auth per query).

Why this exists: the Java `trino` CLI holds its OAuth2 token in process memory
only, so every invocation triggers a fresh SSO handshake. The Python client
with the `external-authentication-token-cache` extra persists the JWT in the
OS keyring (macOS Keychain), so the browser dance happens at most once per
token lifetime, no matter how many times this script runs.

Usage examples:
    uv run trino_exec.py -e "SELECT 1"
    uv run trino_exec.py -e "SHOW SCHEMAS IN polaris_datalake" --format table
    uv run trino_exec.py -f query.sql --format json
    echo "SELECT 2; SELECT 3" | uv run trino_exec.py
    uv run trino_exec.py --clear-token-cache
"""

from __future__ import annotations

import argparse
import csv
import io
import json
import os
import sys
import time
from typing import Any, Iterable, List, Optional, Sequence, Tuple
from urllib.parse import urlparse

DEFAULT_SERVER = os.environ.get(
    "TRINO_SERVER", "https://trino-engine-1-g-us-west-2.roktinternal.com"
)
DEFAULT_CATALOG = os.environ.get("TRINO_CATALOG", "polaris_datalake")
DEFAULT_USER = os.environ.get("TRINO_USER")  # None -> principal comes from the OAuth token
DEFAULT_MAX_ROWS = 1000


def eprint(*args: Any) -> None:
    print(*args, file=sys.stderr, flush=True)


# ---------------------------------------------------------------------------
# Statement splitting: honors '...', "...", -- line comments, /* */ blocks
# ---------------------------------------------------------------------------

def split_statements(sql: str) -> List[str]:
    statements: List[str] = []
    buf: List[str] = []
    i, n = 0, len(sql)
    in_single = in_double = in_line_comment = in_block_comment = False

    while i < n:
        ch = sql[i]
        nxt = sql[i + 1] if i + 1 < n else ""

        if in_line_comment:
            buf.append(ch)
            if ch == "\n":
                in_line_comment = False
        elif in_block_comment:
            buf.append(ch)
            if ch == "*" and nxt == "/":
                buf.append(nxt)
                i += 1
                in_block_comment = False
        elif in_single:
            buf.append(ch)
            if ch == "'":
                if nxt == "'":  # escaped quote
                    buf.append(nxt)
                    i += 1
                else:
                    in_single = False
        elif in_double:
            buf.append(ch)
            if ch == '"':
                if nxt == '"':
                    buf.append(nxt)
                    i += 1
                else:
                    in_double = False
        elif ch == "'":
            in_single = True
            buf.append(ch)
        elif ch == '"':
            in_double = True
            buf.append(ch)
        elif ch == "-" and nxt == "-":
            in_line_comment = True
            buf.append(ch)
        elif ch == "/" and nxt == "*":
            in_block_comment = True
            buf.append(ch)
        elif ch == ";":
            stmt = "".join(buf).strip()
            if stmt:
                statements.append(stmt)
            buf = []
        else:
            buf.append(ch)
        i += 1

    tail = "".join(buf).strip()
    if tail:
        statements.append(tail)
    return statements


# ---------------------------------------------------------------------------
# Output formatting
# ---------------------------------------------------------------------------

def json_safe(value: Any) -> Any:
    if value is None or isinstance(value, (str, int, float, bool)):
        return value
    return str(value)


def emit(
    columns: List[str],
    rows: List[Tuple[Any, ...]],
    fmt: str,
    header: bool,
    out: io.TextIOBase,
) -> None:
    if fmt == "csv":
        writer = csv.writer(out)
        if header:
            writer.writerow(columns)
        for row in rows:
            writer.writerow(["" if v is None else v for v in row])
    elif fmt == "tsv":
        if header:
            out.write("\t".join(columns) + "\n")
        for row in rows:
            out.write("\t".join("" if v is None else str(v) for v in row) + "\n")
    elif fmt == "json":
        out.write(
            json.dumps(
                [dict(zip(columns, (json_safe(v) for v in row))) for row in rows],
                indent=2,
                default=str,
            )
            + "\n"
        )
    elif fmt == "jsonl":
        for row in rows:
            out.write(json.dumps(dict(zip(columns, (json_safe(v) for v in row))), default=str) + "\n")
    elif fmt == "table":
        cells = [[("" if v is None else str(v)) for v in row] for row in rows]
        widths = [len(c) for c in columns]
        for row in cells:
            for idx, cell in enumerate(row):
                widths[idx] = max(widths[idx], len(cell))
        if header:
            out.write(" | ".join(c.ljust(widths[i]) for i, c in enumerate(columns)) + "\n")
            out.write("-+-".join("-" * w for w in widths) + "\n")
        for row in cells:
            out.write(" | ".join(cell.ljust(widths[i]) for i, cell in enumerate(row)) + "\n")
    else:
        raise ValueError("unknown format: " + fmt)
    out.flush()


# ---------------------------------------------------------------------------
# Token cache management
# ---------------------------------------------------------------------------

def clear_token_cache(host: str, user: Optional[str]) -> None:
    import keyring

    # trino.auth._OAuth2KeyRingTokenCache stores the JWT under
    #   service = <host>            (when no explicit user was sent)
    #   service = <host>@<user>     (when a user WAS sent)
    #   username = "token", with overflow shards "token__1", "token__2", ...
    # (macOS Keychain caps entry size, so long JWTs are sharded.)
    services = [host]
    if user:
        services.append(f"{host}@{user}")
    cleared = 0
    for svc in services:
        for uname in ["token"] + [f"token__{i}" for i in range(1, 10)]:
            try:
                if keyring.get_password(svc, uname) is not None:
                    keyring.delete_password(svc, uname)
                    eprint(f"cleared keyring entry service={svc!r} username={uname!r}")
                    cleared += 1
            except Exception:
                continue
    if cleared == 0:
        eprint(
            f"no cached token found in keyring for {services!r} "
            "(inspect Keychain Access for entries matching the host)"
        )


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def build_connection(args: argparse.Namespace) -> Any:
    import trino
    import trino.auth
    from trino.auth import OAuth2Authentication

    # Default MAX_OAUTH_ATTEMPTS is 5; each attempt long-polls the token server
    # for ~10s, so a human gets <1 min to finish the browser SSO flow before
    # "Exceeded max attempts while getting the token". Give them ~5 minutes.
    trino.auth._OAuth2TokenBearer.MAX_OAUTH_ATTEMPTS = args.auth_attempts

    parsed = urlparse(args.server if "://" in args.server else "https://" + args.server)
    host = parsed.hostname or args.server
    port = parsed.port or (443 if (parsed.scheme or "https") == "https" else 80)

    kwargs: dict = dict(
        host=host,
        port=port,
        http_scheme=parsed.scheme or "https",
        catalog=args.catalog,
        auth=OAuth2Authentication(),
        verify=True,
        source="opencode-trino-exec",
    )
    if args.user:
        kwargs["user"] = args.user
    if args.schema:
        kwargs["schema"] = args.schema
    if args.session_property:
        props = {}
        for kv in args.session_property:
            k, _, v = kv.partition("=")
            props[k] = v
        kwargs["session_properties"] = props
    return trino.dbapi.connect(**kwargs)


def main(argv: Sequence[str]) -> int:
    ap = argparse.ArgumentParser(
        description="Run Trino SQL with persistent OAuth2 token cache (keyring)."
    )
    ap.add_argument("-e", "--execute", action="append", default=[], metavar="SQL",
                    help="SQL to run (repeatable; each value may contain multiple ';'-separated statements)")
    ap.add_argument("-f", "--file", metavar="PATH", help="read SQL from file ('-' for stdin)")
    ap.add_argument("--server", default=DEFAULT_SERVER,
                    help=f"Trino coordinator URL (env TRINO_SERVER; default {DEFAULT_SERVER})")
    ap.add_argument("--catalog", default=DEFAULT_CATALOG,
                    help=f"default catalog (env TRINO_CATALOG; default {DEFAULT_CATALOG})")
    ap.add_argument("--schema", default=None, help="default schema (optional)")
    ap.add_argument("--user", default=DEFAULT_USER,
                    help="Trino user; normally OMIT — the principal is taken from the OAuth token. "
                         "Setting a mismatched user causes 'cannot impersonate' errors. (env TRINO_USER)")
    ap.add_argument("--format", default="csv", choices=["csv", "tsv", "json", "jsonl", "table"],
                    help="output format (default csv)")
    ap.add_argument("--no-header", action="store_true", help="omit header row (csv/tsv/table)")
    ap.add_argument("--max-rows", type=int, default=DEFAULT_MAX_ROWS,
                    help=f"cap fetched rows per statement, 0 = unlimited (default {DEFAULT_MAX_ROWS})")
    ap.add_argument("--output", "-o", default=None, help="write results to file instead of stdout")
    ap.add_argument("--session-property", action="append", default=[], metavar="K=V",
                    help="Trino session property (repeatable)")
    ap.add_argument("--quiet", "-q", action="store_true", help="suppress per-statement stats on stderr")
    ap.add_argument("--auth-attempts", type=int, default=30,
                    help="OAuth token-poll attempts (~10s each) before giving up; only matters "
                         "on first auth when the browser flow is pending (default 30 ≈ 5 min)")
    ap.add_argument("--clear-token-cache", action="store_true",
                    help="delete the cached OAuth token from the OS keyring and exit")
    args = ap.parse_args(argv)

    parsed = urlparse(args.server if "://" in args.server else "https://" + args.server)
    host = parsed.hostname or args.server

    if args.clear_token_cache:
        clear_token_cache(host, args.user)
        return 0

    # Collect SQL
    sql_blobs: List[str] = list(args.execute)
    if args.file:
        if args.file == "-":
            sql_blobs.append(sys.stdin.read())
        else:
            with open(args.file, "r", encoding="utf-8") as fh:
                sql_blobs.append(fh.read())
    if not sql_blobs and not sys.stdin.isatty():
        sql_blobs.append(sys.stdin.read())

    statements: List[str] = []
    for blob in sql_blobs:
        statements.extend(split_statements(blob))
    if not statements:
        ap.error("no SQL provided (use -e, -f, or pipe via stdin)")

    out: io.TextIOBase
    if args.output:
        out = open(args.output, "w", encoding="utf-8", newline="")
    else:
        out = sys.stdout

    conn = build_connection(args)
    exit_code = 0
    try:
        for idx, stmt in enumerate(statements):
            t0 = time.monotonic()
            cur = conn.cursor()
            try:
                cur.execute(stmt)
                if cur.description is None:
                    columns: List[str] = []
                    rows: List[Tuple[Any, ...]] = []
                else:
                    columns = [d[0] for d in cur.description]
                    if args.max_rows and args.max_rows > 0:
                        rows = cur.fetchmany(args.max_rows)
                        truncated = bool(cur.fetchone()) if len(rows) == args.max_rows else False
                    else:
                        rows = cur.fetchall()
                        truncated = False
                elapsed = time.monotonic() - t0
                if idx > 0 and args.format in ("csv", "tsv", "table") and not args.output:
                    out.write("\n")
                emit(columns, rows, args.format, not args.no_header, out)
                if not args.quiet:
                    qid = getattr(cur, "query_id", None) or ""
                    note = " (TRUNCATED at --max-rows, more rows exist)" if truncated else ""
                    eprint(
                        f"-- statement {idx + 1}/{len(statements)}: {len(rows)} row(s) "
                        f"in {elapsed:.1f}s query_id={qid}{note}"
                    )
            except Exception as exc:  # surface trino errors cleanly, keep going? No: fail fast.
                eprint(f"-- statement {idx + 1}/{len(statements)} FAILED after "
                       f"{time.monotonic() - t0:.1f}s:\n{exc}\nSQL:\n{stmt}")
                exit_code = 1
                break
            finally:
                cur.close()
    finally:
        conn.close()
        if args.output:
            out.close()
    return exit_code


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
