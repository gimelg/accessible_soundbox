#!/usr/bin/env bash
set -euo pipefail

# ------------------------------------------------------------
# Audiobox install.sh (no-wrap version; loadlist/M3U playlist)
# ------------------------------------------------------------
# Usage:
#   sudo ./install.sh
#   sudo ./install.sh --user <username>
#
# Behavior:
# - Installs mplayer + gpiozero + espeak-ng
# - Creates user scripts in the target user's home
# - Installs and enables:
#     audiobox-player.service
#     audiobox-gpio.service
#     usb-watcher.service
#     audiobox-boot-ready.service   (NEW)
#
# Notes:
# - Next/Prev do NOT wrap in this version (pt_step ±1).
# - Playlist loading uses an M3U and mplayer "loadlist" for reliable stepping.
# - NEW: On boot, speaks "Hello, soundbox is ready."
# ------------------------------------------------------------

TARGET_USER=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --user)
      TARGET_USER="${2:-}"
      shift 2
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

if [[ "$(id -u)" -ne 0 ]]; then
  echo "ERROR: Must be run as root (use sudo)." >&2
  exit 1
fi

if [[ -z "${TARGET_USER}" ]]; then
  if [[ -n "${SUDO_USER:-}" && "${SUDO_USER}" != "root" ]]; then
    TARGET_USER="${SUDO_USER}"
  else
    echo "ERROR: Could not determine target user. Use --user <username>." >&2
    exit 1
  fi
fi

TARGET_HOME="$(getent passwd "${TARGET_USER}" | cut -d: -f6)"
if [[ -z "${TARGET_HOME}" || ! -d "${TARGET_HOME}" ]]; then
  echo "ERROR: Home directory not found for user '${TARGET_USER}'." >&2
  exit 1
fi

echo "Installing Audiobox for user: ${TARGET_USER}"
echo "Home directory: ${TARGET_HOME}"

# ----------------------------
# Helpers
# ----------------------------
subst_user_home() {
  local content="$1"
  # Replace /home/USER -> actual home
  content="${content//\/home\/USER/${TARGET_HOME}}"
  # Replace USER token -> actual username
  content="${content//USER/${TARGET_USER}}"
  printf "%s" "$content"
}

write_user_file() {
  local path="$1"
  local content="$2"
  install -d "$(dirname "$path")"
  subst_user_home "$content" > "$path"
  chown "${TARGET_USER}:${TARGET_USER}" "$path"
}

write_root_file() {
  local path="$1"
  local content="$2"
  install -d "$(dirname "$path")"
  subst_user_home "$content" > "$path"
}

make_exec_user() {
  local path="$1"
  chmod +x "$path"
  chown "${TARGET_USER}:${TARGET_USER}" "$path"
}

# ----------------------------
# Packages
# ----------------------------
apt-get update -y
apt-get install -y \
  mplayer \
  python3 \
  python3-gpiozero \
  espeak-ng \
  util-linux

# ----------------------------
# Base dirs / files
# ----------------------------
install -d -o "${TARGET_USER}" -g "${TARGET_USER}" "${TARGET_HOME}/audiobooks"
touch "${TARGET_HOME}/usb-import.log"
chown "${TARGET_USER}:${TARGET_USER}" "${TARGET_HOME}/usb-import.log"

# State file is created but the player script deletes it on boot (by design)
touch "${TARGET_HOME}/.audiobox_state"
chown "${TARGET_USER}:${TARGET_USER}" "${TARGET_HOME}/.audiobox_state"

install -d /media/usb

# ----------------------------
# User scripts
# ----------------------------

write_user_file "${TARGET_HOME}/start_audiobox_player.sh" \
'#!/bin/bash
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
'
make_exec_user "${TARGET_HOME}/start_audiobox_player.sh"

# Updated: command-aware ctl that quotes only paths for loadfile/loadlist.
write_user_file "${TARGET_HOME}/audiobox_ctl.sh" \
'#!/bin/bash
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
'
make_exec_user "${TARGET_HOME}/audiobox_ctl.sh"

# Updated: load_playlist uses M3U + loadlist (reliable playtree)
write_user_file "${TARGET_HOME}/load_playlist.sh" \
'#!/bin/bash
set -euo pipefail

AUDIO_DIR="/home/USER/audiobooks"
CTL="/home/USER/audiobox_ctl.sh"
STATE="/home/USER/.audiobox_state"
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
"$CTL" pt_play

