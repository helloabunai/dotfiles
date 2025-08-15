#!/bin/bash

if ip addr show tun0 &>/dev/null; then
  echo ""
  echo "VPN is connected"
else
  echo ""
  echo "VPN is disconnected"
fi
