# fastfetch sized to the window (each run; an image already on screen can't follow a resize):
#   wide   — portrait beside the info, shrinking with the width (38 → 20 columns);
#   medium — portrait on top, as wide as fits and short enough that nothing scrolls off;
#   narrow — no portrait. Long lines are cut instead of wrapped.
# The info needs ~75 columns (69 for the longest line + padding) and ~17 rows.
function fastfetch --wraps fastfetch --description 'fastfetch, laid out for the window size'
    set -g __fastfetch_live (count $argv)                  # redraw on resize (only plain runs)
    # ask the terminal itself: $COLUMNS/$LINES can be stale (non-interactive shells, mid-resize)
    set -l size (string split ' ' -- (stty size </dev/tty 2>/dev/null))
    set -l rows $size[1]
    set -l cols $size[2]
    test -n "$cols"; or set cols $COLUMNS
    test -n "$rows"; or set rows $LINES
    if not set -q KITTY_WINDOW_ID; or test $cols -lt 40
        command fastfetch --logo none --disable-linewrap true $argv
        return
    end
    # cell aspect (pixel width / pixel height of one character cell), for image heights in rows
    set -l cell 0.45
    set -l px (kitten icat --print-window-size 2>/dev/null | string split x)
    if test (count $px) -eq 2
        set cell (math "($px[1] / $cols) / ($px[2] / $rows)")
    end
    set -l ratio (math "$cell * 1085 / 1200")             # rows per column of the portrait
    set -l side (math --scale 0 "min(38, $cols - 75)")
    if test $side -ge 20
        command fastfetch --logo-width $side --disable-linewrap true $argv
    else
        # on top: as wide as the window allows, as tall as the free rows allow
        set -l w (math --scale 0 "min(38, $cols - 6, ($rows - 22) / $ratio)")
        if test $w -lt 12
            command fastfetch --logo none --disable-linewrap true $argv
        else
            set -l h (math --scale 0 "round($w * $ratio)")
            command fastfetch --logo-position top --logo-width $w --logo-height $h --disable-linewrap true $argv
        end
    end
end