# Update state
echo "PLAYING" > "$STATE"
'
make_exec_user "${TARGET_HOME}/load_playlist.sh"

write_user_file "${TARGET_HOME}/btn_playpause.sh" \
'#!/bin/bash

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
'
make_exec_user "${TARGET_HOME}/btn_playpause.sh"

# No-wrap version
write_user_file "${TARGET_HOME}/btn_next.sh" \
'#!/bin/bash
/home/USER/audiobox_ctl.sh pt_step 1
'
make_exec_user "${TARGET_HOME}/btn_next.sh"

write_user_file "${TARGET_HOME}/btn_prev.sh" \
'#!/bin/bash
/home/USER/audiobox_ctl.sh pt_step -1
'
make_exec_user "${TARGET_HOME}/btn_prev.sh"

write_user_file "${TARGET_HOME}/audiobox_gpio.py" \
'#!/usr/bin/env python3
from gpiozero import Button
from signal import pause
import subprocess
import time

# BCM pins
PIN_PLAYPAUSE = 17
PIN_NEXT = 27
PIN_PREV = 22

SCRIPT_PLAYPAUSE = "/home/USER/btn_playpause.sh"
SCRIPT_NEXT = "/home/USER/btn_next.sh"
SCRIPT_PREV = "/home/USER/btn_prev.sh"

BOUNCE = 0.10          # debounce (seconds)
MIN_INTERVAL = 0.20    # guard against double-fires
_last = {"pp": 0.0, "n": 0.0, "p": 0.0}

def run_script(path: str) -> None:
    subprocess.Popen([path])

def guarded(key: str, fn) -> None:
    now = time.monotonic()
    if now - _last[key] >= MIN_INTERVAL:
        _last[key] = now
        fn()

playpause = Button(PIN_PLAYPAUSE, pull_up=True, bounce_time=BOUNCE)
next_btn  = Button(PIN_NEXT,      pull_up=True, bounce_time=BOUNCE)
prev_btn  = Button(PIN_PREV,      pull_up=True, bounce_time=BOUNCE)

playpause.when_pressed = lambda: guarded("pp", lambda: run_script(SCRIPT_PLAYPAUSE))
next_btn.when_pressed  = lambda: guarded("n",  lambda: run_script(SCRIPT_NEXT))
prev_btn.when_pressed  = lambda: guarded("p",  lambda: run_script(SCRIPT_PREV))

pause()
'
make_exec_user "${TARGET_HOME}/audiobox_gpio.py"

# NEW: Boot greeting script (runs once per boot via systemd)
write_user_file "${TARGET_HOME}/audiobox_boot_ready.sh" \
'#!/bin/bash
set -e

# Small delay to ensure audio stack is ready
sleep 2

espeak-ng "Hello, soundbox is ready."
'
make_exec_user "${TARGET_HOME}/audiobox_boot_ready.sh"

# usb_manager.py (as provided; USER token substituted)
write_user_file "${TARGET_HOME}/usb_manager.py" \
'#!/usr/bin/env python3
import shutil
import time
from pathlib import Path
import subprocess

USB_MOUNT = Path("/media/usb")
AUDIO_DIR = Path("/home/USER/audiobooks")
LOG_FILE = Path("/home/USER/usb-import.log")

REBOOT_FILE_DEFAULT = """### Remove the "–" before Reboot to reboot the soundbox. ###
– Reboot
"""


def speak(msg: str) -> None:
    """Speak a message aloud if espeak-ng is installed."""
    try:
        subprocess.run(["espeak-ng", msg])
    except Exception:
        pass


def log(msg: str) -> None:
    LOG_FILE.parent.mkdir(parents=True, exist_ok=True)
    with LOG_FILE.open("a", encoding="utf-8") as f:
        f.write(f"{time.ctime()}: {msg}\n")


def safe_copy(src: Path, dst_dir: Path) -> None:
    dst_dir.mkdir(parents=True, exist_ok=True)
    dst = dst_dir / src.name
    shutil.copy2(src, dst)
    log(f"Copied: {src} → {dst}")


def safe_delete(filename: str, target_dir: Path) -> bool:
    target = target_dir / filename
    if target.exists():
        target.unlink()
        log(f"Deleted: {target}")
        return True
    return False


