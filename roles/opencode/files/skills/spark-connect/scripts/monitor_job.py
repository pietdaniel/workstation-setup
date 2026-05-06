#!/usr/bin/env python3
"""
Spark REST API job monitor — query Spark Connect's REST API to monitor
application progress, stages, executors, and diagnose stuck jobs.

Usage:
    python monitor_job.py --list-apps
    python monitor_job.py --app <app-id> --summary
    python monitor_job.py --app <app-id> --jobs
    python monitor_job.py --app <app-id> --job-id <job-id>
    python monitor_job.py --app <app-id> --stages
    python monitor_job.py --app <app-id> --stages --status active
    python monitor_job.py --app <app-id> --executors
    python monitor_job.py --app <app-id> --sql
    python monitor_job.py --app <app-id> --sql-id <execution-id>
    python monitor_job.py --app <app-id> --threads <executor-id>
    python monitor_job.py --app <app-id> --threads <executor-id> --all-threads
    python monitor_job.py --app <app-id> --environment
    python monitor_job.py --app <app-id> --diagnose
"""

import argparse
import json
import sys
import urllib.request
import urllib.error
from datetime import datetime, timezone

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------
SPARK_UI_BASE = "https://spark-connect-us-west-2.roktinternal.com"
API_BASE = f"{SPARK_UI_BASE}/api/v1"


# ---------------------------------------------------------------------------
# HTTP helpers
# ---------------------------------------------------------------------------
def _get_json(url: str) -> dict | list | None:
    """Fetch JSON from the Spark REST API."""
    try:
        req = urllib.request.Request(url, headers={"Accept": "application/json"})
        with urllib.request.urlopen(req, timeout=30) as resp:
            return json.loads(resp.read().decode())
    except urllib.error.HTTPError as e:
        print(f"HTTP {e.code}: {e.reason} — {url}", file=sys.stderr)
        return None
    except urllib.error.URLError as e:
        print(f"Connection error: {e.reason} — {url}", file=sys.stderr)
        return None


def _fmt_duration_ms(ms: int | None) -> str:
    """Format milliseconds into human-readable duration."""
    if ms is None:
        return "N/A"
    secs = ms / 1000
    if secs < 60:
        return f"{secs:.1f}s"
    mins = secs / 60
    if mins < 60:
        return f"{mins:.1f}m"
    hours = mins / 60
    return f"{hours:.1f}h"


def _fmt_bytes(b: int | None) -> str:
    """Format bytes into human-readable size."""
    if b is None:
        return "N/A"
    for unit in ["B", "KB", "MB", "GB", "TB"]:
        if abs(b) < 1024:
            return f"{b:.1f} {unit}"
        b /= 1024
    return f"{b:.1f} PB"


# ---------------------------------------------------------------------------
# Commands
# ---------------------------------------------------------------------------
def list_apps(status: str | None = None):
    """List all Spark applications."""
    url = f"{API_BASE}/applications"
    if status:
        url += f"?status={status}"
    apps = _get_json(url)
    if not apps:
        print("No applications found.")
        return

    print(f"{'ID':<50} {'Name':<30} {'State':<10} {'Duration'}")
    print("-" * 110)
    for app in apps[:20]:
        app_id = app.get("id", "?")
        name = app.get("name", "?")[:30]
        attempts = app.get("attempts", [{}])
        latest = attempts[0] if attempts else {}
        completed = latest.get("completed", False)
        state = "COMPLETED" if completed else "RUNNING"
        duration = latest.get("duration", 0)
        print(f"{app_id:<50} {name:<30} {state:<10} {_fmt_duration_ms(duration)}")


