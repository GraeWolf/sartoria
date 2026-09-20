# Sartoria — Design

Canonical design for Sartoria. User-facing overview: [`README.md`](../README.md). Keyboard and daily use: [`MANUAL.md`](../MANUAL.md).

Sartoria is a personal opinionated Linux distribution: a Devuan remix with its own ISO and installer. It is not a Debian fork, not Arch, and not a post-install gist.

---

## 1. Charter

Sartoria is an omakase desktop: finished defaults, keyboard-first tiling, no account required to install or boot.

**Steal from Omarchy:** complete defaults, own ISO, a small unified CLI, a written manual, theme consistency.

**Steal from LCOS:** Devuan parent, XLibre, Brave Origin, no online account, ship a desktop not a kit. Sysvinit is used because it is Devuan’s default, not as branding.

**Reject from Omarchy:** Arch, systemd, Hyprland, Wayland, “ten agents are the OS.”

**Reject from LCOS:** no-AI rule, 90s Xfce as the identity, politics-as-branding.

The name is Italian for tailoring: one cut, not a kit.

---

## 2. Locked decisions

| Topic | Decision |
| --- | --- |
| Name | Sartoria |
| Shape of v1 | Remix parent → own ISO + TUI installer |
| Parent | Devuan 6 Excalibur (`excalibur`, Debian 13 Trixie without systemd) |
| Init | sysvinit as PID 1 (Devuan default; not runit, not OpenRC, not systemd) |
| Display | XLibre only; no Wayland session shipped |
| WM | herbstluftwm (manual tiling, X11). Super is modkey |
| Bindings | Omarchy-ish Super bindings; herbstluftwm frame mechanics |
| Installer | Text TUI only (no Calamares) |
| ISO | Installer-first, like Omarchy; not a live desktop |
| ISO contents | Offline: everything needed to install is on the image |
| Disk (v0.1) | Whole-disk wipe, ext4, no encryption |
| Session start | Console login on tty1, then **manual `startx`**. Auto-startx is off so a failed X (hybrid GPU) does not log you out. No display manager |
| Desktop stack | alacritty, polybar, rofi, dunst, picom |
| v0.1 apps | Session minimum only (no browser, office, or file manager) |
| Packaging | apt/dpkg, `sartoria-desktop` + `sartoria-nvidia` (hardware) |
| Package freshness | Excalibur + `excalibur-backports` + pinned extra repos |
| NVIDIA | Phase E. Hybrid laptop first (Prime offload). Desktop dGPU later. Not on the v0.1 ISO. |
| Browser (later) | Brave Origin (AI stays out of the browser) |
| Office (later) | LibreOffice |
| AI | None in v0.1. OS must work with zero AI config. Optional slot later |
| Audience | Personal first; public repo is fine; no community SLA |
| Daily-driver target | This G15 (hybrid AMD+NVIDIA). VM remains the ISO gate. |
| v0.1 done | ISO installs into a VM and boots the session |
| Build isolation | ISO is built inside a Devuan VM/chroot, not on the host |
| Arch/boot (v0.1) | amd64, UEFI, GRUB; BIOS if live-build gives it cheaply |
| Privileges | One sudo user; root login disabled; sudo asks for the user password |
| Network/audio | NetworkManager + PipeWire; PulseAudio only if PipeWire has no usable sysvinit scripts |
| Shell/editor/font | bash, neovim, JetBrainsMono Nerd Font |
| Theme | One dark, dense, cool-neutral theme (Tokyo Night-class) |
| CLI | `sartoria status`, `help`, `version`; Phase E adds `gpu` and `nvidia` |
| Installer prompts | Username, password, hostname (default `sartoria`), keyboard, **disk to wipe** (menu; other disks untouched), explicit YES confirm. Locale `en_US.UTF-8`. Timezone UTC |
| FDE | Skip on v0.1 VM; later for a laptop profile |
| Gaming | Capable later (`sartoria-games`), after NVIDIA works. Not in the base ISO |

### Non-goals for v1

