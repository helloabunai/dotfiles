#!/bin/bash

##
## Proton Wayland/HDR Launcher Wrapper
##
## Usage: Set Steam Launch Option to: /path/to/script.sh %command%
##

ulimit -c 0 ## ignore core dumps

LOGFILE="${HOME}/scripts/debug.log"
: >"$LOGFILE"

# pipe + grep output to avoid wayland overlay messages (valve pls fix steam overlay wayland)
IGNORE_PATTERN="wrong ELF class: ELFCLASS(32|64)|libgamemode.*cannot open shared object file|skipping destruction \(fork without exec\?\)|pv-locale-gen:|setlocale .* No such file|Container startup will be faster if missing locales"
exec > >(grep --line-buffered -vE "$IGNORE_PATTERN" | tee -a "$LOGFILE") 2>&1
log() {
  echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] SCRIPTLOG::::::: $*\n"
}

## -- Screensaver Config --
TERMINAL="kitty"
WRAPPED_CMD="bash -c 'sleep 0.3; exec cmatrix -bs'"

## -- Source variables --
ENV_FILE="$HOME/.config/scripts/targetdevice"
[ -f "$ENV_FILE" ] && source "$ENV_FILE"
echo "Connected from: $TARGET_CLIENT"
echo "Target workspace: $TARGET_WKSPC"

## --- Environment Flag Definitions ---
# PC Flags (Monitor)
PC_ENV_VARS="PROTON_ENABLE_WAYLAND=1 PROTON_PREFER_SDL=1 WAYLANDDRV_PRIMARY_MONITOR=DP-1"

# TV/HDR Flags
TV_ENV_VARS="PROTON_ENABLE_WAYLAND=1 PROTON_ENABLE_HDR=1 ENABLE_HDR_WSI=1 PROTON_PREFER_SDL=1 WAYLANDDRV_PRIMARY_MONITOR=HDMI-A-1"

## --- Conditional Logic ---
## Map each streaming client to the virtual monitor it requires
declare -A CLIENT_MONITOR_MAP=( [shield]="HDMI-A-1" [deck]="HDMI-A-2" [mac]="HDMI-A-1" )
declare -A CLIENT_WORKSPACE_MAP=( [shield]="6" [deck]="7" [mac]="4" )

ACTIVE_ENV_VARS=""
TARGET_ENV=""
HYPR_WORKSPACE=""

EXPECTED_MONITOR="${CLIENT_MONITOR_MAP[$TARGET_CLIENT]}"
STREAM_ACTIVE=false

if [ -n "$EXPECTED_MONITOR" ]; then
  if hyprctl monitors | grep -q "$EXPECTED_MONITOR"; then
    STREAM_ACTIVE=true
    log "Verified: Target client '$TARGET_CLIENT' has expected monitor '$EXPECTED_MONITOR' active"
  else
    log "Target client is '$TARGET_CLIENT' but monitor '$EXPECTED_MONITOR' is NOT active → stale config, defaulting to PC"
  fi
else
  log "No target client set or unknown client '$TARGET_CLIENT' → defaulting to PC"
fi

if [ "$STREAM_ACTIVE" = true ]; then
  if [[ "$TARGET_CLIENT" == "mac" ]]; then
    log "HDMI-A-1 present but client is Mac → using PC flags"
    ACTIVE_ENV_VARS="$PC_ENV_VARS"
    TARGET_ENV="pc_env"
    export HYPR_WORKSPACE="4"
  else
    log "Active stream to '$TARGET_CLIENT'. Using HDR/TV flags"
    ACTIVE_ENV_VARS="$TV_ENV_VARS"
    TARGET_ENV="tv_env"
    export HYPR_WORKSPACE="${CLIENT_WORKSPACE_MAP[$TARGET_CLIENT]}"
  fi
else
  log "No active stream. Using PC Standard flags."
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
  env -u LD_PRELOAD /home/alastairm/.local/bin/pttfix >>/tmp/pttfix.log 2>&1 &
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
  log "Detected Lutris launch (LUTRIS_GAME_UUID=$LUTRIS_GAME_UUID)"
  IS_LUTRIS=true
