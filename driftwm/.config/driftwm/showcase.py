#!/usr/bin/env python3
"""Show the rice off: a set of windows on the biggest screen.

    ┌──────────────┬──────────┬────────────┐
    │              │  clock   │            │
    │  fastfetch   ├──────────┤            │
    │              │  player  │    btop    │
    │              ├──────────┤            │
    │              │   keys   │            │
    ├──────────────┼──────────┴────────────┤
    │     yazi     │         cava          │
    └──────────────┴───────────────────────┘

Arrange the windows the way you like on that screen and save it (Mod+Shift+F8): their
positions and sizes and the screen's view and zoom go to showcase.json, next to this
script. Mod+F8 puts the saved layout back, reusing the windows that are open and opening
the missing ones; with nothing saved, the default arrangement above, around the view.
At login (driftwm autostart) the saved layout opens by itself when its screen is connected.

Usage: showcase.py             restore the saved layout (else the default one)
       showcase.py save        save the windows of the biggest screen's current desktop
       showcase.py --login     restore, if the saved screen is connected (session start)
       showcase.py clock|keys  (the content of those two panes)
"""
import json, os, shutil, signal, subprocess, sys, time

sys.path.insert(0, os.path.dirname(os.path.realpath(__file__)))
import nav  # noqa: E402  (msg, area, LAYOUT, BAR)
from guard import cursor_to  # noqa: E402

GAP = 20
HERE = os.path.realpath(__file__)
SAVED = os.environ.get("SHOWCASE_FILE") or os.path.join(os.path.dirname(HERE), "showcase.json")
DOTFILES = os.path.expanduser("~/Documents/opensource/dotfiles")
KITTY = ["kitty", "-o", "remember_window_size=no"]
# watch mode lays itself out once, at start: wait until the window has its final size
FETCH = "sleep 1.5; fastfetch --dynamic-interval 300000"    # refreshed every 5 min


def commands():
    """How to open each window a layout can hold, by app_id."""
    return {
        "showcase-fetch": KITTY + ["--class", "showcase-fetch", "fish", "-C", FETCH],
        "showcase-clock": KITTY + ["--class", "showcase-clock", "-o", "font_family=DSEG7 Classic",
                                   "-o", "font_size=48", HERE, "clock"],
        "nowplaying": KITTY + ["--class", "nowplaying", "--title", "nowplaying", "nowplaying"],
        "showcase-keys": KITTY + ["--class", "showcase-keys", HERE, "keys"],
        "showcase-btop": KITTY + ["--class", "showcase-btop", "btop"],
        "showcase-yazi": KITTY + ["--class", "showcase-yazi", "-d", DOTFILES, "yazi"],
        "showcase-cava": KITTY + ["--class", "showcase-cava", "cava"],
        "clawd": ["kitty", "--class", "clawd", "--title", "Claude usage", "clawd"],
    }


def panes(W, H):
    """The default layout: (app_id, x, y, w, h) in screen px from the usable area's top-left."""
    left = 1000 * W // 2560                       # fastfetch / yazi column
    right = 840 * W // 2560                       # btop column
    mid = W - 4 * GAP - left - right
    top = 900 * H // 1384                         # top row height
    bottom = H - 3 * GAP - top
    clock, player = 220 * H // 1384, 300
    keys = top - 2 * GAP - clock - player
    x1, x2, x3 = GAP, 2 * GAP + left, 3 * GAP + left + mid
    y2 = 2 * GAP + top
    return [
        ("showcase-fetch", x1, GAP, left, top),
        ("showcase-clock", x2, GAP, mid, clock),
        ("nowplaying", x2, 2 * GAP + clock, mid, player),
        ("showcase-keys", x2, 3 * GAP + clock + player, mid, keys),
        ("showcase-btop", x3, GAP, right, top),
        ("showcase-yazi", x1, y2, left, bottom),
        ("showcase-cava", x2, y2, W - 3 * GAP - left, bottom),
    ]


def state():
    return nav.msg("state")["Ok"]["State"]


def output(name):
    return next((o for o in state()["outputs"] if o["name"] == name), None)


def biggest(st):
    return max((o for o in st["outputs"] if o["name"] in nav.LAYOUT),
               key=lambda o: o["size"][0] * o["size"][1])


def wait_until(test, timeout):
    end = time.monotonic() + timeout
    while time.monotonic() < end:
        r = test()
        if r:
            return r
        time.sleep(0.05)
    return None


def spawn(cmd, size):
    if cmd[0] == "kitty":                         # open at the final size (the program inside
        cmd = cmd[:1] + ["-o", f"initial_window_width={size[0]}",       # lays itself out once)
                         "-o", f"initial_window_height={size[1]}"] + cmd[1:]
    subprocess.Popen(cmd, cwd=os.path.expanduser("~"), stdin=subprocess.DEVNULL,
                     stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, start_new_session=True)


