#!/usr/bin/env python3
import subprocess
import time
from pathlib import Path
import os

MOUNTPOINT = Path("/media/usb")
LOG_FILE = Path("/home/USER/usb-import.log")

def log(msg):
    with LOG_FILE.open("a") as f:
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

    import json
    data = json.loads(out)

    def walk(blocks):
        for b in blocks:
            name = b.get("name")
            path = b.get("path")
            rm = b.get("rm")
            mnt = b.get("mountpoint")
            children = b.get("children", [])

            # We want partitions (like sda1) that are removable (rm==1) and not mounted
            if rm == 1 and name and name[-1].isdigit() and (mnt is None or mnt == ""):
                return path
            # Recurse
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
                # Ensure mountpoint exists
                MOUNTPOINT.mkdir(parents=True, exist_ok=True)

                # Mount device
                subprocess.run(
                    ["mount", "-o", "umask=000", dev, str(MOUNTPOINT)],
                    check=True,
                )
                log(f"Mounted {dev} at {MOUNTPOINT}")

                # Run importer
                subprocess.run(
                    ["/usr/bin/python3", "/home/USER/usb_manager.py"],
                    check=True,
                )
                log("usb_manager.py completed")

                # Flush and unmount
                subprocess.run(["sync"])
                subprocess.run(["umount", str(MOUNTPOINT)], check=True)
                log(f"Unmounted {dev}")

                last_device = dev
            except Exception as e:
                log(f"Error handling {dev}: {e}")

        # If no device now, reset last_device so we handle next insert
        if not dev:
            if last_device:
                log(f"USB device {last_device} removed")
            last_device = None

        time.sleep(5)

if __name__ == "__main__":
    main()

