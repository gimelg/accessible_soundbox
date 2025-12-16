# Audiobox Raspberry Pi Software Playbook

The Audiobox is an appliance‑style audio player for a limited-access user such as a child, an elderly person, or a visually impaired user:
- No screen
- No keyboard
- No Wi‑Fi required
- One primary Play/Pause button
- One Next button, one Prev button
- USB stick–based content management

This document is a **complete, end‑to‑end software playbook** for recreating the Audiobox system on a fresh Raspberry Pi.  
It covers **design intent**, **architecture**, and **exact implementation steps**, including **GPIO button wiring**.

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
- **GPIO button handler** that runs the shell scripts on button presses
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
├── btn_next.sh                 # Next track/book
├── btn_prev.sh                 # Previous track/book
├── audiobox_gpio.py            # GPIO listener -> runs button scripts
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

## 17. Hardware Buttons: Wiring + GPIO Service

### 17.1 Button hardware (EG STARTS arcade buttons)

EG STARTS arcade buttons typically use a microswitch with three terminals:
- **COM** (common)
- **NO** (normally open)
- **NC** (normally closed)

For Audiobox, use **COM + NO** only (ignore NC).

### 17.2 Wiring method (recommended)

Use the Pi’s **internal pull-up resistors**.

For each button:
- **COM → GND**
- **NO → GPIO pin**

Do **not** connect to 3.3V.

### 17.3 Suggested GPIO mapping (BCM numbering)

- Play/Pause → **GPIO17**
- Next → **GPIO27**
- Prev → **GPIO22**
- Ground → any Pi GND pin (e.g., physical pin 6)

### 17.4 Software: GPIO handler script

Install dependency:
```bash
sudo apt update
sudo apt install -y python3-gpiozero
```

Create `/home/USER/audiobox_gpio.py`:

```python
#!/usr/bin/env python3
from gpiozero import Button
from signal import pause
import subprocess
import time

# BCM pin numbers
PIN_PLAYPAUSE = 17
PIN_NEXT = 27
PIN_PREV = 22

SCRIPT_PLAYPAUSE = "/home/USER/btn_playpause.sh"
SCRIPT_NEXT = "/home/USER/btn_next.sh"
SCRIPT_PREV = "/home/USER/btn_prev.sh"

BOUNCE = 0.10
MIN_INTERVAL = 0.20
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
```

Make executable:

```bash
chmod +x /home/USER/audiobox_gpio.py
```

Test interactively (Ctrl+C to stop):
```bash
python3 /home/USER/audiobox_gpio.py
```

### 17.5 systemd service: audiobox-gpio.service

Create `/etc/systemd/system/audiobox-gpio.service`:

```ini
[Unit]
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
```

Enable/start:

```bash
sudo systemctl daemon-reload
sudo systemctl enable audiobox-gpio.service
sudo systemctl restart audiobox-gpio.service
sudo systemctl status audiobox-gpio.service
```

#### Common failure: systemd unit parse errors

If you see errors like:
- `Assignment outside of section`
- `Missing '='`

Then the unit file contains stray characters or broken lines. Fix by **replacing the file entirely** with the exact unit content above, then run:

```bash
sudo systemctl daemon-reload
sudo systemctl restart audiobox-gpio.service
```

To inspect with line numbers:
```bash
nl -ba /etc/systemd/system/audiobox-gpio.service
```

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

