#!/bin/bash

# Usage: ./streamclient deck || shield || mac
ENV_FILE="$HOME/.config/scripts/targetdevice"
SUNSHINE_DIR="$HOME/.config/sunshine"

restart_sunshine() {
  echo "Restarting Sunshine..."
  pkill -f sunshine
  sleep 1
  nohup sunshine >/dev/null 2>&1 &
}

update_sunshine_config() {
  local source_file="$1"
  local target_file="$SUNSHINE_DIR/sunshine.conf"

  if cmp -s "$source_file" "$target_file"; then
    echo "Sunshine config already matches $source_file — skipping copy/restart."
  else
    echo "Updating Sunshine config from $source_file..."
    cp "$source_file" "$target_file"
    restart_sunshine
  fi
}

case "$1" in
deck)
  # -- env vars for other scripts --
  echo "Exporting TARGET_CLIENT=deck..."
  echo 'export TARGET_CLIENT="deck"' >"$ENV_FILE"
  echo 'export TARGET_WKSPC="7"' >>"$ENV_FILE"
  # -- virtual monitor
  echo "Enabling monitor: HDMI-A-2 (Steam Deck)"
  hyprctl keyword monitor "HDMI-A-2,1280x800@90,7840x0,1"
  # -- sunshine config --
  update_sunshine_config "$SUNSHINE_DIR/sunshine-steamdeck.conf"
  ;;
shield)
  # -- env vars for other scripts --
  echo "Exporting TARGET_CLIENT=shield..."
  echo 'export TARGET_CLIENT="shield"' >"$ENV_FILE"
  echo 'export TARGET_WKSPC="6"' >>"$ENV_FILE"
  # -- virtual monitor --
  echo "Enabling monitor: HDMI-A-1 (Shield)"
  hyprctl keyword monitor "HDMI-A-1,3840x2160@120,4000x0,1.5,bitdepth,10,cm,hdr,vrr,1"
  # -- sunshine config --
  update_sunshine_config "$SUNSHINE_DIR/sunshine-shield.conf"
  ;;
mac)
  # -- env vars for other scripts --
  echo "Exporting TARGET_CLIENT=mac..."
  echo 'export TARGET_CLIENT="mac"' >"$ENV_FILE"
  echo 'export TARGET_WKSPC="4"' >>"$ENV_FILE"
  # -- sunshine config --
  echo "Enabling monitor: HDMI-A-1 (Mac)"
  hyprctl keyword monitor "HDMI-A-1,3840x2160@120,4000x0,1.5,bitdepth,10,cm,hdr"
  update_sunshine_config "$SUNSHINE_DIR/sunshine-steamdeck.conf"
  ;;
*)
  echo "Usage: $0 deck|shield|mac"
  exit 1
  ;;
esac

echo "Done :)"
