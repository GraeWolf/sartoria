#!/usr/bin/env bash
# Build sartoria-nvidia_*.deb on the host (dpkg-deb or ar+tar).
set -euo pipefail
source "$(cd "$(dirname "$0")" && pwd)/lab-common.sh"

VERSION="${SARTORIA_NVIDIA_VERSION:-0.0.9}"
PKG=sartoria-nvidia
STAGE="$CACHE/deb-stage/${PKG}"
OUTDIR="${OUTDIR:-$CACHE}"
DEB="$OUTDIR/${PKG}_${VERSION}_all.deb"

need tar
need gzip
need find

rm -rf "$STAGE"
mkdir -p "$STAGE/DEBIAN" \
  "$STAGE/usr/bin" \
  "$STAGE/usr/share/doc/$PKG" \
  "$STAGE/usr/libexec/system-sleep" \
  "$STAGE/etc/X11/xorg.conf.d" \
  "$STAGE/etc/modprobe.d" \
  "$STAGE/etc/elogind/sleep.conf.d" \
  "$STAGE/etc/default/grub.d" \
  "$STAGE/etc/rsyslog.d" \
  "$STAGE/var/lib/nvidia"

install -m 0755 "$ROOT/config/sartoria-cli/sartoria-nvidia-run" "$STAGE/usr/bin/sartoria-nvidia-run"
install -m 0755 "$ROOT/config/elogind/system-sleep/sartoria-nvidia" \
  "$STAGE/usr/libexec/system-sleep/sartoria-nvidia"
install -m 0644 "$ROOT/config/x11/xorg.conf.d/20-nvidia-hybrid.conf" \
  "$STAGE/etc/X11/xorg.conf.d/20-nvidia-hybrid.conf"
install -m 0644 "$ROOT/config/modprobe.d/sartoria-nvidia.conf" \
  "$STAGE/etc/modprobe.d/sartoria-nvidia.conf"
install -m 0644 "$ROOT/config/elogind/sleep.conf.d/20-sartoria-nvidia.conf" \
  "$STAGE/etc/elogind/sleep.conf.d/20-sartoria-nvidia.conf"
install -m 0644 "$ROOT/config/grub.d/sartoria-nvidia.cfg" \
  "$STAGE/etc/default/grub.d/sartoria-nvidia.cfg"
install -m 0644 "$ROOT/config/rsyslog.d/sartoria-nvidia.conf" \
  "$STAGE/etc/rsyslog.d/sartoria-nvidia.conf"

cat > "$STAGE/usr/share/doc/$PKG/copyright" <<'EOF'
Format: https://www.debian.org/doc/packaging-manuals/copyright-format/1.0/
Files: *
Copyright: Kelly McCuddy
License: MIT
EOF

installed_kb="$(du -sk "$STAGE" --exclude=DEBIAN | awk '{print $1}')"
cat > "$STAGE/DEBIAN/control" <<EOF
Package: $PKG
Version: $VERSION
Section: metapackages
Priority: optional
Architecture: all
Maintainer: Kelly McCuddy <graewolf@use.startmail.com>
Installed-Size: $installed_kb
Depends: sartoria-desktop (>= 0.0.4), nvidia-driver, nvidia-kernel-dkms, linux-headers-amd64, firmware-nvidia-gsp, nvidia-smi, nvidia-modprobe, mesa-utils, pciutils
Conflicts: bumblebee, bumblebee-nvidia
Recommends: nvidia-vulkan-icd
Homepage: https://github.com/kmccuddy/sartoria
Description: Sartoria hybrid NVIDIA (Prime offload)
 Proprietary NVIDIA kernel module and Prime render offload for
 Sartoria on hybrid AMD/Intel + NVIDIA laptops.
EOF
install -m 0755 "$ROOT/metapackages/sartoria-nvidia/preinst" "$STAGE/DEBIAN/preinst"
install -m 0755 "$ROOT/metapackages/sartoria-nvidia/postinst" "$STAGE/DEBIAN/postinst"
install -m 0755 "$ROOT/metapackages/sartoria-nvidia/postrm" "$STAGE/DEBIAN/postrm"

mkdir -p "$OUTDIR"
if command -v dpkg-deb >/dev/null 2>&1; then
  dpkg-deb --root-owner-group --build "$STAGE" "$DEB"
else
  need ar
  tmp="$(mktemp -d)"
  ( cd "$STAGE/DEBIAN" && tar --owner=0 --group=0 -czf "$tmp/control.tar.gz" . )
  ( cd "$STAGE" && tar --owner=0 --group=0 --exclude=DEBIAN -czf "$tmp/data.tar.gz" . )
  printf '2.0\n' > "$tmp/debian-binary"
  rm -f "$DEB"
  ar r "$DEB" "$tmp/debian-binary" "$tmp/control.tar.gz" "$tmp/data.tar.gz"
  rm -rf "$tmp"
fi

echo "built $DEB"
ls -lh "$DEB"
