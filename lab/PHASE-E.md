# Phase E result

Recorded 2026-09-20 on **voyager** (ASUS ROG Zephyrus G15 GA503RM). Hybrid laptop first; desktop dGPU is later.

Design originally said desktop dGPU first. Override: this machine is the gate.

| | |
| --- | --- |
| iGPU | AMD Rembrandt Radeon 680M (`07:00.0`, amdgpu) |
| dGPU | GA106M RTX 3060 Mobile (`01:00.0`) |
| Panel | iGPU (MUX hybrid) |
| X | XLibre, herbstluftwm 0.9.5, `modesetting` PrimaryGPU |
| Driver | proprietary `nvidia-kernel-dkms` 550.163.01 |
| PID 1 | sysvinit |
| Session GL | Mesa 25.0.7 / AMD Radeon 680M |
| Offload GL | NVIDIA GeForce RTX 3060 Laptop GPU, OpenGL 4.6.0 |

`nvidia-persistenced` postinst failed on first install (started the daemon before `nvidia.ko`). Finished with a one-shot `policy-rc.d` exit 101; package is `ii`. Daemon is not required (Persistence-M Off); it also blocks runtime D3 and prints `startpar: ... failed!` at boot. `sartoria-nvidia` 0.0.2 ships a preinst so the next install does not hit the dpkg half-configured state. 0.0.3 disabled the sysv service but set `HandleNvidiaSleep=yes` with `options nvidia` (ignored on Debian). 0.0.4 is the suspend path (see Phase F).

NVIDIA-G0 xrandr caps are `Sink Output` only. Prime offload still works via `__NV_PRIME_RENDER_OFFLOAD=1` (`sartoria nvidia`). Reverse-PRIME / NVIDIA-wired HDMI is not this gate.

## Exit

| Check | Result |
| --- | --- |
| E1 nvidia.ko + nvidia-smi, nouveau unbound, sysvinit | pass |
| E2 startx on iGPU, Mesa/AMD default GL, no black windows | pass |
| E3 `sartoria nvidia glxinfo` is NVIDIA 3060, not a black window | pass |

```bash
sartoria gpu
sartoria nvidia glxinfo -B
```
