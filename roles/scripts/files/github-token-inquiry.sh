#!/usr/bin/env bash
TOKEN=$1
echo "Scopes:"
curl -sS -f -I \
  -H "Authorization: token $TOKEN" \
  https://api.github.com | grep -i ^x-oauth-scopes
echo "User:"
curl -s -L \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer $TOKEN" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  https://api.github.com/user | jq
echo "Emails:"
curl -s -L \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer $GITHUB_PAT" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  https://api.github.com/user/emails | jq
