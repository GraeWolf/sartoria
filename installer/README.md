# Sartoria TUI installer

Product installer (Phase D). Not Calamares. Not this lab VM’s debian-installer preseed.

v0.1 prompts:

1. Keyboard layout
2. Hostname (default `sartoria`)
3. Username and password (sudo user; no root login)
4. Disk to wipe (menu of disks ≥ 1G; NTFS/Windows is labelled; other disks are not touched)
5. Explicit whole-disk wipe confirm (type YES)
6. Install

Offline ISO. Whole disk, ext4, no LUKS. NVIDIA detect → skip proprietary install on the live ISO (iGPU/modesetting). After reboot, hybrid laptops install `sartoria-nvidia`.

Unattended lab: boot the GRUB entry “Install Sartoria (unattended lab)” or pass `sartoria.auto=1`. Defaults: keymap `us`, hostname `sartoria`, user `sartoria` / password `sartoria`, wipe the first non-live disk.

The TUI runs on **tty1 (the VM graphical display)**. Boot logs, `sshd`, and `x11-common` messages are not the installer. Do not SSH in to install. Open the VGA/Spice/VNC window.
