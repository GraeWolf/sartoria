# Phase F — Daily-driver extras

Started 2026-09-20 on **voyager** (ASUS ROG Zephyrus G15 GA503RM). Phase E (hybrid Prime) is closed. This phase is “willing to daily-drive,” not a new ISO gate. v0.1 ISO remains Phase D.

Suggested product order was Origin → LibreOffice → daily bits → games → LUKS last → AI last. **F1 jumped the line:** Alacritty on this machine was falling back to DejaVu Sans (proportional), so letters ran together or showed gaps.

Do **not** LUKS voyager’s current disk first. Firefox ESR can stay until Origin is installed. OS must work with zero AI.

| Id | Item | Status |
| --- | --- | --- |
| F1 | Alacritty / Nerd Font actually installed; monospace, not DejaVu Sans | done (`sartoria-desktop` 0.0.3 on voyager) |
| F-suspend | Lid/s2idle resume: keyboard works; no persistenced boot failure; MM off the login tty | 0.0.9 passed one lid cycle on 2026-09-24 03:40 (keys work, hook re-enumerated `1-3`, backlight restored to 3). AC-plug spam is the Samsung NVMe AER, still open |
| F2 | Brave Origin (pinned Brave apt repo, `brave-origin`) | installed on voyager (`brave-origin` 1.95.104; `brave-browser` pinned to -1) |
| F3 | LibreOffice from Excalibur + floating dialog rules | done (`sartoria-office` 0.0.1, Excalibur 25.2.3, gtk3; Writer tiles, File → Open floats) |
| F4 | File manager, screenshots, laptop DPI | done (`sartoria-desktop` 0.0.7, `sartoria-daily` 0.0.1). Nautilus tiles (`org.gnome.Nautilus`, floating off). `Xft.dpi` is 144. `hyprland` pin -1. Print is bound to `sartoria-shot` |
| F5 | Optional `sartoria-games` (Steam on the dGPU) | installed on voyager (`sartoria-games` 0.0.1, i386, Super+g, Prime offload). "Sign in to Steam" still tiles |
| F6 | Laptop LUKS on the installer ISO | in progress. Interactive LUKS2; unattended lab stays ext4. Not applied to voyager’s disk |
| F7 | Optional `sartoria-ai` (last) | not started |

Not this gate: desktop dGPU, reverse-PRIME HDMI, `sartoria-nvidia` on the v0.1 ISO. `nvidia-persistenced` stays disabled.

## F1 — Terminal font

`sartoria-desktop` 0.0.2 shipped an empty `/usr/share/fonts/truetype/sartoria` because the desktop build only extracted Nerd Fonts if `lab/cache/JetBrainsMonoNerdFont.zip` already existed. It never downloaded the zip. The session config asked for `JetBrainsMono Nerd Font`; `fc-match` returned **DejaVu Sans**.

That is the spacing bug: a proportional font in a terminal cell grid.

Fix in `sartoria-desktop` 0.0.3:

- Build downloads Nerd Fonts v3.4.0 if the zip is missing.
- Package ships Regular + Bold of **Nerd Font** (polybar/rofi/GTK) and **Nerd Font Mono** (Alacritty).
- Alacritty uses `JetBrainsMono Nerd Font Mono` (Nerd Fonts’ monospaced flavor; icons stay inside the cell).
- fontconfig aliases those families through `JetBrains Mono` then `monospace`, never a proportional default.

```bash
fc-match "JetBrainsMono Nerd Font Mono"
# expect: JetBrainsMonoNerdFontMono-Regular.ttf, not DejaVuSans.ttf
fc-match "JetBrainsMono Nerd Font"
# expect: JetBrainsMonoNerdFont-Regular.ttf
```

Restart Alacritty after install. Existing `~/.config/alacritty/alacritty.toml` is not overwritten by `seed-user-config`; copy the family name from `/usr/share/sartoria/config/alacritty/alacritty.toml` if the session was seeded before 0.0.3.

Panel is 2560×1440 at ~189 DPI; `Xft.dpi` is still 96. That makes glyphs small, not unevenly spaced. DPI is F4 if 96 is wrong for daily use.

## F-suspend — Lid resume and boot console

Recorded after F1, before F2 install. Closing the lid (elogind s2idle; this G15 has no S3/deep) came back with a dead keyboard. Power button (ACPI) still worked; USB HID `0b05:19b6` on Rembrandt xHCI `07:00.3` did not. Force power-off was the only recovery.