def app_summary(app_id: str):
    """Print a summary of an application: jobs, active stages, executors."""
    jobs = _get_json(f"{API_BASE}/applications/{app_id}/jobs") or []
    stages = _get_json(f"{API_BASE}/applications/{app_id}/stages") or []
    executors = _get_json(f"{API_BASE}/applications/{app_id}/executors") or []

    running_jobs = [j for j in jobs if j.get("status") == "RUNNING"]
    active_stages = [s for s in stages if s.get("status") == "ACTIVE"]
    pending_stages = [s for s in stages if s.get("status") == "PENDING"]
    failed_stages = [s for s in stages if s.get("status") == "FAILED"]

    print("=" * 60)
    print(f"APPLICATION SUMMARY: {app_id}")
    print("=" * 60)
    print(f"Total jobs     : {len(jobs)} ({len(running_jobs)} running)")
    print(f"Total stages   : {len(stages)} ({len(active_stages)} active, {len(pending_stages)} pending, {len(failed_stages)} failed)")
    print(f"Executors      : {len(executors)}")

    if active_stages:
        print("\nACTIVE STAGES:")
        print(f"  {'ID':<8} {'Tasks':<20} {'Input':<12} {'Output':<12} {'Name'}")
        print("  " + "-" * 80)
        for s in active_stages:
            sid = s.get("stageId", "?")
            tasks_complete = s.get("numCompleteTasks", 0)
            tasks_total = s.get("numTasks", 0)
            tasks_active = s.get("numActiveTasks", 0)
            input_bytes = _fmt_bytes(s.get("inputBytes", 0))
            output_bytes = _fmt_bytes(s.get("outputBytes", 0))
            name = (s.get("name") or "?")[:40]
            print(f"  {sid:<8} {tasks_complete}/{tasks_total} ({tasks_active} active) {input_bytes:<12} {output_bytes:<12} {name}")

    if executors:
        total_cores = sum(e.get("totalCores", 0) for e in executors)
        total_mem = sum(e.get("maxMemory", 0) for e in executors)
        active_tasks = sum(e.get("activeTasks", 0) for e in executors)
        print(f"\nEXECUTOR RESOURCES: {total_cores} cores, {_fmt_bytes(total_mem)} memory, {active_tasks} active tasks")

    print("=" * 60)


def list_jobs(app_id: str, status: str | None = None):
    """List jobs for an application."""
    url = f"{API_BASE}/applications/{app_id}/jobs"
    if status:
        url += f"?status={status}"
    jobs = _get_json(url)
    if not jobs:
        print("No jobs found.")
        return

    print(f"{'Job ID':<8} {'Status':<12} {'Stages':<20} {'Tasks':<20} {'Name'}")
    print("-" * 90)
    for job in jobs:
        jid = job.get("jobId", "?")
        status_val = job.get("status", "?")
        stages_completed = len(job.get("stageIds", []))
        active_stages = len(job.get("stageIds", [])) - len(job.get("completedStageIds", []))
        tasks_completed = job.get("numCompletedTasks", 0)
        tasks_total = job.get("numTasks", 0)
        name = (job.get("name") or "?")[:30]
        print(f"{jid:<8} {status_val:<12} {active_stages} active/{stages_completed} total   {tasks_completed}/{tasks_total}{'':>8} {name}")


