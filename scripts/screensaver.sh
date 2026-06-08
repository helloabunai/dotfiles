#!/bin/bash

# Configuration
TERMINAL="kitty"
CMD="unimatrix -a -b -s 95"
LOCK_CMD="hyprlock"
TOLERANCE=50
POLL_INTERVAL=0.2  # Even slower polling to reduce false positives
LOG_FILE="/home/alastairm/screensaver.log"

# Optimized cursor position functions - cache hyprctl output
get_cursor_pos() {
    local pos_json
    pos_json=$(hyprctl cursorpos -j) || return 1
    echo "$pos_json" | jq -r '.x,.y'
}

# Keyboard wake is handled implicitly: unimatrix exits on q/Space (and other
# specific keys -- not arbitrary keys). When the focused terminal's unimatrix
# exits, the terminal dies and the main loop's process-count check fires the
# lock. We can't read /dev/input/event* directly here because Hyprland's
# libinput holds keyboard devices with an exclusive grab.

# Logging function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $*" >> "$LOG_FILE"
}

# Set up signal traps for clean exit
trap EXIT INT TERM

case "$1" in
    "start")
        # Exit if already running
        if pgrep -x "$LOCK_CMD" > /dev/null; then exit 0; fi
        if pgrep -f "matrix_screensaver" > /dev/null; then exit 0; fi

        log "Starting matrix screensavers..."
        echo "Starting matrix screensavers..."

        # Improvement B: pass `fullscreen = true` directly to exec_cmd so the
        # spawned kitty windows come up fullscreen without the previous
        # sleep+toggle dance (which raced on focus). Monitor placement is
        # handled by class-specific windowrules in lua/windowrules.lua.
        hyprctl dispatch "hl.dsp.exec_cmd([[$TERMINAL --class matrix_screensaver_DP-1 -e bash -c '$CMD 2>>/home/alastairm/matrix_dp1.log || echo \"Exit code: \$?\" >> /home/alastairm/matrix_dp1.log']], { fullscreen = true })" &
        hyprctl dispatch "hl.dsp.exec_cmd([[$TERMINAL --class matrix_screensaver_DP-2 -e bash -c '$CMD 2>>/home/alastairm/matrix_dp2.log || echo \"Exit code: \$?\" >> /home/alastairm/matrix_dp2.log']], { fullscreen = true })" &


        # Poll for both terminals to come up (typically ~200-500ms) instead
        # of a fixed 2s sleep -- cuts the dead-time window before the wake
        # monitoring loop starts running. Bail after 3s as a worst-case.
        EXPECTED_COUNT=2
        for _ in $(seq 1 30); do
            [ "$(pgrep -fc "matrix_screensaver")" -ge "$EXPECTED_COUNT" ] && break
            sleep 0.1
        done

        # Count initial processes and get PIDs
        initial_count=$(pgrep -fc "matrix_screensaver")
        kitty_pids=$(pgrep -f "matrix_screensaver" | tr '\n' ' ')
        unimatrix_pids=$(pgrep -f "unimatrix" | tr '\n' ' ')
        log "Matrix screensavers launched, process count: $initial_count"
        log "Kitty PIDs: $kitty_pids"
        log "Unimatrix PIDs: $unimatrix_pids"
        # Capture cursor AFTER spawns settle. Hyprland warps the cursor when
        # a fullscreen window comes up; capturing pre-spawn (the earlier
        # "improvement A") made that warp register as user movement and fired
        # the lock immediately. Capturing post-warp absorbs it into the
        # baseline. The trade-off is that movement during the (~200-500ms)
        # spawn window isn't detected -- minor compared to the false-fire
        # this avoids.
        cursor_data=$(get_cursor_pos)
        start_x=$(echo "$cursor_data" | sed -n '1p')
        start_y=$(echo "$cursor_data" | sed -n '2p')
        log "Starting monitoring (cursor baseline post-spawn: $start_x,$start_y)"

        echo "Monitoring cursor movement (tolerance: $TOLERANCE px) and keyboard input..."

        # Mouse monitoring loop - runs indefinitely until movement detected
        while true; do
            # Check matrix terminal count EVERY iteration. unimatrix exits on
            # q/Space, so one terminal dropping below the expected spawn count
            # IS our keyboard wake signal (we can't read /dev/input/event*
            # directly because libinput holds the device with an exclusive
            # grab). EXPECTED_COUNT is hardcoded above to the number of spawns
            # so early keypresses during the startup window are caught too --
            # using a dynamic `initial_count` from pgrep would silently lower
            # the baseline when a terminal dies before stabilization.
            current_count=$(pgrep -fc "matrix_screensaver")
            if [ "$current_count" -lt "$EXPECTED_COUNT" ]; then
                log "Matrix terminal count below expected ($EXPECTED_COUNT, got $current_count), activating lock..."
                $LOCK_CMD --no-fade-in &
                sleep 0.3
                pkill -f "matrix_screensaver" 2>/dev/null
                pkill -f "unimatrix" 2>/dev/null
                exit 0
            fi


            # Get current cursor position
            cursor_data=$(get_cursor_pos)
            if [ $? -ne 0 ]; then
                sleep $POLL_INTERVAL
                continue
            fi
            
            curr_x=$(echo "$cursor_data" | sed -n '1p')
            curr_y=$(echo "$cursor_data" | sed -n '2p')
            
            # Calculate distance² (avoiding floating point)
            diff_x=$((curr_x - start_x))
            diff_y=$((curr_y - start_y))
            dist_sq=$(( (diff_x * diff_x) + (diff_y * diff_y) ))
            tol_sq=$((TOLERANCE * TOLERANCE))

            # Mouse moved beyond tolerance - activate lock immediately
            if [ "$dist_sq" -gt "$tol_sq" ]; then
                log "Mouse movement detected (distance²: $dist_sq > $tol_sq), activating lock..."
                echo "Mouse movement detected, activating lock..."

                # Launch hyprlock FIRST so its layer surface is mapped on top
                # before the matrix terminals die -- otherwise there's a brief
                # gap (~100-500ms hyprlock startup) where the desktop flashes.
                $LOCK_CMD --no-fade-in &
                sleep 0.3
                pkill -f "matrix_screensaver" 2>/dev/null
                pkill -f "unimatrix" 2>/dev/null
                exit 0
            fi
            
            sleep $POLL_INTERVAL
        done
        ;;
        
    "stop")
        log "Stop command received"
        echo "Stopping screensaver..."
        
        # Kill matrix screensavers
        pkill -f "matrix_screensaver" 2>/dev/null
        pkill -f "unimatrix" 2>/dev/null

        # Start lock if not already running
        if ! pgrep -x "$LOCK_CMD" > /dev/null; then
            log "Starting lock screen after stop"
            echo "Starting lock screen..."
            $LOCK_CMD --no-fade-in &
        fi
        ;;
        
    *)
        echo "Usage: $0 {start|stop}"
        echo "  start - Start matrix screensaver with mouse monitoring"
        echo "  stop  - Stop screensaver and activate lock"
        exit 1
        ;;
esac