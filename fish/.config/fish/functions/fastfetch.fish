# fastfetch sized to the window (each run; an image already on screen can't follow a resize):
#   wide   — portrait beside the info, shrinking with the width (38 → 20 columns);
#   medium — portrait on top, as wide as fits and short enough that nothing scrolls off;
#   narrow — no portrait. Long lines are cut instead of wrapped.
# The info needs ~75 columns (69 for the longest line + padding) and 19 rows.
#
# Watch mode (--dynamic-interval / -w / --watch): each refresh fastfetch rewrites the text
# from the top but draws the portrait only once. So the portrait sits beside the text (on
# top, the text gets rewritten over it), and everything ends above the last row: otherwise
# each refresh scrolls the screen, the portrait drifts up and away and the text gets mangled.
# In a short window the least useful lines go first (down to title, OS, uptime, CPU, memory
# and disk), and the portrait gets as tall as the window allows.
function fastfetch --wraps fastfetch --description 'fastfetch, laid out for the window size'
    set -g __fastfetch_live (count $argv)                  # redraw on resize (only plain runs)
    # ask the terminal itself: $COLUMNS/$LINES can be stale (non-interactive shells, mid-resize)
    set -l size (string split ' ' -- (stty size </dev/tty 2>/dev/null))
    set -l rows $size[1]
    set -l cols $size[2]
    test -n "$cols"; or set cols $COLUMNS
    test -n "$rows"; or set rows $LINES
    set -l opts --disable-linewrap true
    set -l watch 0
    if string match -qr -- '^(--dynamic-interval|-w|--watch)' $argv
        set watch 1
        set -a opts --hide-cursor true                     # (fastfetch shows it again on exit)
        # the info's lines (gpu: one per GPU) and what to drop, in order, until it fits
        set -l lines 19
        set -l drop
        for m in break:2 colors:1 separator:1 display:1 terminal:1 wm:1 shell:1 packages:1 gpu:2 host:1 kernel:1
            test $lines -lt $rows; and break
            set -l kv (string split : -- $m)
            set -a drop $kv[1]
            set lines (math $lines - $kv[2])
        end
        test (count $drop) -gt 0; and set -a opts --structure-disabled (string join : -- $drop)
    end
    if not set -q KITTY_WINDOW_ID; or test $cols -lt 40
        command fastfetch --logo none $opts $argv
        return
    end
    # cell aspect (pixel width / pixel height of one character cell), for image heights in rows
    set -l cell 0.45
    set -l px (kitten icat --print-window-size 2>/dev/null | string split x)
    if test (count $px) -eq 2
        set cell (math "($px[1] / $cols) / ($px[2] / $rows)")
    end
    set -l ratio (math "$cell * 1085 / 1200")             # rows per column of the portrait
    if test $watch -eq 1
        # beside the text only. fastfetch pads its output to the portrait: padding row + height
        # + 1, which must end above the last row
        set -l side (math --scale 0 "min(38, $cols - 75, floor(($rows - 3) / $ratio))")
        if test $side -ge 12
            command fastfetch --logo-width $side $opts $argv
        else
            command fastfetch --logo none $opts $argv
        end
        return
    end
    set -l side (math --scale 0 "min(38, $cols - 75)")
    if test $side -ge 20
        command fastfetch --logo-width $side $opts $argv
    else
        # on top: as wide as the window allows, as tall as the free rows allow
        set -l w (math --scale 0 "min(38, $cols - 6, ($rows - 22) / $ratio)")
        if test $w -lt 12
            command fastfetch --logo none $opts $argv
        else
            set -l h (math --scale 0 "round($w * $ratio)")
            command fastfetch --logo-position top --logo-width $w --logo-height $h $opts $argv
        end
    end
end
