# QEMU smoke (Phase D+)

Lab A3 is `./scripts/lab-verify.sh`. Phase D exit is `./scripts/test-iso.sh`. This checklist is for the **Sartoria ISO**.

1. Boot the ISO in QEMU, UEFI, no NVIDIA.
2. TUI installer runs (not a live herbstluftwm session).
3. Whole-disk install to a virtio disk. The unattended path and the default No stay ext4, no LUKS, and the installed cmdline keeps `nosplash`. Interactive Yes is the F6 LUKS layout: the next boot shows the Tokyo Night Plymouth passphrase box (`quiet splash`), then a tty login.
4. Reboot the installed disk without the ISO.
5. `cat /proc/1/comm` is `init` (sysvinit). Not systemd, not runit, not openrc.
6. tty1 login gives a shell; `startx` starts XLibre. `Xorg -version` is XLibre.
7. `herbstclient version` works.
8. `sartoria status` prints init, display, session, NVIDIA skipped.
9. `apt-get update` works with signed sources.

NVIDIA checks are hardware-only (`lab/PHASE-E.md`). Do not install `sartoria-nvidia` in QEMU.