- Custom kernel
- Own package mirror of all of Devuan
- Wayland
- Mandatory LUKS
- Linux From Scratch
- Switching init away from Devuan’s default
- Replacing the current host OS before a VM boots cleanly
- Calamares
- A live “try Sartoria” desktop on the USB
- Theme store, agent zoo, or updater wrapper

---

## 3. What “remix” means

Consume Devuan packages. Overlay only Sartoria packages, branding, session, installer, and a short pin list of third-party repos (XLibre; later Brave, NVIDIA).

Do not fork the archive. Do not move the whole OS to Freia (testing) or Ceres (sid). If a specific package is too old, backport or vendor **that package**.

### Allowed extra repos (pinned, documented, signed)

1. XLibre Devuan repo (`xlibre-debian/devuan`). Excalibur **requires backports** for this repo.
2. Later: Brave’s official repo for Origin.
3. Later: NVIDIA if Devuan’s `nvidia-driver` is insufficient.

Rollback of XLibre to Xorg is a **development rescue**, not a shipped session.

---

## 4. Architecture

```
USB ISO (installer-first, offline)
  └─ console TUI installer
        ├─ prompts: user, password, hostname, keyboard, YES WIPE
        ├─ partitions one disk: GPT + ESP + ext4 root (UEFI)
        ├─ copies the offline pool + sartoria-desktop
        ├─ NVIDIA detect → skip on virtio/QXL; stub proprietary path
        └─ GRUB, sysvinit, console login (manual startx)
Installed system
  └─ login on tty1 → shell → startx → herbstluftwm on XLibre
```

The USB is not a daily-driver live session. The desktop exists after the target reboots.

### PID 1

`/sbin/init` is sysvinit (`sysvinit-core`). Extra services (NetworkManager, ssh, later display bits) use Devuan’s existing `/etc/init.d` scripts. Do not install `runit-init` or switch to OpenRC.

### Session

- No LightDM/GDM/SDDM.
- After a **local tty1** login you get a shell. Run `startx` for herbstluftwm. `.bash_profile` does **not** exec startx (a failed X session would replace the login shell and dump you back at getty).
- SSH and other ttys must not start X.
- `.xinitrc` launches herbstluftwm (and the autostart that starts polybar, picom, dunst).

### herbstluftwm

Manual tiling: the user splits frames. The Omarchy feel comes from bindings and a finished autostart, not from copying Hyprland layouts.

Default bindings (v1):

| Key | Action |
| --- | --- |
| Super+Return | terminal (alacritty) |
| Super+Space | launcher (rofi) |
| Super+q | close window |
| Super+1..9 | use tag |
| Super+Shift+1..9 | move window to tag |
| Super+h/j/k/l | focus |
| Super+Shift+h/j/k/l | shift window |
| Super+o / Super+u | split right / split down |
| Super+s | toggle floating (dialogs) |
| Super+Shift+e | exit session |

Floating rules for LibreOffice/Steam dialogs come when those apps land.

### NVIDIA (Phase E; not a v0.1 ISO gate)

The installer looks for NVIDIA hardware. In a VM it logs “none found” / “stubbed” and continues with modesetting/virtio. Do not load `nvidia.ko` on virtio. Do not put `nvidia-driver` on the installer ISO.

**Phase E profile is hybrid laptop, not desktop dGPU.** First machine: ASUS ROG Zephyrus G15 GA503RM (AMD Rembrandt 680M + RTX 3060 Mobile). The internal panel is wired to the iGPU.

Locked hybrid behaviour:

- **On-demand Prime render offload.** The session stays on the iGPU. NVIDIA is an offload source for opted-in clients.
- X: `modesetting` + `PrimaryGPU yes` on amdgpu/i915 (`10-igpu.conf`). NVIDIA DDX matches `nvidia-drm` with `AllowEmptyInitialConfiguration` and `PrimaryGPU no`. `AllowNVIDIAGPUScreens` on.
- Kernel: proprietary `nvidia-kernel-dkms` 550 from Excalibur (not the open flavor: 550-open fails to build on 6.12.107). `nvidia-drm.modeset=1`. `nouveau` stays blacklisted. Do not set `NVreg_PreserveVideoMemoryAllocations` (breaks Optimus).
- GLX: Mesa remains the session default so herbstluftwm/alacritty/picom do not go through NVIDIA GL (XLibre + Prime black windows). NVIDIA GLX only via `sartoria nvidia <cmd>` (`__NV_PRIME_RENDER_OFFLOAD=1`, `__GLX_VENDOR_LIBRARY_NAME=nvidia`).
- picom stays on the `xrender` backend.
- Do not run `nvidia-xconfig`, do not install Bumblebee, do not make NVIDIA the primary GPU. A MUX / dGPU-drives-panel mode is a later option, not the E exit.
- Package: `sartoria-nvidia`, installed on the target after the ISO. DKMS needs `linux-headers-amd64` matching the running 6.12 image; do not pull linux 7 headers from backports just to build the module.

