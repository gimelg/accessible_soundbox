#!/bin/bash

AUDIO_DIR="/home/USER/audiobooks"
CTL="/home/USER/audiobox_ctl.sh"
STATE="/home/USER/.audiobox_state"

shopt -s nullglob
files=("$AUDIO_DIR"/*)

# If no files, do nothing
if [ ${#files[@]} -eq 0 ]; then
  exit 0
fi

# Stop current playback
$CTL stop

# Build playlist
first=1
for f in "${files[@]}"; do
  base="$(basename "$f")"
  [[ "$base" == .* ]] && continue

  if [ $first -eq 1 ]; then
    $CTL loadfile "$f" 0
    first=0
  else
    $CTL loadfile "$f" 1
  fi
done

# Update state
echo "PLAYING" > "$STATE"

