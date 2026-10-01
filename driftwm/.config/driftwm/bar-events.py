#!/usr/bin/env python3
"""Refresh waybar's desktop/window pills (signal RTMIN+8) when they'd change.

Follows driftwm's event stream and signals waybar only when something the pills show changes:
the windows (and which (desktop, screen) area each is in), the focused window, or the area
each screen is looking at. Saves the custom modules from polling driftwm every second.
"""
import json, os, signal, subprocess, sys

sys.path.insert(0, os.path.dirname(os.path.realpath(__file__)))
import nav  # noqa: E402  (area)


def main():
    last = None
    p = subprocess.Popen(["driftwm", "msg", "--json", "subscribe"], stdout=subprocess.PIPE, text=True)
    for line in p.stdout:
        try:
            st = json.loads(line).get("State")
        except json.JSONDecodeError:
            continue
        if not st:
            continue
        sig = (tuple(sorted((w["id"], nav.area(*w["position"]), w["is_focused"], w["app_id"]) for w in st["windows"])),
               tuple(sorted((o["name"], nav.area(*o["camera"])) for o in st["outputs"])))
        if sig != last:
            last = sig
            subprocess.run(["pkill", "-RTMIN+8", "-x", "waybar"])
    sys.exit(p.wait())


if __name__ == "__main__":
    main()
