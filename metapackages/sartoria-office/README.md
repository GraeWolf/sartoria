# sartoria-office

LibreOffice from Excalibur (Phase F3). Not a VM package. Not on the installer ISO. No third-party repo.

Depends on `libreoffice` and `libreoffice-gtk3` (GTK VCL so file/options dialogs set `_NET_WM_WINDOW_TYPE_DIALOG`). Document windows stay tiled. Do not add `class=Soffice` or `class=libreoffice` rules: the document first-maps with those classes and stays floating.

Excalibur’s `libreoffice` is 25.2 (priority 500). Do not pull 26 from `excalibur-backports` (priority 100) unless you mean to.

```bash
./scripts/build-sartoria-desktop.sh
./scripts/build-sartoria-office.sh
sudo apt-get install ./lab/cache/sartoria-desktop_0.0.6_all.deb ./lab/cache/sartoria-office_0.0.1_all.deb
```

Reload herbstluftwm (Super+Shift+r). Existing `~/.config/herbstluftwm/autostart` is not overwritten; if it still has `class=Soffice` or `class=libreoffice` floating rules, remove them so Writer tiles.
