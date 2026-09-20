# Sartoria manual

This is page one. v0.1 is the installer ISO. Keep this file honest.

## Install

1. Write `sartoria-*-amd64.iso` to USB (`dd` or similar), or attach it as a CD in a VM.
2. Boot it. GRUB: **Install Sartoria**.
3. Use the **graphical/VGA console**, not serial and not SSH. The TUI is on tty1.
4. TUI asks keyboard, hostname, user, password, **which disk to wipe**, and a YES confirm. Other disks (for example Windows) are not touched. Do not pick the Windows drive.
5. Reboot without the USB/ISO. Log in on tty1. Auto-startx is **off** so a failed X session does not log you out. Run `startx` when you want the desktop.


## Principles

- Finished defaults. The installer should leave a session you can use, not a kit.
- Keyboard first. Super is the modkey. Mouse is optional after login.
- No account required to install or boot.
- Devuan 6 Excalibur is the parent. Sysvinit is PID 1 because that is Devuan’s default.
- Display is XLibre. There is no Wayland session.
- Window manager is herbstluftwm (manual tiling). You split frames; the OS does not pretend to be Hyprland.
- One theme. One terminal (alacritty). One launcher (rofi). One bar (polybar).
- AI is not part of the OS in v0.1. The machine must work with zero API keys.

## What we are not

- Arch, systemd, Hyprland, Wayland
- runit or OpenRC as PID 1
- Calamares
- A live “try before install” desktop (the USB is an installer)
- LCOS’s no-AI rule, 90s Xfce identity, or politics-as-branding
- Omarchy’s “ten agents are the OS”

## Login (installed system)

1. Boot.
2. Log in on tty1 with the user created at install time.
3. You get a shell. Run `startx` for herbstluftwm. If X fails you stay logged in; check `~/.local/share/xorg/Xorg.0.log` or `/var/log/Xorg.0.log`.

Hybrid AMD/NVIDIA (or Intel/NVIDIA): the panel is on the iGPU. Firmware for amdgpu and common Wi‑Fi chips ships on the ISO. `nouveau` is blacklisted until `sartoria-nvidia`. `/tmp/.X11-unix` must be mode `1777` (x11-common).

Wi‑Fi: `sudo nmtui` (needs `wpasupplicant`). If the radio is blocked: `sudo rfkill unblock wifi`. Then `ip link` should show a `wlan` or `wlp` interface.
4. Super+Return (or **Alt+Return** if Super is eaten by the host) opens a terminal. Super+Space / Alt+Space opens the launcher.

SSH sessions and other VTs do not start X.

## Init

```bash
cat /proc/1/comm    # expect: init
readlink -f /sbin/init
# expect a sysvinit binary, not systemd, not runit
```

Do not install `runit-init` or switch to OpenRC.

## Updates

Until `sartoria update` exists (not v0.1):

```bash
sudo apt-get update
sudo apt-get dist-upgrade
```

Stay on `excalibur` + backports + the pinned extra repos. Do not add Freia or Ceres for fun.

## Rescue (development only)

XLibre is third-party. If a lab VM will not start X, rolling back to Xorg is allowed **on the lab machine** while debugging. Sartoria still ships XLibre.

## Bindings

Super is the product modkey. **Alt is bound to the same actions** so a host compositor (Omarchy/Hyprland) that owns Super can still drive a Sartoria VM. Click the VM window, then use Alt.

If Super is stolen and no terminal is open: SSH in and run `DISPLAY=:0 herbstclient spawn alacritty`, or log in on a guest VT and run that. A first login with an empty tag also spawns one terminal.

| Key | Action |
| --- | --- |
| Super+Return | terminal (alacritty) |
| Super+Space | launcher (rofi) |
| Super+q | close window |
| Super+Shift+e | exit session |
| Super+1..9 | use tag |
| Super+Shift+1..9 | move window to tag |
| Super+h/j/k/l | focus |
| Super+Shift+h/j/k/l | move window |
| Super+o / Super+u | split right / split down |
| Super+s | toggle floating |

herbstluftwm is **manual** tiling: you split frames. It will not auto-tile like Hyprland.
