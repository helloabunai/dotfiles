#!/bin/bash

# Configuration
TERMINAL="kitty"
CMD="unimatrix -a -b -s 95" 
LOCK_CMD="hyprlock"
TOLERANCE=100
POLL_INTERVAL=0.2  # Even slower polling to reduce false positives
LOG_FILE="/home/alastairm/screensaver.log"

# Optimized cursor position functions - cache hyprctl output
get_cursor_pos() {
    local pos_json
    pos_json=$(hyprctl cursorpos -j) || return 1
    echo "$pos_json" | jq -r '.x,.y'
}

# Hardcoded keyboard device (PFU Limited HHKB-Hybrid)
KEYBOARD_DEVICE="/dev/input/event2"

# Check for keyboard input (non-blocking)
has_keyboard_input() {
    # Use timeout with dd for non-blocking check of input events
    if timeout 0.001 dd if="$KEYBOARD_DEVICE" bs=1 count=1 of=/dev/null 2>/dev/null; then
        return 0  # Keyboard input detected
    fi
    return 1  # No input detected
}

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

        # Launch matrix screensavers with debug output
        log "Starting matrix screensavers..."
        echo "Starting matrix screensavers..."
        
        # Launch with error logging
        hyprctl dispatch exec "$TERMINAL --class matrix_screensaver_DP-1 -e bash -c '$CMD 2>>/home/alastairm/matrix_dp1.log || echo \"Exit code: \$?\" >> /home/alastairm/matrix_dp1.log'" &
        sleep 0.4 
        hyprctl dispatch fullscreen

        hyprctl dispatch exec "$TERMINAL --class matrix_screensaver_DP-2 -e bash -c '$CMD 2>>/home/alastairm/matrix_dp2.log || echo \"Exit code: \$?\" >> /home/alastairm/matrix_dp2.log'" &
        sleep 0.4  
        hyprctl dispatch fullscreen
        
        sleep 2  # Give terminals more time to stabilize and go fullscreen
        
        # Count initial processes and get PIDs
        initial_count=$(pgrep -fc "matrix_screensaver")
        kitty_pids=$(pgrep -f "matrix_screensaver" | tr '\n' ' ')
        unimatrix_pids=$(pgrep -f "unimatrix" | tr '\n' ' ')
        log "Matrix screensavers launched, process count: $initial_count"
        log "Kitty PIDs: $kitty_pids"
        log "Unimatrix PIDs: $unimatrix_pids"
        log "Starting monitoring"

        # Initialize keyboard monitoring
        if [ -r "$KEYBOARD_DEVICE" ]; then
            log "Monitoring keyboard device: $KEYBOARD_DEVICE"
            echo "Keyboard monitoring enabled"
            KEYBOARD_ENABLED=true
        else
            log "WARNING: Cannot read keyboard device $KEYBOARD_DEVICE (check permissions)"
            echo "WARNING: Keyboard monitoring disabled (no read access)"
            KEYBOARD_ENABLED=false
        fi

        # Get initial cursor position with error handling
        cursor_data=$(get_cursor_pos)        
        start_x=$(echo "$cursor_data" | sed -n '1p')
        start_y=$(echo "$cursor_data" | sed -n '2p')
        
        echo "Monitoring cursor movement (tolerance: $TOLERANCE px) and keyboard input..."
        loop_count=0
        last_process_check=0

        # Mouse monitoring loop - runs indefinitely until movement detected
        while true; do
            # Check if matrix terminals are still running every 10 iterations
            if [ $((loop_count % 10)) -eq 0 ]; then
                current_count=$(pgrep -fc "matrix_screensaver")
                unimatrix_count=$(pgrep -c "unimatrix")
                
                if [ "$current_count" -ne "$initial_count" ]; then
                    log "WARNING: Process count changed from $initial_count to $current_count"
                    log "Kitty processes: $(pgrep -fa matrix_screensaver)"
                    log "Unimatrix processes: $(pgrep -fa unimatrix)"
                fi
                if [ "$current_count" -eq 0 ]; then
                    log "CRITICAL: All kitty terminals died! Unimatrix count: $unimatrix_count"
                    exec $LOCK_CMD --no-fade-in
                    exit 0
                fi
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
                
                # Kill matrix screensavers immediately
                pkill -f "matrix_screensaver" 2>/dev/null
                
                # Start lock command directly for fastest response
                exec $LOCK_CMD --no-fade-in
                exit 0
            fi
            
            # Check for keyboard input if devices available
            if [ "$KEYBOARD_ENABLED" = true ] && has_keyboard_input; then
                log "Keyboard input detected, activating lock..."
                echo "Keyboard input detected, activating lock..."
                
                # Kill matrix screensavers immediately
                pkill -f "matrix_screensaver" 2>/dev/null
                
                # Start lock command directly for fastest response
                exec $LOCK_CMD --no-fade-in
                exit 0
            fi
            
            ((loop_count++))
            sleep $POLL_INTERVAL
        done
        ;;
        
    "stop")
        log "Stop command received"
        echo "Stopping screensaver..."
        
        # Kill matrix screensavers
        pkill -f "matrix_screensaver" 2>/dev/null
        
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