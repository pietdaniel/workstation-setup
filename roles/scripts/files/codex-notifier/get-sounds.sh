#!/usr/bin/env bash

set -euo pipefail

BOARD_URL="https://www.101soundboards.com/boards/40988-starcraft-soundboard"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ALL_DIR="$SCRIPT_DIR/sounds/all"
ENABLED_DIR="$SCRIPT_DIR/sounds/enabled"
TRIM_SCRIPT="$SCRIPT_DIR/trim-mp3.py"
force_download=false

if [[ "${1:-}" == "--force" ]]; then
  force_download=true
elif (( $# > 0 )); then
  printf 'Usage: %s [--force]\n' "${0##*/}" >&2
  exit 64
fi

for command_name in curl python3; do
  if ! command -v "$command_name" >/dev/null 2>&1; then
    printf 'Required command not found: %s\n' "$command_name" >&2
    exit 1
  fi
done

if [[ ! -f "$TRIM_SCRIPT" ]]; then
  printf 'Required helper not found: %s\n' "$TRIM_SCRIPT" >&2
  exit 1
fi

mkdir -p "$ALL_DIR" "$ENABLED_DIR"

temp_dir="$(mktemp -d)"
trap 'rm -rf "$temp_dir"' EXIT
seen_urls="$temp_dir/seen-urls"
: > "$seen_urls"

downloaded=0
page=1

while (( page <= 100 )); do
  page_url="$BOARD_URL"
  if (( page > 1 )); then
    page_url="$BOARD_URL?page=$page"
  fi

  html_file="$temp_dir/page-$page.html"
  manifest_file="$temp_dir/page-$page.tsv"

  printf 'Reading page %d...\n' "$page"
  if ! curl -L --fail --silent --show-error --retry 3 \
    "$page_url" -o "$html_file"; then
    if (( page > 1 )); then
      printf 'Reached the end after page %d.\n' "$((page - 1))"
      break
    fi
    printf 'Unable to download the soundboard page.\n' >&2
    exit 1
  fi

  python3 - "$html_file" > "$manifest_file" <<'PYTHON'
import json
import re
import sys
import unicodedata
from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import urlsplit, urlunsplit


LICENSE_ALPHABET = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"


class JsonLdParser(HTMLParser):
    def __init__(self):
        super().__init__()
        self.in_json_ld = False
        self.parts = []
        self.documents = []
        self.sources = []

    def handle_starttag(self, tag, attrs):
        attributes = dict(attrs)
        if tag == "script" and attributes.get("type") == "application/ld+json":
            self.in_json_ld = True
            self.parts = []
        elif tag == "source":
            url = attributes.get("data-sound-filename-url") or attributes.get("data-sound-file-url")
            if url:
                self.sources.append((url, attributes.get("data-sound-license")))

    def handle_data(self, data):
        if self.in_json_ld:
            self.parts.append(data)

    def handle_endtag(self, tag):
        if tag == "script" and self.in_json_ld:
            self.documents.append("".join(self.parts))
            self.in_json_ld = False


def walk(value):
    if isinstance(value, dict):
        if value.get("@type") == "AudioObject" and value.get("contentUrl"):
            yield value
        for child in value.values():
            yield from walk(child)
    elif isinstance(value, list):
        for child in value:
            yield from walk(child)


def slugify(value):
    value = unicodedata.normalize("NFKD", value).encode("ascii", "ignore").decode()
    value = re.sub(r"[^a-zA-Z0-9]+", "-", value).strip("-").lower()
    return value[:100] or "sound"


def resolve_sound_url(url, license_code):
    if not license_code or license_code not in LICENSE_ALPHABET:
        return url

    parts = urlsplit(url)
    pattern = re.compile(
        r"((?:/storage)?/(?:public/)?(?:board_sounds|board_sounds_rendered|sounds)/)(\d+)(?=[.-])"
    )
    match = pattern.search(parts.path)
    if not match:
        return url

    encoded_id = int(match.group(2))
    license_index = LICENSE_ALPHABET.index(license_code)
    offset = 104729 + license_index * 1000003
    multiplier = 17 + license_index * 12
    remainder = encoded_id - offset

    if remainder <= 0 or remainder % multiplier != 0:
        return url

    sound_id = remainder // multiplier
    if not 1 <= sound_id <= 4294967295:
        return url

    path = parts.path[:match.start(2)] + str(sound_id) + parts.path[match.end(2):]
    return urlunsplit((parts.scheme, parts.netloc, path, parts.query, parts.fragment))


page_text = Path(sys.argv[1]).read_text(errors="replace")
parser = JsonLdParser()
parser.feed(page_text)
audio_objects = []
skip_by_id = {}

marker = "var board_data_inline = "
marker_position = page_text.find(marker)
if marker_position >= 0:
    try:
        board_data, _ = json.JSONDecoder().raw_decode(
            page_text[marker_position + len(marker):]
        )
        skip_by_id = {
            str(sound["id"]): int(sound.get("sound_skip", 0)) * 100
            for sound in board_data.get("sounds", [])
            if "id" in sound
        }
    except (json.JSONDecodeError, TypeError, ValueError):
        pass

for document in parser.documents:
    try:
        data = json.loads(document)
    except json.JSONDecodeError:
        continue

    audio_objects.extend(walk(data))

emitted = set()
for index, audio in enumerate(audio_objects):
        if index < len(parser.sources):
            source_url, license_code = parser.sources[index]
            url = resolve_sound_url(source_url, license_code)
        else:
            url = audio["contentUrl"]

        if url in emitted:
            continue
        emitted.add(url)

        sound_id_match = re.search(r"/sounds/(\d+)", audio.get("@id", ""))
        sound_id = sound_id_match.group(1) if sound_id_match else "unknown"
        suffix = Path(urlsplit(url).path).suffix.lower() or ".mp3"
        filename = f"{slugify(audio.get('name', 'sound'))}-{sound_id}{suffix}"
        print(f"{filename}\t{url}\t{skip_by_id.get(sound_id, 0)}")
PYTHON

  if [[ ! -s "$manifest_file" ]]; then
    break
  fi

  new_on_page=0
  while IFS=$'\t' read -r filename sound_url skip_ms; do
    [[ -n "$filename" && -n "$sound_url" ]] || continue

    canonical_url="${sound_url%%\?*}"
    if grep -Fqx -- "$canonical_url" "$seen_urls"; then
      continue
    fi
    printf '%s\n' "$canonical_url" >> "$seen_urls"
    ((new_on_page += 1))

    destination="$ALL_DIR/$filename"
    if [[ -f "$destination" && "$force_download" != true ]]; then
      printf 'Already downloaded: %s\n' "$filename"
      continue
    fi

    printf 'Downloading: %s\n' "$filename"
    curl -L --fail --silent --show-error --retry 3 \
      "$sound_url" -o "$destination.part"
    if (( skip_ms > 0 )); then
      python3 "$TRIM_SCRIPT" "$destination.part" "$destination.trimmed" "$skip_ms"
      mv "$destination.trimmed" "$destination"
      rm "$destination.part"
    else
      mv "$destination.part" "$destination"
    fi
    ((downloaded += 1))
  done < "$manifest_file"

  if (( new_on_page == 0 )); then
    break
  fi

  ((page += 1))
done

printf 'Done. Downloaded %d new sound(s) into %s\n' "$downloaded" "$ALL_DIR"
