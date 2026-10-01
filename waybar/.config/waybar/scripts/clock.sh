#!/usr/bin/env bash
# LCD clock for waybar: HH:MM with a blinking colon (dimmed, not removed, so digits don't shift).
# Ticks on the second boundary so the blink stays in sync with real seconds.
# waybar forwards its refresh signals (RTMIN+8 desktops, RTMIN+9 cover) to running
# scripts, and their default action is to terminate: ignore them
trap '' RTMIN+8 RTMIN+9
while :; do
    if (( 10#$(date +%S) % 2 )); then colon="<span alpha='18%'>:</span>"; else colon=":"; fi
    printf '%s%s%s\n' "$(date +%H)" "$colon" "$(date +%M)"
    ns=$(date +%N); sleep "0.$(printf '%09d' $((1000000000 - 10#$ns)) | cut -c1-3)"
done
