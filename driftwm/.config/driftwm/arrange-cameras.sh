#!/usr/bin/env bash
# Each screen is its own canvas: screen i lives in the canvas area around y = -i * 100000
# (desktops go along x, see desktop.sh), so screens can never show each other's windows.
# Put every screen's camera on its own area (desktop 1). `msg camera` acts on the screen
# under the mouse, so walk the mouse across the screens. Runs at login.
set -u
LAYOUT=(DP-1 HDMI-A-2 eDP-1)      # physical order, left to right = area index 0, 1, 2
DY=100000
m() { driftwm msg "$@" >/dev/null; }
sleep 1                            # let outputs come up after login
for _ in "${LAYOUT[@]}"; do m action send-cursor-to-output left; done
for i in "${!LAYOUT[@]}"; do
    m camera 0 $(( -i * DY ))
    (( i < ${#LAYOUT[@]} - 1 )) && m action send-cursor-to-output right
done
m action send-cursor-to-output left   # finish on the middle screen
