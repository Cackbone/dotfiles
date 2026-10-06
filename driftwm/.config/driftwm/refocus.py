#!/usr/bin/env python3
"""After closing the focused window, focus the closest window on the same screen.

driftwm picks the next focus itself (with auto_navigate_on_close = false: some visible
window, possibly on another screen). This helper, autostarted with the session, follows the
event stream and, when the focused window disappears, focuses the window nearest to where it
was *in the same area* (same screen, same desktop — see desktop.sh) and centres that screen's
camera on it, keeping the zoom (nav.show). An area with no window left keeps focus as is.
"""
import json, os, subprocess, sys

sys.path.insert(0, os.path.dirname(os.path.realpath(__file__)))
import nav  # noqa: E402  (area, show, msg, LAYOUT)


def main():
    last = None          # (id, position, area) of the focused window in the previous event
    p = subprocess.Popen(["driftwm", "msg", "--json", "subscribe"], stdout=subprocess.PIPE, text=True)
    for line in p.stdout:
        try:
            state = json.loads(line).get("State")
        except json.JSONDecodeError:
            continue
        if not state:
            continue
        wins = {w["id"]: w for w in state["windows"]}
        # a window going fullscreen or pinned leaves `windows` for the screen-space
        # inventories: it's still open (refocusing would pan, and panning ends fullscreen)
        alive = set(wins) | {w["id"] for w in state.get("fullscreen", []) + state.get("pinned", [])}
        if last and last[0] not in alive:                  # the focused window just closed
            wid, (x, y), here = last
            cand = [w for w in state["windows"] if not w.get("is_widget") and not w.get("suspended")
                    and nav.area(*w["position"]) == here]
            if cand:
                target = min(cand, key=lambda w: (w["position"][0] - x) ** 2 + (w["position"][1] - y) ** 2)
                screen = next((o for o in state["outputs"] if nav.area(*o["camera"]) == here), None)
                active = next((o for o in state["outputs"] if o["active"]), None)
                if screen and active and screen["name"] != active["name"] \
                        and screen["name"] in nav.LAYOUT and active["name"] in nav.LAYOUT:
                    step = nav.LAYOUT.index(screen["name"]) - nav.LAYOUT.index(active["name"])
                    for _ in range(abs(step)):
                        nav.msg("action", "send-cursor-to-output", "right" if step > 0 else "left")
                if screen:
                    nav.show(screen, target)                # centre on it, keeping the zoom
                last = None
                continue
        f = next((w for w in state["windows"] if w["is_focused"]), None)
        last = (f["id"], f["position"], nav.area(*f["position"])) if f else last if last and last[0] in alive else None
    sys.exit(p.wait())


if __name__ == "__main__":
    main()
