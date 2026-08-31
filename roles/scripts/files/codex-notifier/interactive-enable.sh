#!/usr/bin/env bash

set -u

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ALL_DIR="$SCRIPT_DIR/sounds/all"
ENABLED_DIR="$SCRIPT_DIR/sounds/enabled"
COMPLETES_DIR="$ENABLED_DIR/completes"
QUESTIONS_DIR="$ENABLED_DIR/questions"

if ! command -v afplay >/dev/null 2>&1; then
  printf 'Required command not found: afplay\n' >&2
  exit 1
fi

mkdir -p "$ALL_DIR" "$COMPLETES_DIR" "$QUESTIONS_DIR"
shopt -s nullglob
sound_count=0

prompt_category() {
  local label="$1"
  local category_dir="$2"
  local filename="$3"
  local answer

  while true; do
    read -r -p "Enable for $label notifications? [y/n/q] " answer
    case "$answer" in
      y|Y)
        ln -sfn "../../all/$filename" "$category_dir/$filename"
        printf 'Enabled for %s: %s\n' "$label" "$filename"
        return 0
        ;;
      n|N)
        if [[ -L "$category_dir/$filename" ]]; then
          rm "$category_dir/$filename"
        fi
        printf 'Disabled for %s: %s\n' "$label" "$filename"
        return 0
        ;;
      q|Q)
        return 1
        ;;
      *)
        printf 'Please enter y, n, or q.\n'
        ;;
    esac
  done
}

for sound in "$ALL_DIR"/*; do
  [[ -f "$sound" ]] || continue
  ((sound_count += 1))
  filename="${sound##*/}"

  printf '\nPlaying: %s\n' "$filename"
  afplay "$sound"

  if ! prompt_category "complete" "$COMPLETES_DIR" "$filename"; then
    printf 'Stopped.\n'
    exit 0
  fi
  if ! prompt_category "question" "$QUESTIONS_DIR" "$filename"; then
    printf 'Stopped.\n'
    exit 0
  fi
done

if (( sound_count == 0 )); then
  printf 'No sounds found. Run %s/get-sounds.sh first.\n' "$SCRIPT_DIR" >&2
  exit 1
fi
