# sartoria-nvidia

Hybrid laptop NVIDIA path (Phase E). Not a VM package. Not on the installer ISO.

Install on the G15 (or another AMD/Intel + NVIDIA laptop) after the desktop session already works on the iGPU:

```bash
./scripts/build-sartoria-desktop.sh   # CLI 0.0.2
./scripts/build-sartoria-nvidia.sh
sudo apt-get install ./lab/cache/sartoria-desktop_0.0.2_all.deb ./lab/cache/sartoria-nvidia_0.0.2_all.deb
sudo reboot
```

Then log in on tty1, `startx`, and:

```bash
sartoria status
sartoria gpu
sartoria nvidia glxinfo -B
```

Profile: Prime render offload. Panel stays on the iGPU. `nouveau` stays blacklisted. Do not run `nvidia-xconfig`.
