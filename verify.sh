#!/usr/bin/env bash
set -euo pipefail

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

if [[ -z "${TARGET_USER}" ]]; then
  TARGET_USER="$(whoami)"
fi

TARGET_HOME="$(getent passwd "${TARGET_USER}" | cut -d: -f6)"
if [[ -z "${TARGET_HOME}" || ! -d "${TARGET_HOME}" ]]; then
  echo "ERROR: Home directory not found for user '${TARGET_USER}'." >&2
  exit 1
fi

FIFO="/tmp/audiobox_fifo"
USB_MOUNT="/media/usb"
LOG_FILE="${TARGET_HOME}/usb-import.log"

say() { printf "\n== %s ==\n" "$1"; }
ok()  { printf "OK: %s\n" "$1"; }
warn(){ printf "WARN: %s\n" "$1"; }
fail(){ printf "FAIL: %s\n" "$1"; exit 1; }

need_cmd() {
  local c="$1"
  command -v "$c" >/dev/null 2>&1 || fail "Missing command: $c"
  ok "Found command: $c"
}

need_file_exec() {
  local f="$1"
  [[ -f "$f" ]] || fail "Missing file: $f"
  [[ -x "$f" ]] || fail "Not executable: $f"
  ok "Executable present: $f"
}

need_file() {
  local f="$1"
  [[ -f "$f" ]] || fail "Missing file: $f"
  ok "File present: $f"
}

svc_exists() {
  local s="$1"
  systemctl list-unit-files "$s" >/dev/null 2>&1
}

svc_status() {
  local s="$1"
  if ! svc_exists "$s"; then
    fail "Systemd unit not installed: $s"
  fi
  ok "Unit installed: $s"

  local enabled
  enabled="$(systemctl is-enabled "$s" 2>/dev/null || true)"
  if [[ "$enabled" == "enabled" ]]; then
    ok "Unit enabled: $s"
  else
    warn "Unit not enabled (is-enabled=$enabled): $s"
  fi

  local active
  active="$(systemctl is-active "$s" 2>/dev/null || true)"
  if [[ "$active" == "active" ]]; then
    ok "Unit active: $s"
  else
    warn "Unit not active (is-active=$active): $s"
  fi
}

say "Environment"
echo "User: ${TARGET_USER}"
echo "Home: ${TARGET_HOME}"

say "Required commands"
need_cmd mplayer
need_cmd python3
need_cmd systemctl
need_cmd lsblk
need_cmd mount
need_cmd umount
need_cmd sync
# Optional: espeak-ng (usb_manager uses it)
if command -v espeak-ng >/dev/null 2>&1; then
  ok "Found command: espeak-ng"
else
  warn "Missing command: espeak-ng (usb_manager.py will silently skip speech)"
fi

say "Expected scripts"
need_file_exec "${TARGET_HOME}/start_audiobox_player.sh"
need_file_exec "${TARGET_HOME}/audiobox_ctl.sh"
need_file_exec "${TARGET_HOME}/load_playlist.sh"
need_file_exec "${TARGET_HOME}/btn_playpause.sh"
need_file_exec "${TARGET_HOME}/btn_next.sh"
need_file_exec "${TARGET_HOME}/btn_prev.sh"
need_file_exec "${TARGET_HOME}/audiobox_gpio.py"
need_file_exec "${TARGET_HOME}/usb_manager.py"
need_file_exec "${TARGET_HOME}/watch_usb.py"
# usb-wrapper.sh is optional; present in your current set
if [[ -f "${TARGET_HOME}/usb-wrapper.sh" ]]; then
  if [[ -x "${TARGET_HOME}/usb-wrapper.sh" ]]; then
    ok "Optional executable present: ${TARGET_HOME}/usb-wrapper.sh"
  else
    warn "Optional present but not executable: ${TARGET_HOME}/usb-wrapper.sh"
  fi
else
  warn "Optional missing: ${TARGET_HOME}/usb-wrapper.sh"
fi

say "State/log files"
if [[ -f "${TARGET_HOME}/.audiobox_state" ]]; then
  ok "State file present: ${TARGET_HOME}/.audiobox_state"
  echo "State contents: $(cat "${TARGET_HOME}/.audiobox_state" 2>/dev/null || true)"
else
  warn "State file missing (this is normal until first boot of player script): ${TARGET_HOME}/.audiobox_state"
fi

if [[ -f "${LOG_FILE}" ]]; then
  ok "USB log present: ${LOG_FILE}"
else
  warn "USB log missing; creating: ${LOG_FILE}"
  touch "${LOG_FILE}" || warn "Could not create ${LOG_FILE} (permissions?)"
fi

say "Systemd units"
svc_status audiobox-player.service
svc_status audiobox-gpio.service
svc_status usb-watcher.service

say "FIFO check"
if [[ -p "${FIFO}" ]]; then
  ok "FIFO exists: ${FIFO}"
else
  warn "FIFO not found: ${FIFO}"
  warn "Attempting to restart audiobox-player.service to (re)create FIFO..."
  if command -v sudo >/dev/null 2>&1; then
    sudo systemctl restart audiobox-player.service || true
  else
    systemctl restart audiobox-player.service || true
  fi

  if [[ -p "${FIFO}" ]]; then
    ok "FIFO created after restart: ${FIFO}"
  else
    warn "FIFO still missing after restart. Check audiobox-player logs."
  fi
fi

say "mplayer process check"
if pgrep -x mplayer >/dev/null 2>&1; then
  ok "mplayer is running"
  echo "mplayer PID(s): $(pgrep -x mplayer | tr '\n' ' ')"
else
  warn "mplayer is not running"
fi

say "GPIO stack sanity (no hardware interaction)"
python3 - <<'PY'
try:
    import gpiozero
    print("OK: gpiozero importable")
except Exception as e:
    print(f"FAIL: gpiozero import failed: {e}")
PY

say "USB mountpoint check"
if [[ -d "${USB_MOUNT}" ]]; then
  ok "USB mountpoint exists: ${USB_MOUNT}"
else
  fail "USB mountpoint missing: ${USB_MOUNT}"
fi

# Show whether something is mounted there now
if mount | grep -q "on ${USB_MOUNT} "; then
  ok "A filesystem is currently mounted at ${USB_MOUNT}"
  mount | grep "on ${USB_MOUNT} " || true
else
  warn "Nothing currently mounted at ${USB_MOUNT} (insert a USB stick to test import path)"
fi

say "Recent logs (last 50 lines each)"
echo "-- audiobox-player.service --"
systemctl --no-pager -n 50 status audiobox-player.service || true
echo
echo "-- audiobox-gpio.service --"
systemctl --no-pager -n 50 status audiobox-gpio.service || true
echo
echo "-- usb-watcher.service --"
systemctl --no-pager -n 50 status usb-watcher.service || true
echo
echo "-- usb-import.log --"
tail -n 50 "${LOG_FILE}" 2>/dev/null || true

say "Done"
echo "If USB import is not firing, insert a USB stick and watch:"
echo "  journalctl -u usb-watcher.service -f"
echo "  tail -f ${LOG_FILE}"

