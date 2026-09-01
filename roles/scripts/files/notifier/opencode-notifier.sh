#!/usr/bin/env bash

set -u

DEFAULT_SOUND_FILE="/System/Library/Sounds/Glass.aiff"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ENABLED_SOUND_ROOT="$SCRIPT_DIR/sounds/enabled"

event_type="${1:-}"
message="${2:-OpenCode needs your attention.}"
project_name="${3:-}"

case "$event_type" in
  permission|question)
    notification_category="questions"
    status="Question"
    ;;
  complete|subagent_complete|error|plan_exit)
    notification_category="completes"
    status="Complete"
    ;;
  *)
    exit 0
    ;;
esac

title="OpenCode"
if [[ -n "${TMUX_PANE:-}" ]] && command -v tmux >/dev/null 2>&1; then
  tmux_label="$(tmux display-message -p -t "$TMUX_PANE" '#S:#I.#P' 2>/dev/null || true)"
  [[ -z "$tmux_label" ]] || title+=" - $tmux_label"
fi

subtitle="$status"
[[ -z "$project_name" ]] || subtitle+=" - $project_name"

sound_file="$DEFAULT_SOUND_FILE"
enabled_sound_dir="$ENABLED_SOUND_ROOT/$notification_category"
if [[ -d "$enabled_sound_dir" ]]; then
  shopt -s nullglob
  enabled_sounds=("$enabled_sound_dir"/*)
  if (( ${#enabled_sounds[@]} > 0 )); then
    sound_file="${enabled_sounds[RANDOM % ${#enabled_sounds[@]}]}"
  fi
fi

if [[ -f "$sound_file" ]] && command -v afplay >/dev/null 2>&1; then
  afplay "$sound_file" >/dev/null 2>&1 &
fi

if command -v osascript >/dev/null 2>&1; then
  osascript -l JavaScript - "$title" "$subtitle" "$message" <<'JAVASCRIPT'
function run(argv) {
  const app = Application.currentApplication();
  app.includeStandardAdditions = true;
  app.displayNotification(argv[2], {
    withTitle: argv[0],
    subtitle: argv[1]
  });
}
JAVASCRIPT
fi
