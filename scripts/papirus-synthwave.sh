#!/usr/bin/env bash
# Build ~/.local/share/icons/Papirus-Synthwave: Papirus-Dark with magenta folders.
# Same idea as papirus-folders, but in $HOME (no root, survives package updates).
set -euo pipefail
color=${1:-magenta}
src=/usr/share/icons/Papirus
dst=${XDG_DATA_HOME:-$HOME/.local/share}/icons/Papirus-Synthwave
[[ -d $src ]] || { echo "papirus-icon-theme is not installed" >&2; exit 1; }

rm -rf "$dst"; mkdir -p "$dst"
dirs=()
for d in "$src"/*/places; do
    rel=${d#"$src"/}; mkdir -p "$dst/$rel"; dirs+=("$rel")
    # every link pointing at a blue icon gets re-pointed at the same icon in $color
    find "$d" -maxdepth 1 -type l -printf '%f %l\n' | while read -r name target; do
        [[ $target == *-blue* ]] || continue
        new=${target//-blue/-$color}
        [[ -e $d/$new ]] && ln -s "$d/$new" "$dst/$rel/$name"
    done
done

# index.theme: our places dirs (sections copied from Papirus), everything else inherited
{
    printf '[Icon Theme]\nName=Papirus-Synthwave\nComment=Papirus-Dark with %s folders\n' "$color"
    printf 'Inherits=Papirus-Dark,Papirus,breeze-dark,hicolor\n'
    printf 'Directories=%s\n\n' "$(IFS=,; echo "${dirs[*]}")"
    for rel in "${dirs[@]}"; do
        awk -v s="[$rel]" '$0==s{p=1; print; next} /^\[/{p=0} p' "$src/index.theme"; echo
    done
} > "$dst/index.theme"
gtk-update-icon-cache -q -f "$dst" 2>/dev/null || true
echo "Built $dst ($(find "$dst" -type l | wc -l) folder icons in $color)"
