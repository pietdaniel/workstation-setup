---
name: cortex
description: "Query the Cortex REST API using CORTEX_API_KEY (bearer auth) against https://cortex-api.eng.roktinternal.com. Use for fetching Cortex entities, scorecards, workflows, or related metadata from the Cortex API."
---

# Cortex

## Overview

Use the Cortex REST API (CORTEX_API_KEY bearer auth) to fetch data from the Cortex platform. Reference docs: `references/cortex-api.md`.

## Quick start

1) Ensure `CORTEX_API_KEY` is available in the environment.
2) Use the base URL: `https://cortex-api.eng.roktinternal.com`.
3) Call the endpoint needed for the user request.

Example pattern:

```bash
curl -sS \
  -H "Authorization: Bearer $CORTEX_API_KEY" \
  -H "Content-Type: application/json" \
  "https://cortex-api.eng.roktinternal.com/<endpoint>"
```

## Notes

- Rate limits: 1000 req/min, 2MB body; 429 on limit (see docs).
- Prefer reading the official API docs for endpoint-specific payloads.
