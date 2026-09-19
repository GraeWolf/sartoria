#!/usr/bin/env bash
# Build the Sartoria installer-first ISO. Must run on Devuan Excalibur.
set -euo pipefail

if ! grep -q '^ID=devuan' /etc/os-release 2>/dev/null; then
  echo "error: build the ISO inside a Devuan Excalibur VM/chroot, not on this host." >&2
  exit 1
fi

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VERSION="${SARTORIA_ISO_VERSION:-0.0.1}"
WORK="${SARTORIA_ISO_WORK:-/var/tmp/sartoria-iso}"
ROOTFS="$WORK/rootfs"
ISOTREE="$WORK/isotree"
OUT="${SARTORIA_ISO_OUT:-$WORK/sartoria-${VERSION}-amd64.iso}"
VARIANT="${BUILD_VARIANT:-release}" # release | test
DEB="${SARTORIA_DESKTOP_DEB:-}"
MIRROR="${SARTORIA_MIRROR:-http://deb.devuan.org/merged}"

export DEBIAN_FRONTEND=noninteractive

need_root() { [[ "$(id -u)" -eq 0 ]] || { echo "error: run as root" >&2; exit 1; }; }
need_root

apt-get update
apt-get install -y --no-install-recommends \
  debootstrap squashfs-tools xorriso grub-pc-bin grub-efi-amd64-bin \
  mtools dosfstools rsync ca-certificates curl gnupg unzip

rm -rf "$WORK"
mkdir -p "$ROOTFS" "$ISOTREE/live" "$ISOTREE/boot/grub"

echo "debootstrap excalibur"
debootstrap --variant=minbase \
  --include=sysvinit-core,eudev,sudo,ca-certificates,curl,gnupg \
  excalibur "$ROOTFS" "$MIRROR"

mount --bind /proc "$ROOTFS/proc"
mount --bind /sys "$ROOTFS/sys"
mount --bind /dev "$ROOTFS/dev"
trap 'umount "$ROOTFS/proc" "$ROOTFS/sys" "$ROOTFS/dev" 2>/dev/null || true' EXIT

cat > "$ROOTFS/etc/apt/sources.list" <<EOF
deb $MIRROR excalibur main contrib non-free non-free-firmware
deb $MIRROR excalibur-security main contrib non-free non-free-firmware
deb $MIRROR excalibur-updates main contrib non-free non-free-firmware
deb $MIRROR excalibur-backports main contrib non-free non-free-firmware
EOF

if [[ -n "$DEB" && -f "$DEB" ]]; then
  cp "$DEB" "$ROOTFS/tmp/sartoria-desktop.deb"
else
  echo "error: set SARTORIA_DESKTOP_DEB to the sartoria-desktop .deb" >&2
  exit 1
fi

chroot "$ROOTFS" apt-get update
chroot "$ROOTFS" apt-get install -y --no-install-recommends \
  linux-image-amd64 live-boot \
  dialog gdisk parted dosfstools e2fsprogs rsync squashfs-tools \
  grub-efi-amd64 grub-pc-bin efibootmgr \
  openssh-server locales kbd pciutils \
  initramfs-tools
chroot "$ROOTFS" apt-get install -y --no-install-recommends live-boot-initramfs-tools || true
chroot "$ROOTFS" dpkg -i /tmp/sartoria-desktop.deb || true
chroot "$ROOTFS" apt-get install -y -f
chroot "$ROOTFS" apt-get update
chroot "$ROOTFS" apt-get install -y xlibre xlibre-archive-keyring

echo 'en_US.UTF-8 UTF-8' > "$ROOTFS/etc/locale.gen"
chroot "$ROOTFS" locale-gen
echo 'LANG=en_US.UTF-8' > "$ROOTFS/etc/default/locale"
echo 'sartoria-live' > "$ROOTFS/etc/hostname"

install -m 0755 "$ROOT/installer/sartoria-installer" "$ROOTFS/usr/sbin/sartoria-installer"
install -m 0755 "$ROOT/installer/installer-tty" "$ROOTFS/usr/lib/sartoria/installer-tty"
install -m 0755 "$ROOT/installer/sartoria-live.init" "$ROOTFS/etc/init.d/sartoria-live"
chroot "$ROOTFS" update-rc.d sartoria-live start 01 S . || \
  ln -sf ../init.d/sartoria-live "$ROOTFS/etc/rcS.d/S01sartoria-live"
# XLibre removes xorg's x11-common package but an rc symlink can remain.
chroot "$ROOTFS" update-rc.d -f x11-common remove 2>/dev/null || true
rm -f "$ROOTFS"/etc/rc*.d/[SK]*x11-common
touch "$ROOTFS/.sartoria-live"
cp "$ROOTFS/etc/inittab" "$ROOTFS/usr/share/sartoria/inittab.disk"
if grep -q '^1:' "$ROOTFS/etc/inittab"; then
  sed -i 's#^1:.*#1:2345:respawn:/usr/lib/sartoria/installer-tty#' "$ROOTFS/etc/inittab"
else
  echo '1:2345:respawn:/usr/lib/sartoria/installer-tty' >> "$ROOTFS/etc/inittab"
fi
# Serial getty so auto-install logs are visible in QEMU.
if ! grep -q '^T0:' "$ROOTFS/etc/inittab"; then
  echo 'T0:23:respawn:/sbin/getty -L ttyS0 115200 vt100' >> "$ROOTFS/etc/inittab"
fi

chroot "$ROOTFS" update-initramfs -u
KVER="$(chroot "$ROOTFS" bash -c 'ls -1 /boot/vmlinuz-*' | sed 's#.*/vmlinuz-##' | tail -n1)"
cp "$ROOTFS/boot/vmlinuz-$KVER" "$ISOTREE/live/vmlinuz"
cp "$ROOTFS/boot/initrd.img-$KVER" "$ISOTREE/live/initrd.img"

umount "$ROOTFS/proc" "$ROOTFS/sys" "$ROOTFS/dev"
trap - EXIT

echo "squashfs"
mksquashfs "$ROOTFS" "$ISOTREE/live/filesystem.squashfs" -comp xz -e boot/initrd.img-* boot/vmlinuz-*

write_grub() {
  local default="$1" timeout="$2"
  cat > "$ISOTREE/boot/grub/grub.cfg" <<EOF
serial --unit=0 --speed=115200
terminal_input console serial
terminal_output console serial
set timeout=$timeout
set default=$default
menuentry "Install Sartoria" {
  linux /live/vmlinuz boot=live components username=root hostname=sartoria-live nopersistence console=tty0 console=ttyS0,115200n8
  initrd /live/initrd.img
}
menuentry "Install Sartoria (unattended lab)" --id unattended {
  linux /live/vmlinuz boot=live components sartoria.auto=1 username=root hostname=sartoria-live nopersistence console=tty0 console=ttyS0,115200n8
  initrd /live/initrd.img
}
EOF
}

if [[ "$VARIANT" == test ]]; then
  write_grub unattended 0
else
  write_grub 0 8
fi

echo "grub-mkrescue"
grub-mkrescue -o "$OUT" "$ISOTREE"
ls -lh "$OUT"
echo "SARTORIA_ISO_OK $OUT"
