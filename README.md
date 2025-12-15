# Audiobox Raspberry Pi Software Playbook

The Audiobox is an appliance‑style audio player for a limited-access user such as a child, an elderly person, or a visually impared user:
- No screen
- No keyboard
- No Wi‑Fi required
- One primary Play/Pause button
- One Next button, one Prev button
- USB stick–based content management

This document is a **complete, end‑to‑end software playbook** for recreating the Audiobox system on a fresh Raspberry Pi.  
It covers **design intent**, **architecture**, and **exact implementation steps**.

---

## 1. Design Goals

- Predictable behavior
- No auto‑play surprises
- All maintenance possible via USB stick
- Works offline
- Uses simple, inspectable tools (shell scripts, systemd)

---

## 2. High‑Level Architecture

### Core components
- **mplayer** running in slave + idle mode
- **FIFO pipe** for playback control
- **Shell scripts** representing button actions
- **USB manager** handling content updates and reboot
- **systemd services** to glue everything together

### Key principle
> The Pi behaves like an appliance, not a computer.

---

## 3. Filesystem Layout

**SETUP REQUIRED:** Replace "USER" with your actual Linux username in all configuration files before installation.

```
/home/USER/
├── audiobooks/                 # Audio files live here
├── start_audiobox_player.sh    # Starts mplayer idle on boot
├── audiobox_ctl.sh             # Writes commands into FIFO
├── load_playlist.sh            # Loads and starts playlist
├── btn_playpause.sh            # Smart Play/Pause logic
├── usb_manager.py              # USB Add/Delete/Reboot logic
├── usb-import.log              # USB operation log
└── .audiobox_state             # PLAYING / PAUSED
```

FIFO:
```
/tmp/audiobox_fifo
```

USB mount point:
```
/media/usb
```

---

## 4. Audio Backend (mplayer)

### Why mplayer
- Mature
- Supports many formats (MP3, WAV, M4A, AMR, OGG, etc.)
- Works well headless
- Slave mode allows external control

### Mode
mplayer runs with:
- `-slave`
- `-idle`
- FIFO input

This means:
- It never exits
- It never auto‑plays
- It waits for commands

---

## 5. Boot Behavior

On boot:
- mplayer starts idle
- No playlist loaded
- No sound
- Device waits for button press

This avoids confusion for the user.

---

## 6. Playback Control Model

### One Play/Pause button

Behavior depends on state:

| State | Button action |
|-----|--------------|
| Boot / idle | Load playlist and start from beginning |
| Playing | Pause |
| Paused | Resume |
| Playlist finished | Load playlist and start from beginning |

### State detection strategy

mplayer does **not** provide request/response IPC via FIFO.

Solution:
- Inspect `/proc/<mplayer_pid>/fd`
- If no file under `~/audiobooks` is open → player is idle
- Otherwise → mid‑file (playing or paused)

This avoids fragile log parsing.

---

## 7. systemd Service

### audiobox-player.service

Runs mplayer continuously in background.


---

## 8. start_audiobox_player.sh

Responsibilities:
- Reset state file
- Create FIFO
- Start mplayer idle

---

## 9. FIFO Control Helper

### audiobox_ctl.sh

---

## 10. Playlist Loader

### load_playlist.sh

- Loads all files from `~/audiobooks`
- Ignores dotfiles (`._*`, `.DS_Store`)
- Plays once (no looping)

---

## 11. Smart Play/Pause Script

### btn_playpause.sh

---

## 12. USB Workflow (Caregiver Interface)

### USB structure

```
USB_ROOT/
├── Add/
│   └── new_books.*
├── library.txt
└── Reboot.txt
```

---

## 13. library.txt

Written by the Pi.

```
Inventory:
book1.mp3
book2.wav

Deletion:
```

Caregiver adds filenames under `Deletion:` to remove them.

---

## 14. Reboot Mechanism

### Reboot.txt default

```
### Remove the "–" before Reboot to reboot the soundbox. ###
– Reboot
```

If dash is removed from second line:
- Pi speaks “Rebooting now.”
- Restores file to default
- Runs `sync`
- Reboots safely

---

## 15. usb_manager.py

Responsibilities (in order):
1. Handle reboot trigger
2. Copy files from `Add/`
3. Delete files listed in `library.txt`
4. Rewrite `library.txt`
5. Ignore dotfiles

Triggered automatically via systemd when `/media/usb` appears.

---

## 16. Logging

All USB operations logged to:

```
/home/USER/usb-import.log
```

---

## 17. Hardware Buttons (Later)

GPIO buttons simply execute shell scripts:
- Play/Pause → `btn_playpause.sh`

No GPIO code touches mplayer directly.

---

## 18. Supported Formats

All formats supported by mplayer, including:
- MP3
- WAV
- M4A
- OGG
- AMR

---

## 19. Design Philosophy

- Appliance behavior
- Simplicity over cleverness
- Files over GUIs
- Inspectable state

---

## 20. Outcome

A durable audiobook player that:
- A blind person can use
- A non‑technical caregiver can maintain
- Recovers from errors
- Requires no ongoing supervision
