#!/usr/bin/env python3
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

