#!/usr/bin/env bash
# waybar music text: title (bold) over artist (dim), left-aligned together; nothing when idle.
# Prints a JSON line when it changes. On a new track it signals the cover image (RTMIN+9).
# The equalizer / pause icon is a separate module (scripts/eq.sh) so it centres vertically.
# waybar forwards its refresh signals (RTMIN+8 desktops, RTMIN+9 cover) to running
# scripts, and their default action is to terminate: ignore them
trap '' RTMIN+8 RTMIN+9
set -u
PLAYERS=spotify_player,spotify,%any
TITLE_LEN=28 ARTIST_LEN=30
esc() { local s=${1//&/&amp;}; s=${s//</&lt;}; s=${s//>/&gt;}; REPLY=$s; }   # pango-safe
cut_to() { local s=$1; (( ${#s} > $2 )) && s="${s:0:$2-1}…"; REPLY=$s; }
title="" last=""
while :; do
    s="" t="" a=""
    if pgrep -x spotify_player >/dev/null && json=$(timeout 1 spotify_player get key playback 2>/dev/null) \
            && [[ $json == "{"* ]] && jq -e '.item' <<<"$json" >/dev/null 2>&1; then
        IFS=$'\t' read -r s t a < <(jq -r '[(if .is_playing then "Playing" else "Paused" end),
            .item.name, ([.item.artists[]?.name] | join(", "))] | join("\t")' <<<"$json")
    else
        IFS=$'\t' read -r s t a < <(playerctl -p "$PLAYERS" metadata --format $'{{status}}\t{{title}}\t{{artist}}' 2>/dev/null)
    fi
    [[ ${t:-} != "$title" ]] && { title=${t:-}; pkill -RTMIN+9 -x waybar; }   # new track: refresh cover
    if [[ -z ${s:-} || $s == Stopped ]]; then
        out='{"text": ""}'
    else
        cut_to "${t:-}" $TITLE_LEN; esc "$REPLY"; et=$REPLY
        cut_to "${a:-}" $ARTIST_LEN; esc "$REPLY"; ea=$REPLY
        esc "${a:-} - ${t:-}"; tip=$REPLY
        cls=playing; [[ $s == Playing ]] || cls=paused
        out=$(jq -cn --arg text "<b>$et</b>"$'\n'"<span size='smaller' foreground='#8b8bc7'>$ea</span>" \
                     --arg cls "$cls" --arg tip "$tip" '{text: $text, class: $cls, tooltip: $tip}')
    fi
    [[ $out != "$last" ]] && { printf '%s\n' "$out"; last=$out; }
    sleep 0.5
done
