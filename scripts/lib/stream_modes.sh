#!/bin/bash
# Single source of truth for the HDMI-A-1 mode + output enabling. Sourced by set_stream_display.sh
# and sunshine_connect.sh so the two can never drift apart.

STREAM_RES_FILE="$HOME/.config/scripts/streamres"

hdmi1_mode_args() {
  case "$1" in
  lowres) echo 'output = "HDMI-A-1", mode = "2560x1440@120", position = "4000x0", scale = 1, bitdepth = 10, cm = "hdr", sdr_min_luminance = 0.005, sdr_max_luminance = 230, vrr = 1, disabled = false' ;;
  *)      echo 'output = "HDMI-A-1", mode = "3840x2160@120", position = "4000x0", scale = 1.5, bitdepth = 10, cm = "hdr", sdr_min_luminance = 0.005, sdr_max_luminance = 230, vrr = 1, disabled = false' ;;
  esac
}

stream_res() {
  local r
  r=$(cat "$STREAM_RES_FILE" 2>/dev/null)
  case "$r" in
  hires | lowres) echo "$r" ;;
  *) echo "hires" ;;
  esac
}

# drm_lit <name>: kernel is scanning out <name> (Hyprland still lists it enabled
# after a failed modeset). Virtual outputs with no DRM connector pass.
drm_lit() {
  local f
  for f in /sys/class/drm/card*-"$1"/enabled; do
    [ -e "$f" ] || return 0
    [ "$(cat "$f")" = enabled ] && return 0
  done
  return 1
}

# drm_reprobe <name>: drop + re-force the connector so nvidia re-reads the forced
# EDID (a hotplug while it's off makes nvidia reject every modeset on it)
drm_reprobe() {
  local f
  for f in /sys/class/drm/card*-"$1"/status; do
    [ -e "$f" ] || return 0
    echo "  re-probing $1 connector"
    { echo detect | sudo -n tee "$f" && sleep 1 && echo on | sudo -n tee "$f"; } >/dev/null \
      || echo "  WARNING: re-probe failed (sudoers rule from etc/sudoers.d/stream-reprobe missing?)"
  done
}

# enable_output <name> <hl.monitor args>: enable and wait (~6s) for Hyprland + the
# kernel to both have it up, retrying once if dark. Returns 1 if not up; disabled again if dark.
enable_output() {
  local name="$1" args="$2" attempt tries
  for attempt in 1 2; do
    hyprctl eval "hl.monitor({ $args })"
    tries=30
    while [ $tries -gt 0 ]; do
      if hyprctl -j monitors all | jq -e --arg n "$name" \
          '.[] | select(.name == $n and .disabled == false and .width > 0)' >/dev/null 2>&1 \
          && drm_lit "$name"; then
        return 0
      fi
      sleep 0.2
      tries=$((tries - 1))
    done
    # only cycle if the kernel is dark; a slow Hyprland (or virtual output) just times out
    if [ $attempt = 2 ] || drm_lit "$name"; then break; fi
    # identical args break under hypr, so disable to force a fresh modeset
    hyprctl eval "hl.monitor({ output = \"$name\", disabled = true })"
    drm_reprobe "$name"
    sleep 1
  done
  drm_lit "$name" || hyprctl eval "hl.monitor({ output = \"$name\", disabled = true })"
  return 1
}
