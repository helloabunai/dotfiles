#!/bin/bash
#
# sunshine_connect.sh
#
# Called by sunshine global_prep_cmd at every client connect. Reads
# STREAM_DISPLAY (set via set_stream_display.sh) to decide which Hyprland
# monitor to enable, then moves Steam Big Picture onto its workspace and
# fullscreens it. Sunshine itself is never restarted -- its cached KMS
# connector index from boot is what makes HDR/KMS capture stable
# (see project_gotchas.md::gotcha-sunshine-kms-boot-race).

STATE_FILE="$HOME/.config/scripts/streamdisplay"
STREAM_DISPLAY=$(cat "$STATE_FILE" 2>/dev/null)

case "$STREAM_DISPLAY" in
HDMI-A-1)
  TARGET_WKSPC=6
  echo "Enabling monitor: HDMI-A-1 (Shield/TV/Mac, HDR)"
  hyprctl eval 'hl.monitor({ output = "HDMI-A-1", mode = "3840x2160@120", position = "4000x0", scale = 1.5, bitdepth = 10, cm = "hdr", vrr = 1, disabled = false })'
  ;;
HDMI-A-2)
  TARGET_WKSPC=7
  echo "Enabling monitor: HDMI-A-2 (Steam Deck)"
  hyprctl eval 'hl.monitor({ output = "HDMI-A-2", mode = "1280x800@90", position = "7840x0", scale = 1, disabled = false })'
  ;;
*)
  echo "STREAM_DISPLAY not set or invalid ('$STREAM_DISPLAY'). Run set_stream_display.sh."
  exit 1
  ;;
esac

# Wait for Hyprland to actually online the monitor before placing windows.
tries=30
while [ $tries -gt 0 ]; do
  if hyprctl -j monitors all | jq -e --arg n "$STREAM_DISPLAY" \
      '.[] | select(.name == $n and .disabled == false and .width > 0)' >/dev/null 2>&1; then
    break
  fi
  sleep 0.2
  tries=$((tries - 1))
done

# Steam Big Picture: launch tenfoot if Steam isn't running, otherwise raise BP.
if ! pgrep -x steam >/dev/null; then
  steam -tenfoot &
else
  xdg-open steam://open/bigpicture &
fi

# Wait for the BP window to appear.
timeout=10
while [ $timeout -gt 0 ]; do
  if hyprctl clients | grep -q "Steam Big Picture Mode"; then
    break
  fi
  sleep 1
  timeout=$((timeout - 1))
done

if [ $timeout -gt 0 ]; then
  WINADDR=$(hyprctl -j clients | jq -r '.[] | select(.title == "Steam Big Picture Mode") | .address')
  echo "Moving Big Picture to workspace $TARGET_WKSPC..."
  hyprctl dispatch "hl.dsp.window.move({ workspace = \"$TARGET_WKSPC\", window = \"address:$WINADDR\" })"
  sleep 5
  hyprctl dispatch "hl.dsp.focus({ window = \"address:$WINADDR\" })"
  sleep 10
  hyprctl dispatch "hl.dsp.window.fullscreen({ mode = \"fullscreen\", action = \"set\", window = \"address:$WINADDR\" })"

  # Cursor warps are globally disabled (cursor:no_warps in lua/config.lua), so
  # focusing BP above doesn't move the pointer. Manually warp it to the centre
  # of the stream display so the controller's virtual mouse is already on the
  # Big Picture window when the remote client takes over. Coords are read
  # dynamically from the running monitor config.
  read MX MY MW MH < <(hyprctl -j monitors | jq -r --arg n "$STREAM_DISPLAY" \
      '.[] | select(.name == $n) | "\(.x) \(.y) \(.width) \(.height)"')
  if [ -n "$MX" ]; then
    CX=$((MX + MW / 2))
    CY=$((MY + MH / 2))
    hyprctl dispatch "hl.dsp.cursor.move({ x = $CX, y = $CY })"
  fi
else
  echo "Big Picture window not found."
  exit 0
fi