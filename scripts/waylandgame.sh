#!/bin/bash

##
## Proton Wayland/HDR Launcher Wrapper
##
## Usage: Set Steam Launch Option to: /path/to/script.sh %command%
##

#!/bin/bash

trap - PIPE
ulimit -c 0 ## ignore core dumps

LOGFILE="${HOME}/scripts/debug.log"
: >"$LOGFILE"
# filter steam wayland overlay noise
IGNORE_PATTERN="wrong ELF class: ELFCLASS(32|64)|libgamemode.*cannot open shared object file|skipping destruction \(fork without exec\?\)|pv-locale-gen:|setlocale .* No such file|Container startup will be faster if missing locales"
exec > >(grep --line-buffered -vE "$IGNORE_PATTERN" | tee --output-error=exit -a "$LOGFILE") 2>&1

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

## --- Parse keyword args (presence = enabled) ---
## Usage: waylandgame.sh [wayland] [hdr] [nohud] [latency] [dheap] %command%
##   wayland -> PROTON_ENABLE_WAYLAND=1. Steam Input needs X11.
##   hdr     -> HDR on. Requires wayland.
##   nohud   -> skip MangoHud. Default on.
##   latency -> Reflex low-latency flags. Default off.
##   dheap   -> VKD3D_CONFIG=descriptor_heap. Unset entirely when absent.
## Keywords go before %command% and are shifted out.
USE_WAYLAND=0
USE_HDR=0
USE_HUD=1
USE_LATENCY=0
USE_DHEAP=0
while [ $# -gt 0 ]; do
  case "$1" in
    wayland) USE_WAYLAND=1; shift ;;
    hdr)     USE_HDR=1;     shift ;;
    nohud)   USE_HUD=0;     shift ;;
    latency) USE_LATENCY=1; shift ;;
    dheap)   USE_DHEAP=1;   shift ;;
    *) break ;;
  esac
done
# HDR requires Wayland.
[ "$USE_WAYLAND" -eq 0 ] && USE_HDR=0

## --- Reflex / low-latency flags ---
# vkd3d drives DX12, dxvk drives DX11 and under.
# Opt-in so a plain run stays a clean baseline.
LL_ENV_VARS=""
if [ "$USE_LATENCY" -eq 1 ]; then
  LL_ENV_VARS="PROTON_VKD3D_LOWLATENCY=1 PROTON_DXVK_LOWLATENCY=1"
fi

## --- MangoHud: FPS counter, top-left ---
HUD_ENV_VARS=""
if [ "$USE_HUD" -eq 1 ]; then
  HUD_ENV_VARS="MANGOHUD=1 MANGOHUD_CONFIGFILE=$HOME/.config/MangoHud/waylandgame.conf"
fi

## --- vkd3d descriptor heap ---
# Opt-in only. Absent means VKD3D_CONFIG is left unset, not set to something else.
DHEAP_ENV_VARS=""
if [ "$USE_DHEAP" -eq 1 ]; then
  DHEAP_ENV_VARS="VKD3D_CONFIG=descriptor_heap"
fi

## --- Environment Flag Definitions ---
# PC Flags (Monitor)
PC_ENV_VARS="PROTON_ENABLE_WAYLAND=$USE_WAYLAND PROTON_DLSS_UPGRADE=1 PROTON_DISABLE_HIDRAW=1 PROTON_PREFER_SDL=1 WAYLANDDRV_PRIMARY_MONITOR=DP-1"

# TV/HDR flags. DXVK_HDR=1 is what actually enables HDR.
TV_ENV_VARS="PROTON_ENABLE_WAYLAND=$USE_WAYLAND PROTON_DLSS_UPGRADE=1 PROTON_ENABLE_HDR=$USE_HDR DXVK_HDR=$USE_HDR PROTON_DISABLE_HIDRAW=1 PROTON_PREFER_SDL=1 WAYLANDDRV_PRIMARY_MONITOR=HDMI-A-1"

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
[ "$USE_HUD" -eq 1 ] && log "MangoHud: enabled (fps only, top-left)" || log "MangoHud: disabled via 'nohud'"
[ "$USE_LATENCY" -eq 1 ] && log "Low-latency: ENABLED via 'latency' ($LL_ENV_VARS)" || log "Low-latency: disabled (baseline run; pass 'latency' to enable)"
[ "$USE_DHEAP" -eq 1 ] && log "vkd3d descriptor heap: ENABLED via 'dheap' ($DHEAP_ENV_VARS)" || log "vkd3d descriptor heap: disabled (VKD3D_CONFIG unset; pass 'dheap' to enable)"

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

