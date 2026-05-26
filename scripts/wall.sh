#!/bin/bash
# Sets per-monitor wallpapers via awww. Idempotent: if the daemon
# already runs, just sends new `awww img` commands.

if ! pgrep -x awww-daemon >/dev/null 2>&1; then
    awww-daemon >/dev/null 2>&1 &
    # Wait for the socket to appear (up to ~3s)
    for _ in 1 2 3 4 5 6; do
        awww query >/dev/null 2>&1 && break
        sleep 0.5
    done
fi

awww img /mnt/storage2/Pictures/walls/1stMonitor.jpg --outputs=DP-1
awww img /mnt/storage2/Pictures/walls/2ndMonitor.jpg --outputs=DP-2
awww img /mnt/storage2/Pictures/walls/1stMonitor.jpg --outputs=HDMI-A-1