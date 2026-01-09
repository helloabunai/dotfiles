#!/bin/bash

##
## Proton Wayland/HDR Launcher Wrapper
## 
## Goals:
## 1) Apply Proton Environment variables (HDR, Wayland) based on Display (TV vs Monitor)
## 2) Fetch game-specific overrides from JSON DB (e.g. renoDX HDR mod DLL overrides)
## 3) Move window to specific Hyprland workspaces (Monitor = 4, TV = 6)
## 4) Handle PC-specific QOL (PTT fix for discord xwayland shit, Waybar toggle)
##
## Usage: Set Steam Launch Option to: /usr/bin/bash /path/to/script.sh %command%
##

ulimit -c 0 ## ignore core dumps (probs not needed since we don't use gamescope anymore)

LOGFILE="${HOME}/scripts/debug.log"
: > "$LOGFILE"
exec > >(tee -a "$LOGFILE") 2>&1
log() {
    echo -e "SCRIPTLOG::::::: $*\n\n"
}

## -- Source variables --
ENV_FILE="$HOME/.config/scripts/targetdevice"
[ -f "$ENV_FILE" ] && source "$ENV_FILE"
echo "Connected from: $TARGET_CLIENT"
echo "Target workspace: $TARGET_WKSPC"

## --- Environment Flag Definitions ---

# Standard PC Flags (Monitor)
# PREFER_SDL for controllers to function / mouse stuff to stop mouse leaving windowed fullscreen noborder
PC_ENV_VARS="PROTON_ENABLE_WAYLAND=1 PROTON_PREFER_SDL=1 SDL_VIDEO_MOUSE_GRAB=1 WINE_MOUSE_WARP_OVERRIDE=force"
# TV/HDR Flags
# need to specify primary monitor else will appear on OS primary not TV.
TV_ENV_VARS="PROTON_ENABLE_WAYLAND=1 PROTON_ENABLE_HDR=1 ENABLE_HDR_WSI=1 PROTON_PREFER_SDL=1 WAYLANDDRV_PRIMARY_MONITOR=HDMI-A-1"

## --- Conditional Logic ---
ACTIVE_ENV_VARS=""
TARGET_ENV=""
HYPR_WORKSPACE=""

if hyprctl monitors | grep -Eq "HDMI-A-[12]"; then
    if [[ "$TARGET_CLIENT" == "mac" ]]; then
        log "HDMI-A-1 present but client is Mac → using PC flags"
        ACTIVE_ENV_VARS="$PC_ENV_VARS"
        TARGET_ENV="pc_env"
        export HYPR_WORKSPACE="4"
    else
        log "TV/Virtual monitor present. Using HDR/TV flags"
        ACTIVE_ENV_VARS="$TV_ENV_VARS"
        TARGET_ENV="tv_env"
        export HYPR_WORKSPACE="6"
    fi
else
    log "Using PC Standard flags."
    ACTIVE_ENV_VARS="$PC_ENV_VARS"
    TARGET_ENV="pc_env"
    export HYPR_WORKSPACE="4"
fi

log "Selected Env Vars: $ACTIVE_ENV_VARS"
log "Target: workspace $HYPR_WORKSPACE"

## --- Steam App ID + Database Overrides ---
DB_ENV_FLAGS=""
DB_PATH="$HOME/scripts/game_envs.json"
GAME_LAUNCH_CMD="$*"
log "Raw game launch cmd: $GAME_LAUNCH_CMD"
STEAM_APPID=$(echo "$GAME_LAUNCH_CMD" | grep -oP 'AppId=\K\d+')
log "Launched SteamAppId: $STEAM_APPID"

if [ -n "$STEAM_APPID" ] && [ -f "$DB_PATH" ]; then
    # Helper to fetch flags from JSON
    DB_ENV_FLAGS=$(jq -r --arg id "$STEAM_APPID" --arg key "$TARGET_ENV" '.[$id][$key] // empty' "$DB_PATH")
    NOTE=$(jq -r --arg id "$STEAM_APPID" '.[$id].note // empty' "$DB_PATH")

    if [ -n "$DB_ENV_FLAGS" ]; then
        log "Loaded DB_ENV_FLAGS: $DB_ENV_FLAGS"
        [ -n "$NOTE" ] && log "Note/Parsed game: $NOTE"
    else
        log "No env flags found for Steam AppId=$STEAM_APPID in context=$TARGET_ENV"
    fi
else
    log "No Steam AppId found or DB missing"
fi

#################
## config done ##
#################

## --- PC Specific: Discord PTT & Waybar ---
if [ "$TARGET_ENV" = "pc_env" ]; then
    log "Starting push-to-talk fix"
    env -u LD_PRELOAD /home/alastairm/.local/bin/pttfix >> /tmp/pttfix.log 2>&1 &
    PTTFIX_PID=$!
    log "PTTFIX started with PID $PTTFIX_PID"

    log "Switching Waybar to fullscreen config"
    chmod +w ~/.config/waybar/config.jsonc
    cp ~/.config/waybar/config-fullscreen.jsonc ~/.config/waybar/config.jsonc
    chmod -w ~/.config/waybar/config.jsonc
    ~/scripts/waybar_refresh.sh
