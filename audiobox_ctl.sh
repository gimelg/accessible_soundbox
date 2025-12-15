#!/bin/bash
FIFO="/tmp/audiobox_fifo"

if [ ! -p "$FIFO" ]; then
  echo "Control FIFO not found: $FIFO" >&2
  exit 1
fi

# Forward all arguments as one command line to mplayer
echo "$@" > "$FIFO"

