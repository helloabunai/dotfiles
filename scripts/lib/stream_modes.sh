#!/bin/bash
# Single source of truth for the HDMI-A-1 mode. Sourced by set_stream_display.sh
# and sunshine_connect.sh so the two can never drift apart.

STREAM_RES_FILE="$HOME/.config/scripts/streamres"

hdmi1_mode_args() {
  case "$1" in
  lowres) echo 'output = "HDMI-A-1", mode = "2560x1440@120", position = "4000x0", scale = 1, bitdepth = 10, cm = "hdr", vrr = 1, disabled = false' ;;
  *)      echo 'output = "HDMI-A-1", mode = "3840x2160@120", position = "4000x0", scale = 1.5, bitdepth = 10, cm = "hdr", vrr = 1, disabled = false' ;;
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