fi

## -- Lutris Detection --
if [ -n "$LUTRIS_GAME_UUID" ]; then
    log "Detected Lutris launch (LUTRIS_GAME_UUID=$LUTRIS_GAME_UUID) → skipping Wayland logic"
    USE_WAYLAND=false
else
    USE_WAYLAND=true
fi

## -- Launch Game --
log "Launching game with Environment Variables..."
log "FINAL EXEC: $ACTIVE_ENV_VARS $DB_ENV_FLAGS gamemoderun $@"

# We use 'env' to apply variables. 
# IMPORTANT: $ACTIVE_ENV_VARS must be unquoted to expand into multiple args for env.
env $ACTIVE_ENV_VARS $DB_ENV_FLAGS gamemoderun "$@" &
GAME_PID_WRAPPER=$!

## -- Window Detection & Enforcement Loop --
## Replaces simple wait with a 15s persistence loop to catch stubborn windows.
GAME_ADDR=""
STEAMBP_ADDR=""

## Toggle Steam Big Picture (SBP) not exclusive fullscreen if needed
if [ "$TARGET_ENV" = "tv_env" ]; then
    STEAMBP_ADDR=$(hyprctl clients -j | jq -r '.[] | select(.title == "Steam Big Picture Mode") | .address')
    if [ -n "$STEAMBP_ADDR" ]; then
        hyprctl dispatch fullscreen address:$STEAMBP_ADDR
    fi
fi

if [ "$USE_WAYLAND" = true ]; then
    LOG_ONCE=true
    MAX_CHECKS=30 
    SLEEP_INTERVAL=1
    
    log "Proton window movement loop begins..."

    for ((i=1; i<=MAX_CHECKS; i++)); do
        CURRENT_ADDR=$(hyprctl clients -j | jq -r '.[] | select(.xdgTag == "proton-game") | .address' | head -n1)

        if [ -n "$CURRENT_ADDR" ]; then
            GAME_ADDR="$CURRENT_ADDR" 

            # 2. Get Workspace/Fullscreen status (0=windowed, 1=fullscreen)
            WINDOW_STATE=$(hyprctl clients -j | jq -r --arg addr "$CURRENT_ADDR" '.[] | select(.address == "$addr") | "\(.workspace.id) \(.fullscreen)"')
            read CURRENT_WS CURRENT_FS <<< "$WINDOW_STATE"
            
            if [ "$CURRENT_WS" != "$HYPR_WORKSPACE" ]; then
                log "Enforcing: Moving $CURRENT_ADDR from WS $CURRENT_WS to WS $HYPR_WORKSPACE (Attempt $i/$MAX_CHECKS)"
                hyprctl dispatch movetoworkspace "$HYPR_WORKSPACE,address:$CURRENT_ADDR"
                
                # Reset LOG_ONCE so we confirm success next loop
                LOG_ONCE=true 
            
            elif [ "$LOG_ONCE" = true ]; then
                log "Window $CURRENT_ADDR is correctly on WS $HYPR_WORKSPACE. Monitoring..."
                LOG_ONCE=false
            fi

            if [ "$CURRENT_FS" == "0" ]; then
                log "Enforcing: Window detected as Windowed (0). Toggling fullscreen..."
                hyprctl dispatch fullscreen address:$CURRENT_ADDR
            fi

        else
            # If no window found yet, just log periodically
            if (( i % 5 == 0 )); then
                 log "Waiting for Proton window... ($i/$MAX_CHECKS)"
            fi
        fi

        # Check if game died
        if ! kill -0 $GAME_PID_WRAPPER 2>/dev/null; then
            log "Game process died. Exiting loop."
            break
        fi

        sleep "$SLEEP_INTERVAL"
    done
fi

## -- Wait for game exit --
# Ensure we are focused on the game workspace before waiting
hyprctl dispatch workspace "$HYPR_WORKSPACE"
wait $GAME_PID_WRAPPER

## -- Cleanup --
if [ -n "$PTTFIX_PID" ] && ps -p $PTTFIX_PID > /dev/null 2>&1; then
    log "Killing push-to-talk fix (PID $PTTFIX_PID)"
    kill $PTTFIX_PID
fi

log "Restoring normal Waybar config"
chmod +w ~/.config/waybar/config.jsonc
cp ~/.config/waybar/config-normal.jsonc ~/.config/waybar/config.jsonc
chmod -w ~/.config/waybar/config.jsonc
~/scripts/waybar_refresh.sh

if [ "$TARGET_ENV" = "tv_env" ]; then
    if [ -n "$STEAMBP_ADDR" ]; then
        log "Restoring steam big picture to exclusive fullscreen..."
        sleep 3
        hyprctl dispatch fullscreen address:$STEAMBP_ADDR
    fi
fi