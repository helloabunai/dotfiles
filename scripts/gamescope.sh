#!/bin/bash

##
## Simple Gamescope QOL script with the goal of:
## 1) Avoiding the need of setting gamescope screen-res arguments in every steam title
## 2) Avoiding the need to change screen-res gamescope arguments each time i change display (monitor/tv)
## 3) Getting game-specific (steam appID) required environment flags for stuff e.g. DX11 vs DX12 Proton HDR flags
## 4) Move the gamescope window to specific hyprland workspaces (monitor = 4, TV = 6)
## 5) Maximise window upon move
##
## Remember to add the script to the launch options one time only
## Any other args should be set in the script, not launch options
## /path/to/gamescope.sh -- %command%
##

LOGFILE="${HOME}/scripts/debug.log"
: > "$LOGFILE"
exec > >(tee -a "$LOGFILE") 2>&1
log() {
    echo -e "SCRIPTLOG::::::: $*\n\n"
}

# --- Gamescope flags ---
ASUS_FLAGS="-W 2560 -H 1440 -r 144" # Asus/PC Monitor
BRAVIA_FLAGS="-W 3840 -H 2160 -r 120 --hdr-enabled --hdr-itm-enabled --hdr-itm-sdr-nits 300 --hdr-sdr-content-nits 300" # Bravia/TV
HYPR_WORKSPACE="" # Target hyprland workspace

# --- Conditional ---
GAMESCOPE_COMMAND=""
TARGET_ENV=""
if hyprctl monitors | grep -q "HDMI-A-1"; then
    log "TV/Virtual monitor present. Using TV gamescope flags"
    GAMESCOPE_COMMAND="gamescope mangohud $BRAVIA_FLAGS"
    TARGET_ENV="tv_env"
    export HYPR_WORKSPACE="6"
else
    log "Using PC gamescope flags."
    GAMESCOPE_COMMAND="gamescope mangohud $ASUS_FLAGS"
    TARGET_ENV="pc_env"
    export HYPR_WORKSPACE="4"
fi

log "Executing: $GAMESCOPE_COMMAND %COMMAND%"
log "Target: workspace $HYPR_WORKSPACE"
log "Target: environment $TARGET_ENV"

# --- Steam App ID + Env Flags ---
ENV_FLAGS=""
DB_PATH="$HOME/scripts/game_envs.json"
GAME_LAUNCH_CMD="$*"
log "Raw game launch cmd: $GAME_LAUNCH_CMD"
STEAM_APPID=$(echo "$GAME_LAUNCH_CMD" | grep -oP 'AppId=\K\d+')
log "Launched SteamAppId: $STEAM_APPID"

if [ -n "$STEAM_APPID" ] && [ -f "$DB_PATH" ]; then
    ENV_FLAGS=$(jq -r --arg id "$STEAM_APPID" --arg key "$TARGET_ENV" '.[$id][$key] // empty' "$DB_PATH")
    NOTE=$(jq -r --arg id "$STEAM_APPID" '.[$id].note // empty' "$DB_PATH")
    if [ -n "$ENV_FLAGS" ]; then
        log "Loaded ENV_FLAGS: $ENV_FLAGS"
        [ -n "$NOTE" ] && log "Note/Parsed game: $NOTE"
    else
        log "No env flags found for Steam AppId=$STEAM_APPID and context=$TARGET_ENV"
    fi
else
    log "No Steam AppId/Game DB missing"
fi

#################
## config done ##
#################

## -- Launch game & get window address --
env $ENV_FLAGS $GAMESCOPE_COMMAND "$@" &
GAMESCOPE_PID=$!
sleep 8
GAME_ADDR=$(hyprctl clients -j | jq -r '.[] | select(.class == "gamescope") | .address')

## -- Move to target --
if [ -n "$GAME_ADDR" ]; then
    hyprctl dispatch movetoworkspace "$HYPR_WORKSPACE,address:$GAME_ADDR"
    hyprctl dispatch fullscreen address:$GAME_ADDR
    log "Moved gamescope window to workspace $HYPR_WORKSPACE"
else
    log "gamescope window not found!"
fi

## -- focus + wait for game exit --
hyprctl dispatch workspace "$HYPR_WORKSPACE"
wait $GAMESCOPE_PID
