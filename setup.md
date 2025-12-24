# Audiobox / Pi4 Soundbox — Fresh Pi Setup Playbook (Step-by-Step)

This document is the **operator procedure** for turning a **fresh Raspberry Pi 4** into a fully functioning Audiobox (headless, appliance-style):
- `install.sh` (writes scripts + systemd units, enables services)
- `verify.sh` (validates installation and runtime health)

It assumes:
- Raspberry Pi 4 (any RAM)
- A microSD card (16GB+ recommended)
- Ethernet available for initial setup (Wi‑Fi not required)
- Three momentary buttons wired to GPIO (Play/Pause, Next, Prev)
- Audio output via 3.5mm jack, powered by USB

---

## 1) Flash Raspberry Pi OS Lite and enable SSH

1. Install **Raspberry Pi Imager** on your Mac/PC.
2. Choose OS: **Raspberry Pi OS Lite (64-bit)**.
3. Click the **gear** icon (OS customization) and set:
   - Hostname: `audiobox`
   - Username: `<USER>` (your preferred user)
   - Password: (set a strong one)
   - Enable **SSH**
   - (Optional) Configure Wi‑Fi if you want it for setup; Ethernet is fine.
4. Flash to the microSD card.

Boot the Pi with:
- the microSD inserted
- Ethernet connected (recommended)
- your audio hardware connected (can be done at a later step)

---

## 2) SSH into the Pi

From your computer:

```bash
ssh <USER>@audiobox.local
```

If mDNS is not available on your network, find the Pi’s IP address in your router and use:

```bash
ssh <USER>@<PI_IP_ADDRESS>
```

---

## 3) Update the base system

On the Pi:

```bash
sudo apt update
sudo apt full-upgrade -y
sudo reboot
```

Reconnect via SSH after reboot.

---

## 4) Copy the installer files onto the Pi

You need these files on the Pi (same directory is easiest):
- `install.sh`
- `verify.sh`

Example from your Mac/PC:

```bash
scp install.sh verify.sh <USER>@audiobox.local:/home/<USER>/
```

Then SSH back in:

```bash
ssh <USER>@audiobox.local
```

---

## 5) Run the installer

On the Pi:

```bash
cd /home/<USER>
chmod +x install.sh verify.sh
sudo ./install.sh
```

If your target user is not `<USER>`, use:

```bash
sudo ./install.sh --user <username>
```

The installer will:
- install required packages (`mplayer`, `python3`, `python3-gpiozero`, `espeak-ng`, etc.)
- create `/home/<user>/audiobooks`, `.audiobox_state`, `usb-import.log`
- write the runtime scripts (`start_audiobox_player.sh`, button scripts, etc.)
- write and enable systemd units:
  - `audiobox-player.service`
  - `audiobox-gpio.service`
  - `usb-watcher.service`

---

## 6) Verify installation and runtime health

Run:

```bash
./verify.sh --user <USER>
```

Key things it should report:
- `audiobox-player.service` active
- `audiobox-gpio.service` active
- `usb-watcher.service` active
- `/tmp/audiobox_fifo` exists (FIFO)
- `mplayer` is running

For live logs:

```bash
journalctl -u audiobox-player.service -f
journalctl -u audiobox-gpio.service -f
journalctl -u usb-watcher.service -f
tail -f /home/<USER>/usb-import.log
```

---

## 7) Wire the buttons (GPIO)

Use **BCM numbering** (as in your scripts):

- Play/Pause → **GPIO17**
- Next → **GPIO27**
- Prev → **GPIO22**
- Ground → any Pi GND pin

For each button switch:
- **COM → GND**
- **NO → the GPIO pin above**
- Do **not** connect to 3.3V (the software uses internal pull-ups)

---

## 8) Put audio files onto the Pi (initial content)

Option A — Copy files over SSH:

```bash
scp *.mp3 *.m4a *.wav <USER>@audiobox.local:/home/<USER>/audiobooks/
```

Option B — Use the USB workflow (preferred caregiver path)  
See Section 9.

---

## 9) USB caregiver workflow (Add / Delete / Reboot)

### 9.1 USB mount point and behavior
The USB watcher service polls for a removable, unmounted partition and when detected:
- mounts it at `/media/usb`
- runs `/home/<USER>/usb_manager.py`
- unmounts it

### 9.2 USB structure

On the USB root:

```
USB_ROOT/
├── Add/
│   └── new_books.*
├── library.txt
└── Reboot.txt
```
libraary.txt and Reboot.txt are created automatically. The only requirement is an 'Add' directory on the USB stick.

#### Add new books
1. Create folder: `Add/`
2. Put new audio files in `Add/` (MP3/WAV/M4A/etc.)
3. Insert USB into the Pi
4. Wait for completion (watch `usb-import.log`)

#### Delete existing books
1. Insert USB (it will update/write `library.txt`)
2. Remove USB and open `library.txt` on your computer
3. Add filenames under `Deletion:` (exact match)
4. Reinsert USB to perform deletions

#### Reboot mechanism
`Reboot.txt` is created by the Pi (if missing) in this form:

```
### Remove the "–" before Reboot to reboot the soundbox. ###
– Reboot
```

To trigger reboot:
- remove the leading dash so the second line is exactly:

```
Reboot
```

Insert USB:
- the Pi will speak “Rebooting now.”
- it restores `Reboot.txt` to default
- syncs and reboots

---

## 10) Functional test checklist

### 10.1 Player backend (mplayer)
```bash
systemctl status audiobox-player.service
pgrep -x mplayer
ls -l /tmp/audiobox_fifo
```

### 10.2 Button handling
1. Ensure scripts exist:
   ```bash
   ls -l /home/<USER>/btn_*.sh
   ```
2. Press Play/Pause:
   - first press should load playlist and start playing
3. Press Next/Prev:
   - should jump track

If buttons appear unresponsive, check:
```bash
journalctl -u audiobox-gpio.service -n 200 --no-pager
```

### 10.3 USB import
Insert a USB stick with an `Add/` folder and a test audio file. Then:
```bash
journalctl -u usb-watcher.service -n 200 --no-pager
tail -n 200 /home/<USER>/usb-import.log
```

---

## 11) Common failure modes and fixes

### FIFO missing
```bash
sudo systemctl restart audiobox-player.service
ls -l /tmp/audiobox_fifo
journalctl -u audiobox-player.service -n 200 --no-pager
```

### mplayer not producing sound
- Confirm output hardware
- Try a different audio output (3.5mm vs HDMI vs USB audio)
- Ensure volume is up and not muted (especially if using ALSA mixer tools)

### USB import not triggering
- Confirm watcher is running:
  ```bash
  systemctl status usb-watcher.service
  ```
- Confirm device appears in `lsblk` as removable and unmounted before mount:
  ```bash
  lsblk -o NAME,PATH,RM,MOUNTPOINT
  ```
- Watch live logs during insertion:
  ```bash
  journalctl -u usb-watcher.service -f
  ```

---

## 12) “Factory reset” (software only)

If you want to clear all audio books:

```bash
rm -f /home/<USER>/audiobooks/*
echo "IDLE" > /home/<USER>/.audiobox_state
sudo systemctl restart audiobox-player.service
```

---

## 13) What to keep backed up

Back up from the Pi:
- `/home/<USER>/*.sh`
- `/home/<USER>/*.py`
- `/home/<USER>/usb-import.log` (optional)
- your `install.sh` and `verify.sh`

The system can be recreated quickly from the scripts + this playbook.