else
  IS_LUTRIS=false
fi

## -- Launch Game (BACKGROUND) --
log "Launching game with Environment Variables..."
log "FINAL EXEC: $ACTIVE_ENV_VARS $DB_ENV_FLAGS $@"

# Run game in background so we can track and kill it if it hangs
env $ACTIVE_ENV_VARS $DB_ENV_FLAGS "$@" < /dev/null &
GAME_PID_WRAPPER=$!

## -- Steam BP Toggle --
if [ "$TARGET_ENV" = "tv_env" ]; then
  STEAMBP_ADDR=$(hyprctl clients -j | jq -r '.[] | select(.title == "Steam Big Picture Mode") | .address')
  if [ -n "$STEAMBP_ADDR" ]; then
    hyprctl dispatch fullscreen address:$STEAMBP_ADDR >/dev/null 2>&1
  fi
fi

## -- Window Detection & Enforcement Loop (FOREGROUND) --
LOG_ONCE=true
MAX_WAIT=120
SLEEP_INTERVAL=1
SCREENSAVER_TRIGGERED="false"

WINDOW_SEEN="false"
MISSING_COUNT=0
MAX_MISSING=7 # 7 seconds tolerance for splash screens

log "Window movement loop begins..."

# Loop runs as long as the wrapper process is alive
while kill -0 $GAME_PID_WRAPPER 2>/dev/null; do
  CLIENT_INFO=$(hyprctl clients -j | jq -r --arg appid "steam_app_$STEAM_APPID" '.[] | select(.xdgTag == "proton-game" or .contentType == "game" or .class == $appid or .class == "steam_app_default" or (.class != null and (.class | test("^steam_app_\\d+$"))) or (.class != null and (.class | test("\\.(exe|EXE)$")))) | "\(.address) \(.workspace.id) \(.fullscreen)"' | head -n1)

  if [ -n "$CLIENT_INFO" ]; then
    # Window is active!
    WINDOW_SEEN="true"
    MISSING_COUNT=0 # Reset missing counter
    
    read CURRENT_ADDR CURRENT_WS CURRENT_FS <<<"$CLIENT_INFO"

    # 1. Workspace Enforcement
    if [ "$CURRENT_WS" != "$HYPR_WORKSPACE" ]; then
      log "Enforcing: Moving $CURRENT_ADDR to WS $HYPR_WORKSPACE"
      hyprctl dispatch movetoworkspace "$HYPR_WORKSPACE,address:$CURRENT_ADDR" >/dev/null 2>&1
      LOG_ONCE=true
      
    elif [ "$LOG_ONCE" = true ]; then
      log "Window $CURRENT_ADDR is correctly on WS $HYPR_WORKSPACE."
      LOG_ONCE=false

      # 2. Monitor Screensavers (TV Mode Only)
      if [ "$TARGET_ENV" = "tv_env" ] && [ "$SCREENSAVER_TRIGGERED" == "false" ]; then
        log "TV mode: Starting monitor screensavers silently via window rules..."
        ACTIVE_WS_DP1=$(hyprctl monitors -j | jq -r '.[] | select(.name=="DP-1") | .activeWorkspace.id')
        
        # Spawn directly to the target workspaces in fullscreen without changing focus
        hyprctl dispatch exec "[workspace $ACTIVE_WS_DP1 silent; fullscreen] $TERMINAL -e $WRAPPED_CMD"
        hyprctl dispatch exec "[workspace 5 silent; fullscreen] $TERMINAL -e $WRAPPED_CMD"
        
        # Ensure we are definitively focused on the game
        hyprctl dispatch workspace "$HYPR_WORKSPACE"
        SCREENSAVER_TRIGGERED="true"
      fi
    fi
    
    # 3. Fullscreen Enforcement
    if [ "$CURRENT_FS" == "0" ] || [ "$CURRENT_FS" == "false" ]; then
      log "Enforcing: Window detected as Windowed. Toggling fullscreen..."
      hyprctl dispatch fullscreen address:$CURRENT_ADDR >/dev/null 2>&1
    fi

  else
    # Window is missing!
    if [ "$WINDOW_SEEN" == "true" ]; then
      ((MISSING_COUNT++))
      
      # Only log every 5 seconds to prevent log spam
      if ((MISSING_COUNT % 5 == 0)); then
         log "Window missing. Splash screen gap or exit? ($MISSING_COUNT/$MAX_MISSING)"
      fi
      
      if [ "$MISSING_COUNT" -ge "$MAX_MISSING" ]; then
        log "Game window gone for $MAX_MISSING seconds. Assuming full exit."
        # We simply break the loop to restore the desktop, but DO NOT kill the process yet.
        break
      fi
    else
      # Waiting for very first window
      ((MAX_WAIT--))
      if ((MAX_WAIT % 10 == 0)); then
         log "Waiting for initial game window... ($MAX_WAIT seconds left)"
      fi
      if [ "$MAX_WAIT" -le 0 ]; then
         log "Never saw game window after 120s. Exiting watcher."
         break
      fi
    fi
  fi
  
  sleep "$SLEEP_INTERVAL"
