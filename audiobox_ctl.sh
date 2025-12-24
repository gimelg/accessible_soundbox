#!/bin/bash
set -euo pipefail

FIFO="/tmp/audiobox_fifo"

if [ ! -p "$FIFO" ]; then
  echo "Control FIFO not found: $FIFO" >&2
  exit 1
fi

cmd="${1:-}"
shift || true

quote_path() {
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  printf "\"%s\"" "$s"
}

case "$cmd" in
  loadfile)
    # loadfile <file> [append_mode]
    file="${1:-}"
    mode="${2:-0}"
    printf "%s %s %s\n" "$cmd" "$(quote_path "$file")" "$mode" > "$FIFO"
    ;;

  loadlist)
    # loadlist <playlist> [append_mode]
    file="${1:-}"
    mode="${2:-0}"
    printf "%s %s %s\n" "$cmd" "$(quote_path "$file")" "$mode" > "$FIFO"
    ;;

  *)
    # Generic commands (pt_step, pause, stop, etc.)
    # Keep numeric args unquoted.
    printf "%s" "$cmd" > "$FIFO"
    if [[ $# -gt 0 ]]; then
      printf " %s" "$@" >> "$FIFO"
    fi
    printf "\n" >> "$FIFO"
    ;;
esac