def get_job_detail(app_id: str, job_id: str):
    """Show detailed info for a specific job: stages, progress, duration."""
    job = _get_json(f"{API_BASE}/applications/{app_id}/jobs/{job_id}")
    if not job:
        print(f"Job {job_id} not found.")
        return

    status_val = job.get("status", "?")
    name = job.get("name", "?")
    submission_time = job.get("submissionTime", "?")
    completion_time = job.get("completionTime", "")
    stage_ids = job.get("stageIds", [])
    completed_stage_ids = job.get("completedStageIds", [])
    failed_stage_ids = job.get("failedStageIds", [])
    tasks_completed = job.get("numCompletedTasks", 0)
    tasks_total = job.get("numTasks", 0)
    tasks_active = job.get("numActiveTasks", 0)
    tasks_failed = job.get("numFailedTasks", 0)
    tasks_skipped = job.get("numSkippedTasks", 0)

    print("=" * 70)
    print(f"JOB {job_id}: {status_val}")
    print("=" * 70)
    print(f"Name       : {name[:80]}")
    print(f"Submitted  : {submission_time}")
    if completion_time:
        print(f"Completed  : {completion_time}")
    print(f"Stages     : {len(completed_stage_ids)}/{len(stage_ids)} complete"
          f"{f', {len(failed_stage_ids)} failed' if failed_stage_ids else ''}")
    print(f"Tasks      : {tasks_completed}/{tasks_total} complete"
          f", {tasks_active} active, {tasks_failed} failed, {tasks_skipped} skipped")

    if job.get("killedTasksSummary"):
        print(f"Killed     : {job['killedTasksSummary']}")

    # Fetch details for each stage in this job
    if stage_ids:
        print(f"\n{'Stage':<8} {'Status':<10} {'Tasks':<28} {'Input':<12} {'Shuffle R':<12} {'Shuffle W':<12}")
        print("-" * 90)
        for sid in sorted(stage_ids):
            stage = _get_json(f"{API_BASE}/applications/{app_id}/stages/{sid}")
            if not stage:
                print(f"{sid:<8} {'ERROR':<10} (could not fetch)")
                continue
            # API returns a list of attempts; take the latest
            s = stage[0] if isinstance(stage, list) else stage
            s_status = s.get("status", "?")
            s_tasks_complete = s.get("numCompleteTasks", 0)
            s_tasks_total = s.get("numTasks", 0)
            s_tasks_active = s.get("numActiveTasks", 0)
            s_input = _fmt_bytes(s.get("inputBytes", 0))
            s_shuffle_r = _fmt_bytes(s.get("shuffleReadBytes", 0))
            s_shuffle_w = _fmt_bytes(s.get("shuffleWriteBytes", 0))
            task_str = f"{s_tasks_complete}/{s_tasks_total} (active:{s_tasks_active})"
            print(f"{sid:<8} {s_status:<10} {task_str:<28} {s_input:<12} {s_shuffle_r:<12} {s_shuffle_w:<12}")

    print("=" * 70)


def list_stages(app_id: str, status: str | None = None):
    """List stages for an application."""
    url = f"{API_BASE}/applications/{app_id}/stages"
    if status:
        url += f"?status={status}"
    stages = _get_json(url)
    if not stages:
        print("No stages found.")
        return

    print(f"{'Stage':<8} {'Status':<10} {'Tasks':<25} {'Input':<12} {'Shuffle R':<12} {'Name'}")
    print("-" * 100)
    for s in stages[:30]:
        sid = s.get("stageId", "?")
        status_val = s.get("status", "?")
        tasks_complete = s.get("numCompleteTasks", 0)
        tasks_total = s.get("numTasks", 0)
        tasks_active = s.get("numActiveTasks", 0)
        tasks_failed = s.get("numFailedTasks", 0)
        input_bytes = _fmt_bytes(s.get("inputBytes", 0))
        shuffle_read = _fmt_bytes(s.get("shuffleReadBytes", 0))
        name = (s.get("name") or "?")[:30]
        task_str = f"{tasks_complete}/{tasks_total} (active:{tasks_active}, fail:{tasks_failed})"
        print(f"{sid:<8} {status_val:<10} {task_str:<25} {input_bytes:<12} {shuffle_read:<12} {name}")


def list_executors(app_id: str):
    """List executors for an application."""
    executors = _get_json(f"{API_BASE}/applications/{app_id}/executors")
    if not executors:
        print("No executors found.")
        return

    print(f"{'Executor':<12} {'Cores':<8} {'Active':<8} {'Memory Used':<15} {'Max Memory':<15} {'Shuffle R':<12}")
    print("-" * 80)
    for e in executors:
        eid = e.get("id", "?")
        cores = e.get("totalCores", 0)
        active = e.get("activeTasks", 0)
        mem_used = _fmt_bytes(e.get("memoryUsed", 0))
        max_mem = _fmt_bytes(e.get("maxMemory", 0))
        shuffle_read = _fmt_bytes(e.get("totalShuffleRead", 0))
        print(f"{eid:<12} {cores:<8} {active:<8} {mem_used:<15} {max_mem:<15} {shuffle_read:<12}")


