#!/bin/bash

HEADLESS_NAME="HDMI-A-2"
WIDTH=1280
HEIGHT=800
REFRESH=90

# Check if headless monitor is already created
if hyprctl monitors | grep -q "$HEADLESS_NAME"; then
    echo "Headless monitor '$HEADLESS_NAME' exists. Disabling..."
    hyprctl eval "hl.monitor({ output = \"$HEADLESS_NAME\", disabled = true })"
else
    echo "Creating headless monitor '$HEADLESS_NAME'..."
    hyprctl output create headless "$HEADLESS_NAME" width "$WIDTH" height "$HEIGHT" refresh "$REFRESH"
    sleep 1
    hyprctl eval "hl.monitor({ output = \"$HEADLESS_NAME\", disabled = true })"
fi
