#!/usr/bin/env bash

DEBUG=true

set -u

LOG_DIR="/tmp/notifier-debug"
DEFAULT_SOUND_FILE="/System/Library/Sounds/Glass.aiff"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ENABLED_SOUND_ROOT="$SCRIPT_DIR/sounds/enabled"
log_file=""

debug_log() {
  if [[ "$DEBUG" == true && -n "$log_file" ]]; then
    printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >> "$log_file"
  fi
}

initialize_debug_log() {
  [[ "$DEBUG" == true ]] || return 0

  if ! mkdir -p "$LOG_DIR" 2>/dev/null; then
    printf 'Unable to create log directory: %s\n' "$LOG_DIR" >&2
    return 1
  fi

  local timestamp
  timestamp="$(date '+%Y%m%d-%H%M%S')"
  log_file="$LOG_DIR/notification-log-$timestamp-$$.log"
  {
    printf '[%s] Notifier invoked\n' "$(date '+%Y-%m-%d %H:%M:%S')"
    printf 'PID: %s\n' "$$"
    printf 'PPID: %s\n' "$PPID"
    printf 'Script: %s\n' "${BASH_SOURCE[0]}"
    printf 'Working directory: %s\n' "$PWD"
    printf 'Argument count: %s\n' "$#"
    printf 'Stdin is TTY: %s\n' "$([[ -t 0 ]] && printf true || printf false)"
    printf 'TMUX_PANE: %s\n' "${TMUX_PANE:-unset}"
    printf 'PATH: %s\n' "$PATH"
  } >> "$log_file"
}

initialize_debug_log "$@" || exit 1
trap 'notifier_status=$?; debug_log "Notifier exiting with status $notifier_status"' EXIT

send_notification() {
  osascript -l JavaScript - "$title" "$subtitle" "$body" <<'JAVASCRIPT'
function run(argv) {
  const app = Application.currentApplication();
  app.includeStandardAdditions = true;
  app.displayNotification(argv[2], {
    withTitle: argv[0],
    subtitle: argv[1]
  });
}
JAVASCRIPT
}

if (( $# > 0 )); then
  payload="$*"
  debug_log "Payload source: arguments"
elif [[ ! -t 0 ]]; then
  payload="$(</dev/stdin)"
  debug_log "Payload source: stdin"
else
  debug_log "No payload received"
  printf 'Usage: %s <notification JSON> (or pipe JSON on stdin)\n' "${0##*/}" >&2
  exit 64
fi

debug_log "Raw payload: $payload"

title="Codex"
subtitle="Notification"
body="$payload"
tmux_details="unavailable"
notification_category="completes"
event_type="notification"
tool_name=""

if ! command -v jq >/dev/null 2>&1; then
  debug_log "JSON parsing skipped: jq is unavailable"
elif ! jq -e . >/dev/null 2>&1 <<< "$payload"; then
  debug_log "JSON parsing skipped: payload is not valid JSON"
else
  debug_log "JSON payload validated"
  client="$(jq -r '.client // ""' <<< "$payload")"
  if [[ "$client" == "Codex Desktop" ]]; then
    debug_log "Notification suppressed: Codex Desktop client"
    exit 0
  fi

  # Codex runs a hidden turn to generate the short title shown in its UI. Its
  # completion is delivered through the same notification hook as real turns,
  # but the JSON response (for example, {"title":"Fix tests"}) is not a user-
  # facing assistant message.
  if jq -e '
    .type == "agent-turn-complete"
    and any(."input-messages"[]?;
      startswith("Generate a concise, single-line task title"))
  ' >/dev/null 2>&1 <<< "$payload"; then
    debug_log "Notification suppressed: hidden task-title turn"
    exit 0
  fi

  event_type="$(jq -r '.type // .hook_event_name // .hookEventName // "notification"' <<< "$payload")"
  cwd="$(jq -r '.cwd // ""' <<< "$payload")"
  body="$(jq -r '."last-assistant-message" // .message // .reason // empty' <<< "$payload")"

  [[ -n "$body" ]] || body="$payload"

  case "$event_type" in
    PreToolUse)
      tool_name="$(jq -r '.tool_name // ""' <<< "$payload")"
      if [[ "$tool_name" == "request_user_input" ]]; then
        notification_category="questions"
        status="Question"
        body="$(jq -r '
          .tool_input.questions[0].question
          // .tool_input.question
          // .tool_input.prompt
          // "Codex is waiting for your input."
        ' <<< "$payload")"
      else
        status="$event_type"
      fi
      ;;
    PermissionRequest|*question*|*input*|*approval*)
      notification_category="questions"
      status="Question"
      if [[ "$event_type" == "PermissionRequest" ]]; then
        body="$(jq -r '.reason // .message // "Codex is requesting permission."' <<< "$payload")"
      fi
      ;;
    agent-turn-complete)
      if [[ "$body" =~ \?[[:space:]]*$ ]]; then
        notification_category="questions"
        status="Question"
      else
        status="Complete"
      fi
      ;;
    *) status="$event_type" ;;
  esac

  if [[ -n "$cwd" ]]; then
    subtitle="$status · ${cwd##*/}"
  else
    subtitle="$status"
  fi
