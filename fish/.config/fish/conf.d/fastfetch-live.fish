# Live fastfetch: while its output is the last thing on screen, redraw it at the new size
# whenever the window is resized (an image already drawn can't resize itself). Running any
# other command ends this, so nothing you're working on ever gets cleared.
status is-interactive; or return

function __fastfetch_live_resize --on-signal WINCH
    test "$__fastfetch_live" = 0; or return                # only a plain `fastfetch`, still on top
    set -g __fastfetch_resize_at (date +%s%N)
    # resizes come in bursts while dragging: redraw once it settles for 150 ms
    set -l mine $__fastfetch_resize_at
    sleep 0.15
    test "$mine" = "$__fastfetch_resize_at"; or return
    printf '\e[H\e[2J\e[3J'                                # clear, including old image rows
    fastfetch
    commandline -f repaint
end

function __fastfetch_live_stop --on-event fish_preexec
    set -e __fastfetch_live
end