Cause: NVIDIA’s `nvidia-suspend.service` units are systemd-only. elogind never wrote `/proc/driver/nvidia/suspend`, `NVreg_PreserveVideoMemoryAllocations` was off (sartoria 0.0.2 said it “breaks Optimus”), and S0ix was off even though the 3060 Mobile reports VRAM self-refresh. The dGPU did not park; USB on the APU did not come back.

Boot tty1 also showed:

- `startpar: service(s) returned failure: nvidia-persistenced ... failed!` — vendor sysv script is `S01` in rc2, `#!/bin/sh -e`, nvidia.ko not ready. Persistence mode is the wrong default on hybrid anyway (blocks runtime D3).
- ModemManager “couldn't check support” for `03:00.0` / `04:00.0` — those are RTL8125 ethernet and MT7922 Wi-Fi. `80-mm-candidate.rules` marks every net device. No syslog daemon, so the lines print on the login prompt.

`sartoria-nvidia` 0.0.3 was installed and made lid-close **worse**. Two bugs:

1. Debian’s `nvidia-modprobe.conf` is `install nvidia modprobe -i nvidia-current $CMDLINE_OPTS`. `options nvidia NVreg_...` never reaches the DKMS module (`nvidia-current.ko`). `/proc/driver/nvidia/params` stayed `PreserveVideoMemoryAllocations: 0`.
2. elogind `HandleNvidiaSleep=yes` does `chvt 63` then writes `/proc/driver/nvidia/suspend`. On this hybrid (panel on AMD, NVIDIA is a GPU screen only) that hangs: not s2idle, black screen, USB keyboard dead. Same class as elogind issue #234.

`sartoria-nvidia` 0.0.4:

- `options nvidia-current NVreg_PreserveVideoMemoryAllocations=1` (and S0ix, TemporaryFilePath)
- `options nvidia-current-drm modeset=1`
- GRUB cmdline `nvidia.NVreg_*` as a second path
- `HandleNvidiaSleep=no`
- `/usr/libexec/system-sleep/sartoria-nvidia` writes suspend/resume **without** chvt, 30s timeout, then re-authorizes USB `0b05:19b6` (resets Rembrandt xHCI `07:00.3` if the keyboard is gone)
- persistenced stays disabled

`sartoria-desktop` 0.0.4 (already on voyager): rsyslog + MM udev ignore.

```bash
./scripts/build-sartoria-nvidia.sh
sudo apt-get install ./lab/cache/sartoria-nvidia_0.0.4_all.deb
sudo reboot
```

After reboot, **before** another lid test:

```bash
grep PreserveVideoMemoryAllocations /proc/driver/nvidia/params
# must be 1. If it is still 0, stop; do not close the lid.
cat /proc/cmdline
# expect nvidia.NVreg_PreserveVideoMemoryAllocations=1
```

0.0.4 did set PVMA=1 (`nvidia-current` + cmdline). It also made `nvidia-current-drm modeset=1` actually apply. XLibre then auto-added `/dev/dri/card1` as `modeset(G0)` while the nvidia DDX added `NVIDIA(G1)`. `startx` died with `Failed to acquire modesetting permission` / `drmSetMaster failed: Permission denied`.

0.0.5 sets `AutoAddGPU false` so only the nvidia DDX owns the offload GPU screen. xorg.conf.d is read at `startx`; no extra reboot is required for that file.

```bash
./scripts/build-sartoria-nvidia.sh
sudo apt-get install ./lab/cache/sartoria-nvidia_0.0.5_all.deb
startx
```

0.0.5: `startx` worked (`AutoAddGPU false`). Lid close did **not** sleep: fans ramped, chassis got hot, lid open had dead keyboard and trackpad. Cause: `/usr/libexec/system-sleep/sartoria-nvidia` wrote `suspend` to `/proc/driver/nvidia/suspend` with `PreserveVideoMemoryAllocations=1`. That path busy-loops the dGPU instead of entering s2idle on this hybrid.

Also at boot: `modprobe: FATAL: Module nvidia not found` from `modules-load.d/sartoria-nvidia.conf` (`nvidia` / `nvidia-drm`). DKMS files are `nvidia-current*.ko`; udev already loads them from PCI aliases.

0.0.6:

- drop `modules-load.d` (and `rm` leftover on upgrade)
- `NVreg_EnableS0ixPowerManagement=1` only (no PVMA, no TemporaryFilePath)
- sleep hook is **post-resume only**: re-authorize USB `0b05:19b6`, rebind i2c-HID touchpad, reset xHCI if the keyboard is gone
- GRUB cmdline is only `nvidia.NVreg_EnableS0ixPowerManagement=1`

```bash
./scripts/build-sartoria-nvidia.sh
sudo apt-get install ./lab/cache/sartoria-nvidia_0.0.6_all.deb
sudo reboot
```