def list_sql(app_id: str):
    """List SQL executions for an application."""
    sql_data = _get_json(f"{API_BASE}/applications/{app_id}/sql?details=true")
    if not sql_data:
        print("No SQL executions found.")
        return

    print(f"{'Exec ID':<10} {'Status':<12} {'Duration':<12} {'Description'}")
    print("-" * 80)
    for s in sql_data[:20]:
        eid = s.get("id", "?")
        status_val = s.get("status", "?")
        duration = _fmt_duration_ms(s.get("duration", 0))
        desc = (s.get("description") or "?")[:50]
        print(f"{eid:<10} {status_val:<12} {duration:<12} {desc}")


def get_sql_detail(app_id: str, sql_id: str):
    """Show structured query plan for a SQL execution."""
    data = _get_json(f"{API_BASE}/applications/{app_id}/sql/{sql_id}?details=true&planDescription=true")
    if not data:
        print("SQL execution not found.")
        return

    status = data.get("status", "?")
    duration = _fmt_duration_ms(data.get("duration", 0))
    desc = data.get("description", "?")
    plan_desc = data.get("planDescription", "")

    print("=" * 70)
    print(f"SQL EXECUTION {sql_id}: {status} ({duration})")
    print("=" * 70)
    print(f"Description: {desc[:120]}")

    # Parse and display the physical plan from nodes
    nodes = data.get("nodes", [])
    edges = data.get("edges", [])

    if nodes:
        # Build parent mapping from edges (child -> parent)
        children_of = {}  # parent_id -> [child_ids]
        for edge in edges:
            from_id = edge.get("fromId")
            to_id = edge.get("toId")
            if from_id is not None and to_id is not None:
                children_of.setdefault(from_id, []).append(to_id)

        # Find root nodes (not a child of anyone)
        all_child_ids = set()
        for kids in children_of.values():
            all_child_ids.update(kids)
        root_ids = [n["nodeId"] for n in nodes if n["nodeId"] not in all_child_ids]

        # Build node lookup
        node_map = {n["nodeId"]: n for n in nodes}

        print(f"\nQUERY PLAN ({len(nodes)} nodes):")
        print("-" * 70)

        def _print_node(node_id, depth=0):
            node = node_map.get(node_id)
            if not node:
                return
            indent = "  " * depth
            name = node.get("nodeName", "?")
            desc_text = node.get("simpleString", "") or node.get("desc", "")

            # Extract key metrics
            metrics = node.get("metrics", [])
            metric_strs = []
            for m in metrics:
                m_name = m.get("name", "")
                m_val = m.get("value", "")
                if m_val and str(m_val) != "0":
                    metric_strs.append(f"{m_name}={m_val}")

            # Print node
            print(f"{indent}[{node_id}] {name}")
            if desc_text and desc_text != name:
                # Truncate long descriptions but show table/column info
                short_desc = desc_text[:120]
                if len(desc_text) > 120:
                    short_desc += "..."
                print(f"{indent}     {short_desc}")
            if metric_strs:
                print(f"{indent}     metrics: {', '.join(metric_strs[:6])}")

            # Recurse into children
            for child_id in children_of.get(node_id, []):
                _print_node(child_id, depth + 1)

        for rid in root_ids:
            _print_node(rid)

    # Show the text plan description if available
    if plan_desc:
        print(f"\nPHYSICAL PLAN:")
        print("-" * 70)
        # Limit output to avoid overwhelming
        lines = plan_desc.strip().split("\n")
        for line in lines[:50]:
            print(line)
        if len(lines) > 50:
            print(f"... ({len(lines) - 50} more lines, use --sql-id-raw for full JSON)")

    print("=" * 70)