def parse_deletion_from_library(library_path: Path) -> list[str]:
    if not library_path.exists():
        return []

    deletion: list[str] = []
    section = None

    try:
        with library_path.open("r", encoding="utf-8") as f:
            for line in f:
                stripped = line.strip()
                if stripped.lower().startswith("inventory"):
                    section = "inventory"
                    continue
                if stripped.lower().startswith("deletion"):
                    section = "deletion"
                    continue
                if not stripped:
                    continue

                if section == "deletion" and not stripped.startswith(".") and not stripped.startswith("#"):
                    deletion.append(stripped)

    except Exception as e:
        log(f"Error parsing library.txt ({library_path}): {e}")

    return deletion


def write_library_to_usb() -> None:
    try:
        if not USB_MOUNT.exists():
            log("USB mount not found; skipping library write")
            return

        library = USB_MOUNT / "library.txt"

        if not AUDIO_DIR.exists():
            entries = []
        else:
            entries = sorted(
                p.name
                for p in AUDIO_DIR.iterdir()
                if p.is_file() and not p.name.startswith(".")
            )

        with library.open("w", encoding="utf-8") as f:
            f.write("Inventory:\n")
            for name in entries:
                f.write(name + "\n")

            f.write("\n")
            f.write("Deletion:\n")

        log("Updated library.txt")

    except Exception as e:
        log(f"Error writing library file: {e}")


def ensure_reboot_file(reboot_file: Path) -> None:
    if not reboot_file.exists():
        try:
            reboot_file.write_text(REBOOT_FILE_DEFAULT, encoding="utf-8")
            log("Created default Reboot.txt")
        except Exception as e:
            log(f"Error creating default Reboot.txt: {e}")


def check_reboot_trigger(reboot_file: Path) -> bool:
    if not reboot_file.exists():
        return False

    try:
        lines = reboot_file.read_text(encoding="utf-8").splitlines()
    except Exception as e:
        log(f"Error reading Reboot.txt: {e}")
        return False

    if len(lines) < 2:
        return False

    return lines[1].strip() == "Reboot"


def restore_reboot_file(reboot_file: Path) -> None:
    try:
        reboot_file.write_text(REBOOT_FILE_DEFAULT, encoding="utf-8")
        log("Restored Reboot.txt to default format")
    except Exception as e:
        log(f"Error restoring Reboot.txt: {e}")


def handle_reboot_file() -> bool:
    reboot_file = USB_MOUNT / "Reboot.txt"

    ensure_reboot_file(reboot_file)

    if check_reboot_trigger(reboot_file):
        log("Reboot trigger detected via Reboot.txt")

        # Restore first so reboot loop cant happen
        restore_reboot_file(reboot_file)

        speak("Rebooting now.")

        try:
            subprocess.run(["sync"])
        except Exception:
            pass

        log("Rebooting now…")
        try:
            subprocess.run(["reboot"])
        except Exception as e:
            log(f"Reboot error: {e}")

        return True

    return False


def process_usb() -> None:
    if handle_reboot_file():
        return

    add_dir = USB_MOUNT / "Add"
    if add_dir.exists():
        added = False
        for f in add_dir.iterdir():
            if f.is_file() and not f.name.startswith("."):
                safe_copy(f, AUDIO_DIR)
                added = True
        if added:
            speak("New books added")

    library = USB_MOUNT / "library.txt"
    to_delete = parse_deletion_from_library(library)
    if to_delete:
        log(f"Requested deletions: {to_delete}")
        deleted = False
        for name in to_delete:
            if safe_delete(name, AUDIO_DIR):
                deleted = True
        if deleted:
            speak("Books deleted")

    write_library_to_usb()


if __name__ == "__main__":
    time.sleep(3)
    process_usb()
'
make_exec_user "${TARGET_HOME}/usb_manager.py"

# watch_usb.py (same functionality; corrected newline)
write_user_file "${TARGET_HOME}/watch_usb.py" \
'#!/usr/bin/env python3
import subprocess
import time
from pathlib import Path
import json

MOUNTPOINT = Path("/media/usb")
LOG_FILE = Path("/home/USER/usb-import.log")

def log(msg: str) -> None:
    LOG_FILE.parent.mkdir(parents=True, exist_ok=True)
    with LOG_FILE.open("a", encoding="utf-8") as f:
        f.write(time.strftime("%Y-%m-%d %H:%M:%S") + " [watcher] " + msg + "\n")

