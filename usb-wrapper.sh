#!/bin/bash

DEVICE="/dev/$1"
MOUNTPOINT="/media/usb"
LOG="/home/USER/usb-import.log"

echo "$(date): Triggered for $DEVICE" >> "$LOG"

# Make mount point
mkdir -p "$MOUNTPOINT"

# Mount it
mount -o umask=000 "$DEVICE" "$MOUNTPOINT"

# Run the python importer
/usr/bin/python3 /home/USER/usb_manager.py

# Sync and unmount
sync
umount "$MOUNTPOINT"

echo "$(date): Finished processing $DEVICE" >> "$LOG"

