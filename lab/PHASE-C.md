# Phase C result

Recorded 2026-09-19. Fresh VM `lab/images/sartoria-c.qcow2` — the Phase B disk was not reused.

| Check | Result |
| --- | --- |
| Install | stock Devuan 6 Excalibur netinstall, then **one** package: `sartoria-desktop` 0.0.1 |
| PID 1 | sysvinit |
| Display | XLibre (`xdpyinfo` vendor string) |
| WM | herbstluftwm 0.9.5 from packaged autostart |
| Helpers | polybar, picom, dunst, pipewire up |
| Terminal | alacritty spawned into a frame |
| CLI | `sartoria` 0.0.1 |
| Login files | `~/.xinitrc` execs `sartoria-session`; tty1 auto-startx |

XLibre is a Recommends. The metapackage ships `/etc/apt/sources.list.d/xlibre-debian.sources` signed by `/usr/share/keyrings/sartoria-xlibre.pgp`. After `apt-get install ./sartoria-desktop.deb`, run `apt-get update && apt-get install xlibre` (cannot `apt-get` from `postinst` while apt holds the lock).

```bash
./scripts/build-sartoria-desktop.sh
LAB_NAME=sartoria-c ./scripts/lab-install.sh    # first time only
LAB_NAME=sartoria-c ./scripts/lab-phase-c.sh
LAB_NAME=sartoria-c ./scripts/lab-ssh.sh
```

SSH port 2223, VNC `127.0.0.1:5902`.
