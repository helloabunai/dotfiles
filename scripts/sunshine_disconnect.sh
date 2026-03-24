## sunshine_disconnect.sh
##
## disable the currently used virtual monitor

## -- Source variables --
ENV_FILE="$HOME/.config/scripts/targetdevice"
[ -f "$ENV_FILE" ] && source "$ENV_FILE"
echo "Connected from: $TARGET_CLIENT"
echo "Target workspace: $TARGET_WKSPC"

## -- Disable client specific monitor --
case "$TARGET_CLIENT" in
shield)
  echo "Disabling monitor: HDMI-A-1 (Shield)"
  hyprctl keyword monitor "HDMI-A-1,disable"
  ;;
deck)
  echo "Disabling monitor: HDMI-A-2 (Steam Deck)"
  hyprctl keyword monitor "HDMI-A-2,disable"
  ;;
mac)
  echo "Disabling monitor: HDMI-A-1 (Mac)"
  hyprctl keyword monitor "HDMI-A-1,disable"
  ;;
esac

## -- Exit Steam Big Picture --
STEAMBP_ADDR=$(hyprctl clients -j | jq -r '.[] | select(.title == "Steam Big Picture Mode") | .address')

if [ -n "$STEAMBP_ADDR" ]; then
  echo "Closing Steam Big Picture window..."
  hyprctl dispatch closewindow address:$STEAMBP_ADDR
else
  echo "Steam Big Picture window not found."
fi