done

## -- Desktop Cleanup Phase --
log "Game window closed. Restoring desktop environment..."

# 1. Push-to-Talk fix cleanup
if [ -n "$PTTFIX_PID" ]; then
  log "Killing push-to-talk fix: PID $PTTFIX_PID"
  kill $PTTFIX_PID 2>/dev/null
fi

# 2. Screensaver cleanup
if [ "$TARGET_ENV" = "tv_env" ]; then
  log "Stopping screensavers (killing cmatrix)..."
  killall cmatrix 2>/dev/null
fi

# 3. Waybar Restore
log "Restoring normal Waybar config"
chmod +w ~/.config/waybar/config.jsonc
cp ~/.config/waybar/config-normal.jsonc ~/.config/waybar/config.jsonc
chmod -w ~/.config/waybar/config.jsonc
~/scripts/waybar_refresh.sh

if [ "$TARGET_ENV" = "tv_env" ] && [ -n "$STEAMBP_ADDR" ]; then
  log "Restoring steam big picture to exclusive fullscreen..."
  sleep 3
  hyprctl dispatch fullscreen address:$STEAMBP_ADDR >/dev/null 2>&1
fi

# 4. Fix waybar dock
pkill kded6

## -- Graceful Proton Shutdown Phase --
# Recursively collect all descendant PIDs of a given PID
get_descendants() {
  local children=$(pgrep -P "$1" 2>/dev/null)
  for child in $children; do
    echo "$child"
    get_descendants "$child"
  done
}

if [ "$IS_LUTRIS" = true ]; then
  log "Lutris game: short grace period for wine cleanup..."
  SHUTDOWN_TIMEOUT=10
else
  log "Desktop restored. Waiting for Steam to cleanly sync cloud saves and natively close Proton..."
  SHUTDOWN_TIMEOUT=60
fi

while kill -0 $GAME_PID_WRAPPER 2>/dev/null; do
  sleep 1
  ((SHUTDOWN_TIMEOUT--))
  
  if [ "$SHUTDOWN_TIMEOUT" -le 0 ]; then
    log "Process failed to close natively after timeout. Forcing termination..."


    # Collect all descendants and SIGTERM them (deepest first)
    DESCENDANTS=$(get_descendants $GAME_PID_WRAPPER)
    for pid in $(echo "$DESCENDANTS" | tac); do
      kill -TERM "$pid" 2>/dev/null
    done
    kill -TERM $GAME_PID_WRAPPER 2>/dev/null
    sleep 2
    # Force-kill any stragglers
    for pid in $(get_descendants $GAME_PID_WRAPPER | tac); do
      kill -9 "$pid" 2>/dev/null
    done
    kill -9 $GAME_PID_WRAPPER 2>/dev/null
    if [ "$IS_LUTRIS" = true ]; then
      pkill -f wineserver 2>/dev/null
    fi

    break
  fi
done

log "Script finished cleanly."