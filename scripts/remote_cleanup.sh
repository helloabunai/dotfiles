#!/bin/bash

# wait a moment for DRM to settle
sleep 2

DP1_STATUS=$(cat /sys/class/drm/card*-DP-1/status 2>/dev/null)
DP2_STATUS=$(cat /sys/class/drm/card*-DP-2/status 2>/dev/null)

if [[ "$DP1_STATUS" == "connected" || "$DP2_STATUS" == "connected" ]]; then
    echo "Physical display detected, disabling dummy HDMI-A-1"
    hyprctl keyword monitor "HDMI-A-1,disable"
else
    echo "No DP monitors, keeping HDMI-A-1 active"
fi
