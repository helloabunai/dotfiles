#!/bin/bash
#
# set_stream_display shield|deck|mac|machdr|mirror
#
# Switches which monitor Sunshine captures, reliably and without a reboot.
#
# Rather than relying on Sunshine's cached-at-boot KMS connector (a race that
# breaks when the target monitor isn't online at the moment Sunshine starts),
# this:
#   1. enables the target Hyprland monitor and waits for it to come online
#      (DP-1 is a physical monitor, always present -> nothing to enable)
#   2. records the choice and swaps in the matching sunshine.conf
#   3. stops the running Sunshine and waits for it to exit
#   4. waits a few seconds for the display to settle
#   5. relaunches Sunshine, which now initialises against a display that
#      already exists and with the correct config.

STATE_FILE="$HOME/.config/scripts/streamdisplay"
SUNSHINE_DIR="$HOME/.config/sunshine"
SUNSHINE_BIN="$(command -v sunshine)"

# enable_monitor <name> <hl.monitor arg string>
# Enables a Hyprland output and waits (~6s) for it to actually be online.
enable_monitor() {
  local name="$1" args="$2" tries=30
  echo "Enabling monitor: $name"
  hyprctl eval "hl.monitor({ $args })"
  while [ $tries -gt 0 ]; do
    if hyprctl -j monitors all | jq -e --arg n "$name" \
        '.[] | select(.name == $n and .disabled == false and .width > 0)' >/dev/null 2>&1; then
      echo "  $name is online."
      return 0
    fi
    sleep 0.2
    tries=$((tries - 1))
  done
  echo "  WARNING: $name did not come online in time; continuing anyway."
  return 1
}

case "$1" in
shield | machdr)
  OUTPUT="HDMI-A-1"
  CONF="sunshine-shield.conf"
  enable_monitor "HDMI-A-1" 'output = "HDMI-A-1", mode = "3840x2160@120", position = "4000x0", scale = 1.5, bitdepth = 10, cm = "hdr", vrr = 1, disabled = false'
  ;;
deck)
  OUTPUT="HDMI-A-2"
  CONF="sunshine-steamdeck.conf"
  enable_monitor "HDMI-A-2" 'output = "HDMI-A-2", mode = "1280x800@90", position = "7840x0", scale = 1, vrr = 1, disabled = false'
  ;;
mac)
  OUTPUT="DP-1"
  CONF="sunshine-mac.conf"
  # DP-1 is a physical, always-on monitor: nothing to enable.
  ;;
mirror)
  OUTPUT="DP-1"
  CONF="sunshine-mirror.conf"
  # DP-1 is a physical, always-on monitor: nothing to enable.
  ;;
*)
  echo "Usage: $0 shield|deck|mac|machdr|mirror"
  echo "  shield -> HDMI-A-1 (KMS, HDR -- Shield/TV)"
  echo "  deck   -> HDMI-A-2 (wlr, virtual -- Steam Deck)"
  echo "  mac    -> DP-1     (wlr -- remote desktop, no monitor prep)"
  echo "  machdr -> HDMI-A-1 (KMS, HDR -- Mac via virtual HDR display, like shield)"
  echo "  mirror -> DP-1     (KMS, SDR -- mirror desktop monitor to the TV)"
  exit 1
  ;;
esac

# Record the choice (sunshine_connect.sh / sunshine_disconnect.sh read this).
echo "$OUTPUT" > "$STATE_FILE"

# Stop the running Sunshine so it can reinitialise against the new display/config.
echo "Stopping Sunshine..."
pkill -x sunshine 2>/dev/null
for _ in $(seq 1 25); do
  pgrep -x sunshine >/dev/null 2>&1 || break
  sleep 0.2
done

# Swap in the matching config.
cp "$SUNSHINE_DIR/$CONF" "$SUNSHINE_DIR/sunshine.conf"

# Let the display settle before Sunshine probes it.
sleep 5

# Relaunch Sunshine detached so it outlives this shell/terminal.
if [ -z "$SUNSHINE_BIN" ]; then
  echo "ERROR: sunshine binary not found on PATH."
  exit 1
fi
echo "Launching Sunshine (STREAM_DISPLAY=$OUTPUT, config=$CONF)..."
setsid "$SUNSHINE_BIN" >/dev/null 2>&1 < /dev/null &
disown 2>/dev/null

echo "STREAM_DISPLAY=$OUTPUT ($1). Sunshine restarted."
