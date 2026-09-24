# sartoria-games

Steam on the hybrid laptop (Phase F5). Not a VM package. Not on the installer ISO.

Excalibur `steam-installer` (contrib) downloads the Steam client. It needs the i386 architecture before apt can see `steam-libs-i386`. `sartoria-steam` runs that client under `sartoria-nvidia-run`, so Steam and the games it starts use the dGPU. The desktop session stays on the iGPU. Super+g is the launch path. The upstream “Steam” menu item does not offload; “Steam (NVIDIA)” does.

32-bit games need `nvidia-driver-libs:i386` and `nvidia-vulkan-icd:i386`. `steam-devices` covers controllers.

Steam dialogs use the same window class as the library. Rules match titles (Friends, settings, chat, properties, progress), not `class=Steam`, so the library can tile.

Enable i386, then install:

```bash
sudo dpkg --add-architecture i386
sudo apt-get update
./scripts/build-sartoria-desktop.sh
./scripts/build-sartoria-games.sh
sudo apt-get install ./lab/cache/sartoria-desktop_0.0.8_all.deb ./lab/cache/sartoria-games_0.0.1_all.deb
```

Reload herbstluftwm (Super+Shift+r). Existing `~/.config/herbstluftwm/autostart` is not overwritten by the package.
