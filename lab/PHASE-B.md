# Phase B result

Recorded 2026-09-19 on the Phase A lab VM.

| Check | Result |
| --- | --- |
| PID 1 | sysvinit |
| Display | XLibre (`xdpyinfo` vendor string) |
| WM | herbstluftwm 0.9.5, Super bindings, tags 1–9 |
| Terminal | alacritty spawned into a frame |
| Bar | polybar `sartoria` running |
| Compositor | picom running |
| Notifications | dunst running |
| Audio | pipewire started from the session (sysvinit has no systemd --user) |
| CLI | `sartoria status` 0.0.0-phase-b |
| Font | JetBrainsMono Nerd Font in `~/.local/share/fonts` |
| Theme | Tokyo Night-class on hlwm / polybar / rofi / alacritty / dunst / GTK Adwaita-dark |
| Login | `~/.bash_profile` auto-startx on tty1 only |
| Network | NetworkManager installed and started; lab `eth0` still in `/etc/network/interfaces` (ifupdown) so SSH is not dropped |

Exit B: this VM is a usable tiling desktop (terminal + keyboard), not yet an ISO.