After reboot, **before** a lid test:

```bash
grep EnableS0ixPowerManagement /proc/driver/nvidia/params   # 1
grep PreserveVideoMemoryAllocations /proc/driver/nvidia/params   # 0
test ! -e /etc/modules-load.d/sartoria-nvidia.conf && echo 'no fake nvidia modules-load'
```

Lid close must actually idle (fans down, not hotter). Open: keyboard and trackpad work. If fans spin up again, stop; that is still a failed suspend, not a resume bug.

0.0.6 did sleep, but the hook always toggled USB `authorized` on `0b05:19b6`. That re-enumerates hid_asus and sets `asus::kbd_backlight` to 0. 0.0.7 saves the brightness on `pre`, only resets xHCI if the keyboard is gone, and restores the LED on `post`. Upgrade from 0.0.6 turns the LED back on once (level 3).

```bash
sudo apt-get install ./lab/cache/sartoria-nvidia_0.0.7_all.deb
```

No reboot required for the hook. If the keys are dark now: `echo 3 | sudo tee /sys/class/leds/asus::kbd_backlight/brightness` (postinst does that when upgrading from < 0.0.7).

0.0.7 left the keys dead again. The ITE device (`0b05:19b6` on xHCI `07:00.3`) was still in sysfs after s2idle, so the hook skipped the reset, but the reports had stopped. There is also an i8042 AT keyboard with a full keymap; 0.0.7 never touched it. 0.0.8 always de-authorizes and re-authorizes the ITE device (xHCI reset only if that node is gone), resets `serio0`, then writes the saved backlight back. Re-enumeration still zeros the LED; the restore is what puts it back.

```bash
./scripts/build-sartoria-nvidia.sh
sudo apt-get install ./lab/cache/sartoria-nvidia_0.0.8_all.deb
```

No reboot. Close the lid, wait until the fans drop, open it, and type. `grep sartoria-nvidia /var/log/syslog` should show `re-enumerate ASUS keyboard` and `kbd backlight -> N`. If the fans ramp and the chassis heats, that is still a failed suspend, not this resume bug.

0.0.8 was installed and the lid test failed. On open, the console showed:

```
atkbd serio0: Failed to deactivate keyboard on isa0060/serio0
```

three times in one boot (kernel timestamps 4636s, 5030s, 23121s). That is `ATKBD_CMD_RESET_DIS` (0xF5). The kernel sends it from `atkbd_reconnect` on every resume, and 0.0.8 also ran `echo reset` on `serio0`, which does the same reconnect. Keyboards that reject 0xF5 stop responding until a hard power-off. A warm reboot is not enough.

After that reboot, plugging AC back in made the session stall (touchpad log: "your system is too slow" from 02:40) and switching to tty2 at 02:53 showed a scrolling kernel flood. X exited cleanly on the VT switch. The flood is in `/var/log/kern.log` (adm-only, ~25 MB). 0.0.9's postinst writes a readable count to `/var/log/sartoria-kern-excerpt.txt`.

0.0.9:

- resume hook no longer touches i8042
- still re-enumerates the ITE keyboard and restores the backlight
- `i8042.dumbkbd=1` so the kernel's own resume path does not send 0xF5
- `/var/log/sartoria-sleep.log` (mode 644) and `kern.err` copied to `/var/log/sartoria-kern.log`

```bash
./scripts/build-sartoria-nvidia.sh
sudo apt-get install ./lab/cache/sartoria-nvidia_0.0.9_all.deb
sudo reboot
```

After reboot, before a lid test: `grep dumbkbd /proc/cmdline`. If the login keyboard is dead, remove `i8042.dumbkbd=1` from the GRUB entry. Do not close the lid until the parameter is on the command line.

2026-09-24 03:40, one lid cycle on 0.0.9 with `i8042.dumbkbd=1`: the machine slept, woke, and the keyboard worked. `/var/log/sartoria-sleep.log` shows `re-enumerate ASUS keyboard 1-3` and `kbd backlight -> 3`. AT keyboard, USB keyboard, and the touchpad were all present afterward. No `Failed to deactivate` on that resume.

The AC-plug console flood is the Samsung NVMe `144d:a80a` at `0000:02:00.0` (bridge `00:01.2`): `pcieport 0000:00:01.2: AER: Multiple Correctable error message received from 0000:02:00.0`, from 02:39 through the tty switch at 02:53. Not the keyboard. Left as-is for this pass.

## F2 — Brave Origin

