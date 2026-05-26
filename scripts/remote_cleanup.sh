#!/bin/bash
#
# remote_cleanup.sh
#
# Runs once at Hyprland start. Disables HDMI-A-1 and HDMI-A-2 in Hyprland so
# normal desktop usage only ever shows workspaces 1-5; the stream monitor is
# only re-enabled by sunshine_connect.sh on a Sunshine client connect.
#
# HDMI-A-1's *kernel* framebuffer (from cmdline `video=HDMI-A-1:e` +
# `drm.edid_firmware`) stays bound regardless -- that's what wins the Sunshine
# KMS boot-race for HDR capture. Disabling here just means Hyprland isn't
# drawing on it during normal desktop usage.
#
# DP-1/DP-2 check is a safety fallback for headless/TV-only boots where
# disabling HDMI would leave the session blind.

sleep 2

DP1_STATUS=$(cat /sys/class/drm/card*-DP-1/status 2>/dev/null)
DP2_STATUS=$(cat /sys/class/drm/card*-DP-2/status 2>/dev/null)

if [[ "$DP1_STATUS" == "connected" || "$DP2_STATUS" == "connected" ]]; then
  echo "Physical display detected, disabling HDMI-A-1 / HDMI-A-2 in Hyprland"
  hyprctl eval 'hl.monitor({ output = "HDMI-A-1", disabled = true })'
  hyprctl eval 'hl.monitor({ output = "HDMI-A-2", disabled = true })'
else
  echo "No DP-1/2 monitors, keeping HDMI-A-1 active"
fi