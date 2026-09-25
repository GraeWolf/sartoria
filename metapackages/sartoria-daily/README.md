# sartoria-daily

File manager and screenshots (Phase F4). Not a VM package. Not on the installer ISO. No third-party repo. The session is X11.

Nautilus is the file manager (Excalibur 48, GTK4). Super+e runs `sartoria-files`. It tiles. Dialogs use the existing DIALOG rule. Screenshots are `maim` plus `xclip`: Super+p selects a region, Super+Shift+p grabs the whole screen, both save under `~/Pictures/Screenshots` and copy the PNG.

`sartoria-desktop` pins `hyprland`, `hyprpolkitagent`, and `xdg-desktop-portal-hyprland` to priority -1. This session does not install them.

Laptop DPI is `sartoria-dpi` in `sartoria-desktop`, not this package. A panel at or above 140 DPI gets `Xft.dpi: 144` on the next `startx`. This G15 measures about 189, so it gets 144. A VM stays at 96. `SARTORIA_DPI` in `~/.xinitrc` overrides that.

```bash
./scripts/build-sartoria-desktop.sh
./scripts/build-sartoria-daily.sh
sudo apt-get install ./lab/cache/sartoria-desktop_0.0.7_all.deb ./lab/cache/sartoria-daily_0.0.1_all.deb
```

Reload herbstluftwm (Super+Shift+r) for the keybinds. Restart the X session for DPI. Existing `~/.config/herbstluftwm/autostart` is not overwritten.
