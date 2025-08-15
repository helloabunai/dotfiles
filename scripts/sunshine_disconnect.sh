## use already added EDID monitor for sunshine output
## disable it upon sunshine session end event

hyprctl keyword monitor HDMI-A-1,disable
echo "Removed virtual EDID monitor from compositor..."


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
esac
