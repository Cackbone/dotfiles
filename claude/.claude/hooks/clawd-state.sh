#!/usr/bin/env bash
# Claude Code hook: record whether this session is working, for the clawd window.
#   clawd-state.sh working|idle|end      (session id read from the hook's JSON on stdin)
# Writes "$XDG_RUNTIME_DIR/clawd/<session id>" = "<state> <pid of this claude process>";
# the pid lets clawd ignore sessions that died without an end event.
dir=${XDG_RUNTIME_DIR:-/tmp}/clawd
mkdir -p "$dir"
id=$(jq -r '.session_id // empty' 2>/dev/null)
[[ $id =~ ^[A-Za-z0-9_-]+$ ]] || exit 0
if [[ $1 == end ]]; then rm -f "$dir/$id"; exit 0; fi
pid=$PPID p=$PPID
for _ in 1 2 3 4 5; do                                   # the claude process above us
    # (the process is named "claude", or after its version — 2.1.287 — when started from the
    # versioned binary: its executable tells)
    [[ $(cat /proc/$p/comm 2>/dev/null) == claude || $(readlink /proc/$p/exe 2>/dev/null) == */claude/versions/* ]] && { pid=$p; break; }
    p=$(awk '{print $4}' /proc/$p/stat 2>/dev/null) || break
    (( p > 1 )) || break
done
printf '%s %s\n' "$1" "$pid" > "$dir/$id.tmp" && mv "$dir/$id.tmp" "$dir/$id"