`sartoria-origin` 0.0.1: signed Brave release repo at `/etc/apt/sources.list.d/sartoria-brave.sources`, key `/usr/share/keyrings/sartoria-brave.gpg` (Sartoria path so it does not clash with `brave-keyring`), apt pin allows `brave-origin` + `brave-keyring` and sets `brave-browser` to priority -1. Helper `/usr/bin/sartoria-browser` execs `brave-origin-stable`. Super+b is bound when that helper exists.

Not on the v0.1 ISO. Not `curl | sh`. Firefox ESR may stay. `postinst` cannot `apt-get` (same as XLibre).

```bash
./scripts/build-sartoria-origin.sh
sudo apt-get install ./lab/cache/sartoria-origin_0.0.1_all.deb
sudo apt-get update
sudo apt-get install brave-origin
```

Exit F2: `dpkg -s brave-origin` is `ii`, `command -v brave-origin-stable`, `apt-cache policy brave-browser` is not installable (pin -1), Super+b opens Origin.

## F3 — LibreOffice

`sartoria-office` 0.0.1: Depends on Excalibur `libreoffice` + `libreoffice-gtk3`. No extra apt source. gtk3 VCL is what makes file/options dialogs set a window type (or a fixed size) herbstluftwm can float.

`sartoria-desktop` 0.0.6: no extra LibreOffice class rules. gtk3 VCL makes File → Open a `_NET_WM_WINDOW_TYPE_DIALOG` (`WM_CLASS` soffice/Soffice, role `GtkFileChooserDialog`), which the existing DIALOG/UTILITY/SPLASH rule already floats. Writer/Calc stay tiled.

Do not add `class=Soffice` or `class=libreoffice`: the document first-maps with those classes and stays floating after it becomes `libreoffice-writer`. Same sticky-float if you match `libreoffice-*` + `fixedsize`.

Excalibur candidate is `4:25.2.3-2+deb13u6` (priority 500). Backports has 26.8 at priority 100; do not pull it.

Not on the v0.1 ISO.

```bash
./scripts/build-sartoria-desktop.sh
./scripts/build-sartoria-office.sh
sudo apt-get install ./lab/cache/sartoria-desktop_0.0.6_all.deb ./lab/cache/sartoria-office_0.0.1_all.deb
```

`seed-user-config` does not overwrite `~/.config/herbstluftwm/autostart`. If that file still has `class=Soffice` or `class=libreoffice` floating rules, remove them and Super+Shift+r.

Exit F3: `dpkg -s libreoffice` is `ii`, `dpkg -s libreoffice-gtk3` is `ii`, Writer tiles, File → Open floats (or Super+s if a dialog is missed).

## F4 — File manager, screenshots, laptop DPI

`sartoria-desktop` 0.0.7 adds `sartoria-dpi`. The shipped `Xft.dpi` stays 96, which is right for the VM. On session start the helper measures the primary output. This panel is `eDP-1` 2560×1440 at 344×194 mm, about 189 DPI. Anything at or above 140 DPI gets **144** (1.5×). 192 would turn the tiling workspace into 720p. `SARTORIA_DPI` in `~/.xinitrc`, exported before `sartoria-session`, wins, including `96`. An `Xft.dpi` other than 96 already in the resource database is left alone.

DPI applies on the next `startx`. Reloading herbstluftwm does not re-run it. Open windows keep the DPI they started with.

`sartoria-daily` 0.0.1, not on the v0.1 ISO, no third-party repo:

- **Nautilus** (`sartoria-files`). Super+e and Alt+e. Excalibur 48. It tiles. Dialogs use the existing DIALOG rule. Do not add a `class=Nautilus` floating rule.
- **Screenshots** (`sartoria-shot`, `maim`, `xclip`). Print selects a region. Shift+Print grabs the whole screen. The cursor is hidden. The PNG goes to `~/Pictures/Screenshots` and the clipboard. `SARTORIA_SCREENSHOT_DIR` overrides the directory.
- **No Hyprland.** `sartoria-desktop` pins `hyprland`, `hyprpolkitagent`, and `xdg-desktop-portal-hyprland` to -1. Apt on this machine was willing to select `hyprpolkitagent` from backports as a polkit agent. This session is X11.

```bash
./scripts/build-sartoria-desktop.sh
./scripts/build-sartoria-daily.sh
sudo apt-get install ./lab/cache/sartoria-desktop_0.0.7_all.deb ./lab/cache/sartoria-daily_0.0.1_all.deb
```

`seed-user-config` does not overwrite `~/.config/herbstluftwm/autostart`. Reload (Super+Shift+r) after that file has the new binds. Then restart X and check `xrdb -query | grep dpi` is `144` on this panel, and `sartoria-dpi measure` prints the physical DPI (189 here).

