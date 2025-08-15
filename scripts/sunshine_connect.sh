## sunshine_connect.sh
##
## Grab env var that will be written by streamclient.sh
## Enable appropriate virtual monitor
## Move steam big picture to appropriate workspace

## -- Source variables --
ENV_FILE="$HOME/.config/scripts/targetdevice"
[ -f "$ENV_FILE" ] && source "$ENV_FILE"
echo "Connected from: $TARGET_CLIENT"
echo "Target workspace: $TARGET_WKSPC"

## -- Steam big picture --
if ! pgrep -x steam > /dev/null; then
    # Not running, launch
    steam -tenfoot &
else
    # Already running
    xdg-open steam://open/bigpicture &
fi

## -- Wait for Steam Big Picture to show up --
timeout=10
while [[ $timeout -gt 0 ]]; do
    if hyprctl clients | grep -q "Steam Big Picture Mode"; then
        break
    fi
    sleep 1
    ((timeout--))
done

## -- Move to $TARGET_WKSPC on specific virtual monitor, and fullscreen --
if [[ $timeout -gt 0 ]]; then
    WINADDR=$(hyprctl -j clients | jq -r '.[] | select(.title == "Steam Big Picture Mode") | .address')
    echo "Moving Big Picture to workspace $TARGET_WKSPC..."
    hyprctl dispatch movetoworkspace "$TARGET_WKSPC",address:$WINADDR
    sleep 5
    hyprctl dispatch focuswindow address:$WINADDR
    sleep 10
    hyprctl dispatch fullscreen 1 address:$WINADDR
else
    echo "Big Picture window not found."
    exit 1
fi
