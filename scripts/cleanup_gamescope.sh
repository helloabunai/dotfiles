# --- Kill any zombie gamescope processes (nvidia issue?) ---
GAMESCOPE_PIDS=$(pgrep -f "gamescope")
if [ -n "$GAMESCOPE_PIDS" ]; then
    echo "Killing leftover gamescope processes: $GAMESCOPE_PIDS"
    kill -9 $GAMESCOPE_PIDS
else
    echo "No leftover gamescope processes found."
fi