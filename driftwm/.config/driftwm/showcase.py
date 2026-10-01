#!/usr/bin/env python3
"""Show the rice off: lay out a set of windows on the biggest screen (Mod+F8).

    ┌──────────────┬──────────┬────────────┐
    │              │  clock   │            │
    │  fastfetch   ├──────────┤            │
    │              │  player  │    btop    │
    │              ├──────────┤            │
    │              │   keys   │            │
    ├──────────────┼──────────┴────────────┤
    │     yazi     │         cava          │
    └──────────────┴───────────────────────┘

The panes go around the screen's current camera, at zoom 1. Running it again re-arranges
the panes that are still open and opens the missing ones (no duplicates).

Usage: showcase.py             lay out the showcase
       showcase.py clock|keys  (the content of those two panes)
"""
import os, shutil, signal, subprocess, sys, time

sys.path.insert(0, os.path.dirname(os.path.realpath(__file__)))
import nav  # noqa: E402  (msg, LAYOUT, BAR)
from guard import cursor_to  # noqa: E402

GAP = 20
HERE = os.path.realpath(__file__)
DOTFILES = os.path.expanduser("~/Documents/opensource/dotfiles")
KITTY = ["kitty", "-o", "remember_window_size=no"]


def panes(W, H):
    """(app_id, command, x, y, w, h) in screen px from the usable area's top-left."""
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
        ("showcase-fetch", KITTY + ["--class", "showcase-fetch", "fish", "-C", "fastfetch"],
         x1, GAP, left, top),
        ("showcase-clock", KITTY + ["--class", "showcase-clock", "-o", "font_family=DSEG7 Classic",
                                    "-o", "font_size=48", HERE, "clock"],
         x2, GAP, mid, clock),
        ("nowplaying", KITTY + ["--class", "nowplaying", "--title", "nowplaying", "nowplaying"],
         x2, 2 * GAP + clock, mid, player),
        ("showcase-keys", KITTY + ["--class", "showcase-keys", HERE, "keys"],
         x2, 3 * GAP + clock + player, mid, keys),
        ("showcase-btop", KITTY + ["--class", "showcase-btop", "btop"],
         x3, GAP, right, top),
        ("showcase-yazi", KITTY + ["--class", "showcase-yazi", "-d", DOTFILES, "yazi"],
         x1, y2, left, bottom),
        ("showcase-cava", KITTY + ["--class", "showcase-cava", "cava"],
         x2, y2, W - 3 * GAP - left, bottom),
    ]


def state():
    return nav.msg("state")["Ok"]["State"]


def wait_window(app_id, known, timeout=8.0):
    end = time.monotonic() + timeout
    while time.monotonic() < end:
        for w in state()["windows"]:
            if w["app_id"] == app_id and w["id"] not in known:
                return w
        time.sleep(0.1)
    return None


def layout():
    st = state()
    screen = max((o for o in st["outputs"] if o["name"] in nav.LAYOUT),
                 key=lambda o: o["size"][0] * o["size"][1])
    cursor_to(screen["name"])                                   # spawn / camera act here
    if abs(screen["zoom"] - 1) > 1e-3:
        nav.msg("zoom", 1)
        time.sleep(0.4)
    cx, cy = state_output(screen["name"])["camera"]
    sw, sh = screen["size"]
    W, H = sw, sh - nav.BAR                                     # usable area below the bar
    ox, oy = cx - sw / 2, cy + sh / 2 - nav.BAR                 # its top-left on the canvas (Y up)

    # 1. open the missing panes (driftwm places and may pan to each new window)
    known = {w["id"] for w in st["windows"]}
    wins = {}
    for app_id, cmd, *_ in panes(W, H):
        win = next((v for v in state()["windows"] if v["app_id"] == app_id), None)
        if not win:
            subprocess.Popen(cmd, stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL,
                             stderr=subprocess.DEVNULL, start_new_session=True)
            win = wait_window(app_id, known)
        if win:
            known.add(win["id"])
            wins[app_id] = win["id"]
    # 2. back to where the screen was looking, once the pans have settled
    time.sleep(0.5)
    nav.msg("camera", round(cx), round(cy))
    time.sleep(0.6)
    # 3. size and place them around it
    for app_id, _, x, y, w, h in panes(W, H):
        if app_id in wins:
            nav.msg("resize", "--id", wins[app_id], w, h)
            nav.msg("move", "--id", wins[app_id], round(ox + x + w / 2), round(oy - y - h / 2))
    if "showcase-fetch" in wins:
        time.sleep(0.3)
        nav.msg("focus", "--id", wins["showcase-fetch"])


def state_output(name):
    return next(o for o in state()["outputs"] if o["name"] == name)


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
    {"": layout, "clock": clock_pane, "keys": keys_pane}.get(arg, lambda: sys.exit(__doc__))()
