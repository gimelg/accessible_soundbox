#!/usr/bin/env python3
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


# ----------------------------
# REBOOT.TXT HANDLING
# ----------------------------

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

        # Restore first so reboot loop can't happen
        restore_reboot_file(reboot_file)

        # SAY IT OUT LOUD 🔊
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


# ----------------------------
# MAIN USB PROCESSING
# ----------------------------

def process_usb() -> None:
    # 0. Handle reboot FIRST
    if handle_reboot_file():
        return

    # 1. Add new files
    add_dir = USB_MOUNT / "Add"
    if add_dir.exists():
        added = False
        for f in add_dir.iterdir():
            if f.is_file() and not f.name.startswith("."):
                safe_copy(f, AUDIO_DIR)
                added = True
        if added:
            speak("New books added")

    # 2. Delete files requested in library.txt
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

    # 3. Rewrite library.txt
    write_library_to_usb()


if __name__ == "__main__":
    time.sleep(3)
    process_usb()

