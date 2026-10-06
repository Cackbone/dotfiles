#!/usr/bin/env bash
# Virtual desktops for driftwm (it deliberately has one canvas and no workspaces).
#
# Every screen has its own canvas area (screen i around y = -i * 100000, see
# arrange-cameras.sh) and desktop N of it is around x = (N-1) * 100000: far enough apart that
# you never pan from one into another, so each is its own infinite canvas.
# Desktops are per screen like niri: commands act on the screen under the mouse, and every
# screen remembers where its camera was on each desktop. Send a window to another screen
# with Mod+Alt+arrows.
#
#   desktop.sh go N        switch this screen to desktop N (N = current → previous desktop)
#   desktop.sh back        previous desktop on this screen
#   desktop.sh send N      move the focused window to desktop N (same spot, you stay here)
#   desktop.sh overview    zoom out over the windows of this desktop; again to come back
#   desktop.sh status N    waybar: button for desktop N on $WAYBAR_OUTPUT_NAME (hidden when it's
#                          neither the current desktop nor holds windows; "solo" when it's the
#                          only one shown, else "grouped")
#   desktop.sh win N       waybar: icon of the Nth window of this screen's current desktop
#   desktop.sh wfocus N    focus that window and centre the screen on it
set -u
DX=100000                                  # desktops along x
DY=100000                                  # screens along y
LAYOUT=(DP-1 HDMI-A-2 eDP-1)               # screen i's area is around y = -i * DY
STATE_DIR=${XDG_RUNTIME_DIR:-/tmp}/driftwm-desktops
mkdir -p "$STATE_DIR"

state=$(driftwm msg --json state 2>/dev/null | jq -c '.Ok.State') || exit 1
[[ -n $state && $state != null ]] || exit 1

sidx() { local i; for i in "${!LAYOUT[@]}"; do [[ ${LAYOUT[$i]} == "$1" ]] && { echo "$i"; return; }; done; echo 0; }
out=$(jq -r '.outputs[] | select(.active) | .name' <<<"$state")
read -r cx cy <<<"$(jq -r '.camera | "\(.[0]) \(.[1])"' <<<"$state")"
f() { echo "$STATE_DIR/$1"; }                               # per-screen state files
get() { cat "$(f "$1")" 2>/dev/null || echo "$2"; }
desk_of_x() { awk -v x="$1" -v d=$DX 'BEGIN { printf "%d", int((x + d / 2) / d + (x + d / 2 < 0 ? -1 : 0)) + 1 }'; }
refresh_bar() { pkill -RTMIN+8 -x waybar 2>/dev/null; }

# point this screen's view at canvas point ($1, $2) with zoom $3. Camera first, wait until
# it has arrived, then the zoom: changing the zoom while the (animated) pan is in flight
# stops the pan halfway; and zooming pivots slightly off-centre, so once it has settled the
# camera goes exactly back
view() {
    local tx=$1 ty=$2 z=$3 i
    driftwm msg camera "$tx" "$ty" >/dev/null
    for i in $(seq 100); do
        driftwm msg --json camera | jq -e --argjson x "$tx" --argjson y "$ty" \
            '.Ok.Camera | ((.x - $x) | fabs) < 1 and ((.y - $y) | fabs) < 1' >/dev/null && break
        sleep 0.02
    done
    driftwm msg zoom "$z" >/dev/null
    for i in $(seq 100); do
        driftwm msg --json zoom | jq -e --argjson z "$z" '((.Ok.Zoom - $z) | fabs) < 0.001' >/dev/null && break
        sleep 0.02
    done
    driftwm msg camera "$tx" "$ty" >/dev/null
}

# the current desktop is wherever the screen's camera is (so taskbar clicks, Alt-Tab etc. stay in sync)
cur_of() { desk_of_x "$(jq -r --arg o "$1" '.outputs[] | select(.name == $o) | .camera[0]' <<<"$state")"; }

