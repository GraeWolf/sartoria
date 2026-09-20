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
- Terminal font is JetBrainsMono Nerd Font Mono. If letters run together or show random gaps, Alacritty is not using that family (`fc-match "JetBrainsMono Nerd Font Mono"` must not be DejaVu Sans).
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

Hybrid AMD/NVIDIA (or Intel/NVIDIA): the panel is on the iGPU. Firmware for amdgpu and common Wi‑Fi chips ships on the ISO. `nouveau` is blacklisted. Proprietary NVIDIA is **not** on the ISO; after install run `sudo apt-get install sartoria-nvidia` and reboot. `/tmp/.X11-unix` must be mode `1777` (x11-common).

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

## NVIDIA (hybrid laptop)

The session stays on the iGPU. NVIDIA is opt-in per command (Prime render offload).

```bash
sudo apt-get install sartoria-nvidia   # DKMS build; then reboot
sartoria gpu                           # providers, nvidia-smi, default GL
sartoria nvidia glxinfo -B             # must say NVIDIA, not Mesa/llvmpipe
sartoria nvidia glxgears
```

Do not run `nvidia-xconfig`. Do not install Bumblebee. If every window goes black after the driver install, GLX was switched to NVIDIA; `sudo update-glx --set glx /usr/lib/mesa-diverted` and restart the session.

If `apt` reports `dpkg returned an error code (1)` and `nvidia-persistenced` is half-configured: that daemon’s postinst starts before `nvidia.ko` exists. Finish configure without starting it, then reboot:

```bash
sudo sh -c 'printf "%s\n" "#!/bin/sh" "exit 101" > /usr/sbin/policy-rc.d
chmod 755 /usr/sbin/policy-rc.d
dpkg --configure nvidia-persistenced
dpkg --configure -a
rm -f /usr/sbin/policy-rc.d'
```

`sartoria-nvidia` (≥ 0.0.3) then disables the persistenced sysv service. Persistence mode is not used on hybrid laptops (it blocks runtime D3). Do not re-enable it to “fix” a red `startpar` line; the package is supposed to stay off.

This G15 only suspends as **s2idle** (not S3/deep). Lid close is handled by elogind. After `sartoria-nvidia` ≥ 0.0.6, reboot once. `grep EnableS0ixPowerManagement /proc/driver/nvidia/params` must be `1`. Do **not** set `NVreg_PreserveVideoMemoryAllocations` and do not enable elogind `HandleNvidiaSleep`: both hung this machine (black screen or fans-at-full, dead keyboard/trackpad). Debian’s module is `nvidia-current`; a `modules-load.d` line named `nvidia` prints `modprobe: FATAL: Module nvidia not found`. The keyboard is USB HID on the AMD xHCI; the touchpad is i2c-HID. Keyboard backlight is `asus::kbd_backlight` (0–3) via hid_asus. After resume it should return to the pre-suspend level; to set it now: `echo 3 | sudo tee /sys/class/leds/asus::kbd_backlight/brightness`. Hold the power button only as last resort.

Default `glxinfo` must remain the iGPU (Mesa). picom uses xrender so the compositor does not need NVIDIA GL.

Boot text on tty1: `nvidia-persistenced ... failed!` should be gone after 0.0.3. ModemManager lines about `03:00.0` / `04:00.0` are the ethernet and Wi‑Fi cards, not a modem; `sartoria-desktop` ≥ 0.0.4 ignores those devices and installs `rsyslog` so leftover daemon messages do not print on the login prompt.

## Browser (Brave Origin)

Not on the installer ISO. Firefox ESR may stay until Origin is installed. Do not install `brave-browser` (that product has AI).

```bash
./scripts/build-sartoria-origin.sh
sudo apt-get install ./lab/cache/sartoria-origin_0.0.1_all.deb
sudo apt-get update
sudo apt-get install brave-origin
```

`sartoria-origin` enables Brave’s signed release repo and pins `brave-origin` in; `brave-browser` is apt-priority -1. Super+b runs `sartoria-browser` (the Origin binary is `brave-origin-stable`). Reload herbstluftwm (Super+Shift+r) if the bind was missing.

## Rescue (development only)

XLibre is third-party. If a lab VM will not start X, rolling back to Xorg is allowed **on the lab machine** while debugging. Sartoria still ships XLibre.

## Bindings

Super is the product modkey. **Alt is bound to the same actions** so a host compositor (Omarchy/Hyprland) that owns Super can still drive a Sartoria VM. Click the VM window, then use Alt.

If Super is stolen and no terminal is open: SSH in and run `DISPLAY=:0 herbstclient spawn alacritty`, or log in on a guest VT and run that. A first login with an empty tag also spawns one terminal.

If Alacritty glyphs collide or have holes between letters, the Nerd Font is missing and the terminal fell back to a proportional font. Install/rebuild `sartoria-desktop` (≥ 0.0.3), run `fc-cache -f`, point `~/.config/alacritty/alacritty.toml` at `JetBrainsMono Nerd Font Mono`, and open a new terminal.

| Key | Action |
| --- | --- |
| Super+Return | terminal (alacritty) |
| Super+Space | launcher (rofi) |
| Super+b | browser (Brave Origin, after `sartoria-origin`) |
| Super+q | close window |
| Super+Shift+e | exit session |
| Super+1..9 | use tag |
| Super+Shift+1..9 | move window to tag |
| Super+h/j/k/l | focus |
| Super+Shift+h/j/k/l | move window |
| Super+o / Super+u | split right / split down |
| Super+s | toggle floating |

herbstluftwm is **manual** tiling: you split frames. It will not auto-tile like Hyprland.
