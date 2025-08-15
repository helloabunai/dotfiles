#!/bin/bash

STATE_FILE="$HOME/.cache/idle_inhibitor_status"
TERMINAL="kitty"
COMMAND="cmatrix"
WRAPPED_CMD="bash -c 'sleep 0.3; exec cmatrix -bs'"

# Ensure the state file exists
if [ ! -f "$STATE_FILE" ]; then
    echo "inactive" > "$STATE_FILE"
fi

STATE=$(cat "$STATE_FILE")

if [[ "$STATE" == "inactive" ]]; then
    # Set state to active
    echo "active" > "$STATE_FILE"
    
    # Get the active workspace ID on DP-1
    ACTIVE_WS_DP1=$(hyprctl monitors -j | jq -r '.[] | select(.name=="DP-1") | .activeWorkspace.id')

    # Focus the active workspace on DP-1
    hyprctl dispatch workspace "$ACTIVE_WS_DP1"
    sleep 0.1

    # Spawn terminal on DP-1, then fullscreen
    hyprctl dispatch exec "$TERMINAL -e $WRAPPED_CMD"
    sleep 0.3
    hyprctl dispatch fullscreen

    # Switch to workspace 5 on DP-2
    hyprctl dispatch workspace 5
    sleep 0.1

    # Spawn terminal on DP-2 (workspace 5), then fullscreen
    hyprctl dispatch exec "$TERMINAL -e $WRAPPED_CMD"
    sleep 0.3
    hyprctl dispatch fullscreen

    # === END DISPLAY LOGIC ===

elif [[ "$STATE" == "active" ]]; then
    # Just deactivate
    echo "inactive" > "$STATE_FILE"
fi
