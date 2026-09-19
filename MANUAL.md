# Sartoria manual

This is page one. The lab VM has a Phase B session. The ISO does not exist until Phase D. Keep this file honest.

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
3. `startx` runs automatically on tty1 only.
4. Super+Return opens a terminal. Super+Space opens the launcher.

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

Super is the modkey (Windows key).

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
