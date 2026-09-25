# Sartoria

A personal opinionated Linux distribution. Devuan remix, own ISO, keyboard-first herbstluftwm on XLibre.

Sartoria is omakase: finished defaults, no account to install or boot. It is not Arch, not systemd, not Hyprland, not Wayland, and not a post-install gist.

**Status:** Phase F on this G15 (F1 font done; F-suspend 0.0.9 boots `i8042.dumbkbd=1` so resume does not send the AT deactivate command, and still re-enumerates the USB keyboard; F2 Brave Origin installed; F3 LibreOffice from Excalibur; F4 done: Nautilus, screenshots, and Xft.dpi 144 on this panel; F5 Steam installed (Prime offload, Super+g; sign-in window still tiles); F6 LUKS is an installer question on the next ISO, not this disk). Phase E (hybrid Prime) is done. v0.1 ISO remains Phase D. Desktop dGPU is a later follow-up.

Canonical design: [`docs/DESIGN.md`](docs/DESIGN.md). Daily-use notes: [`MANUAL.md`](MANUAL.md).

## What it is

| | |
| --- | --- |
| Parent | Devuan 6 Excalibur |
| Init | sysvinit (Devuan default) |
| Display | XLibre (not Xorg, not Wayland) |
| WM | herbstluftwm |
| Installer | text TUI, installer-first ISO |
| Packaging | apt/dpkg, `sartoria-desktop`, `sartoria-nvidia`, `sartoria-origin`, `sartoria-office`, `sartoria-daily`, `sartoria-games` |
| v0.1 gate | ISO installs into a VM and boots the session |

## What it is not

- A live USB desktop you try before installing
- Calamares
- An AI OS
- A community distribution with a support contract
- A fork of the Devuan archive

## Lab VM (Phase A)

On this machine, with QEMU/KVM:

```bash
./scripts/lab-install.sh    # download Devuan netinstall, preseed, install
./scripts/lab-run.sh        # boot the installed disk
./scripts/lab-verify.sh     # PID 1, reboot twice, record status
./scripts/lab-ssh.sh        # ssh into the VM
./scripts/lab-phase-b.sh    # opinionated desktop (after A5)
./scripts/build-sartoria-desktop.sh
./scripts/lab-build-iso.sh  # ISO on this machine → lab/iso/
BUILD_VARIANT=test ./scripts/lab-build-iso.sh
./scripts/test-iso.sh
./scripts/build-sartoria-nvidia.sh
./scripts/build-sartoria-origin.sh
./scripts/build-sartoria-office.sh
./scripts/build-sartoria-daily.sh
./scripts/build-sartoria-games.sh
```

See [`lab/README.md`](lab/README.md) for credentials and firmware notes.

## Layout

```
docs/DESIGN.md     locked decisions and phases
MANUAL.md          user-facing manual (stub until the session exists)
lab/               Phase A VM images (gitignored) and preseed
config/            session defaults that will ship in sartoria-desktop
metapackages/      Debian source stubs
scripts/           lab + later ISO build
```

## License

Personal project. Packaging licenses follow their upstreams.
