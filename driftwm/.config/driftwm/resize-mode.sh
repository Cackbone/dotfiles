#!/usr/bin/env bash
# i3-style resize mode for driftwm (which has no keybinding modes): Mod+R.
#
# Remembers the focused window, then opens a small pinned "RESIZE" badge (kitty, see the
# window rule in config.toml) that takes the keyboard:
#   ←/→ (j/m)  narrower / wider    ↑/↓ (l/k)  shorter / taller    (i3 keys, AZERTY jklm)
#   Shift+arrow: fine 10px steps   Esc / Enter / Mod+R: leave (focus returns to the window)
# Like i3, the top-left corner stays put: the right and bottom edges move.
set -u
STEP=40 FINE=10 MIN=120

if [[ ${1:-} != --badge ]]; then
    id=$(driftwm msg --json focus | jq -r '.Ok.Focused.id // empty')
    [[ -n $id ]] || exit 0
    pkill -f '^kitty --class driftwm-resize' && exit 0     # Mod+R again while open: leave
    exec kitty --class driftwm-resize --title RESIZE \
        -o font_size=11 -o background='#e040fb' -o foreground='#131244' -o cursor='#e040fb' \
        -o window_padding_width='6 12' -o cursor_trail=0 -o remember_window_size=no \
        "$0" --badge "$id"
fi

id=$2
# keep our own running size and the fixed top-left corner: re-reading the size after each
# step races the app's resize (held keys would lose steps)
read -r W H <<<"$(driftwm msg --json resize --id "$id" | jq -r '.Ok.Size | "\(.width) \(.height)"')"
read -r X Y <<<"$(driftwm msg --json move --id "$id" | jq -r '.Ok.Position | "\(.x) \(.y)"')"
LEFT=$(( X - W / 2 )) TOP=$(( Y + H / 2 ))                  # canvas is Y up: top = centre + h/2
grow() {   # grow <dw> <dh>: right and bottom edges move, top-left corner stays
    W=$(( W + $1 < MIN ? MIN : W + $1 )); H=$(( H + $2 < MIN ? MIN : H + $2 ))
    driftwm msg resize --id "$id" "$W" "$H" >/dev/null
    # wait until the app has applied the size (moving earlier lets the late resize, which keeps
    # the centre, shift the window), then put the top-left corner back
    local i
    for i in $(seq 20); do
        [[ $(driftwm msg --json resize --id "$id" | jq -r '.Ok.Size | "\(.width) \(.height)"') == "$W $H" ]] && break
        sleep 0.02
    done
    driftwm msg move --id "$id" $(( LEFT + W / 2 )) $(( TOP - H / 2 )) >/dev/null
}

# keep the keyboard: with focus-follows-mouse, moving the mouse over a window (btop…) would
# take focus and with it the keys (Esc!). While the badge is open, take focus back at once.
badge=$(driftwm msg --json state | jq -r '[.Ok.State.pinned[]?, .Ok.State.windows[]] | map(select(.app_id == "driftwm-resize")) | .[0].id // empty')
if [[ -n $badge ]]; then
    ( while :; do
          f=$(driftwm msg --json focus | jq -r '.Ok.Focused.id // empty')
          [[ -n $f && $f != "$badge" ]] && driftwm msg focus --id "$badge" >/dev/null
          sleep 0.1
      done ) &
    keeper=$!
fi
# however the mode ends (Esc/Enter, or Mod+R again closing the badge): stop the keeper and give
# focus back to the resized window
leave() { [[ -n ${keeper:-} ]] && kill "$keeper" 2>/dev/null; driftwm msg focus --id "$id" >/dev/null; }
trap leave EXIT
trap 'exit 0' HUP TERM INT

printf '\e[?25l'                                            # no cursor in the badge
printf ' \e[1mRESIZE\e[0m  ←→ width · ↑↓ height · shift fine · esc'
while IFS= read -rsn1 k; do
    if [[ $k == $'\e' ]]; then                 # escape sequence: ESC [ … final letter, read
        IFS= read -rsn1 -t 0.02 c || c=''      # exactly one (held keys arrive in bursts)
        if [[ $c == '[' ]]; then
            k+=$c
            while IFS= read -rsn1 -t 0.02 c; do k+=$c; [[ $c == [A-Za-z~] ]] && break; done
        fi
    fi
    case $k in
        $'\e[D'|j) grow -$STEP 0 ;;   $'\e[1;2D') grow -$FINE 0 ;;
        $'\e[C'|m) grow  $STEP 0 ;;   $'\e[1;2C') grow  $FINE 0 ;;
        $'\e[A'|l) grow 0 -$STEP ;;   $'\e[1;2A') grow 0 -$FINE ;;
        $'\e[B'|k) grow 0  $STEP ;;   $'\e[1;2B') grow 0  $FINE ;;
        $'\e'|''|q) break ;;                                # Esc, Enter, q
    esac
done
