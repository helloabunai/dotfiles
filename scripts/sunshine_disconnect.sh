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
