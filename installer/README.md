# Sartoria TUI installer

Product installer (Phase D). Not Calamares. Not this lab VM’s debian-installer preseed.

v0.1 prompts:

1. Keyboard layout
2. Hostname (default `sartoria`)
3. Username and password (sudo user; no root login)
4. Disk to wipe (menu of disks ≥ 1G; NTFS/Windows is labelled; other disks are not touched)
5. Encrypt the root with LUKS2, or keep ext4 (default No)
6. Explicit whole-disk wipe confirm (type YES)
7. Install

Offline ISO. Whole disk. After the disk is chosen, the TUI asks whether to encrypt the root with LUKS2. No keeps the v0.1 layout: BIOS boot, EFI, one ext4 root. Yes adds an unencrypted 1G `/boot` and a LUKS2 root. The EFI partition stays unencrypted. The passphrase is not the login password. GRUB loads the kernel from `/boot`, and the initramfs asks for the passphrase once, in a Tokyo Night Plymouth box. Ext4 installs pass `nosplash`, so Plymouth stays off. The installer ISO itself also boots with `nosplash` so the TUI is not covered.

Unattended lab: boot the GRUB entry “Install Sartoria (unattended lab)” or pass `sartoria.auto=1`. Defaults: keymap `us`, hostname `sartoria`, user `sartoria` / password `sartoria`, wipe the first non-live disk, no LUKS. NVIDIA detect → skip proprietary install on the live ISO (iGPU/modesetting). After reboot, hybrid laptops install `sartoria-nvidia`.

The TUI runs on **tty1 (the VM graphical display)**. Boot logs, `sshd`, and `x11-common` messages are not the installer. Do not SSH in to install. Open the VGA/Spice/VNC window.
