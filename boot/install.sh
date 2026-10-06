#!/usr/bin/env bash
# Boot: rEFInd straight to Arch (menu on keypress) + Plymouth splash with the portrait.
#   sudo boot/install.sh
# Every edited file is backed up next to itself as <file>.bak-<date>. Safe to re-run.
set -euo pipefail
cd "$(dirname "$(readlink -f "$0")")/.."
[[ $EUID -eq 0 ]] || { echo "run with sudo" >&2; exit 1; }

stamp=$(date +%Y%m%d-%H%M%S)
backup() { cp -a "$1" "$1.bak-$stamp"; echo "  backup: $1.bak-$stamp"; }

refind=/boot/EFI/refind/refind.conf
mkconf=/etc/mkinitcpio.conf
opts='quiet splash loglevel=3 rd.udev.log_level=3 vt.global_cursor_default=0'

echo "==> rEFInd ($refind)"
backup "$refind"
# boot the default entry immediately; any key held at power-on shows the menu
sed -i -E 's/^timeout[[:space:]]+[0-9-]+/timeout -1/' "$refind"
grep -q '^default_selection' "$refind" || sed -i '/^timeout -1/a default_selection "Arch Linux"' "$refind"
# kernel options for a quiet boot + splash, only inside the "Arch Linux" entry
if ! grep -q 'add_efi_memmap quiet splash' "$refind"; then
    sed -i "/^menuentry \"Arch Linux\"/,/^}/ s/options  \"root=\/dev\/nvme0n1p3 rw add_efi_memmap\"/options  \"root=\/dev\/nvme0n1p3 rw add_efi_memmap $opts\"/" "$refind"
fi
# quiet look: graphics-mode Linux boot (no "Booting OS" text), no menu chrome, navy background
install -Dm644 boot/refind-bg.png /boot/EFI/refind/synthwave-bg.png
# (not "hideui all": that hides the banner too, and rEFInd falls back to a white background)
sed -i '/^hideui all$/d' "$refind"
for line in 'use_graphics_for linux' 'hideui label,hints,arrows,badges,editor,singleuser,safemode,hwtest' 'banner synthwave-bg.png' 'banner_scale fillscreen' 'scanfor manual,external,optical'; do
    grep -qxF "$line" "$refind" || sed -i "/^default_selection/a $line" "$refind"
done
# "Boot to terminal" submenu: no splash there
sed -i 's/add_options "systemd.unit=multi-user.target"$/add_options "systemd.unit=multi-user.target plymouth.enable=0"/' "$refind"
grep -q '^timeout -1' "$refind"                       || { echo "timeout edit failed" >&2; exit 1; }
grep -q '^default_selection "Arch Linux"' "$refind"    || { echo "default_selection edit failed" >&2; exit 1; }
grep -q "add_efi_memmap $opts\"" "$refind"             || { echo "options edit failed" >&2; exit 1; }

echo "==> Plymouth theme"
install -Dm644 -t /usr/share/plymouth/themes/synthwave boot/plymouth/synthwave/*
plymouth-set-default-theme synthwave
# (no "plymouth quit --retain-splash" drop-in: with LightDM + Xorg it froze X on a white screen)
if [[ -e /etc/systemd/system/plymouth-quit.service.d/retain-splash.conf ]]; then
    rm -f /etc/systemd/system/plymouth-quit.service.d/retain-splash.conf
    rmdir --ignore-fail-on-non-empty /etc/systemd/system/plymouth-quit.service.d
    systemctl daemon-reload
    echo "  removed retain-splash drop-in"
fi

echo "==> mkinitcpio ($mkconf)"
backup "$mkconf"
# nvidia modules don't exist for this kernel (and the GPU is compute-only; CUDA loads it on demand).
# i915 early = the splash shows as soon as the kernel starts.
sed -i -E 's/^MODULES=\(.*\)/MODULES=(i915)/' "$mkconf"
grep -qE '^HOOKS=.*\bplymouth\b' "$mkconf" || sed -i -E 's/^HOOKS=\((base systemd)/HOOKS=(\1 plymouth/' "$mkconf"
grep -q '^MODULES=(i915)' "$mkconf"            || { echo "MODULES edit failed" >&2; exit 1; }
grep -qE '^HOOKS=\(base systemd plymouth' "$mkconf" || { echo "HOOKS edit failed" >&2; exit 1; }

mkinitcpio -P

echo
echo "Done. Reboot to see it. If anything looks wrong, hold a key at power-on for the rEFInd menu,"
echo "and restore with the .bak-$stamp files printed above."
