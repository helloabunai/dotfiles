#!/bin/bash
#
# set_stream_display shield|deck|mac
#
# Picks which monitor Sunshine will target at boot. Writes the choice to
# ~/.config/scripts/streamdisplay and copies the matching sunshine.conf into
# place. Reboot to apply: Sunshine's KMS connector index is cached for the
# process lifetime, so switching at runtime is unreliable -- see
# project_gotchas.md::gotcha-sunshine-kms-boot-race.

STATE_FILE="$HOME/.config/scripts/streamdisplay"
SUNSHINE_DIR="$HOME/.config/sunshine"

case "$1" in
shield)
  OUTPUT="HDMI-A-1"
  cp "$SUNSHINE_DIR/sunshine-shield.conf" "$SUNSHINE_DIR/sunshine.conf"
  ;;
deck)
  OUTPUT="HDMI-A-2"
  cp "$SUNSHINE_DIR/sunshine-steamdeck.conf" "$SUNSHINE_DIR/sunshine.conf"
  ;;
mac)
  OUTPUT="DP-1"
  cp "$SUNSHINE_DIR/sunshine-mac.conf" "$SUNSHINE_DIR/sunshine.conf"
  ;;
machdr)
  OUTPUT="HDMI-A-1"
  cp "$SUNSHINE_DIR/sunshine-shield.conf" "$SUNSHINE_DIR/sunshine.conf"
  ;;
*)
  echo "Usage: $0 shield|deck|mac|machdr"
  echo "  shield -> HDMI-A-1 (KMS, HDR -- Shield/TV)"
  echo "  deck   -> HDMI-A-2 (wlr, virtual -- Steam Deck)"
  echo "  mac    -> DP-1     (KMS index 1 -- remote desktop, no monitor prep)"
  echo "  machdr -> HDMI-A-1 (KMS, HDR -- Mac via virtual HDR display, like shield)"
  exit 1
  ;;
esac

echo "$OUTPUT" >"$STATE_FILE"
echo "STREAM_DISPLAY=$OUTPUT ($1). Reboot to apply."