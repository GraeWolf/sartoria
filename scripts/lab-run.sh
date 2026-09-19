#!/usr/bin/env bash
# Boot the installed Phase A lab disk. SSH 127.0.0.1:2222, VNC :5901.
set -euo pipefail
source "$(cd "$(dirname "$0")" && pwd)/lab-common.sh"

need "$QEMU_BIN"
[[ -f "$DISK" ]] || die "no disk at $DISK — run ./scripts/lab-install.sh first"

if [[ -f "$QEMU_PIDFILE" ]] && kill -0 "$(cat "$QEMU_PIDFILE")" 2>/dev/null; then
  echo "lab VM already running (pid $(cat "$QEMU_PIDFILE"))"
  exit 0
fi

mkdir -p "$LAB"
: > "$SERIAL_LOG"

"$QEMU_BIN" \
  -name sartoria-lab \
  -machine q35,accel=kvm \
  -cpu host \
  -m 4096 \
  -smp 4 \
  -drive "file=${DISK},if=virtio,format=qcow2,cache=writeback" \
  -netdev "user,id=n0,hostfwd=tcp:127.0.0.1:${SSH_PORT}-:22" \
  -device virtio-net-pci,netdev=n0 \
  -device virtio-vga \
  -display "vnc=127.0.0.1:${VNC_DISPLAY}" \
  -serial "file:${SERIAL_LOG}" \
  -pidfile "$QEMU_PIDFILE" \
  -daemonize

echo "lab VM started (pid $(cat "$QEMU_PIDFILE"))"
echo "SSH:  ./scripts/lab-ssh.sh"
echo "VNC:  127.0.0.1:$((5900 + VNC_DISPLAY))  (display :${VNC_DISPLAY})"
echo "log:  $SERIAL_LOG"
