# right side, dim: how long the last command took (only when ≥ 3 s), then the time
function fish_right_prompt
    set_color 4a4a8a
    if test -n "$CMD_DURATION"; and test $CMD_DURATION -ge 3000
        printf '%ss · ' (math --scale 1 $CMD_DURATION / 1000)
    end
    date +%H:%M
    set_color normal
end
