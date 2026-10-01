#!/usr/bin/env bash
# waybar image module: the current track's album cover as a small rounded square.
# Prints "<path>\n<tooltip>" (nothing when idle → module hidden). Covers are downloaded once
# and rounded with Pillow (GTK3 can't round images with CSS), cached per album URL.
# Refreshed by scripts/music.sh (SIGRTMIN+9 on track change) and a slow interval.
set -u
CACHE=${XDG_CACHE_HOME:-$HOME/.cache}/waybar-covers; mkdir -p "$CACHE"
url="" tip=""
if pgrep -x spotify_player >/dev/null && json=$(timeout 1 spotify_player get key playback 2>/dev/null) \
        && [[ $json == "{"* ]] && jq -e '.item' <<<"$json" >/dev/null 2>&1; then
    url=$(jq -r '.item.album.images[-1].url // .item.album.images[0].url // .item.images[0].url // ""' <<<"$json")
    tip=$(jq -r '"\(.item.album.name // "")"' <<<"$json")
else
    url=$(playerctl -p spotify_player,spotify,%any metadata mpris:artUrl 2>/dev/null)
    tip=$(playerctl -p spotify_player,spotify,%any metadata album 2>/dev/null)
fi
[[ -n $url ]] || exit 0
out="$CACHE/$(printf '%s' "$url" | md5sum | head -c16).png"
if [[ ! -s $out ]]; then
    src="$out.src"
    case $url in
        file://*) cp "${url#file://}" "$src" 2>/dev/null ;;
        http*)    curl -fsSL --max-time 5 -o "$src" "$url" ;;
    esac || exit 0
    python3 - "$src" "$out" <<'PY'
import sys
from PIL import Image, ImageDraw
im = Image.open(sys.argv[1]).convert("RGBA").resize((64, 64), Image.LANCZOS)   # 2x for scaled screens
mask = Image.new("L", (256, 256), 0)
ImageDraw.Draw(mask).rounded_rectangle((0, 0, 255, 255), radius=64, fill=255)  # smooth corners
im.putalpha(mask.resize((64, 64), Image.LANCZOS))
im.save(sys.argv[2])
PY
    rm -f "$src"
fi
[[ -s $out ]] && printf '%s\n%s\n' "$out" "$tip"
