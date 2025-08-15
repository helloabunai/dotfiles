#!/bin/bash

##
## Simple Gamescope QOL script with the goal of:
## 1) Avoiding the need of setting gamescope screen-res arguments in every steam title
## 2) Avoiding the need to change screen-res gamescope arguments each time i change display (monitor/tv)
## 3) Getting game-specific (steam appID) required environment flags for stuff e.g. DX11 vs DX12 Proton HDR flags
## 4) Move the gamescope window to specific hyprland workspaces (monitor = 4, TV = 6, headless = 7)
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

##
## These flags are commented in/out by streamclient.sh i.e. use
## - Bravia flags + workspace 6 for nvidia shield
## - Deck flags + workspace 7 for steam deck
##
## --- Gamescope flags ---
ASUS_FLAGS="-W 2560 -H 1440 -r 144 -e --force-grab-cursor" # Asus/PC Monitor
#VIRTUAL_FLAGS="-W 3840 -H 2160 -r 120 -e --force-grab-cursor --hdr-enabled --hdr-itm-enabled --hdr-itm-sdr-nits 800 --hdr-sdr-content-nits 800" # Bravia/TV
VIRTUAL_FLAGS="-W 1280 -H 800 -r 90 -e --force-grab-cursor --hdr-enabled --hdr-itm-enabled --hdr-itm-sdr-nits 800 --hdr-sdr-content-nits 800" # Steam deck
HYPR_WORKSPACE="" # Target hyprland workspace

## --- Conditional ---
GAMESCOPE_COMMAND=""
TARGET_ENV=""
if hyprctl monitors | grep -Eq "HDMI-A-[12]"; then
    log "TV/Virtual monitor present. Using virtual-monitor gamescope flags"
    GAMESCOPE_COMMAND="gamemoderun gamescope $VIRTUAL_FLAGS"
    TARGET_ENV="tv_env"
    #export HYPR_WORKSPACE="6"
    export HYPR_WORKSPACE="7"
else
    log "Using PC gamescope flags."
    GAMESCOPE_COMMAND="gamemoderun gamescope $ASUS_FLAGS"
    TARGET_ENV="pc_env"
    export HYPR_WORKSPACE="4"
fi

log "Executing: $GAMESCOPE_COMMAND %COMMAND%"
log "Target: workspace $HYPR_WORKSPACE"
log "Target: environment $TARGET_ENV"

## --- Steam App ID + Env Flags ---
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

GAME_ADDR=""
MAX_TRIES=5
WAIT_TIME=1  # start with 1 second delay

for ((i=1; i<=MAX_TRIES; i++)); do
    sleep "$WAIT_TIME"
    GAME_ADDR=$(hyprctl clients -j | jq -r '.[] | select(.class == "gamescope") | .address')
    if [ -n "$GAME_ADDR" ]; then
        log "Found gamescope window on attempt $i after ${WAIT_TIME}s wait"
        break
    else
        log "Attempt $i/$MAX_TRIES: gamescope window not found yet (waited ${WAIT_TIME}s)"
    fi
    WAIT_TIME=$((WAIT_TIME * 2))  # exponential backoff
done

## -- Move to target --
if [ -n "$GAME_ADDR" ]; then
    hyprctl dispatch movetoworkspace "$HYPR_WORKSPACE,address:$GAME_ADDR"
    sleep 1
    hyprctl dispatch fullscreen 1 address:$GAME_ADDR
    log "Moved gamescope window to workspace $HYPR_WORKSPACE"
else
    log "gamescope window not found after $MAX_TRIES attempts!"
fi


## Discord/wayland PTT fix if on PC
if [ "$TARGET_ENV" = "pc_env" ]; then
    log "Starting push-to-talk fix"
    env -u LD_PRELOAD /home/alastairm/.local/bin/pttfix >> /tmp/pttfix.log 2>&1 &
    PTTFIX_PID=$!
    log "PTTFIX started with PID $PTTFIX_PID"
fi

## -- focus + wait for game exit --
hyprctl dispatch workspace "$HYPR_WORKSPACE"
wait $GAMESCOPE_PID

## -- Kill pttfix if it's running after game end--
if [ -n "$PTTFIX_PID" ] && ps -p $PTTFIX_PID > /dev/null 2>&1; then
    log "Killing push-to-talk fix (PID $PTTFIX_PID)"
    kill $PTTFIX_PID
fi
