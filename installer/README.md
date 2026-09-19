# Sartoria TUI installer

Product installer (Phase D). Not Calamares. Not this lab VM’s debian-installer preseed.

v0.1 prompts:

1. Keyboard layout
2. Hostname (default `sartoria`)
3. Username and password (sudo user; no root login)
4. Explicit whole-disk wipe confirm
5. Install

Offline ISO. Whole disk, ext4, no LUKS. NVIDIA detect → skip in a VM.

Unattended lab: boot the GRUB entry “Install Sartoria (unattended lab)” or pass `sartoria.auto=1`. Defaults: keymap `us`, hostname `sartoria`, user `sartoria` / password `sartoria`, wipe the first non-live disk.
