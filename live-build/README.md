# ISO build

Build **inside a Devuan Excalibur VM**, not on the host.

Phase D does **not** use Debian live-build. `scripts/build-iso.sh` debootstraps Excalibur, installs `sartoria-desktop` + XLibre + live-boot, squashes the tree, and runs `grub-mkrescue`.

Host wrapper: `scripts/lab-build-iso.sh` (runs the builder on `sartoria-c`).

- `BUILD_VARIANT=release` (default): GRUB “Install Sartoria” is the default (interactive TUI).
- `BUILD_VARIANT=test`: GRUB default is unattended (`sartoria.auto=1`) for QEMU.

The ISO is installer-first. It does not boot a daily-driver live desktop.