def find_usb_partition():
    """Return path like /dev/sda1 for a removable, unmounted USB partition, or None."""
    try:
        out = subprocess.check_output(
            ["lsblk", "-J", "-o", "NAME,PATH,RM,MOUNTPOINT"],
            text=True,
        )
    except Exception as e:
        log(f"lsblk failed: {e}")
        return None

    data = json.loads(out)

    def walk(blocks):
        for b in blocks:
            name = b.get("name")
            path = b.get("path")
            rm = b.get("rm")
            mnt = b.get("mountpoint")
            children = b.get("children", [])

            # partitions like sda1: last char digit; removable rm==1; not mounted
            if rm == 1 and name and name[-1].isdigit() and (mnt is None or mnt == ""):
                return path

            if children:
                res = walk(children)
                if res:
                    return res
        return None

    return walk(data.get("blockdevices", []))

def main():
    last_device = None
    LOG_FILE.touch(exist_ok=True)
    log("USB watcher started")

    while True:
        dev = find_usb_partition()

        if dev and dev != last_device:
          log(f"Detected new USB device: {dev}")
          try:
              MOUNTPOINT.mkdir(parents=True, exist_ok=True)

              subprocess.run(
                  ["mount", "-o", "umask=000", dev, str(MOUNTPOINT)],
                  check=True,
              )
              log(f"Mounted {dev} at {MOUNTPOINT}")

              subprocess.run(
                  ["/usr/bin/python3", "/home/USER/usb_manager.py"],
                  check=True,
              )
              log("usb_manager.py completed")

              subprocess.run(["sync"])
              subprocess.run(["umount", str(MOUNTPOINT)], check=True)
              log(f"Unmounted {dev}")

              last_device = dev
          except Exception as e:
              log(f"Error handling {dev}: {e}")

        if not dev:
            if last_device:
                log(f"USB device {last_device} removed")
            last_device = None

        time.sleep(5)

if __name__ == "__main__":
    main()
'
make_exec_user "${TARGET_HOME}/watch_usb.py"

# ----------------------------
# systemd unit files
# ----------------------------

write_root_file "/etc/systemd/system/audiobox-player.service" \
'[Unit]
Description=Audiobook player (mplayer slave)
After=multi-user.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=/home/USER/start_audiobox_player.sh
Restart=always
User=USER
WorkingDirectory=/home/USER

[Install]
WantedBy=multi-user.target
'

write_root_file "/etc/systemd/system/audiobox-gpio.service" \
'[Unit]
Description=Audiobox GPIO button handler
After=multi-user.target audiobox-player.service
Wants=audiobox-player.service

[Service]
Type=simple
User=USER
WorkingDirectory=/home/USER
ExecStart=/usr/bin/python3 /home/USER/audiobox_gpio.py
Restart=always
RestartSec=1

[Install]
WantedBy=multi-user.target
'

write_root_file "/etc/systemd/system/usb-watcher.service" \
'[Unit]
Description=USB Audiobook Watcher
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/python3 /home/USER/watch_usb.py
Restart=always
User=root

[Install]
WantedBy=multi-user.target
'

# NEW: Boot greeting unit (oneshot)
write_root_file "/etc/systemd/system/audiobox-boot-ready.service" \
'[Unit]
Description=Audiobox boot ready announcement
After=audiobox-player.service sound.target
Wants=audiobox-player.service

[Service]
Type=oneshot
User=USER
ExecStart=/home/USER/audiobox_boot_ready.sh

[Install]
WantedBy=multi-user.target
'

# ----------------------------
# Enable + restart services
# ----------------------------
systemctl daemon-reload

systemctl enable audiobox-player.service
systemctl restart audiobox-player.service

systemctl enable audiobox-gpio.service
systemctl restart audiobox-gpio.service

systemctl enable usb-watcher.service
systemctl restart usb-watcher.service

# NEW: enable + trigger boot greeting once now (and on future boots)
systemctl enable audiobox-boot-ready.service
systemctl start audiobox-boot-ready.service

echo
echo "Install complete."
echo "Target user: ${TARGET_USER}"
echo
echo "Basic checks:"
echo "  systemctl status audiobox-player.service --no-pager"
echo "  systemctl status audiobox-gpio.service --no-pager"
echo "  systemctl status usb-watcher.service --no-pager"
echo "  systemctl status audiobox-boot-ready.service --no-pager"
echo
echo "Manual test:"
echo "  ${TARGET_HOME}/btn_playpause.sh"
echo "  ${TARGET_HOME}/btn_next.sh"
echo "  ${TARGET_HOME}/btn_prev.sh"