go() {
    local n=$1 cur rx ry
    cur=$(cur_of "$out")
    if (( n == cur )); then n=$(get "$out.prev" "$cur"); (( n == cur )) && return; fi
    # remember where this screen was on the desktop it leaves (relative to that desktop)
    echo "$(awk -v x="$cx" -v d=$(( (cur - 1) * DX )) 'BEGIN{print x - d}') $(awk -v y="$cy" -v d=$(( -$(sidx "$out") * DY )) 'BEGIN{print y - d}') $(jq -r '.outputs[] | select(.active) | .zoom' <<<"$state")" > "$(f "$out.cam$cur")"
    echo "$cur" > "$(f "$out.prev")"
    rm -f "$(f "$out.overview")"
    read -r rx ry rz <<<"$(get "$out.cam$n" "0 0 1")"
    local tx ty
    tx=$(awk -v r="$rx" -v d=$(( (n - 1) * DX )) 'BEGIN{printf "%d", r + d}')
    ty=$(awk -v r="$ry" -v d=$(( -$(sidx "$out") * DY )) 'BEGIN{printf "%d", r + d}')
    view "$tx" "$ty" "${rz:-1}"                             # each desktop keeps its own zoom
    refresh_bar
}

send() {
    local n=$1 cur x y
    read -r x y <<<"$(driftwm msg --json move | jq -r '.Ok.Position | "\(.x) \(.y)"' 2>/dev/null)" || return
    [[ -n ${x:-} && $x != null ]] || return
    cur=$(desk_of_x "$x")                 # the desktop the *window* is on, not the camera's
    (( n == cur )) && return
    driftwm msg move "$(awk -v x="$x" -v s=$(( (n - cur) * DX )) 'BEGIN{print x + s}')" "$y" >/dev/null
    refresh_bar
}