def get_threads(app_id: str, executor_id: str, show_all: bool = False):
    """Get thread dump for an executor, formatted with task thread filtering."""
    data = _get_json(f"{API_BASE}/applications/{app_id}/executors/{executor_id}/threads")
    if not data:
        print("Thread dump not available (only works on running applications, not history server).")
        return

    threads = data if isinstance(data, list) else list(data.values()) if isinstance(data, dict) else []

    # Separate task threads from others
    task_threads = []
    other_threads = []
    for t in threads:
        name = t.get("threadName", "") or ""
        if "task" in name.lower() and ("executor" in name.lower() or "launch" in name.lower()):
            task_threads.append(t)
        else:
            other_threads.append(t)

    print("=" * 70)
    print(f"THREAD DUMP: Executor {executor_id}")
    print(f"Total threads: {len(threads)}, Task threads: {len(task_threads)}")
    print("=" * 70)

    def _print_thread(t):
        name = t.get("threadName", "?")
        state = t.get("threadState", "?")
        stack = t.get("stackTrace", [])
        # stackTrace can be a list of strings or a list of dicts
        print(f"\n=== {name} ({state}) ===")

        if not stack:
            print("  (no stack trace)")
            return

        # Find the first application frame (non-java.*, non-sun.*, non-jdk.*)
        app_frame = None
        for frame in stack:
            frame_str = frame if isinstance(frame, str) else frame.get("className", "") + "." + frame.get("methodName", "")
            if not any(frame_str.startswith(p) for p in ("java.", "sun.", "jdk.", "scala.concurrent")):
                app_frame = frame_str
                break

        if app_frame:
            print(f"  DOING: {app_frame}")

        # Print stack (up to 20 frames)
        for i, frame in enumerate(stack[:20]):
            if isinstance(frame, str):
                print(f"  {frame}")
            elif isinstance(frame, dict):
                cls = frame.get("className", "?")
                method = frame.get("methodName", "?")
                file_name = frame.get("fileName", "")
                line = frame.get("lineNumber", "")
                loc = f"({file_name}:{line})" if file_name else ""
                print(f"  at {cls}.{method}{loc}")
            else:
                print(f"  {frame}")

        if len(stack) > 20:
            print(f"  ... ({len(stack) - 20} more frames)")

    # Always print task threads
    if task_threads:
        print("\nTASK THREADS:")
        for t in task_threads:
            _print_thread(t)
    else:
        print("\n[INFO] No task threads found on this executor.")
        print("  The task may be on a different executor. Use --executors to find")
        print("  which executor has activeTasks > 0, then check that executor.")

    # Print other threads only if --all-threads
    if show_all and other_threads:
        print(f"\nOTHER THREADS ({len(other_threads)}):")
        for t in other_threads:
            _print_thread(t)
    elif other_threads and not show_all:
        # Print a summary of other thread states
        states = {}
        for t in other_threads:
            state = t.get("threadState", "?")
            states[state] = states.get(state, 0) + 1
        state_summary = ", ".join(f"{v} {k}" for k, v in sorted(states.items(), key=lambda x: -x[1]))
        print(f"\nOther threads: {state_summary}")
        print("  (use --all-threads to see all threads)")

    print("\n" + "=" * 70)


def get_environment(app_id: str):
    """Get application environment/config."""
    data = _get_json(f"{API_BASE}/applications/{app_id}/environment")
    if not data:
        print("Environment not found.")
        return

    print("=" * 60)
    print("SPARK PROPERTIES (selected)")
    print("=" * 60)
    spark_props = data.get("sparkProperties", [])
    for k, v in spark_props:
        if any(kw in k.lower() for kw in ["memory", "cores", "executor", "driver", "shuffle", "sql", "arrow", "iceberg", "catalog"]):
            print(f"  {k} = {v}")
    print("=" * 60)


