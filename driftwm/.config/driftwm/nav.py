#!/usr/bin/env python3
"""Directional window navigation for driftwm (Mod+arrows / Mod+jklm), i3-style across screens.

Each screen is its own canvas (its own area, see arrange-cameras.sh / desktop.sh), so:
  * the nearest window in that direction *on this screen's current desktop* gets focus, and
    the screen's camera centres on it (the zoom stays as it is);
  * with nothing further that way, left/right continue onto the neighbouring screen: the
    mouse moves there and its window nearest to the edge you came from (at about the same
    height) gets focus.

Usage: nav.py left|right|up|down     (or: nav.py focus <window id>)
"""
import json, subprocess, sys, time

DX = DY = 100000                             # desktops along x, screens along y (desktop.sh)
LAYOUT = ["DP-1", "HDMI-A-2", "eDP-1"]       # physical order, left to right; screen i at y = -i*DY
MARGIN = 24                                  # canvas px kept around the window
BAR = 56                                     # screen px waybar reserves at the top (48 + 8 margin)


def msg(*args):
    out = subprocess.run(["driftwm", "msg", "--json", *map(str, args)], capture_output=True, text=True).stdout
    return json.loads(out) if out.strip() else {}


def area(x, y):
    """(desktop, screen) area a canvas point belongs to."""
    return int((x + DX / 2) // DX), int((-y + DY / 2) // DY)


def usable(o):
    cx, cy = o["camera"]
    hw, hh = o["size"][0] / 2 / o["zoom"], o["size"][1] / 2 / o["zoom"]
    return cx - hw, cx + hw, cy - hh, cy + hh - BAR / o["zoom"]


def fit_axis(c, half, lo, hi):
    """Smallest move of a view centre c (half-size half) so [lo, hi] fits inside it."""
    if hi - lo + 2 * MARGIN >= 2 * half:
        return (lo + hi) / 2
    if lo - MARGIN < c - half:
        return lo - MARGIN + half
    if hi + MARGIN > c + half:
        return hi + MARGIN - half
    return c


def show(o, w):
    """Focus window w on screen o (already under the mouse) and centre o on it, keeping o's zoom.

    (driftwm's center-window would reset the zoom to 100%.) The window goes to the middle of
    the usable area, i.e. below the bar; the camera move is animated, so wait for it to land
    before focusing (focusing a not-yet-fully-visible window makes driftwm re-centre)."""
    z = o["zoom"] or 1
    cx, cy = w["position"][0], w["position"][1] + BAR / 2 / z   # Y up: usable centre sits BAR/2 lower
    if abs(cx - o["camera"][0]) > 0.5 or abs(cy - o["camera"][1]) > 0.5:
        msg("camera", round(cx), round(cy))
        deadline = time.monotonic() + 1.5
        while time.monotonic() < deadline:
            cam = msg("camera").get("Ok", {}).get("Camera", {})
            if abs(cam.get("x", 1e9) - round(cx)) < 1 and abs(cam.get("y", 1e9) - round(cy)) < 1:
                break
            time.sleep(0.02)
    msg("focus", "--id", w["id"])


def focus_id(wid):
    """`nav.py focus <id>`: focus that window and centre the active screen on it (zoom kept)."""
    st = msg("state")["Ok"]["State"]
    o = next(o for o in st["outputs"] if o["active"])
    w = next((w for w in st["windows"] if w["id"] == wid), None)
    if w:
        show(o, w)


def main():
    d = sys.argv[1] if len(sys.argv) > 1 else ""
    if d == "focus" and len(sys.argv) > 2:
        return focus_id(int(sys.argv[2]))
    if d not in ("left", "right", "up", "down"):
        sys.exit(__doc__)
    st = msg("state")["Ok"]["State"]
    o = next(o for o in st["outputs"] if o["active"])
    here = area(*o["camera"])
    focused = next((w for w in st["windows"] if w["is_focused"] and area(*w["position"]) == here), None)
    fx, fy = focused["position"] if focused else o["camera"]
    wins = [w for w in st["windows"] if not w.get("is_widget") and area(*w["position"]) == here
            and not (focused and w["id"] == focused["id"])]

    best = None
    for w in wins:
        dx, dy = w["position"][0] - fx, w["position"][1] - fy
        along, across = {"right": (dx, dy), "left": (-dx, dy), "up": (dy, dx), "down": (-dy, dx)}[d]
        if along > 1 and (best is None or along + 2 * abs(across) < best[0]):
            best = (along + 2 * abs(across), w)
    if best:
        show(o, best[1])
        return

    # nothing further this way on this screen: left/right go to the neighbouring screen
    if d not in ("left", "right") or o["name"] not in LAYOUT:
        return
    if not 0 <= LAYOUT.index(o["name"]) + (1 if d == "right" else -1) < len(LAYOUT):
        return
    msg("action", "send-cursor-to-output", d)
    deadline = time.monotonic() + 1.0              # the move is async: wait until driftwm
    while True:                                    # reports the new screen as active
        st = msg("state")["Ok"]["State"]
        o2 = next(x for x in st["outputs"] if x["active"])
        if o2["name"] != o["name"] or time.monotonic() > deadline:
            break
        time.sleep(0.02)
    if o2["name"] == o["name"]:
        return
    there = area(*o2["camera"])
    cand = [w for w in st["windows"] if not w.get("is_widget") and area(*w["position"]) == there]
    if not cand:
        return
    x0, x1, y0, y1 = usable(o2)
    edge = x0 if d == "right" else x1               # the side we came in through
    height = fy - o["camera"][1]                     # where we were, relative to the old screen

    def key(w):
        (wx, wy), (ww, wh) = w["position"], w["size"]
        on = wx + ww / 2 > x0 and wx - ww / 2 < x1 and wy + wh / 2 > y0 and wy - wh / 2 < y1
        return (not on, abs(wx - edge) + 2 * abs((wy - o2["camera"][1]) - height))

    show(o2, min(cand, key=key))


if __name__ == "__main__":
    main()
