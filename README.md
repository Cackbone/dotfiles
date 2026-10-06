# dotfiles — synthwave rice

Arch Linux · **niri** (scrollable-tiling Wayland) or **driftwm** (infinite 2D canvas) · waybar · kitty · rofi · mako · swaylock
The old **i3 / polybar / picom** session is kept as a fallback (pick it at the LightDM login screen).

## Install

```sh
git clone --recursive git@github.com:Cackbone/dotfiles.git
cd dotfiles
./install.sh --packages   # pacman -S packages.txt, then stow everything
```

Every directory at the top level is a [GNU Stow](https://www.gnu.org/software/stow/) package that mirrors `$HOME`
(`niri/.config/niri/config.kdl` → `~/.config/niri/config.kdl`). Files in `~/.config` are symlinks into this repo,
so editing the live config *is* editing the repo; `git status` shows what changed.

| Package | What |
|---|---|
| `niri` | compositor, keybinds (AZERTY, same jklm as i3), outputs, window rules |
| `driftwm` | 2D canvas session (AUR `driftwm`): same keys, colors, bar and wallpaper as niri; `driftwm --check-config`. Each screen is its own canvas (its own far-apart area). Helpers in `.config/driftwm/`: `arrange-cameras.sh` (screen areas, at login), `desktop.sh` (desktops 1–5 per screen), `nav.py` (Mod+arrows, on to the next screen at the edge), `refocus.py` (after a close, centre the closest window on that screen), `guard.py` (a screen pulled into another's area by Alt-Tab, the taskbar or a focus request goes back, and the mouse moves to the window's own screen instead: no mirrored screens), `bar-events.py` (refreshes the bar's desktop and window pills, which show only this screen's existing desktops and the windows of its current one), `showcase.py` (a showcase of windows on the big screen — fastfetch, btop, yazi, clock, keys, player, Claude usage: arrange them, `Mod+Shift+F8` saves the layout to `showcase.json` (positions, sizes, the screen's view and zoom), `Mod+F8` puts it back, and it opens by itself at login when that screen is connected) |
| `waybar` | floating pill bar: per-screen desktop and window pills, a music pill (cover, live equalizer — or the icon of the device Spotify plays on — title / artist; click: play/pause, right-click: `nowplaying`, scroll: next/previous), DSEG7 clock; the Arch button is an overview of that screen |
| `kitty` | terminal + `synthwave.conf` palette |
| `fastfetch` | system info with the dithered portrait (kitty image protocol) |
| `fish` | prompt and colors; `fastfetch` sized to the window (redrawn on resize; `fastfetch -w` watch mode keeps the portrait in place and drops lines in short windows); `ne` / `nee` open Emacs (quick window / IDE layout, see `dot-emacs`) |
| `rofi` | launchers/applets (adi1090x); `launchers/type-6/synthwave.rasi` is the one bound to `Mod+D` |
| `mako`, `swaylock` | notifications, lock screen |
| `wireplumber` | PipeWire session manager limited to video (audio stays on PulseAudio): needed for screen recording / sharing on Wayland (Kooha, OBS, browsers) through `xdg-desktop-portal-wlr` |
| `portal` | `xdg-desktop-portal-wlr` config: pick the screen to record / share by clicking it (themed slurp) |
| `nowplaying` | `~/.local/bin/nowplaying`: just the current track (cover, title, progress, keys) for spotify_player / Spotify via MPRIS — `Mod+F7`, or right-click the music pill. Also `music-ctl` (playerctl for the bar, nowplaying and media keys: wakes Spotify up when it has dropped an idle session — "no playback found" — and makes sure play/pause really happen, re-sending them when Spotify's rate limiting drops them) and `spotify-state` (one shared, rate-friendly playback query for the bar and nowplaying) |
| `btop`, `cava` | synthwave themes |
| `gtk` | GTK3/GTK4 synthwave colors on Adwaita-dark (Thunar, pavucontrol, file dialogs); icons: Papirus-Synthwave |
| `yazi` | terminal file manager theme (`Mod+E`) |
| `fonts` | `~/.local/share/fonts`: DSEG7 Classic (seven-segment clock in waybar, SIL OFL, license included) |
| `fontconfig` | JetBrains Mono Nerd Font + Noto Color Emoji fallback |
| `firefox` | `userChrome.css`/`userContent.css` + `user.js`, linked into the default profile by `install.sh`; video decoded by the Intel GPU, AV1 off (see `chromium`) |
| `chromium` | `chromium-flags.conf`: video decoded by the Intel GPU (VA-API), AV1 off so YouTube sends VP9 (the GPU can't decode AV1) |
| `lightdm` | login screen theme (GTK greeter): **not stowed**, install with `sudo lightdm/install.sh` |
| `boot` | rEFInd boots Arch directly (hold a key for the menu) + Plymouth splash with the portrait: **not stowed**, `sudo boot/install.sh` |
| `claude` | Claude Code theme (`/theme` → Synthwave) and status line (wrapping pills: model, folder, branch, context, 5-hour session; in Emacs only the model, the bars go to the Claude window's mode line). It also saves each session's quotas for `clawd` |
| `clawd` | `Mod+F9`: Claude plan usage (session, weekly, per-model, credits) with an animated Clawd, awake while a Claude Code session works (hooks in `claude/.claude/hooks/`) |
| `wallpapers` | `~/.local/share/wallpapers`: background, 2× upscale, lock image, portrait |
| `scripts/papirus-synthwave.sh` | builds `~/.local/share/icons/Papirus-Synthwave` (Papirus-Dark + magenta folders), run by `install.sh` |
| `dot-emacs` | submodule: the Emacs config ([camron](https://github.com/Cackbone/camron-theme) theme, treemacs on `F8`, Claude Code on `F9`, `nee` = IDE layout), linked by `install.sh` (`init.el`, `README.org` → `~/.emacs.d/config.org`, `camron-theme.el`) |
| `autostart` | hides nm-applet and picom's XDG autostart entries in the Wayland sessions |
| `i3`, `polybar`, `picom`, `background`, `xfce4` | X11 fallback session |

## Keys (niri)

| Keys | Action |
|---|---|
| `Mod+Tab` / `Mod+O` | overview (zoom out over the canvas) |
| `Mod+J/M`, `Mod+←/→` | focus column left / right |
| `Mod+K/L`, `Mod+↓/↑` | focus window down / up in column |
| `Mod+Shift+…` | move instead of focus |
| `Mod+& é " ' ( - è _ ç` | workspace 1–9 (`+Shift` to send the column) |
| `Mod+R` / `Mod+F` / `Mod+Shift+F` | cycle width / maximize column / fullscreen |
| `Mod+,` / `Mod+;` | pull window into / push out of the neighbouring column |
| `Mod+Z` | tabbed column |
| `Mod+Return` / `Mod+D` / `Mod+V` | kitty / launcher / clipboard history |
| `Mod+E` / `Mod+F3` | yazi / Thunar |
| `Print`, `Mod+F4` | screenshot (region) |
| `Mod+Alt+L` | lock |
| `Mod+Shift+,` | cheat sheet of all binds |

## Keys (driftwm)

| Keys | Action |
|---|---|
| `Mod+←↓↑→` / `Mod+J K L M` | nearest window in that direction on this screen; at the edge, on to the next screen (`nav.py`) |
| `Mod+Shift+…` | nudge the window |
| `Mod+Ctrl+arrows`, `Mod+drag`, drag empty canvas | pan the canvas |
| `Mod+scroll`, `Mod+=` / `Mod+-`, pinch | zoom |
| `Mod+Tab` / `Mod+O` / `Mod+W` | overview of the current desktop (again to come back); `Mod+Z` / `Mod+à` 100% |
| `Mod+A` | jump home (canvas origin) and back |
| `Mod+& é " ' (` | desktop 1–5 of this screen, each screen has its own (same key / `Mod+²` = previous; `+Shift` sends the window) — `driftwm/.config/driftwm/desktop.sh` |
| `Mod+Shift+Ctrl+←→` | send the window to the next screen |
| `Mod+R` | resize mode like i3: arrows / `j k l m` (40px, `Shift` = 10px), `Esc` to leave (`resize-mode.sh`) |
| `Mod+F` / `Mod+Shift+F` / `Mod+G` | fullscreen / fit to screen / fill free space |
| `Alt+Tab` | recent windows |
| `Mod+Return` / `Mod+D` / `Mod+E` / `Mod+V` | kitty / launcher / yazi / clipboard |
| `Print`, `Mod+F4` | region screenshot (saved to `~/Pictures/Screenshots` and copied) |
| `Mod+F7` / `Mod+F9` | now playing / Claude usage |
| `Mod+F8` / `Mod+Shift+F8` | showcase layout on the big screen: restore / save |
| media keys | play/pause, next, previous (`music-ctl`), volume (`pactl`) |
| `Mod+Q`, `Mod+Shift+A` | close window · `Mod+Ctrl+Shift+Q` quit |

## Not in this repo

- `~/.config/spotify-player/app.toml` (it holds the Spotify app's client ID). Keep
  `playback_refresh_duration_in_ms = 0`: polling Spotify's Web API every few seconds exhausts a
  developer app's quota, and play/pause then gets rejected (HTTP 429) for hours.

## Palette

| | | |
|---|---|---|
| deep `#090d17` | navy `#131244` | panel `#1a1a6e` |
| magenta `#e040fb` | purple `#7b2cbf` | border-dim `#3b2a78` |
| cyan `#00bcd4` | ice `#76e6f2` | lime `#69ff47` |
| red `#ff4f79` | yellow `#ffd166` | text `#e8e6ff` / dim `#8b8bc7` |
