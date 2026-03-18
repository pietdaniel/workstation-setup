#!/usr/bin/env bash
# quick.sh — fast CLI Q&A via opencode run + sonnet
set -euo pipefail

Q="${*:-How do I fix 'permission denied' when running a script?}"

# Colors
C='\033[36m' B='\033[1m' G='\033[32m' Y='\033[1;33m' R='\033[0m' D='\033[2m'

echo -e "${D}───────────────────────────────────${R}"
echo -e "${B}${C} LLM CLI AnswerBot${R}"
echo -e "${D}───────────────────────────────────${R}"
echo -e "${D}Q:${R} ${B}${Q}${R}\n"

opencode run \
  -m anthropic/claude-haiku-4-5 \
  "You are a terse Unix expert. Answer in ≤3 bullet points. No intro, no summary, no pleasantries. Raw practical answer only. Question: ${Q}" 2>/dev/null \
  | sed -E "s/^([-•*] )/$(printf '\033[32m')\\1$(printf '\033[0m')/" \
  | sed -E "s/\`([^\`]+)\`/$(printf '\033[1;33m')\\1$(printf '\033[0m')/g"

echo -e "\n${D}───────────────────────────────────${R}"
