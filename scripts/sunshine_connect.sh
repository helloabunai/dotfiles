## use already added EDID monitor for sunshine output
## enable it upon session connect event

hyprctl keyword monitor HDMI-A-1,3840x2160@120,4000x0,1,bitdepth,10,vrr,2,cm,auto
echo "Added virtual EDID monitor to compositor..."

# If Steam is not running, launch it in Big Picture
if ! pgrep -x steam > /dev/null; then
    steam -tenfoot &
else
    # If Steam is already running, trigger Big Picture mode
    xdg-open steam://open/bigpicture &
fi

# Wait for Steam Big Picture to show up
timeout=10
while [[ $timeout -gt 0 ]]; do
    if hyprctl clients | grep -q "Steam Big Picture Mode"; then
        break
    fi
    sleep 1
    ((timeout--))
done

# Move to workspace 6 on HDMI-A-1 and fullscreen
if [[ $timeout -gt 0 ]]; then
    WINADDR=$(hyprctl -j clients | jq -r '.[] | select(.title == "Steam Big Picture Mode") | .address')
    hyprctl dispatch movetoworkspace 6,address:$WINADDR
    sleep 5
    hyprctl dispatch focuswindow address:$WINADDR
    sleep 2
    hyprctl dispatch fullscreen address:$WINADDR
else
    echo "Big Picture window not found."
    exit 1
fi
