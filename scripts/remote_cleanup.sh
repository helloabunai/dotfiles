#!/bin/bash

# wait a moment for DRM to settle
sleep 2

DP1_STATUS=$(cat /sys/class/drm/card*-DP-1/status 2>/dev/null)
DP2_STATUS=$(cat /sys/class/drm/card*-DP-2/status 2>/dev/null)

if [[ "$DP1_STATUS" == "connected" || "$DP2_STATUS" == "connected" ]]; then
    echo "Physical display detected, disabling dummy HDMI-A-1/HDMI-A-2"
    hyprctl eval 'hl.monitor({ output = "HDMI-A-1", disabled = true })'
    hyprctl eval 'hl.monitor({ output = "HDMI-A-2", disabled = true })'
else
    echo "No DP-1/2 monitors, keeping HDMI-A-1 active"
fi