overview() {
    local ov cur lo hi box
    ov=$(f "$out.overview")
    if [[ -f $ov ]]; then                                   # second press: back to where we were
        read -r x y z < "$ov"; rm -f "$ov"
        view "$x" "$y" "$z"; return
    fi
    cur=$(cur_of "$out"); lo=$(( (cur - 1) * DX - DX / 2 )); hi=$(( (cur - 1) * DX + DX / 2 ))
    ylo=$(( -$(sidx "$out") * DY - DY / 2 )); yhi=$(( -$(sidx "$out") * DY + DY / 2 ))
    # bounding box of the windows of this screen's current desktop (frame centres, Y up)
    box=$(jq -r --argjson lo "$lo" --argjson hi "$hi" --argjson ylo "$ylo" --argjson yhi "$yhi" '
        [.windows[] | select(.position[0] >= $lo and .position[0] < $hi and .position[1] >= $ylo and .position[1] < $yhi)] as $w
        | if ($w | length) == 0 then empty else
          [ ($w | map(.position[0] - .size[0] / 2) | min), ($w | map(.position[0] + .size[0] / 2) | max),
            ($w | map(.position[1] - .size[1] / 2) | min), ($w | map(.position[1] + .size[1] / 2) | max) ]
          | map(tostring) | join(" ") end' <<<"$state")
    [[ -n $box ]] || return
    read -r x0 x1 y0 y1 <<<"$box"
    read -r ow oh <<<"$(jq -r '.outputs[] | select(.active) | .size | "\(.[0]) \(.[1])"' <<<"$state")"
    echo "$cx $cy $(jq -r '.zoom' <<<"$state")" > "$ov"
    view "$(awk -v a="$x0" -v b="$x1" 'BEGIN{printf "%.0f", (a + b) / 2}')" \
         "$(awk -v c="$y0" -v d="$y1" 'BEGIN{printf "%.0f", (c + d) / 2}')" \
         "$(awk -v a="$x0" -v b="$x1" -v c="$y0" -v d="$y1" -v w="$ow" -v h="$oh" \
            'BEGIN { p = 160; zx = (w - p) / (b - a); zy = (h - p) / (d - c); z = zx < zy ? zx : zy; print (z > 1 ? 1 : z) }')"
}

# grouping classes for button $1 of $2: "solo", or "grouped" plus "first"/"last" at the ends
grp() { if (( $2 <= 1 )); then echo '"solo"'; else
        echo "\"grouped\"$( (( $1 == 1 )) && echo ', "first"')$( (( $1 == $2 )) && echo ', "last"')"; fi; }

status() {
    local n=$1 o=${WAYBAR_OUTPUT_NAME:-$out} cur used k st shown=() pos=0
    cur=$(cur_of "$o")
    # the desktop buttons this screen shows: the current one + those holding windows
    for k in 1 2 3 4 5; do
        if (( k == cur )) || (( $(area_windows "$k" "$o" | jq 'length') > 0 )); then
            shown+=("$k"); (( k == n )) && pos=${#shown[@]}
        fi
    done
    if (( pos == 0 )); then echo '{"text": ""}'; return; fi          # empty text = module hidden
    used=$(area_windows "$n" "$o" | jq 'length')
    (( n == cur )) && st=active || st=occupied
    printf '{"text": "%s", "class": ["%s", %s], "tooltip": "desktop %s · %s window(s)"}\n' \
        "$n" "$st" "$(grp "$pos" "${#shown[@]}")" "$n" "$used"
}

# windows of desktop $1 on screen $2, ordered left to right (then top to bottom)
area_windows() {
    local n=$1 o=$2 lo hi ylo yhi
    lo=$(( (n - 1) * DX - DX / 2 )); hi=$(( (n - 1) * DX + DX / 2 ))
    ylo=$(( -$(sidx "$o") * DY - DY / 2 )); yhi=$(( -$(sidx "$o") * DY + DY / 2 ))
    jq -c --argjson lo "$lo" --argjson hi "$hi" --argjson ylo "$ylo" --argjson yhi "$yhi" \
        '[.windows[] | select((.is_widget | not) and .position[0] >= $lo and .position[0] < $hi
                              and .position[1] >= $ylo and .position[1] < $yhi)]
         | sort_by(.position[0], -.position[1])' <<<"$state"
}

icon() {   # Nerd Font glyph for an app_id
    case ${1,,} in
        kitty|*term*|alacritty|foot|wezterm) printf '\uf120' ;;
        yazi)                       printf '\uf07c' ;;
        firefox*|librewolf*)        printf '\uf269' ;;
        chromium*|*chrome*)         printf '\uf268' ;;
        discord*|vesktop*|webcord*) printf '\uf1ff' ;;
        spotify*)                   printf '\uf1bc' ;;
        emacs*)                     printf '\ue632' ;;
        thunar*|*nautilus*|*files*) printf '\uf07c' ;;
        code*|*vscod*|cursor*)      printf '\uf121' ;;
        steam*)                     printf '\uf1b6' ;;
        gimp*)                      printf '\uf338' ;;
        *telegram*)                 printf '\uf2c6' ;;
        element*|*matrix*|*iamb*)   printf '\uf086' ;;
        *pavucontrol*)              printf '\uf028' ;;
        *)                          printf '\uf2d0' ;;
    esac
}

win() {
    local i=$1 o=${WAYBAR_OUTPUT_NAME:-$out} ws n w
    ws=$(area_windows "$(cur_of "$o")" "$o"); n=$(jq 'length' <<<"$ws")
    w=$(jq -c --argjson i "$i" '.[$i - 1] // empty' <<<"$ws")
    if [[ -z $w ]]; then echo '{"text": ""}'; return; fi              # no window: slot hidden
    jq -c --arg icon "$(icon "$(jq -r '.app_id' <<<"$w")")" --argjson grp "[$(grp "$i" "$n")]" \
        '{text: $icon, class: ([(if .is_focused then "focused" else "idle" end)] + $grp), tooltip: (.app_id + " · " + .title)}' <<<"$w"
}

wfocus() {
    local id
    id=$(area_windows "$(cur_of "$out")" "$out" | jq -r --argjson i "$1" '.[$i - 1].id // empty')
    [[ -n $id ]] || return
    ~/.config/driftwm/nav.py focus "$id"       # focus + centre, keeping the zoom
}

case ${1:-} in
    go)       go "$2" ;;
    back)     go "$(get "$out.prev" "$(cur_of "$out")")" ;;
    send)     send "$2" ;;
    overview) overview ;;
    status)   status "$2" ;;
    win)      win "$2" ;;
    wfocus)   wfocus "$2" ;;
    *)        sed -n '2,15p' "$0"; exit 1 ;;
esac
