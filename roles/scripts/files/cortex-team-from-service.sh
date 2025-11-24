#!/usr/bin/env bash

SERVICE_NAME="$1"
API_KEY=""

curl -X GET "https://cortex-api.eng.roktinternal.com/api/v1/services/$SERVICE_NAME" \
  -H "Authorization: Bearer $API_KEY" \
  -H "Content-Type: application/json" | jq
