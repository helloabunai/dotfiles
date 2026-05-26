#!/bin/bash
#
# streamclient.sh -- compat wrapper around set_stream_display.sh
#
# Old usage (deck|shield|mac) used to enable a monitor and restart Sunshine on
# the fly. That broke Sunshine's KMS connector cache and lost HDR capture on
# the TV (project_gotchas.md::gotcha-sunshine-kms-boot-race). The new model is
# "pick a stream display, then reboot":
#   set_stream_display shield   # HDMI-A-1 (KMS, HDR -- Shield/TV/Mac)
#   set_stream_display deck     # HDMI-A-2 (wlr, virtual -- Steam Deck)
# At connect time, sunshine_connect.sh enables the matching monitor and spawns
# Big Picture there.

case "$1" in
shield|mac) exec "$HOME/scripts/set_stream_display.sh" shield ;;
deck)       exec "$HOME/scripts/set_stream_display.sh" deck ;;
*)
  echo "Usage: $0 shield|deck|mac (deprecated -- prefer set_stream_display.sh)"
  exit 1
  ;;
esac