def place(app_id, cmd, center, size, used):
    """The window for app_id — an open one, else a new one from cmd — at center with size."""
    def find():
        return next((w for w in state()["windows"] if w["app_id"] == app_id and w["id"] not in used), None)
    win = find()
    if not win:
        if not cmd:
            return None
        spawn(cmd, size)
        win = wait_until(find, 10)
        if not win:
            return None
        # until its first real size, a move is lost: driftwm places the window once it maps
        wait_until(lambda: next((w["size"][0] > 50 for w in state()["windows"] if w["id"] == win["id"]), True), 3)
    used.add(win["id"])
    nav.msg("resize", "--id", win["id"], *size)
    nav.msg("move", "--id", win["id"], *center)
    return win["id"]


def view(cx, cy, z):
    """The screen under the mouse to (cx, cy) at zoom z: camera first (a zoom in flight stops
    a pan), then the zoom, then the camera again (zooming pivots slightly off-centre)."""
    def cam_at():
        c = nav.msg("camera").get("Ok", {}).get("Camera", {})
        return abs(c.get("x", 1e9) - cx) < 1 and abs(c.get("y", 1e9) - cy) < 1
    nav.msg("camera", round(cx), round(cy))
    wait_until(cam_at, 1.5)
    nav.msg("zoom", z)
    wait_until(lambda: abs(nav.msg("zoom").get("Ok", {}).get("Zoom", 0) - z) < 1e-3, 1.5)
    nav.msg("camera", round(cx), round(cy))
    wait_until(cam_at, 1.5)


def default_layout():
    """The arrangement in the docstring, around the biggest screen's view, at zoom 1."""
    screen = biggest(state())
    cursor_to(screen["name"])                                   # spawn / camera act here
    cx, cy = screen["camera"]
    sw, sh = screen["size"]
    ox, oy = cx - sw / 2, cy + sh / 2 - nav.BAR                 # usable area's top-left (Y up)
    used, cmds = set(), commands()
    for app_id, x, y, w, h in panes(sw, sh - nav.BAR):
        place(app_id, cmds[app_id], (round(ox + x + w / 2), round(oy - y - h / 2)), (w, h), used)
    view(cx, cy, 1)


def launch_command(app_id):
    """How the open window `app_id` was started, for a saved layout: its kitty (--class)."""
    for pid in filter(str.isdigit, os.listdir("/proc")):
        try:
            with open(f"/proc/{pid}/cmdline", "rb") as f:
                args = f.read().decode(errors="replace").split("\0")[:-1]
        except OSError:
            continue
        if args and os.path.basename(args[0]) == "kitty" and "--class" in args \
                and args[args.index("--class") + 1:args.index("--class") + 2] == [app_id]:
            return args
    return [app_id] if shutil.which(app_id) else None


def save():
    st = state()
    screen = biggest(st)
    here = nav.area(*screen["camera"])
    wins = [w for w in st["windows"] if not w.get("is_widget") and nav.area(*w["position"]) == here]
    known, lost, out = commands(), [], []
    for w in sorted(wins, key=lambda w: (-w["position"][1], w["position"][0])):    # top first
        e = {"app_id": w["app_id"], "position": [round(c) for c in w["position"]], "size": w["size"]}
        if w["app_id"] not in known:
            e["command"] = launch_command(w["app_id"])
            if not e["command"]:
                lost.append(w["app_id"])
        out.append(e)
    with open(SAVED, "w") as f:
        json.dump({"screen": screen["name"], "camera": [round(c) for c in screen["camera"]],
                   "zoom": round(screen["zoom"], 6), "windows": out}, f, indent=2)
        f.write("\n")
    msg = f"{len(out)} windows on {screen['name']}" + (f" (can't reopen: {', '.join(lost)})" if lost else "")
    subprocess.run(["notify-send", "-a", "showcase", "Layout saved", msg], check=False)
    print(msg)


