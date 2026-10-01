#!/usr/bin/env bash
# Symlink every package into $HOME with GNU Stow.
#   ./install.sh            link everything
#   ./install.sh --packages also install packages.txt with pacman first
set -euo pipefail
cd "$(dirname "$(readlink -f "$0")")"

if [[ ${1:-} == --packages ]]; then
    sudo pacman -S --needed $(grep -v '^#' packages.txt)
fi

PKGS=(
    # shared
    autostart fish fontconfig fonts gtk rofi wallpapers kitty fastfetch btop cava yazi nowplaying claude clawd
    # wayland / niri session
    niri driftwm waybar mako swaylock
    # x11 / i3 session (fallback)
    i3 picom polybar background xfce4
)

# --no-folding: link files, not whole directories, so apps writing new files
#   (caches, generated state) never end up inside the repo.
# --adopt: if a real file already exists at the target, move it into the repo
#   and link it. The live version wins; review with `git diff` afterwards.
stow --no-folding --adopt -t "$HOME" "${PKGS[@]}"

# Emacs: dot-emacs is a submodule; its README.org is the literate config.
git submodule update --init --recursive
mkdir -p ~/.emacs.d
ln -sfn "$PWD/dot-emacs/README.org"               ~/.emacs.d/config.org
ln -sfn "$PWD/dot-emacs/camron-theme/camron-theme.el" ~/.emacs.d/camron-theme.el

# Icons: Papirus-Dark with magenta folders, built in ~/.local/share/icons
[[ -d /usr/share/icons/Papirus ]] && scripts/papirus-synthwave.sh

# Firefox: profile folders have random names, so link into the default one from profiles.ini.
ff=~/.mozilla/firefox
if [[ -f $ff/profiles.ini ]]; then
    prof=$(awk -F= '/^\[Install/{i=1} i && /^Default=/{print $2; exit}' "$ff/profiles.ini")
    if [[ -n $prof && -d $ff/$prof ]]; then
        ln -sfn "$PWD/firefox/chrome"  "$ff/$prof/chrome"
        ln -sfn "$PWD/firefox/user.js" "$ff/$prof/user.js"
        echo "Firefox theme linked into $prof (restart Firefox to apply)"
    fi
fi

fc-cache -f >/dev/null
echo "Linked. Review any adopted changes with: git -C '$PWD' status"
