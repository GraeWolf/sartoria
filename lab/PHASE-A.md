# Phase A result

Recorded 2026-09-19 on this host. Lab disk: `lab/images/sartoria-lab.qcow2` (gitignored).

| Check | Result |
| --- | --- |
| Parent | Devuan GNU/Linux 6 (excalibur) |
| Kernel | 6.12.107+deb13-amd64 |
| PID 1 | `init` → `/usr/sbin/init` (`sysvinit-core` 3.14-4devuan1), runlevel 2 |
| Two reboots | PID 1 still sysvinit |
| A4 | X.Org 1.21.1.16 + herbstluftwm 0.9.5 on virtio-vga 1280×800 |
| A5 | XLibre X Server 1.25.2.2 (`xlibre` 1:7.8+5); `xdpyinfo` vendor string `XLibre` |
| After XLibre reboot | PID 1 sysvinit; `Xorg -version` is XLibre 1.25.2.2 |
| NVIDIA | none (virtio) |

Lab bootstrap used QEMU direct-kernel debian-installer (SeaBIOS linuxboot), not the product UEFI ISO. See `docs/DESIGN.md` §11.

The first preseed `late_command` failed (nested quotes around the SSH pubkey) and dropped d-i to the main menu. The disk was already GRUB-installed; SSH key was added after boot. `lab/preseed.cfg.in` now copies `/sartoria-authorized_keys` from the initrd instead.
