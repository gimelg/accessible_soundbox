#!/bin/bash
set -e

AUDIO_DIR="/home/USER/audiobooks"
FIFO="/tmp/audiobox_fifo"
STATE="/home/USER/.audiobox_state"

# Reset state to IDLE on boot
rm -f "$STATE"

# Create FIFO
if [ ! -p "$FIFO" ]; then
  rm -f "$FIFO"
  mkfifo "$FIFO"
fi

mkdir -p "$AUDIO_DIR"
cd "$AUDIO_DIR" || exit 0

# mplayer runs idle waiting for commands
exec mplayer -slave -idle -quiet -input file="$FIFO"

