function nee --description 'Emacs in IDE mode: the file or folder, treemacs and Claude Code'
    set -l target (path resolve -- (test (count $argv) -gt 0; and echo $argv[1]; or echo .))
    set target (string replace -a '\\' '\\\\' -- $target | string replace -a '"' '\\"')
    if test "$XDG_CURRENT_DESKTOP" = driftwm
        # driftwm doesn't honour a "maximized" frame: open it, size it (92% of the screen's
        # view, centred), then lay it out, so the layout gets its real widths
        set -l known (driftwm msg --json state | jq -c '[.Ok.State.windows[].id]')
        emacsclient -nc -a "" >/dev/null
        set -l win
        for i in (seq 40)
            set win (driftwm msg --json state | jq -r --argjson k "$known" \
                '[.Ok.State.windows[] | select(.app_id == "Emacs" and ((.id) as $i | $k | index($i) | not))][0].id // empty')
            test -n "$win"; and break
            sleep 0.1
        end
        if test -n "$win"
            set -l geo (driftwm msg --json state | jq -r '.Ok.State.outputs[] | select(.active) |
                "\((.size[0] * 0.92 / .zoom) | floor) \(((.size[1] - 56) * 0.92 / .zoom) | floor) \(.camera[0] | floor) \((.camera[1] - 28 / .zoom) | floor)"' | string split ' ')
            driftwm msg resize --id $win $geo[1] $geo[2] >/dev/null
            driftwm msg move --id $win $geo[3] $geo[4] >/dev/null
            sleep 0.3
        end
        emacsclient -n -e "(my/ide \"$target\")" >/dev/null &
    else
        emacsclient -nc -a "" -F '((fullscreen . maximized))' -e "(my/ide \"$target\")" >/dev/null &
    end
end