def restore(login=False):
    try:
        with open(SAVED) as f:
            saved = json.load(f)
    except (OSError, ValueError):
        if not login:
            default_layout()
        return
    name = saved["screen"]
    def connected():                                           # (at login, driftwm may still
        try:                                                   # be bringing screens up)
            return output(name) is not None
        except Exception:
            return False
    if not wait_until(connected, 10 if login else 0.1):        # that screen isn't connected
        if not login:
            subprocess.run(["notify-send", "-a", "showcase", "Showcase", f"{name} isn't connected"], check=False)
        return
    st = state()
    back = next((o["name"] for o in st["outputs"] if o["active"]), None)
    had_focus = next((w["id"] for w in st["windows"] if w["is_focused"]), None)
    cursor_to(name)                                             # new windows open here

    # the open windows are reused; the missing ones all open at once, each placed as soon as
    # it maps (until its first real size, a move is lost: driftwm places it when it maps)
    used, todo, placed, cmds = set(), [], [], commands()
    def put(win, w):
        used.add(win["id"])
        nav.msg("resize", "--id", win["id"], *w["size"])
        nav.msg("move", "--id", win["id"], *w["position"])
        placed.append((win["id"], w["app_id"], w["position"]))
    st = state()
    for w in saved["windows"]:
        win = next((v for v in st["windows"] if v["app_id"] == w["app_id"] and v["id"] not in used), None)
        if win:
            put(win, w)
        elif cmd := w.get("command") or cmds.get(w["app_id"]):
            spawn(cmd, w["size"])
            todo.append(w)
    end = time.monotonic() + 15
    while todo and time.monotonic() < end:
        st = state()
        for w in list(todo):
            win = next((v for v in st["windows"] if v["app_id"] == w["app_id"] and v["id"] not in used
                        and v["size"][0] > 50), None)
            if win:
                put(win, w)
                todo.remove(w)
        time.sleep(0.1)
    time.sleep(0.3)                                             # driftwm may snap a window to a
    for wid, _, pos in placed:                                  # neighbour: put it exactly back
        cur = next((v["position"] for v in state()["windows"] if v["id"] == wid), pos)
        if list(cur) != list(pos):
            nav.msg("move", "--id", wid, *pos)

    view(*saved["camera"], saved["zoom"])
    time.sleep(0.3)                                             # at rest: guard.py keeps it as this
    if back and back != name:                                   # screen's view
        cursor_to(back)                                         # the mouse back where it was
    # focus back where it was (new windows take it), else the fastfetch pane — only on the
    # screen under the mouse: focusing a window elsewhere pans this screen over there
    mouse = back or name
    here = nav.LAYOUT.index(mouse) if mouse in nav.LAYOUT else None
    wins = {v["id"]: v for v in state()["windows"]}
    def under_mouse(wid):
        return wid in wins and nav.area(*wins[wid]["position"])[1] == here
    fetch = next((wid for wid, app_id, _ in placed if app_id == "showcase-fetch"), None)
    target = had_focus if under_mouse(had_focus) else fetch if under_mouse(fetch) else None
    if target is not None:
        nav.msg("focus", "--id", target)


# ---------------------------------------------------------------- pane contents
MAGENTA, CYAN, ICE, LIME, YELLOW, FG, DIM = ("e040fb", "00bcd4", "76e6f2", "69ff47",
                                             "ffd166", "e8e6ff", "8b8bc7")


def c(hexcol, s, bold=False):
    r, g, b = (int(hexcol[i:i + 2], 16) for i in (0, 2, 4))
    return f"\033[{'1;' if bold else ''}38;2;{r};{g};{b}m{s}\033[0m"


def run_pane(draw, every):
    """Redraw `draw(cols, rows)` centred, every `every` s and on resize; no cursor."""
    resized = [True]
    signal.signal(signal.SIGWINCH, lambda *_: resized.__setitem__(0, True))
    sys.stdout.write("\033[?25l")
    try:
        while True:
            cols, rows = shutil.get_terminal_size()
            lines = draw(cols, rows)
            out = "\033[H\033[2J" if resized[0] else "\033[H"
            resized[0] = False
            pad = max(0, (rows - len(lines)) // 2)
            out += "\n" * pad + "\n".join(lines)
            sys.stdout.write(out)
            sys.stdout.flush()
            end = time.monotonic() + every
            while time.monotonic() < end and not resized[0]:     # a resize redraws at once
                time.sleep(0.05)
    except KeyboardInterrupt:
        pass
    finally:
        sys.stdout.write("\033[?25h")


def clock_pane():
    def draw(cols, rows):
        t = time.localtime()
        colon = ":" if t.tm_sec % 2 == 0 else " "               # blinks like the bar's clock
        s = time.strftime(f"%H{colon}%M{colon}%S", t)
        return [" " * max(0, (cols - len(s)) // 2) + c(MAGENTA, s, True)]
    run_pane(draw, 0.25)


KEYS = [
    ("Mod+Enter", "terminal"), ("Mod+D", "launcher"), ("Mod+E", "files"),
    ("Mod+F7", "now playing"), ("Mod+arrows", "focus · next screen"),
    ("Mod+R", "resize mode"), ("Mod+Tab", "overview"),
    ("Mod+& é \" ' (", "desktops 1-5"), ("Mod+Shift+Ctrl+←→", "window → screen"),
    ("Mod+V", "clipboard"), ("Mod+Alt+L", "lock"),
    ("F8 · F9", "emacs tree · claude"),
]


def keys_pane():
    def draw(cols, rows):
        kw = max(len(k) for k, _ in KEYS)
        width = kw + 3 + max(len(v) for _, v in KEYS)
        left = " " * max(0, (cols - width) // 2)
        lines = [left + c(CYAN, "driftwm", True) + c(DIM, " · synthwave rice"), ""]
        for k, v in KEYS[: max(0, rows - 2)]:
            lines.append(left + c(ICE, k.ljust(kw), True) + c(DIM, " · ") + c(FG, v))
        return lines
    run_pane(draw, 5)


if __name__ == "__main__":
    arg = sys.argv[1] if len(sys.argv) > 1 else ""
    {"": restore, "save": save, "--login": lambda: restore(login=True),
     "clock": clock_pane, "keys": keys_pane}.get(arg, lambda: sys.exit(__doc__))()
