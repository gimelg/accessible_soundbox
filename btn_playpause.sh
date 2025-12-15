#!/bin/bash

STATE="/home/USER/.audiobox_state"
CTL="/home/USER/audiobox_ctl.sh"
LOAD="/home/USER/load_playlist.sh"

# No state file → nothing has ever played → start playback
if [ ! -f "$STATE" ]; then
    $LOAD
    exit 0
fi

status=$(cat "$STATE")

case "$status" in
    PLAYING)
        # Pause playback
        $CTL pause
        echo "PAUSED" > "$STATE"
        ;;
    PAUSED)
        # Resume playback
        $CTL pause
        echo "PLAYING" > "$STATE"
        ;;
    IDLE|STOPPED|"")
        # Playlist ended → restart from beginning
        $LOAD
        ;;
    *)
        # Unknown state → safest fallback
        $LOAD
        ;;
esac

