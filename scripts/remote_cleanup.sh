#!/bin/bash

DP1_STATUS=""
DP2_STATUS=""
for _ in $(seq 1 30); do
  DP1_STATUS=$(cat /sys/class/drm/card*-DP-1/status 2>/dev/null)
  DP2_STATUS=$(cat /sys/class/drm/card*-DP-2/status 2>/dev/null)
  [[ "$DP1_STATUS" == "connected" || "$DP2_STATUS" == "connected" ]] && break
  sleep 0.5
done

for _ in $(seq 1 40); do
  pgrep -x sunshine >/dev/null && break
  sleep 0.25
done
sleep 3

if [[ "$DP1_STATUS" == "connected" || "$DP2_STATUS" == "connected" ]]; then
  hyprctl eval 'hl.monitor({ output = "HDMI-A-1", disabled = true })'
  hyprctl eval 'hl.monitor({ output = "HDMI-A-2", disabled = true })'
fi

"$HOME/.local/lib/hyde/waybar.py" --watch --update &
disown

for _ in $(seq 1 60); do
  busctl --user list 2>/dev/null | grep -q "org.kde.StatusNotifierWatcher" && break
  sleep 0.25
done
xembedsniproxy >/dev/null 2>&1 &
disown