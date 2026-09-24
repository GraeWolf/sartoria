# sartoria-nvidia

Hybrid laptop NVIDIA path (Phase E). Not a VM package. Not on the installer ISO.

Install on the G15 (or another AMD/Intel + NVIDIA laptop) after the desktop session already works on the iGPU:

```bash
./scripts/build-sartoria-desktop.sh   # 0.0.4 (Nerd Fonts, rsyslog, MM udev)
./scripts/build-sartoria-nvidia.sh    # 0.0.4 (nvidia-current params, no chvt)
sudo apt-get install ./lab/cache/sartoria-desktop_0.0.4_all.deb ./lab/cache/sartoria-nvidia_0.0.9_all.deb
sudo reboot
```

Then log in on tty1, `startx`, and:

```bash
sartoria status
sartoria gpu
sartoria nvidia glxinfo -B
```

Profile: Prime render offload. Panel stays on the iGPU. `nouveau` stays blacklisted. Do not run `nvidia-xconfig`.

Suspend is s2idle on this G15. Debian’s module is `nvidia-current` (there is no `nvidia.ko`). Do not put `nvidia` in `modules-load.d`. Do **not** enable elogind `HandleNvidiaSleep` and do **not** write `/proc/driver/nvidia/suspend` here (both hung). S0ix is `NVreg_EnableS0ixPowerManagement=1` only. The command line also sets `i8042.dumbkbd=1`: resume was sending ATKBD_CMD_RESET_DIS, the EC logged `Failed to deactivate keyboard on isa0060/serio0`, and the keys stayed dead. The sleep hook re-enumerates the USB keyboard (a listed-but-silent ITE device), rebinds the i2c touchpad if it is missing, and restores the backlight. It does not reset i8042. Reboot after this upgrade, and do not close the lid until `dumbkbd` is on `/proc/cmdline`. Then:

```bash
grep EnableS0ixPowerManagement /proc/driver/nvidia/params   # 1
grep PreserveVideoMemoryAllocations /proc/driver/nvidia/params   # 0
```
