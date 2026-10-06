#!/usr/bin/env bash
# Theme the LightDM GTK greeter. Needs root: the greeter runs as the `lightdm` user,
# which can't read $HOME, so files are copied (not linked) to system paths.
#   sudo lightdm/install.sh        (re-run after changing anything here)
set -euo pipefail
cd "$(dirname "$(readlink -f "$0")")/.."
[[ $EUID -eq 0 ]] || { echo "run with sudo" >&2; exit 1; }

W=wallpapers/.local/share/wallpapers
install -Dm644 "$W/night-city@2x.png" /usr/share/backgrounds/synthwave/night-city.png
install -Dm644 lightdm/avatar.svg /usr/share/backgrounds/synthwave/avatar.svg

# GTK theme "Synthwave" = Adwaita-dark + the same overrides as ~/.config/gtk-3.0 + greeter widgets
tmp=$(mktemp)
{
    echo '@import url("resource:///org/gtk/libgtk/theme/Adwaita/gtk-contained-dark.css");'
    cat gtk/.config/gtk-3.0/gtk.css lightdm/greeter.css
} > "$tmp"
install -Dm644 "$tmp" /usr/share/themes/Synthwave/gtk-3.0/gtk.css
rm -f "$tmp"

conf=/etc/lightdm/lightdm-gtk-greeter.conf
[[ -f $conf && ! -f $conf.orig ]] && cp "$conf" "$conf.orig"
install -Dm644 lightdm/lightdm-gtk-greeter.conf "$conf"
echo "Greeter themed. It shows at next logout (original config saved as $conf.orig)."
