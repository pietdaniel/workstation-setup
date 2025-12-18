#!/usr/bin/env python3
"""
Datadog Log Query Tool
Query Datadog logs from the command line with custom time ranges.
"""

import argparse
import json
import os
import re
import sys
from datetime import datetime, timedelta
from dotenv import load_dotenv
from datadog_api_client import ApiClient, Configuration
from datadog_api_client.v2.api.logs_api import LogsApi
from datadog_api_client.v2.model.logs_list_request import LogsListRequest
from datadog_api_client.v2.model.logs_list_request_page import LogsListRequestPage
from datadog_api_client.v2.model.logs_query_filter import LogsQueryFilter
from datadog_api_client.v2.model.logs_sort import LogsSort


def parse_duration(duration_str):
    """
    Parse duration string like '15m', '30m', '1h', '1d' into timedelta.
    
    Args:
        duration_str: String in format of <number><unit> where unit is m/h/d
        
    Returns:
        timedelta object
        
    Raises:
        ValueError: If duration format is invalid
    """
    pattern = r'^(\d+)(m|h|d)$'
    match = re.match(pattern, duration_str)
    
    if not match:
        raise ValueError(
            f"Invalid duration format: '{duration_str}'. "
            "Expected format: <number><unit> (e.g., 15m, 1h, 2d)"
        )
    
    value = int(match.group(1))
    unit = match.group(2)
    
    if unit == 'm':
        return timedelta(minutes=value)
    elif unit == 'h':
        return timedelta(hours=value)
    elif unit == 'd':
        return timedelta(days=value)


def query_datadog_logs(query_string, duration_str, limit=100, json_output=False):
    """
    Query Datadog logs with the given query string and time range.
    
    Args:
        query_string: Datadog log query string
        duration_str: Duration string (e.g., '15m', '1h', '1d')
        limit: Maximum number of logs to retrieve (default: 100)
        json_output: If True, output raw JSON format (default: False)
    """
    # Load environment variables
    load_dotenv()
    
    # Get Datadog credentials
    api_key = os.getenv('DD_API_KEY')
    app_key = os.getenv('DD_APP_KEY')
    dd_site = os.getenv('DD_SITE', 'datadoghq.com')
    
    if not api_key or not app_key:
        print("Error: DD_API_KEY and DD_APP_KEY must be set in .env file", file=sys.stderr)
        sys.exit(1)
    
    # Parse duration
    try:
        duration = parse_duration(duration_str)
    except ValueError as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)
    
    # Calculate time range
    to_time = datetime.utcnow()
    from_time = to_time - duration
    
    # Convert to RFC3339 format (Datadog API requirement)
    from_timestamp = from_time.strftime('%Y-%m-%dT%H:%M:%S.%f')[:-3] + 'Z'
    to_timestamp = to_time.strftime('%Y-%m-%dT%H:%M:%S.%f')[:-3] + 'Z'
    
    # Configure Datadog API client
    configuration = Configuration()
    configuration.api_key["apiKeyAuth"] = api_key
    configuration.api_key["appKeyAuth"] = app_key
    configuration.server_variables["site"] = dd_site
    
    print(f"Querying Datadog logs...")
    print(f"Query: {query_string}")
    print(f"Time range: {from_time.strftime('%Y-%m-%d %H:%M:%S')} to {to_time.strftime('%Y-%m-%d %H:%M:%S')} UTC")
    print(f"Duration: {duration_str}")
    print("-" * 80)
    
    try:
        with ApiClient(configuration) as api_client:
            api_instance = LogsApi(api_client)
            
            # Create the logs list request
            body = LogsListRequest(
                filter=LogsQueryFilter(
                    query=query_string,
                    _from=from_timestamp,
                    to=to_timestamp,
                ),
                sort=LogsSort.TIMESTAMP_ASCENDING,
                page=LogsListRequestPage(
                    limit=limit,
                ),
            )
            
            # Execute the query
            response = api_instance.list_logs(body=body)
            
            # Process and display results
            if response.data:
                print(f"\nFound {len(response.data)} log entries:\n")
                
                if json_output:
                    # Output raw JSON
                    logs_list = []
                    for log in response.data:
                        # Convert the log object to dict using to_dict() method
                        log_dict = log.to_dict() if hasattr(log, 'to_dict') else {}
                        logs_list.append(log_dict)
                    print(json.dumps(logs_list, indent=2, default=str))
                else:
                    # Output formatted text
                    for idx, log in enumerate(response.data, 1):
                        timestamp = log.attributes.get('timestamp', 'N/A')
                        message = log.attributes.get('message', 'N/A')
                        status = log.attributes.get('status', 'N/A')
                        service = log.attributes.get('service', 'N/A')
                        
                        print(f"[{idx}] {timestamp}")
                        print(f"    Service: {service}")
                        print(f"    Status: {status}")
                        print(f"    Message: {message}")
                        print()
            else:
                print("No logs found matching the query.")
                
    except Exception as e:
        print(f"Error querying Datadog: {e}", file=sys.stderr)
        sys.exit(1)


def main():
    """Main entry point for the CLI tool."""
    parser = argparse.ArgumentParser(
        description='Query Datadog logs with a custom query string and time range.',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  %(prog)s "service:my-app AND status:error" --duration 15m
  %(prog)s "host:prod-server" --duration 1h
  %(prog)s "error" --duration 2d --limit 50
        """
    )
    
    parser.add_argument(
        'query',
        type=str,
        help='Datadog log query string (e.g., "service:my-app AND status:error")'
    )
    
    parser.add_argument(
        '--duration',
        type=str,
        required=True,
        help='Time duration to query (e.g., 15m, 30m, 1h, 2h, 1d, 7d)'
    )
    
    parser.add_argument(
        '--limit',
        type=int,
        default=100,
        help='Maximum number of logs to retrieve (default: 100)'
    )
    
    parser.add_argument(
        '--json',
        action='store_true',
        help='Output logs in JSON format'
    )
    
    args = parser.parse_args()
    
    query_datadog_logs(args.query, args.duration, args.limit, args.json)


if __name__ == '__main__':
    main()
