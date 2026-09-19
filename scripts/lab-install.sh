#!/usr/bin/env bash
# A2: unattended Devuan Excalibur lab VM via debian-installer preseed.
set -euo pipefail
source "$(cd "$(dirname "$0")" && pwd)/lab-common.sh"

need "$QEMU_BIN"
need qemu-img
need bsdtar
need cpio
need gzip
need curl
need sha256sum
need ssh-keygen

mkdir -p "$ISO_DIR" "$IMG_DIR" "$CACHE" "$SSH_DIR"

if [[ "${1:-}" == "--force" ]]; then
  rm -f "$DISK"
fi
if [[ -f "$DISK" ]]; then
  echo "disk already exists: $DISK"
  echo "boot with ./scripts/lab-run.sh or reinstall with --force"
  exit 0
fi

if [[ ! -f "$SSH_KEY" ]]; then
  ssh-keygen -t ed25519 -N "" -f "$SSH_KEY" -C "sartoria-lab"
fi
PUBKEY="$(cat "$SSH_KEY.pub")"
sed "s|@SSH_PUBKEY@|${PUBKEY}|" "$LAB/preseed.cfg.in" > "$LAB/preseed.cfg"

if [[ ! -f "$ISO_PATH" ]]; then
  echo "downloading $ISO_NAME"
  curl -fL --retry 3 --retry-delay 2 -o "$ISO_PATH.part" "$ISO_URL"
  mv "$ISO_PATH.part" "$ISO_PATH"
fi
echo "$ISO_SHA256  $ISO_PATH" | sha256sum -c -

echo "extracting installer kernel/initrd"
# Devuan 6.1 netinstall (syslinux), not Debian's install.amd/ layout.
bsdtar -xOf "$ISO_PATH" boot/isolinux/linux > "$CACHE/vmlinuz"
bsdtar -xOf "$ISO_PATH" boot/isolinux/initrd.gz > "$CACHE/initrd.gz"
[[ -s "$CACHE/vmlinuz" && -s "$CACHE/initrd.gz" ]] || die "failed to extract installer from ISO"

echo "injecting preseed.cfg + ssh key into initrd (concatenated cpio)"
PRE="$CACHE/preseed-cpio"
rm -rf "$PRE"
mkdir -p "$PRE"
cp "$LAB/preseed.cfg" "$PRE/preseed.cfg"
cp "$SSH_KEY.pub" "$PRE/sartoria-authorized_keys"
( cd "$PRE" && find . -print0 | cpio --null --create --format=newc ) | gzip -9 > "$CACHE/preseed.cpio.gz"
cat "$CACHE/preseed.cpio.gz" "$CACHE/initrd.gz" > "$CACHE/initrd-preseed.gz"

qemu-img create -f qcow2 "$DISK" "$DISK_SIZE"

echo "starting debian-installer (serial log: $SERIAL_LOG)"
echo "this is the official Devuan netinstall; it needs network and several minutes"

# Direct-kernel d-i boot. Product ISO is UEFI; see docs/DESIGN.md §11.
set +e
"$QEMU_BIN" \
  -name sartoria-lab-install \
  -machine q35,accel=kvm \
  -cpu host \
  -m 4096 \
  -smp 4 \
  -drive "file=${DISK},if=virtio,format=qcow2,cache=writeback" \
  -netdev user,id=n0 \
  -device virtio-net-pci,netdev=n0 \
  -cdrom "$ISO_PATH" \
  -kernel "$CACHE/vmlinuz" \
  -initrd "$CACHE/initrd-preseed.gz" \
  -append "auto=true priority=critical locale=en_US.UTF-8 keymap=us hostname=sartoria-lab domain=local interface=auto debian-installer/framebuffer=false nomodeset --- console=ttyS0,115200n8" \
  -nographic \
  -no-reboot \
  >"$SERIAL_LOG" 2>&1
rc=$?
set -e

if [[ $rc -ne 0 ]]; then
  echo "qemu exited $rc; last 80 lines of $SERIAL_LOG:" >&2
  tail -n 80 "$SERIAL_LOG" >&2
  exit "$rc"
fi

echo "installer qemu exited 0 (expected on reboot after success)"
echo "next: ./scripts/lab-run.sh && ./scripts/lab-verify.sh"