## -- Disable close-window bind while the game runs --
# Trap rebinds it even if the loop bails or we get TERM/INT.
# hl.unbind is not a dispatcher, so it needs eval not dispatch.
QUITBIND_KEY="SUPER + Q"
QUITBIND_CMD="$HOME/.local/lib/hyde/dontkillsteam.sh"
QUITBIND_DESC="[Window Management] close focused window"
restore_quitbind() {
  [ "$QUITBIND_DISABLED" = "1" ] || return 0
  QUITBIND_DISABLED=0
  hyprctl eval "hl.bind(\"$QUITBIND_KEY\", hl.dsp.exec_cmd(\"$QUITBIND_CMD\"), { description = \"$QUITBIND_DESC\" })" >/dev/null 2>&1
  log "Restored $QUITBIND_KEY"
}
trap restore_quitbind EXIT INT TERM HUP
if hyprctl eval "hl.unbind(\"$QUITBIND_KEY\")" >/dev/null 2>&1; then
  QUITBIND_DISABLED=1
  log "Disabled $QUITBIND_KEY for this session"
fi

## -- Launch Game (BACKGROUND) --
log "Launching game with Environment Variables..."
log "FINAL EXEC: $ACTIVE_ENV_VARS $DHEAP_ENV_VARS $LL_ENV_VARS $HUD_ENV_VARS $DB_ENV_FLAGS $@"

# Background so a hang can be tracked and killed.
# DB_ENV_FLAGS last so per-game entries win.
env $ACTIVE_ENV_VARS $DHEAP_ENV_VARS $LL_ENV_VARS $HUD_ENV_VARS $DB_ENV_FLAGS "$@" < /dev/null &
GAME_PID_WRAPPER=$!

## -- Steam BP Toggle --
if [ "$TARGET_ENV" = "tv_env" ]; then
  STEAMBP_ADDR=$(hyprctl clients -j | jq -r '.[] | select(.title == "Steam Big Picture Mode") | .address' | head -n1)
  if [ -n "$STEAMBP_ADDR" ]; then
    hyprctl dispatch "hl.dsp.window.fullscreen({ action = \"unset\", window = \"address:$STEAMBP_ADDR\" })" >/dev/null 2>&1
  fi
fi

## -- Window Detection & Enforcement Loop (FOREGROUND) --
LOG_ONCE=true
MAX_WAIT_INIT=120
MAX_WAIT=$MAX_WAIT_INIT
SLEEP_INTERVAL=1
SCREENSAVER_TRIGGERED="false"

WINDOW_SEEN="false"
MISSING_COUNT=0
MAX_MISSING=7 # 7 seconds tolerance for splash screens

# Loader windows match the same filters as the game but refuse fullscreen; track state per address so we stop fighting them.
declare -A FS_ATTEMPTS=()
declare -A FS_GIVEUP=()
declare -A FIRST_SEEN=()
MAX_FS_ATTEMPTS=4
FS_GRACE=3       # settle time for a window that looks like the game proper
LOADER_GRACE=20  # settle time for loader-shaped windows; most are gone by then
FS_HOLD=3        # consecutive fullscreen polls before a window counts as the real game

# Fullscreen but not solitary means full composition every frame; kick it once it has held that way.
declare -A SOLITARY_KICKS=()
MAX_SOLITARY_KICKS=3
SOL_HOLD=8
SOL_BLOCKED_COUNT=0

# Proton tags launchers as "proton-game" too, so shape is the only tell: a loader is both untitled and a fraction of the screen.
LOADER_AREA_PCT=20
case "$TARGET_ENV" in
  tv_env) TARGET_MONITOR="${CLIENT_MONITOR_MAP[$TARGET_CLIENT]}" ;;
  *)      TARGET_MONITOR="DP-1" ;;
esac
MON_AREA=$(hyprctl monitors -j | jq -r --arg m "$TARGET_MONITOR" '[.[] | select(.name == $m) | ((.width / .scale) * (.height / .scale))] | .[0] // 0' | cut -d. -f1)
MIN_GAME_AREA=$(( ${MON_AREA:-0} * LOADER_AREA_PCT / 100 ))
log "Loader filter: monitor $TARGET_MONITOR area ${MON_AREA:-0}, windows under ${MIN_GAME_AREA}px or untitled treated as loaders"
TICK=0
SELECTED_ADDR=""
DIAG_LAST=""
FS_STABLE=0
REAL_WINDOW_SEEN="false"
LOADER_GAP_HANDLED="false"