fi

if [[ -n "${TMUX_PANE:-}" ]] && command -v tmux >/dev/null 2>&1; then
  tmux_label="$(tmux display-message -p -t "$TMUX_PANE" \
    '#S:#I.#P' 2>/dev/null || true)"
  tmux_details="$(tmux display-message -p -t "$TMUX_PANE" \
    '#S:#I.#P · #{pane_current_command} · #{pane_current_path}' \
    2>/dev/null || true)"

  if [[ -n "$tmux_label" ]]; then
    title="Codex · $tmux_label"
  fi
  [[ -n "$tmux_details" ]] || tmux_details="unavailable"
fi

sound_file="$DEFAULT_SOUND_FILE"
ENABLED_SOUND_DIR="$ENABLED_SOUND_ROOT/$notification_category"
if [[ -d "$ENABLED_SOUND_DIR" ]]; then
  shopt -s nullglob
  enabled_count=0
  for candidate in "$ENABLED_SOUND_DIR"/*; do
    if [[ -f "$candidate" ]]; then
      enabled_sounds[$enabled_count]="$candidate"
      ((enabled_count += 1))
    fi
  done

  if (( enabled_count > 0 )); then
    sound_file="${enabled_sounds[RANDOM % enabled_count]}"
  fi
fi

if [[ "$DEBUG" == true ]]; then
  {
    printf 'Event type: %s\n' "$event_type"
    printf 'Tool name: %s\n' "${tool_name:-none}"
    printf 'Tmux: %s\n' "$tmux_details"
    printf 'Title: %s\n' "$title"
    printf 'Subtitle: %s\n' "$subtitle"
    printf 'Body: %s\n' "$body"
    printf 'Category: %s\n' "$notification_category"
    printf 'Sound: %s\n' "$sound_file"
    printf 'Sound exists: %s\n' "$([[ -f "$sound_file" ]] && printf true || printf false)"
    printf 'afplay command: %s\n' "$(command -v afplay 2>/dev/null || printf unavailable)"
    printf 'osascript command: %s\n' "$(command -v osascript 2>/dev/null || printf unavailable)"
  } >> "$log_file"
fi

if [[ -f "$sound_file" ]]; then
  if [[ "$DEBUG" == true ]]; then
    (
      debug_log "Audio started: $sound_file"
      audio_output="$(afplay "$sound_file" 2>&1)"
      audio_status=$?
      if [[ -n "$audio_output" ]]; then
        debug_log "Audio output: $audio_output"
      fi
      debug_log "Audio exited with status $audio_status"
    ) &
  else
    afplay "$sound_file" >/dev/null 2>&1 &
  fi
  audio_pid=$!
  debug_log "Audio PID: $audio_pid"
else
  debug_log "Audio skipped: sound file does not exist"
fi

debug_log "Notification delivery started"
if [[ "$DEBUG" == true ]]; then
  notification_output="$(send_notification 2>&1)"
  notification_status=$?
  if [[ -n "$notification_output" ]]; then
    debug_log "Notification output: $notification_output"
  fi
else
  send_notification
  notification_status=$?
fi
debug_log "Notification delivery exited with status $notification_status"
exit "$notification_status"
