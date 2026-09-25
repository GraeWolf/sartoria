# Phase D result

Recorded 2026-09-19. This is **v0.1**.

The 2026-09-19 ISO was built inside the Devuan `sartoria-c` VM. Later ISOs are built on this laptop with the same scripts (`scripts/lab-build-iso.sh` → `scripts/build-iso.sh`). Not live-build: debootstrap + `sartoria-desktop` + squashfs + `grub-mkrescue`. The build chroot is `/var/tmp/sartoria-iso`, not this machine's root disk.

| Check | Result |
| --- | --- |
| ISO | `lab/iso/sartoria-0.0.1-amd64.iso` (895M, interactive GRUB default) |
| Auto ISO | `lab/iso/sartoria-0.0.1-amd64-auto.iso` (unattended GRUB default, used for the QEMU proof) |
| Installer | TUI (`dialog`); unattended via `sartoria.auto=1` |
| Disk | Whole-disk GPT, 512M EFI, ext4 root, no LUKS |
| NVIDIA | Detect and skip (no GPU in QEMU) |
| Exit test | OVMF boots auto ISO → install to virtio disk → reboot **without ISO** |
| PID 1 | sysvinit |
| Display | XLibre |
| Session | herbstluftwm 0.9.5, polybar/picom/dunst/pipewire, alacritty |
| Package | `sartoria-desktop` 0.0.1 |

```bash
./scripts/build-sartoria-desktop.sh
BUILD_VARIANT=test ./scripts/lab-build-iso.sh   # unattended GRUB default
./scripts/test-iso.sh
# product image (interactive default): same squashfs, GRUB default=0
```

Installed test VM: SSH port **2224**, VNC `127.0.0.1:5903`, user `sartoria` / `sartoria`.