def diagnose(app_id: str):
    """Run a diagnostic: check for stuck stages, skewed tasks, failed stages."""
    print("=" * 60)
    print(f"DIAGNOSTIC REPORT: {app_id}")
    print("=" * 60)

    # Check active stages for stalls
    stages = _get_json(f"{API_BASE}/applications/{app_id}/stages?status=active") or []
    if not stages:
        print("[OK] No active stages.")
    else:
        for s in stages:
            sid = s.get("stageId", "?")
            attempt = s.get("attemptId", 0)
            tasks_complete = s.get("numCompleteTasks", 0)
            tasks_total = s.get("numTasks", 0)
            tasks_active = s.get("numActiveTasks", 0)
            tasks_failed = s.get("numFailedTasks", 0)

            print(f"\n[ACTIVE] Stage {sid} (attempt {attempt}): {tasks_complete}/{tasks_total} tasks complete, {tasks_active} active, {tasks_failed} failed")

            if tasks_total > 0 and tasks_active <= 2 and tasks_complete > tasks_total * 0.9:
                print(f"  [WARN] Possible straggler — {tasks_total - tasks_complete} tasks remaining with only {tasks_active} active")

            if tasks_failed > 0:
                print(f"  [WARN] {tasks_failed} failed tasks detected")

            # Check task summary for skew
            summary = _get_json(
                f"{API_BASE}/applications/{app_id}/stages/{sid}/{attempt}/taskSummary?quantiles=0.0,0.25,0.5,0.75,1.0"
            )
            if summary:
                duration = summary.get("executorRunTime", {})
                if duration:
                    p50 = duration.get("50th Percentile", 0)
                    p100 = duration.get("100th Percentile", 0)
                    if p100 > 0 and p50 > 0 and p100 / p50 > 10:
                        print(f"  [WARN] Task skew detected: p50={_fmt_duration_ms(p50)}, max={_fmt_duration_ms(p100)} (max/p50 = {p100/p50:.0f}x)")

                shuffle_read = summary.get("shuffleReadMetrics", {}).get("readBytes", {})
                if shuffle_read:
                    sr_p50 = shuffle_read.get("50th Percentile", 0)
                    sr_p100 = shuffle_read.get("100th Percentile", 0)
                    if sr_p100 > 0 and sr_p50 > 0 and sr_p100 / sr_p50 > 20:
                        print(f"  [WARN] Shuffle read skew: p50={_fmt_bytes(sr_p50)}, max={_fmt_bytes(sr_p100)}")

    # Check for AQE coalescing bottleneck
    # When AQE coalesces post-shuffle partitions to very few tasks, CPU-heavy
    # operations (nested lambdas, complex UDFs) get bottlenecked on 1-2 cores.
    completed = _get_json(f"{API_BASE}/applications/{app_id}/stages?status=complete") or []
    for s in completed[-10:]:  # check recent completed stages
        sid = s.get("stageId", "?")
        tasks_total = s.get("numTasks", 0)
        shuffle_read = s.get("shuffleReadBytes", 0)
        duration_ms = s.get("executorRunTime", 0)
        if tasks_total <= 2 and shuffle_read > 10_000_000 and duration_ms > 60_000:
            print(f"\n  [WARN] AQE coalescing bottleneck — Stage {sid}: {tasks_total} task(s), "
                  f"{_fmt_bytes(shuffle_read)} shuffle read, {_fmt_duration_ms(duration_ms)} executor time")
            print(f"    AQE coalesced post-shuffle partitions to {tasks_total} because data size was small,")
            print(f"    but per-row CPU cost was high. Fix options:")
            print(f"      1. Add /*+ REPARTITION(N) */ hint to force parallelism")
            print(f"      2. SET spark.sql.adaptive.advisoryPartitionSizeInBytes = 5m")
            print(f"      3. SET spark.sql.adaptive.coalescePartitions.enabled = false")

    for s in stages:  # also check currently active stages
        sid = s.get("stageId", "?")
        tasks_total = s.get("numTasks", 0)
        tasks_active = s.get("numActiveTasks", 0)
        shuffle_read = s.get("shuffleReadBytes", 0)
        if tasks_total <= 2 and shuffle_read > 10_000_000 and tasks_active > 0:
            print(f"\n  [WARN] Likely AQE coalescing bottleneck — Active Stage {sid}: only {tasks_total} task(s) "
                  f"processing {_fmt_bytes(shuffle_read)} shuffle read")
            print(f"    If this stage is slow, AQE coalesced partitions due to small data size")
            print(f"    but the query has expensive per-row operations. Consider cancelling and")
            print(f"    re-running with REPARTITION hint or reduced advisoryPartitionSizeInBytes.")

    # Check failed stages
    failed = _get_json(f"{API_BASE}/applications/{app_id}/stages?status=failed") or []
    if failed:
        print(f"\n[ALERT] {len(failed)} FAILED stages:")
        for s in failed[:5]:
            sid = s.get("stageId", "?")
            reason = (s.get("failureReason") or "unknown")[:100]
            print(f"  Stage {sid}: {reason}")

    # Check executors
    executors = _get_json(f"{API_BASE}/applications/{app_id}/executors") or []
    dead = [e for e in executors if not e.get("isActive", True)]
    if dead:
        print(f"\n[WARN] {len(dead)} dead executors detected")

    print("\n" + "=" * 60)


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
def main():
    parser = argparse.ArgumentParser(description="Monitor Spark Connect jobs via REST API")
    parser.add_argument("--app", help="Application ID (e.g., spark-abc123)")
    parser.add_argument("--list-apps", action="store_true", help="List all applications")
    parser.add_argument("--summary", action="store_true", help="Application summary")
    parser.add_argument("--jobs", action="store_true", help="List jobs")
    parser.add_argument("--job-id", metavar="JOB_ID", help="Show details for a specific job")
    parser.add_argument("--stages", action="store_true", help="List stages")
    parser.add_argument("--executors", action="store_true", help="List executors")
    parser.add_argument("--sql", action="store_true", help="List SQL executions")
    parser.add_argument("--sql-id", help="Get SQL execution details")
    parser.add_argument("--threads", metavar="EXECUTOR_ID", help="Thread dump for executor")
    parser.add_argument("--all-threads", action="store_true", help="Show all threads (not just task threads)")
    parser.add_argument("--sql-id-raw", metavar="SQL_ID", help="Get raw JSON for a SQL execution")
    parser.add_argument("--environment", action="store_true", help="Application environment/config")
    parser.add_argument("--diagnose", action="store_true", help="Run diagnostic checks")
    parser.add_argument("--status", help="Filter by status (running/completed/active/failed)")
    args = parser.parse_args()

    if args.list_apps:
        list_apps(args.status)
    elif not args.app:
        print("ERROR: --app <app-id> is required (or use --list-apps)", file=sys.stderr)
        sys.exit(1)
    elif args.summary:
        app_summary(args.app)
    elif args.job_id:
        get_job_detail(args.app, args.job_id)
    elif args.jobs:
        list_jobs(args.app, args.status)
    elif args.stages:
        list_stages(args.app, args.status)
    elif args.executors:
        list_executors(args.app)
    elif args.sql:
        list_sql(args.app)
    elif args.sql_id:
        get_sql_detail(args.app, args.sql_id)
    elif args.threads:
        get_threads(args.app, args.threads, show_all=args.all_threads)
    elif args.sql_id_raw:
        data = _get_json(f"{API_BASE}/applications/{args.app}/sql/{args.sql_id_raw}?details=true&planDescription=true")
        if data:
            print(json.dumps(data, indent=2, default=str))
        else:
            print("SQL execution not found.")
    elif args.environment:
        get_environment(args.app)
    elif args.diagnose:
        diagnose(args.app)
    else:
        app_summary(args.app)


if __name__ == "__main__":
    main()
