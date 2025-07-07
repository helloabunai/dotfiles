#!/bin/bash

##
## Remember to add steam game launch options
## /path/to/gamescope.sh -- %command%
##

# --- Gamescope flags ---
# Asus/PC Monitor
ASUS_FLAGS="-W 2560 -H 1440 -r 144 -f -e --mangoapp"
# Bravia/TV
BRAVIA_FLAGS="-W 3840 -H 2160 -r 120 --hdr-enabled --hdr-itm-enable --hdr-itm-sdr-nits 300 --hdr-sdr-content-nits 300 -f -e --mangoapp"
# Target workspace
HYPR_WORKSPACE=""

# --- Conditional ---
GAMESCOPE_COMMAND=""
if hyprctl monitors | grep -q "HDMI-A-1"; then
    echo "TV/Virtual monitor present. Using TV gamescope flags"
    GAMESCOPE_COMMAND="gamescope $BRAVIA_FLAGS"
    export HYPR_WORKSPACE="6"
else
    echo "Using PC gamescope flags."
    GAMESCOPE_COMMAND="gamescope $ASUS_FLAGS"
    export HYPR_WORKSPACE="4"
fi

echo "Executing: $GAMESCOPE_COMMAND %COMMAND%"
echo "Target: workspace $HYPR_WORKSPACE"

#################
## config done ##
#################

## Launch game & get window address
exec $GAMESCOPE_COMMAND "$@" &
GAMESCOPE_PID=$!
sleep 10
GAME_ADDR=$(hyprctl clients -j | jq -r '.[] | select(.class == "gamescope") | .address')

## Move to target
if [ -n "$GAME_ADDR" ]; then
    hyprctl dispatch movetoworkspace "$HYPR_WORKSPACE,address:$GAME_ADDR"
    sleep 2
    hyprctl dispatch fullscreen address:$GAME_ADDR
    echo "Moved gamescope window to workspace $HYPR_WORKSPACE"
else
    echo "gamescope window not found!"
fi

## focus + wait for game exit
hyprctl dispatch workspace "$HYPR_WORKSPACE"
wait $GAMESCOPE_PID