Exit F4: `dpkg -s nautilus` and `dpkg -s maim` are `ii`; `apt-cache policy hyprland` is not installable (pin -1); Super+e opens Nautilus tiled; Print writes a PNG and the clipboard; after a new `startx`, `Xft.dpi` is 144 on this panel and would stay 96 on a VM.

2026-09-24 on voyager: `sartoria-desktop` 0.0.7 and `sartoria-daily` 0.0.1 are installed. `sartoria-files` mapped Nautilus (`org.gnome.Nautilus`) tiled. `xrdb` reports `Xft.dpi: 144`. `hyprland` and `hyprpolkitagent` are pin priority -1. Print and Shift+Print are bound to `sartoria-shot`. `maim` plus `xclip` produced an `image/png` clipboard target.

## F5 — Steam

`sartoria-games` 0.0.1. Not on the v0.1 ISO. NVIDIA Prime is already on this machine (`sartoria-nvidia` 0.0.9), so games can offload.

Excalibur `steam-installer` 1:1.0.0.83~ds-3 (contrib) is a downloader plus the library set. `steam-libs-i386` is invisible until i386 is enabled:

```bash
sudo dpkg --add-architecture i386
sudo apt-get update
./scripts/build-sartoria-desktop.sh
./scripts/build-sartoria-games.sh
sudo apt-get install ./lab/cache/sartoria-desktop_0.0.8_all.deb ./lab/cache/sartoria-games_0.0.1_all.deb
```

`sartoria-desktop` 0.0.8 is the session autostart with the Steam rules. `sartoria-steam` execs `sartoria-nvidia-run steam`, so the client and its games use the 3060. Super+g and Alt+g. “Steam (NVIDIA)” is the offload menu item. The upstream “Steam” item is still the iGPU client.

Depends also pulls `steam-devices`, `nvidia-driver-libs:i386`, `nvidia-vulkan-icd:i386`, and `xdg-desktop-portal-gtk` (already installed here; the X11 portal, so apt does not pick a Wayland backend).

Dialog rules match titles on class `steam` / `Steam` / `steamwebhelper`: Friends, Friends List, Steam Dialog, settings, ` - Chat`, Properties, Progress. They do not float every `class=Steam` window. The library stays tileable. The generic DIALOG rule still covers typed dialogs.

`seed-user-config` does not overwrite `~/.config/herbstluftwm/autostart`. Reload after that file has the new bind and rules. The first `sartoria-steam` downloads the client into the home directory.

Exit F5: `dpkg -s steam-installer` is `ii`, `dpkg --print-foreign-architectures` includes `i386`, Super+g starts Steam through `sartoria-nvidia-run`, a Steam dialog with one of those titles floats, and the library window can tile.

2026-09-24 on voyager: `sartoria-desktop` 0.0.8 and `sartoria-games` 0.0.1 are installed. i386 is enabled. Super+g and Alt+g spawn `sartoria-steam`. The running client has `__NV_PRIME_RENDER_OFFLOAD=1`. The first window is class `steam`, title "Sign in to Steam", and it is tiled. That title is not in the float rules.

## F6 — LUKS on the installer ISO

The interactive installer asks whether to encrypt the root. Yes builds this layout:

| Partition | Size | Filesystem |
| --- | --- | --- |
| bios_grub | 1M | GRUB BIOS boot |
| EFI | 512M | vfat, unencrypted |
| boot | 1G | ext4, unencrypted |
| cryptroot | rest | LUKS2, ext4 inside (`sartoria_crypt`) |

The passphrase is separate from the login password (8 or more characters). GRUB reads the kernel from the plain `/boot`. `cryptsetup-initramfs` asks for the passphrase once. `crypttab` is `sartoria_crypt UUID=… none luks,discard`. No is the v0.1 layout (BIOS boot, EFI, one ext4 root). `sartoria.auto=1` always takes No, so the lab ISO test does not stop for a passphrase.

`scripts/build-iso.sh` installs `cryptsetup`, `cryptsetup-initramfs`, and `console-setup` into the image so the passphrase prompt can use the chosen keymap. Build it on this laptop with `./scripts/lab-build-iso.sh`. The output is `lab/iso/sartoria-0.0.1-amd64.iso`. The build chroot is not voyager's root disk.

Exit F6: an encrypted install boots on a spare disk or VM, the initramfs accepts the passphrase, and the root is `/dev/mapper/sartoria_crypt`. The unattended install still has no `crypttab`. Do not point the installer at voyager’s current root until that boot has been proved.

## Later

- **F7.** `sartoria-ai` last and optional.

## Exit

Willing to daily-drive this G15.
