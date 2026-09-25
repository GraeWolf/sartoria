# ISO build

Build on this Devuan Excalibur laptop. `scripts/lab-build-iso.sh` runs `scripts/build-iso.sh` as root.

Phase D does **not** use Debian live-build. The builder debootstraps Excalibur into `/var/tmp/sartoria-iso`, installs `sartoria-desktop` + XLibre + live-boot, squashes the tree, and runs `grub-mkrescue`. The chroot is not this laptop's root disk.

The finished file is `lab/iso/sartoria-0.0.1-amd64.iso`. `*.iso` is gitignored.

- `BUILD_VARIANT=release` (default): GRUB “Install Sartoria” is the default (interactive TUI, including the LUKS question).
- `BUILD_VARIANT=test`: GRUB default is unattended (`sartoria.auto=1`) and the file is `lab/iso/sartoria-0.0.1-amd64-auto.iso`.

The desktop package defaults to the newest `lab/cache/sartoria-desktop_*.deb`. Override with `DEB=...`.

The ISO is installer-first. It does not boot a daily-driver live desktop.
