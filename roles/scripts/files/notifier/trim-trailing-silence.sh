#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ALL_DIR="$SCRIPT_DIR/sounds/all"
SILENCE_THRESHOLD="-45dB"
MIN_SILENCE_DURATION="0.10"

if ! command -v ffmpeg >/dev/null 2>&1; then
  printf 'Required command not found: ffmpeg\n' >&2
  printf 'Install it with: brew install ffmpeg\n' >&2
  exit 1
fi

if [[ ! -d "$ALL_DIR" ]]; then
  printf 'Sound directory not found: %s\n' "$ALL_DIR" >&2
  exit 1
fi

shopt -s nullglob
sound_count=0

for sound in "$ALL_DIR"/*.mp3; do
  ((sound_count += 1))
  temporary_file="${sound%.mp3}.trimmed.mp3"
  printf 'Trimming: %s\n' "${sound##*/}"

  if ffmpeg -hide_banner -loglevel error -y \
    -i "$sound" \
    -af "areverse,silenceremove=start_periods=1:start_duration=$MIN_SILENCE_DURATION:start_threshold=$SILENCE_THRESHOLD,areverse" \
    -codec:a libmp3lame -q:a 2 \
    "$temporary_file"; then
    mv "$temporary_file" "$sound"
  else
    rm -f "$temporary_file"
    printf 'Failed: %s\n' "${sound##*/}" >&2
  fi
done

if (( sound_count == 0 )); then
  printf 'No MP3 files found in %s\n' "$ALL_DIR" >&2
  exit 1
fi

printf 'Finished trimming trailing silence from %d sound(s).\n' "$sound_count"
