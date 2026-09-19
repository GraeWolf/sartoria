#!/usr/bin/env bash
# Phase D exit: UEFI QEMU boots the ISO, auto-installs, reboots from disk only.
set -euo pipefail
source "$(cd "$(dirname "$0")" && pwd)/lab-common.sh"

ISO="${ISO:-$ISO_DIR/sartoria-0.0.1-amd64.iso}"
TARGET="$IMG_DIR/sartoria-from-iso.qcow2"
VARS="$IMG_DIR/sartoria-d-vars.fd"
OVMF_CODE="${OVMF_CODE:-/usr/share/edk2/x64/OVMF_CODE.4m.fd}"
OVMF_VARS_TEMPLATE="${OVMF_VARS_TEMPLATE:-/usr/share/edk2/x64/OVMF_VARS.4m.fd}"
TEST_SERIAL="$LAB/sartoria-d-serial.log"
TEST_PID="$LAB/sartoria-d.pid"
SSH_TEST_PORT="${SSH_TEST_PORT:-2224}"

need "$QEMU_BIN"
[[ -f "$ISO" ]] || die "no ISO at $ISO — ./scripts/lab-build-iso.sh"
[[ -f "$OVMF_CODE" ]] || die "no OVMF at $OVMF_CODE"

if [[ -f "$TEST_PID" ]] && kill -0 "$(cat "$TEST_PID")" 2>/dev/null; then
  kill "$(cat "$TEST_PID")" || true
  sleep 1
fi

qemu-img create -f qcow2 "$TARGET" 12G
cp "$OVMF_VARS_TEMPLATE" "$VARS"
: > "$TEST_SERIAL"

echo "booting ISO (UEFI) for unattended install"
"$QEMU_BIN" \
  -name sartoria-d-install \
  -machine q35,accel=kvm \
  -cpu host \
  -m 4096 \
  -smp 4 \
  -drive "if=pflash,format=raw,readonly=on,file=$OVMF_CODE" \
  -drive "if=pflash,format=raw,file=$VARS" \
  -drive "file=$TARGET,if=none,id=hd0,format=qcow2,cache=writeback" \
  -device virtio-blk-pci,drive=hd0,bootindex=2 \
  -cdrom "$ISO" \
  -boot order=d \
  -netdev user,id=n0 \
  -device virtio-net-pci,netdev=n0 \
  -serial "file:$TEST_SERIAL" \
  -display none \
  -pidfile "$TEST_PID" \
  -daemonize

echo "waiting for SARTORIA_INSTALL_OK (up to 25m)"
ok=0
for i in $(seq 1 150); do
  if grep -q 'SARTORIA_INSTALL_OK' "$TEST_SERIAL" 2>/dev/null; then
    ok=1
    break
  fi
  if [[ -f "$TEST_PID" ]] && ! kill -0 "$(cat "$TEST_PID")" 2>/dev/null; then
    if grep -q 'SARTORIA_INSTALL_OK' "$TEST_SERIAL" 2>/dev/null; then
      ok=1
    fi
    break
  fi
  sleep 10
done
[[ "$ok" -eq 1 ]] || {
  echo "install did not signal success; last serial:" >&2
  tail -n 80 "$TEST_SERIAL" >&2
  exit 1
}
echo "install reported OK"
if [[ -f "$TEST_PID" ]] && kill -0 "$(cat "$TEST_PID")" 2>/dev/null; then
  kill "$(cat "$TEST_PID")" || true
  sleep 2
fi
rm -f "$TEST_PID"

echo "booting installed disk (no ISO)"
cp "$OVMF_VARS_TEMPLATE" "$VARS"
: > "$LAB/sartoria-d-boot.log"
"$QEMU_BIN" \
  -name sartoria-d \
  -machine q35,accel=kvm \
  -cpu host \
  -m 4096 \
  -smp 4 \
  -drive "if=pflash,format=raw,readonly=on,file=$OVMF_CODE" \
  -drive "if=pflash,format=raw,file=$VARS" \
  -drive "file=$TARGET,if=none,id=hd0,format=qcow2,cache=writeback" \
  -device virtio-blk-pci,drive=hd0,bootindex=1 \
  -netdev "user,id=n0,hostfwd=tcp:127.0.0.1:${SSH_TEST_PORT}-:22" \
  -device virtio-net-pci,netdev=n0 \
  -device virtio-vga \
  -display "vnc=127.0.0.1:3" \
  -serial "file:$LAB/sartoria-d-boot.log" \
  -pidfile "$TEST_PID" \
  -daemonize

echo "waiting for SSH on :$SSH_TEST_PORT"
ssh_ok=0
for i in $(seq 1 60); do
  if ssh \
    -o StrictHostKeyChecking=no \
    -o UserKnownHostsFile="$SSH_DIR/known_hosts" \
    -o IdentitiesOnly=yes \
    -o PreferredAuthentications=password \
    -o PubkeyAuthentication=no \
    -o ConnectTimeout=5 \
    -p "$SSH_TEST_PORT" \
    sartoria@127.0.0.1 true >/dev/null 2>&1; then
    ssh_ok=1
    break
  fi
  # key from lab might work if installer copied none; password is sartoria
  sleep 3
done

askpass() { printf '%s\n' sartoria; }
export -f askpass 2>/dev/null || true
cat > /tmp/sartoria-d-askpass <<'EOF'
#!/bin/sh
printf '%s\n' sartoria
EOF
chmod +x /tmp/sartoria-d-askpass

ssh_d() {
  DISPLAY=:0 SSH_ASKPASS=/tmp/sartoria-d-askpass SSH_ASKPASS_REQUIRE=force \
    ssh \
      -o StrictHostKeyChecking=no \
      -o UserKnownHostsFile="$SSH_DIR/known_hosts" \
      -o PreferredAuthentications=password \
      -o PubkeyAuthentication=no \
      -o ConnectTimeout=8 \
      -p "$SSH_TEST_PORT" \
      sartoria@127.0.0.1 "$@"
}

ssh_d true || {
  echo "SSH failed; serial:" >&2
  tail -n 50 "$LAB/sartoria-d-boot.log" >&2
  exit 1
}

echo "=== installed system ==="
ssh_d 'cat /proc/1/comm; readlink -f /sbin/init; grep PRETTY /etc/os-release; dpkg -s sartoria-desktop | grep Version; dpkg -s xlibre | grep Version; test -x ~/.config/herbstluftwm/autostart && echo HAS_AUTOSTART'
echo PHASE_D_OK
echo "VNC 127.0.0.1:5903  SSH port $SSH_TEST_PORT user sartoria/sartoria"
