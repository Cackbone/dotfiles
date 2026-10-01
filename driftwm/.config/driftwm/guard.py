#!/usr/bin/env python3
"""Keep every screen on its own canvas area (no "mirrored" screens), whatever moved it.

Each screen owns an area of the canvas (arrange-cameras.sh). Anything that focuses a window
on another screen's area — Alt-Tab, a taskbar click, an app asking for attention, a script's
`driftwm msg focus` — pans the screen under the mouse over there, so two screens show the
same windows. This helper, autostarted with the session, follows the event stream and turns
that into "go to that screen": the moved screen's camera goes back to where it was in its
own area, the mouse moves to the screen that owns the window, and the window is focused and
centred there.
"""
import json, os, select, subprocess, sys, time

sys.path.insert(0, os.path.dirname(os.path.realpath(__file__)))
import nav  # noqa: E402  (msg, area, LAYOUT)


def own(o):
    return nav.LAYOUT.index(o["name"]) if o["name"] in nav.LAYOUT else None


def wait_active(name, timeout=1.0):
    end = time.monotonic() + timeout
    while time.monotonic() < end:
        st = nav.msg("state")["Ok"]["State"]
        if any(o["active"] and o["name"] == name for o in st["outputs"]):
            return True
        time.sleep(0.02)
    return False


def cursor_to(name):
    st = nav.msg("state")["Ok"]["State"]
    cur = next((o["name"] for o in st["outputs"] if o["active"]), None)
    if cur == name or cur not in nav.LAYOUT or name not in nav.LAYOUT:
        return
    step = nav.LAYOUT.index(name) - nav.LAYOUT.index(cur)
    for _ in range(abs(step)):
        nav.msg("action", "send-cursor-to-output", "right" if step > 0 else "left")
    wait_active(name)


def latest_states(p):
    """Yield driftwm states, skipping any that queued up while we were busy (keep the newest)."""
    fd, buf = p.stdout.fileno(), b""
    while True:
        r, _, _ = select.select([fd], [], [], 0.2)
        if r:
            chunk = os.read(fd, 1 << 16)
            if not chunk:
                return
            buf += chunk
            while select.select([fd], [], [], 0)[0]:            # drain the backlog
                chunk = os.read(fd, 1 << 16)
                if not chunk:
                    break
                buf += chunk
        lines = buf.split(b"\n")
        buf = lines.pop()
        for line in reversed(lines):
            try:
                st = json.loads(line).get("State")
            except json.JSONDecodeError:
                continue
            if st:
                yield st
                break
        else:
            yield None                                          # timer tick: re-check rest


def main():
    last_ok = {}            # output → last camera position *at rest* inside its own area
    seen = {}               # output → (camera, time it got there): pans are animated
    current = None
    busy_until = 0.0
    p = subprocess.Popen(["driftwm", "msg", "--json", "subscribe"], stdout=subprocess.PIPE)
    for st in latest_states(p):
        st = st or current
        if not st:
            continue
        current = st
        now = time.monotonic()
        for o in st["outputs"]:
            i = own(o)
            if i is None:
                continue
            cam = tuple(o["camera"])
            old = seen.get(o["name"])
            if not old or abs(old[0][0] - cam[0]) > 0.5 or abs(old[0][1] - cam[1]) > 0.5:
                seen[o["name"]] = old = (cam, now)
            if nav.area(*cam)[1] == i:
                if now - old[1] >= 0.15:                        # unchanged for 150 ms: at rest
                    last_ok[o["name"]] = cam
                continue
            if now < busy_until or o["name"] not in last_ok:
                continue
            # o has been pulled into another screen's area
            busy_until = now + 0.8
            owner_idx = nav.area(*cam)[1]
            owner = nav.LAYOUT[owner_idx] if 0 <= owner_idx < len(nav.LAYOUT) else None
            focused = next((w for w in st["windows"] if w["is_focused"]), None)
            cursor_to(o["name"])                              # `msg camera` moves the active screen
            nav.msg("camera", *map(round, last_ok[o["name"]]))
            if owner:
                cursor_to(owner)
                if focused and nav.area(*focused["position"])[1] == owner_idx:
                    st2 = nav.msg("state")["Ok"]["State"]
                    o2 = next((x for x in st2["outputs"] if x["name"] == owner), None)
                    if o2:
                        nav.show(o2, focused)                # centre it there, keeping the zoom
            break
    sys.exit(p.wait())


if __name__ == "__main__":
    main()
