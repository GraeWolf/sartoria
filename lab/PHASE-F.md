# Phase F — Daily-driver extras

Started 2026-09-20 on **voyager** (ASUS ROG Zephyrus G15 GA503RM). Phase E (hybrid Prime) is closed. This phase is “willing to daily-drive,” not a new ISO gate. v0.1 ISO remains Phase D.

Suggested product order was Origin → LibreOffice → daily bits → games → LUKS last → AI last. **F1 jumped the line:** Alacritty on this machine was falling back to DejaVu Sans (proportional), so letters ran together or showed gaps.

Do **not** LUKS voyager’s current disk first. Firefox ESR can stay until Origin is installed. OS must work with zero AI.

| Id | Item | Status |
| --- | --- | --- |
| F1 | Alacritty / Nerd Font actually installed; monospace, not DejaVu Sans | done (`sartoria-desktop` 0.0.3 on voyager) |
| F-suspend | Lid/s2idle resume: keyboard works; no persistenced boot failure; MM off the login tty | 0.0.6 s2idle+keys work; 0.0.6 zeroed kbd backlight (USB reset). 0.0.7 restores LED |
| F2 | Brave Origin (pinned Brave apt repo, `brave-origin`) | package in tree; install on voyager needs sudo |
| F3 | LibreOffice from Excalibur + floating dialog rules | done (`sartoria-office` 0.0.1, Excalibur 25.2.3, gtk3; Writer tiles, File → Open floats) |
| F4 | Remaining daily bits (file manager, screenshots, laptop DPI) | not started |
| F5 | Optional `sartoria-games` | not started |
| F6 | Laptop LUKS profile on a **spare** disk / second install | not started |
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

## Later

- **F4.** Daily bits only after the terminal, browser, and office do not block work.
- **F5.** `sartoria-games` after NVIDIA; optional.
- **F6.** LUKS installer profile. Prove on a spare disk. v0.1 stays whole-disk ext4, no encryption.
- **F7.** `sartoria-ai` last and optional.

## Exit

Willing to daily-drive this G15.