log "Window movement loop begins..."

# Loop runs as long as the wrapper process is alive
while kill -0 $GAME_PID_WRAPPER 2>/dev/null; do
  ((TICK++))

  # Game-shaped beats loader-shaped; then self-declared game beats appid class beats bare .exe; larger area breaks ties.
  CANDIDATES=$(hyprctl clients -j | jq -r --arg appid "steam_app_$STEAM_APPID" --argjson minarea "${MIN_GAME_AREA:-0}" '
    [ .[]
      | select(.xdgTag == "proton-game" or .contentType == "game" or .class == $appid or .class == "steam_app_default" or (.class != null and (.class | test("^steam_app_\\d+$"))) or (.class != null and (.class | test("\\.(exe|EXE)$"))))
      | { addr: .address, ws: .workspace.id, fs: .fullscreen,
          area: (((.size[0] // 0) * (.size[1] // 0))),
          loaderish: (if ((.title // "") == "" and (((.size[0] // 0) * (.size[1] // 0)) < $minarea)) then 1 else 0 end),
          fsclient: (.fullscreenClient // "-"), handler: (.fullscreenHandler // "-"),
          rank: (if (.xdgTag == "proton-game" or .contentType == "game") then 0
                 elif (.class == $appid) then 1
                 else 2 end) } ]
    | sort_by(.loaderish, .rank, -.area) | .[] | "\(.rank) \(.loaderish) \(.addr) \(.ws) \(.fs) \(.fsclient) \(.handler)"')

  # A written-off loader scores last, so the real window wins as soon as it maps.
  CLIENT_INFO=""
  BEST_SCORE=99
  while read -r C_RANK C_LOADERISH C_ADDR C_WS C_FS C_FSCLIENT C_HANDLER; do
    [ -z "$C_ADDR" ] && continue
    SCORE=$((C_RANK + C_LOADERISH * 5))
    [ "${FS_GIVEUP[$C_ADDR]}" = "1" ] && SCORE=$((SCORE + 10))
    if [ "$SCORE" -lt "$BEST_SCORE" ]; then
      BEST_SCORE=$SCORE
      CLIENT_INFO="$C_ADDR $C_WS $C_FS $C_RANK $C_LOADERISH $C_FSCLIENT $C_HANDLER"
    fi
  done <<<"$CANDIDATES"

  if [ -n "$CLIENT_INFO" ]; then
    # Window is active!
    WINDOW_SEEN="true"
    MISSING_COUNT=0 # Reset missing counter

    read CURRENT_ADDR CURRENT_WS CURRENT_FS CURRENT_RANK CURRENT_LOADERISH CURRENT_FSCLIENT CURRENT_HANDLER <<<"$CLIENT_INFO"

    read MON_SOLITARY MON_SOLBLOCK MON_SCANOUT MON_SCANBLOCK MON_TEAR MON_VRR MON_FMT MON_ACTIVE_WS <<<"$(hyprctl monitors -j | jq -r --arg m "$TARGET_MONITOR" '.[] | select(.name==$m) | "\(.solitary) \((.solitaryBlockedBy // ["null"])|join(",")) \(.directScanoutTo) \((.directScanoutBlockedBy // ["null"])|join(",")) \(.activelyTearing) \(.vrr) \(.currentFormat) \(.activeWorkspace.id)"')"

    # Solitary and fullscreen only mean anything while the game's workspace is the one on screen.
    WIN_VISIBLE=0
    [ "$CURRENT_WS" = "$MON_ACTIVE_WS" ] && WIN_VISIBLE=1

    # Logged only on change: catches what actually flips when a judder clears.
    DIAG="fs=$CURRENT_FS fsClient=$CURRENT_FSCLIENT handler=$CURRENT_HANDLER solitary=$MON_SOLITARY solitaryBlockedBy=$MON_SOLBLOCK scanoutTo=$MON_SCANOUT scanoutBlockedBy=$MON_SCANBLOCK tearing=$MON_TEAR vrr=$MON_VRR fmt=$MON_FMT"
    if [ "$DIAG" != "$DIAG_LAST" ]; then
      log "STATE: $DIAG"
      DIAG_LAST="$DIAG"
    fi

    if [ "$CURRENT_ADDR" != "$SELECTED_ADDR" ]; then
      WIN_DESC=$(hyprctl clients -j | jq -r --arg a "$CURRENT_ADDR" '.[] | select(.address == $a) | "class=\(.class) title=\(.title) size=\(.size[0])x\(.size[1]) xdgTag=\(.xdgTag) contentType=\(.contentType) floating=\(.floating)"')
      log "Enforcement target: $CURRENT_ADDR (rank $CURRENT_RANK, loaderish $CURRENT_LOADERISH) $WIN_DESC"
      SELECTED_ADDR="$CURRENT_ADDR"
      FS_STABLE=0
      SOL_BLOCKED_COUNT=0
      LOG_ONCE=true
    fi
    [ -z "${FIRST_SEEN[$CURRENT_ADDR]}" ] && FIRST_SEEN[$CURRENT_ADDR]=$TICK

    # 1. Workspace Enforcement
    if [ "$CURRENT_WS" != "$HYPR_WORKSPACE" ]; then
      log "Enforcing: Moving $CURRENT_ADDR to WS $HYPR_WORKSPACE"
      hyprctl dispatch "hl.dsp.window.move({ workspace = \"$HYPR_WORKSPACE\", window = \"address:$CURRENT_ADDR\" })" >/dev/null 2>&1
      LOG_ONCE=true
      
    elif [ "$LOG_ONCE" = true ]; then
      log "Window $CURRENT_ADDR is correctly on WS $HYPR_WORKSPACE."
      LOG_ONCE=false

      # 2. Monitor Screensavers (TV Mode Only)
      if [ "$TARGET_ENV" = "tv_env" ] && [ "$SCREENSAVER_TRIGGERED" == "false" ]; then
        log "TV mode: Starting monitor screensavers silently via window rules..."
        ACTIVE_WS_DP1=$(hyprctl monitors -j | jq -r '.[] | select(.name=="DP-1") | .activeWorkspace.id')
        
        # Spawn fullscreen to target workspaces without changing focus
        hyprctl dispatch "hl.dsp.exec_cmd([[$TERMINAL -e $WRAPPED_CMD]], { workspace = \"$ACTIVE_WS_DP1 silent\", fullscreen = true })"
        hyprctl dispatch "hl.dsp.exec_cmd([[$TERMINAL -e $WRAPPED_CMD]], { workspace = \"5 silent\", fullscreen = true })"

        # Ensure we are definitively focused on the game
        hyprctl dispatch "hl.dsp.focus({ workspace = \"$HYPR_WORKSPACE\" })"
        SCREENSAVER_TRIGGERED="true"
      fi
    fi
    
    # 3. Fullscreen Enforcement
    if [ "$CURRENT_FS" == "0" ] || [ "$CURRENT_FS" == "false" ]; then
      FS_STABLE=0
      AGE=$((TICK - ${FIRST_SEEN[$CURRENT_ADDR]}))
      # Loader-shaped windows get a long leash, so short-lived ones are never touched at all.
      GRACE=$FS_GRACE
      [ "$CURRENT_LOADERISH" = "1" ] && GRACE=$LOADER_GRACE
      if [ "$WIN_VISIBLE" != "1" ]; then
        : # off screen; a fullscreen transition now just stalls a backgrounded game
      elif [ "${FS_GIVEUP[$CURRENT_ADDR]}" = "1" ]; then
        : # written-off loader, leave it alone
      elif [ "$AGE" -lt "$GRACE" ]; then
        : # let it settle, it may fullscreen itself
      elif [ "${FS_ATTEMPTS[$CURRENT_ADDR]:-0}" -ge "$MAX_FS_ATTEMPTS" ]; then
        FS_GIVEUP[$CURRENT_ADDR]=1
        log "Window $CURRENT_ADDR refused fullscreen ${MAX_FS_ATTEMPTS}x. Treating as loader; waiting for the real game window."
      else
        FS_ATTEMPTS[$CURRENT_ADDR]=$((${FS_ATTEMPTS[$CURRENT_ADDR]:-0} + 1))
        log "Enforcing: Window detected as Windowed. Setting fullscreen (${FS_ATTEMPTS[$CURRENT_ADDR]}/$MAX_FS_ATTEMPTS)..."
        hyprctl dispatch "hl.dsp.window.fullscreen({ action = \"set\", mode = \"fullscreen\", window = \"address:$CURRENT_ADDR\" })" >/dev/null 2>&1
      fi
    else
      ((FS_STABLE++))
      if [ "$FS_STABLE" -ge "$FS_HOLD" ]; then
        # Holding fullscreen proves it is not a loader, so its budget resets for later alt-tabs.
        FS_ATTEMPTS[$CURRENT_ADDR]=0
        if [ "$REAL_WINDOW_SEEN" != "true" ]; then
          REAL_WINDOW_SEEN="true"
          log "Window $CURRENT_ADDR held fullscreen for ${FS_HOLD}s. Treating as the real game window."
        fi
      fi

      # A self-fullscreened game is never promoted to solitary, so every frame stays composited and the camera judders.
      # Dropping fullscreen lets the enforcement branch re-apply it next tick, which is what fixes it by hand.
      if [ "$WIN_VISIBLE" != "1" ]; then
        # Another workspace is on screen, so solitary describes that instead. Kicking here
        # would mangle a backgrounded game's swapchain and stall it on return.
        SOL_BLOCKED_COUNT=0
      elif [ "$MON_SOLITARY" = "0" ] || [ "$MON_SOLITARY" = "null" ]; then
        ((SOL_BLOCKED_COUNT++))
      else
        SOL_BLOCKED_COUNT=0
      fi
      # First kick fires the moment the game settles, while loading screens hide the flip.
      # Later ones wait SOL_HOLD so a transient overlay can't cause a flash mid-game.
      KICKED=${SOLITARY_KICKS[$CURRENT_ADDR]:-0}
      if [ "$REAL_WINDOW_SEEN" = "true" ] && [ "$SOL_BLOCKED_COUNT" -ge 1 ] && [ "$KICKED" -lt "$MAX_SOLITARY_KICKS" ] &&
        { [ "$KICKED" -eq 0 ] || [ "$SOL_BLOCKED_COUNT" -ge "$SOL_HOLD" ]; }; then
        SOLITARY_KICKS[$CURRENT_ADDR]=$((KICKED + 1))
        log "Fullscreen but not solitary ($MON_SOLBLOCK) for ${SOL_BLOCKED_COUNT}s. Kicking fullscreen off so it re-applies (${SOLITARY_KICKS[$CURRENT_ADDR]}/$MAX_SOLITARY_KICKS)..."
        SOL_BLOCKED_COUNT=0
        hyprctl dispatch "hl.dsp.window.fullscreen({ action = \"unset\", window = \"address:$CURRENT_ADDR\" })" >/dev/null 2>&1
      fi
    fi

  else
    # Window is missing! Only a window that held fullscreen counts as an exit; a vanished loader means the game is still coming.
    if [ "$WINDOW_SEEN" == "true" ] && [ "$REAL_WINDOW_SEEN" != "true" ] && [ "$LOADER_GAP_HANDLED" != "true" ]; then
      LOADER_GAP_HANDLED="true"
      MAX_WAIT=$MAX_WAIT_INIT
      log "Loader closed before any window held fullscreen. Resetting ${MAX_WAIT}s budget for the real game window."
    fi

    if [ "$WINDOW_SEEN" == "true" ] && [ "$REAL_WINDOW_SEEN" == "true" ]; then
      ((MISSING_COUNT++))
      
      # Only log every 5 seconds to prevent log spam
      if ((MISSING_COUNT % 5 == 0)); then
         log "Window missing. Splash screen gap or exit? ($MISSING_COUNT/$MAX_MISSING)"
      fi
      
      if [ "$MISSING_COUNT" -ge "$MAX_MISSING" ]; then
        log "Game window gone for $MAX_MISSING seconds. Assuming full exit."
        # Break to restore desktop; don't kill process yet.
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
  sleep 3
  # Re-resolve: the launch-time address is long stale, and dispatching to a dead one silently no-ops.
  BP_ADDR=$(hyprctl clients -j | jq -r '.[] | select(.title == "Steam Big Picture Mode") | .address' | head -n1)
  if [ -n "$BP_ADDR" ]; then
    log "Restoring steam big picture to exclusive fullscreen ($BP_ADDR)..."
    hyprctl dispatch "hl.dsp.window.fullscreen({ action = \"set\", mode = \"fullscreen\", window = \"address:$BP_ADDR\" })" >/dev/null 2>&1
    sleep 1
    log "BP state: $(hyprctl clients -j | jq -r --arg a "$BP_ADDR" '.[] | select(.address==$a) | "fs=\(.fullscreen) fsClient=\(.fullscreenClient)"') $(hyprctl monitors -j | jq -r --arg m "$TARGET_MONITOR" '.[] | select(.name==$m) | "solitary=\(.solitary) solitaryBlockedBy=\((.solitaryBlockedBy // ["null"])|join(","))"')"
  else
    log "Big Picture window is gone; nothing to restore."
  fi
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