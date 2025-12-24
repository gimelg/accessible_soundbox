#!/bin/bash
set -euo pipefail

AUDIO_DIR="/home/gershon/audiobooks"
CTL="/home/gershon/audiobox_ctl.sh"
STATE="/home/gershon/.audiobox_state"
PLAYLIST="/tmp/audiobox.m3u"

shopt -s nullglob

# Build M3U playlist (one absolute path per line)
: > "$PLAYLIST"
for f in "$AUDIO_DIR"/*; do
  base="$(basename "$f")"
  [[ "$base" == .* ]] && continue
  [[ "$base" == "._"* ]] && continue
  [[ "$base" == ".DS_Store" ]] && continue
  [[ -f "$f" ]] || continue
  echo "$f" >> "$PLAYLIST"
done

# If no files, do nothing
if [ ! -s "$PLAYLIST" ]; then
  exit 0
fi

# Stop current playback
"$CTL" stop

# Load the playlist file as the playtree (replace current)
"$CTL" loadlist "$PLAYLIST" 0

# Start playback at first entry
"$CTL" pt_step 1

# Update state
echo "PLAYING" > "$STATE"
