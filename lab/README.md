# Phase A lab VM

This directory holds the **lab** Devuan Excalibur VM. It is not the Sartoria installer.

## What this proves

- Devuan 6 Excalibur boots in QEMU with virtio
- PID 1 is sysvinit
- Later: herbstluftwm on Xorg, then on XLibre

## Firmware

The product ISO (Phase D) is UEFI. This lab bootstrap uses QEMU **direct-kernel** boot of debian-installer (SeaBIOS linuxboot) because remastering the official ISO needs xorriso/root we do not use on the host.

Do not copy this bootstrap into the Sartoria ISO.

## Credentials (lab only)

| | |
| --- | --- |
| User | `sartoria` |
| Password | `sartoria` |
| Hostname | `sartoria-lab` |
| SSH | `./scripts/lab-ssh.sh` (key in `lab/ssh/`, port 2222) |
| Sudo | password required |

Weak password is intentional for a disposable VM.

## Commands

```bash
./scripts/lab-install.sh    # download ISO, inject preseed, install
./scripts/lab-run.sh        # boot the disk (VNC 127.0.0.1:5901, SSH :2222)
./scripts/lab-verify.sh     # A3: PID 1 + two reboots
./scripts/lab-ssh.sh
```

Images and ISOs are gitignored.
