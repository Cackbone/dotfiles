#!/usr/bin/env bash
# waybar: a small monochrome live equalizer (cava, 4 bars) while music plays, the pause icon
# when paused, nothing when idle; while it plays on another device (phone…), that device's
# icon instead (there's nothing to hear here). One JSON line per frame (~25/s). Play/pause comes from
# spotify_player directly when it runs (its MPRIS state lags 2-3 s), else MPRIS.
# waybar forwards its refresh signals (RTMIN+8 desktops, RTMIN+9 cover) to running
# scripts, and their default action is to terminate: ignore them
trap '' RTMIN+8 RTMIN+9
set -u
PLAYERS=spotify_player,spotify,%any
BLOCKS=(▁ ▂ ▃ ▄ ▅ ▆ ▇ █)
PAUSE=$''
CFG=${XDG_RUNTIME_DIR:-/tmp}/waybar-eq-cava.cfg
cat > "$CFG" <<'CFG'
[general]
bars = 4
framerate = 25
[input]
method = pulse
source = auto
[output]
method = raw
raw_target = /dev/stdout
data_format = ascii
ascii_max_range = 7
bar_delimiter = 59
frame_delimiter = 10
[smoothing]
noise_reduction = 55
CFG
coproc CAVA { exec cava -p "$CFG" 2>/dev/null; }
trap '[[ -n ${CAVA_PID:-} ]] && kill "$CAVA_PID" 2>/dev/null' EXIT
trap 'exit 0' TERM HUP INT                 # so the EXIT trap (stop cava) runs when waybar quits

nowms() { local t=$EPOCHREALTIME; echo $(( ${t%.*} * 1000 + 10#${t#*.} / 1000 )); }
status="" remote="" last_poll=0 eq="0;0;0;0;" loud=0 last=""
poll() {
    local json
    remote=""
    local st dn
    if json=$("$HOME/.local/bin/spotify-state") && [[ $json == "{"* ]] \
            && IFS=$'\t' read -r st dn < <(jq -r 'select(.item) | [(if .is_playing then "Playing" else "Paused" end),
                                                 (.device.name // "")] | join("\t")' <<<"$json") && [[ -n $st ]]; then
        status=$st                                # one query; the device's icon only when it isn't this one
        [[ -n $dn && $dn != spotify-player ]] && remote=$("$HOME/.local/bin/spotify-state" --device | cut -f1)
    else
        status=$(playerctl -p "$PLAYERS" status 2>/dev/null)
    fi
}
while :; do
    n=$(nowms)
    (( n - last_poll >= 1000 )) && { poll; last_poll=$n; }
    # (cava gone — PulseAudio restarted…: no levels, the fake bounce stands in)
    [[ -n ${CAVA[0]:-} ]] && while IFS= read -r -t 0.001 -u "${CAVA[0]}" line; do eq=$line; done
    case $status in
        Playing)
            if [[ -n $remote ]]; then
                out="{\"text\": \"$remote\", \"class\": \"remote\"}"
                [[ $out != "$last" ]] && { printf '%s\n' "$out"; last=$out; }
                sleep 0.04; continue
            fi
            IFS=';' read -ra v <<<"$eq"
            (( ${v[0]:-0} + ${v[1]:-0} + ${v[2]:-0} + ${v[3]:-0} > 0 )) && loud=$n
            if (( n - loud > 1500 )); then           # silent output (muted…): soft fake bounce
                t=$(( n / 120 )); fake=(2 5 3 6 4 7 3 5 2 4 6 3)
                v=("${fake[t % 12]}" "${fake[(t + 4) % 12]}" "${fake[(t + 7) % 12]}" "${fake[(t + 2) % 12]}")
            fi
            bars="${BLOCKS[${v[0]:-0}]}${BLOCKS[${v[1]:-0}]}${BLOCKS[${v[2]:-0}]}${BLOCKS[${v[3]:-0}]}"
            # spacing between the bars so they read as four bars, not one block
            out="{\"text\": \"<span letter_spacing='2400'>$bars</span>\", \"class\": \"playing\"}" ;;
        Paused)  out="{\"text\": \"$PAUSE\", \"class\": \"paused\"}" ;;
        *)       out='{"text": ""}' ;;
    esac
    [[ $out != "$last" ]] && { printf '%s\n' "$out"; last=$out; }
    sleep 0.04
done
