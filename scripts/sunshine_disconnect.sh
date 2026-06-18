#!/bin/bash
#
# sunshine_disconnect.sh
#
# Called by sunshine global_prep_cmd on client disconnect. Closes Big Picture
# and disables whichever monitor STREAM_DISPLAY points at, which collapses
# the transient workspace (6 for HDMI-A-1, 7 for HDMI-A-2) so normal desktop
# usage only ever sees workspaces 1-5.

STATE_FILE="$HOME/.config/scripts/streamdisplay"
STREAM_DISPLAY=$(cat "$STATE_FILE" 2>/dev/null)

# DP-1 (mac desktop stream) has no monitor/Big Picture prep to undo.
if [ "$STREAM_DISPLAY" = "DP-1" ]; then
  echo "STREAM_DISPLAY=DP-1: desktop stream, nothing to tear down."
  exit 0
fi

# Close Steam Big Picture first so it doesn't get reflowed onto another monitor
# when the stream display goes away.
STEAMBP_ADDR=$(hyprctl clients -j | jq -r '.[] | select(.title == "Steam Big Picture Mode") | .address')
if [ -n "$STEAMBP_ADDR" ]; then
  echo "Closing Steam Big Picture..."
  hyprctl dispatch "hl.dsp.window.close({ window = \"address:$STEAMBP_ADDR\" })"
fi

case "$STREAM_DISPLAY" in
HDMI-A-1|HDMI-A-2)
  echo "Disabling monitor: $STREAM_DISPLAY"
  hyprctl eval "hl.monitor({ output = \"$STREAM_DISPLAY\", disabled = true })"
  ;;
*)
  echo "STREAM_DISPLAY not set or invalid ('$STREAM_DISPLAY'); skipping monitor disable."
  ;;
esac

# Steam closes the Friends List window when Big Picture launches. Now that BP
# is gone (stream disconnected), trigger it back via the URL handler -- the
# window.open hook in lua/windowrules.lua places it on top of DP-2's ws 5.
echo "Re-opening Steam Friends List..."
steam steam://open/friends >/dev/null 2>&1 &
disown