Desktop dGPU (NVIDIA as the only / primary GPU) is a later Phase E follow-up, not this gate.

---

## 5. Phases

Each phase has an exit test. Do not start the next until it passes.

### Phase A — Lab VM, no ISO yet

**A1.** Git repo with this tree, `README.md`, this file, `MANUAL.md` stub.

**A2.** Devuan Excalibur in QEMU/KVM. virtio disk. **Do not** enable NVIDIA. Accept the default init.

**A3.** Confirm PID 1 is sysvinit. Reboot twice. Do not convert to runit or OpenRC.

**A4.** Stock Xorg + herbstluftwm via startx. Prove tiling, terminal, network. Isolates WM config from XLibre.

**A5.** Add XLibre from [xlibre-debian/devuan](https://github.com/xlibre-debian/devuan) with backports enabled. Confirm XLibre version; herbstluftwm still runs.

**Exit A:** VM reboots to a usable herbstluftwm session on XLibre with sysvinit, no NVIDIA.

Lab bootstrap notes:

- The host is not Devuan. The lab VM is created with QEMU from the official Devuan 6.1.1 amd64 **netinstall** ISO, unattended via debian-installer preseed injected into the installer initrd.
- That bootstrap uses QEMU direct-kernel boot (SeaBIOS linuxboot). It does **not** remaster the official ISO. The **Sartoria ISO** (Phase D) is UEFI + GRUB; this lab shortcut is only for Phase A.
- Lab credentials are for the VM only; see `lab/README.md`.

### Phase B — Opinionated desktop (still one VM)

Autostart, polybar, rofi, dunst, picom, one theme, `sartoria` CLI stub.

**Exit B:** You would use this VM for an hour of real work (terminal + tiling; browser is still later). Done 2026-09-19; see `lab/PHASE-B.md`.

### Phase C — Metapackages

`sartoria-desktop` on a **fresh** Devuan Excalibur VM reproduces Phase B.

**Exit C:** Fresh VM + one metapackage = Sartoria desktop. Done 2026-09-19; see `lab/PHASE-C.md`.

### Phase D — ISO + TUI installer

Build the ISO **inside** a Devuan Excalibur VM/chroot (`scripts/build-iso.sh`). live-build or Devuan’s current live-sdk — verify before investing.

Installer-first offline ISO. TUI: user, password, hostname, keyboard, whole-disk wipe. Install to a second VM disk. Installed VM boots without the live medium.

**Exit D:** Install from ISO → working Sartoria VM. This is **v0.1**. Done 2026-09-19; see `lab/PHASE-D.md`. Build is debootstrap + squashfs + grub-mkrescue inside a Devuan VM, not live-build.

### Phase E — Hardware (NVIDIA gate)

Real NVIDIA machine. `sartoria-nvidia`. **Hybrid laptop first** (this G15); desktop dGPU later.

**E1.** Kernel module: `nvidia.ko` loaded, `nvidia-smi` lists the RTX 3060, `nouveau` not bound, PID 1 still sysvinit.

**E2.** Session: `startx` → XLibre + herbstluftwm on the AMD iGPU. Default `glxinfo` is Mesa/AMD, not llvmpipe, not NVIDIA. No black windows.

**E3.** Offload: `xrandr --listproviders` shows modesetting + NVIDIA. `sartoria nvidia glxinfo` reports the NVIDIA renderer. An offloaded GL client is not a black window.

**Exit E:** E1–E3 on this laptop. Done 2026-09-20; see `lab/PHASE-E.md`. Desktop dGPU is a later follow-up, not this gate.

### Phase F — Daily-driver extras

Brave Origin, LibreOffice, optional `sartoria-games`, optional `sartoria-ai`, laptop LUKS profile.

**Exit F:** Willing to daily-drive on hardware.

---

## 6. Freshness policy

Write this in the manual and keep it:

1. Default ISO tracks `excalibur` + `excalibur-updates` + `excalibur-security` + `excalibur-backports` + `contrib` + `non-free` + `non-free-firmware`.
2. Extra repos are pinned, documented, and signed.
3. Vendor a package if it is too old; do not move the OS to Ceres.
4. Optional later flavor: Sartoria Testing on Freia. Not v1.
5. Escape hatch if NVIDIA/gaming on Excalibur is a dead end: reconsider Artix. That is a **base change**, not a tweak. Do not mix Artix and Devuan in one ISO.

---

## 7. AI policy

v1 ships no AI packages. `sartoria ai` may exist later as documentation or a no-op.

Later (not v0.1):

- Desktop, network, NVIDIA, and updates work with AI completely absent.
- At most one default agent recipe, disabled until a key exists.
- No AI in the browser (Origin). No AI in the installer.
- Document what an agent may change (`~/.config/sartoria`, herbstluftwm autostart) vs must never change (bootloader, LUKS, apt sources) without confirmation.

---

## 8. Repository layout

```
sartoria/
  README.md
  MANUAL.md
  docs/DESIGN.md
  lab/                    # Phase A VM; qcow2/ISO gitignored
  metapackages/
    sartoria-desktop/
    sartoria-live/
    sartoria-nvidia/
    sartoria-ai/
    sartoria-games/
  config/                 # shipped under /usr/share/sartoria
  sysv/init.d/            # only scripts Devuan does not already ship
  live-build/
  installer/              # TUI installer
  branding/
  scripts/
  tests/qemu-smoke.md
```

---

## 9. Verification (every ISO, Phase D+)

`scripts/test-qemu.sh` should:

1. Boot the ISO in QEMU (UEFI).
2. Run the TUI installer against a second disk (or a documented unattended path).
3. Reboot the installed disk without the ISO.
4. Check PID 1 is sysvinit (not systemd, not runit, not openrc).
5. Check XLibre is the server (`xdpyinfo` / `Xorg -version`).
6. Check `herbstclient version`.
7. Check `apt-get update` works with signed sources.

NVIDIA checks are hardware-only. Do not fake them in QEMU.

On the G15 (Phase E), also:

1. `nvidia-smi` lists the dGPU.
2. Default GL renderer is the iGPU (Mesa). `sartoria nvidia glxinfo` is NVIDIA.
3. herbstluftwm session has no black windows.

There is no pytest suite for v1. The test is **boot + session + metapackage reproduce**.

---

## 10. Risks

1. **XLibre is third-party.** ABI/driver mismatch is the usual breakage. Pin versions.
2. **NVIDIA + XLibre** is the hardest integration; it is not a VM milestone. Hybrid Prime on XLibre has a known black-window failure if NVIDIA becomes the session GLX provider — keep Mesa as default.
3. **Installer-first ISO** must be tested as an installer, not as a live desktop.
4. **auto-startx on tty1** must not run on SSH or extra VTs.
5. **live-build on the host will fight you.** Build ISOs in a Devuan VM/chroot.
6. **Calamares was rejected.** Do not fall back to it if the TUI is hard; finish the TUI.
7. **Freshness is a pin list**, not a move to Freia/Ceres.

---

## 11. Lab vs product firmware

| | Phase A lab VM | Phase D Sartoria ISO |
| --- | --- | --- |
| Firmware | SeaBIOS (d-i direct-kernel bootstrap) | UEFI + GRUB |
| How it is installed | Official Devuan netinstall + preseed | Sartoria TUI on our ISO |
| Disk | virtio, ext4, no LUKS | virtio/SATA, ext4, no LUKS |
| NVIDIA | none | detect and skip |

Do not treat the lab bootstrap as the product installer.
