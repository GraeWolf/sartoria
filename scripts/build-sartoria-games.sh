#!/usr/bin/env bash
# Build sartoria-games_*.deb on the host (dpkg-deb or ar+tar).
set -euo pipefail
source "$(cd "$(dirname "$0")" && pwd)/lab-common.sh"

VERSION="${SARTORIA_GAMES_VERSION:-0.0.1}"
PKG=sartoria-games
STAGE="$CACHE/deb-stage/${PKG}"
OUTDIR="${OUTDIR:-$CACHE}"
DEB="$OUTDIR/${PKG}_${VERSION}_all.deb"

need tar
need gzip
need find

rm -rf "$STAGE"
mkdir -p "$STAGE/DEBIAN" \
  "$STAGE/usr/bin" \
  "$STAGE/usr/share/applications" \
  "$STAGE/usr/share/doc/$PKG"

install -m 0755 "$ROOT/config/sartoria-cli/sartoria-steam" "$STAGE/usr/bin/sartoria-steam"
install -m 0644 "$ROOT/config/applications/sartoria-steam.desktop" \
  "$STAGE/usr/share/applications/sartoria-steam.desktop"

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
Depends: sartoria-desktop (>= 0.0.8), sartoria-nvidia (>= 0.0.9), steam-installer, steam-devices, nvidia-driver-libs:i386, nvidia-vulkan-icd:i386, xdg-desktop-portal-gtk
Homepage: https://github.com/kmccuddy/sartoria
Description: Sartoria Steam (Phase F5)
 Steam from Excalibur contrib, launched with Prime offload.
 Not on the v0.1 ISO. Requires the i386 architecture.
EOF
install -m 0755 "$ROOT/metapackages/sartoria-games/postinst" "$STAGE/DEBIAN/postinst"

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
