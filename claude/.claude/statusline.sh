#!/usr/bin/env bash
# Claude Code status line — synthwave pills, same look as the waybar modules.
#  [ model ]  [ dir ]  [ branch ]  [ context meter ]
in=$(cat)
# hand the plan quotas Claude Code gives us to the clawd window (no extra API call there):
# one file per session — sessions can see different numbers, and clawd shows the highest
rl=$(jq -c '.rate_limits // empty' <<<"$in" 2>/dev/null)
sid=$(jq -r '.session_id // "default"' <<<"$in" 2>/dev/null); [[ $sid =~ ^[A-Za-z0-9_-]+$ ]] || sid=default
feed=${XDG_RUNTIME_DIR:-/tmp}/clawd-statusline; mkdir -p "$feed"
[[ -n $rl ]] && printf '{"at":%s,"rate_limits":%s}\n' "$(date +%s)" "$rl" > "$feed/$sid.json.$$" \
    && mv "$feed/$sid.json.$$" "$feed/$sid.json"
q() { jq -r "$1 // empty" <<<"$in"; }

fg() { printf '\e[38;2;%d;%d;%dm' "0x${1:1:2}" "0x${1:3:2}" "0x${1:5:2}"; }
bg() { printf '\e[48;2;%d;%d;%dm' "0x${1:1:2}" "0x${1:3:2}" "0x${1:5:2}"; }
rst=$'\e[0m'; bold=$'\e[1m'

# palette (README.md)
PILL=#1a1a6e TEXT=#e8e6ff DIM=#8b8bc7 MAG=#e040fb NAVY=#131244
ICE=#76e6f2 LIME=#69ff47 RED=#ff4f79 EMPTY=#3b2a78

L=$'' R=$''   # rounded pill caps (Nerd Font)

# pill <bg> <fg> <text>
pill() { printf '%s%s%s%s %s %s%s%s%s ' "$(fg "$1")" "$L" "$(bg "$1")" "$(fg "$2")" "$3" "$rst" "$(fg "$1")" "$R" "$rst"; }

model=$(q .model.display_name)
cwd=$(q .workspace.current_dir)
dir=${cwd/#$HOME/\~}
# keep the last two folders: ~/…/opensource/dotfiles
IFS=/ read -ra parts <<<"$dir"
(( ${#parts[@]} > 3 )) && dir="${parts[0]}/…/${parts[-2]}/${parts[-1]}"
pct=$(q .context_window.used_percentage); pct=${pct%.*}; pct=${pct:-0}

branch=$(git -C "$cwd" branch --show-current 2>/dev/null)
[[ -n $branch && -n $(git -C "$cwd" status --porcelain 2>/dev/null | head -1) ]] && branch+="*"

# meter <percent> <cells>: filled cells fade cyan → magenta (red past 80%), empty cells dim.
# Sets $M (the bar) and $PC (color for the percentage label).
meter() {
    local pct=$1 n=$2 i c r g b
    local filled=$(( (pct * n + 50) / 100 ))
    M=""
    for (( i = 0; i < n; i++ )); do
        if (( i < filled )); then
            if (( pct >= 80 )); then c=$RED; else
                r=$(( 0xe0 * i / (n - 1) )); g=$(( 0xbc + (0x40 - 0xbc) * i / (n - 1) )); b=$(( 0xd4 + (0xfb - 0xd4) * i / (n - 1) ))
                c=$(printf '#%02x%02x%02x' $r $g $b)
            fi
            M+="$(fg "$c")━"
        else
            M+="$(fg "$EMPTY")━"
        fi
    done
    (( pct >= 80 )) && PC=$RED || PC=$DIM
}

# meter_pill <label> <percent> <cells> [reset text]
meter_pill() {
    meter "$2" "$3"
    local extra=""
    [[ -n $4 ]] && extra=" $(fg "$DIM")↻ $4"
    pill "$PILL" "$DIM" "$1 $(bg "$PILL")${M}$(fg "$PC") ${2}%${extra}"
}

# plan quota (Pro/Max only): 5-hour session
q5=$(q .rate_limits.five_hour.used_percentage);  q5=${q5%.*}
r5=$(q .rate_limits.five_hour.resets_at)

# Inside Emacs (claude-code-ide, in an eat buffer): only the model pill here. The folder and
# branch are on screen already, and the context and session bars sit in the Claude window's
# mode line instead, from a file named after this Claude's process (Emacs knows each Claude
# buffer's process): $XDG_RUNTIME_DIR/claude-emacs/<pid>.json
if [[ -n ${INSIDE_EMACS:-} ]]; then
    p=$$ cpid=""
    for _ in 1 2 3 4 5 6; do                             # up to the claude process
        p=$(awk '{print $4}' "/proc/$p/stat" 2>/dev/null) || break
        (( p > 1 )) || break
        if [[ $(cat "/proc/$p/comm" 2>/dev/null) == claude || $(readlink "/proc/$p/exe" 2>/dev/null) == */claude/versions/* ]]; then
            cpid=$p; break
        fi
    done
    if [[ -n $cpid ]]; then
        d=${XDG_RUNTIME_DIR:-/tmp}/claude-emacs; mkdir -p "$d"
        reset=""; [[ -n $r5 ]] && reset=$(date -d "@$r5" +%H:%M 2>/dev/null)
        printf '{"ctx":%s,"q5":%s,"reset":"%s"}\n' "$pct" "${q5:-null}" "$reset" > "$d/$cpid.json.$$" \
            && mv "$d/$cpid.json.$$" "$d/$cpid.json"
    fi
    pill "$MAG" "$NAVY" "$bold$(printf '')  ${model}"; echo
    exit 0
fi

# Pills are laid out like wrapping text: each goes on the current line if it fits in the
# terminal width Claude Code passes as $COLUMNS, otherwise it starts a new line.
export LC_ALL=C.UTF-8                      # so ${#s} counts characters, not bytes
maxw=$(( ${COLUMNS:-80} - 4 ))             # small margin for Claude Code's own indent
vis() { local s; s=$(sed -E 's/\x1b\[[0-9;]*m//g' <<<"$1"); echo "${#s}"; }

pills=()
pills+=("$(pill "$MAG" "$NAVY" "$bold$(printf '\uf2db')  ${model}")")
dirpill=$(pill "$PILL" "$ICE" "$(printf '\uf07c')  ${dir}")
# very narrow: just the folder name
(( $(vis "$dirpill") > maxw )) && dirpill=$(pill "$PILL" "$ICE" "$(printf '\uf07c')  ${cwd##*/}")
pills+=("$dirpill")
[[ -n $branch ]] && pills+=("$(pill "$PILL" "$MAG" "$(printf '\ue0a0') ${branch}")")
pills+=("$(meter_pill "ctx" "$pct" 10)")
if [[ -n $q5 ]]; then
    qpill=$(meter_pill "5h" "$q5" 8 "$(date -d "@$r5" +%H:%M 2>/dev/null)")
    (( $(vis "$qpill") > maxw )) && qpill=$(meter_pill "5h" "$q5" 8)   # very narrow: drop the reset time
    pills+=("$qpill")
fi

line="" w=0
for p in "${pills[@]}"; do
    pw=$(vis "$p")
    # wrap: finish the line, then a spacer row. It holds U+2800 (braille blank): it looks like a
    # space but isn't whitespace, so Claude Code doesn't trim the row away as empty.
    if (( w > 0 && w + pw > maxw )); then printf '%s\n\u2800\n' "$line"; line="" w=0; fi
    line+=$p; w=$(( w + pw ))
done
printf '%s\n' "$line"
