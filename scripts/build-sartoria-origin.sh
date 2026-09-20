#!/usr/bin/env bash
# Build sartoria-origin_*.deb on the host (dpkg-deb or ar+tar).
set -euo pipefail
source "$(cd "$(dirname "$0")" && pwd)/lab-common.sh"

VERSION="${SARTORIA_ORIGIN_VERSION:-0.0.1}"
PKG=sartoria-origin
STAGE="$CACHE/deb-stage/${PKG}"
OUTDIR="${OUTDIR:-$CACHE}"
DEB="$OUTDIR/${PKG}_${VERSION}_all.deb"
KEY_URL="https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg"

need tar
need gzip
need find
need curl

rm -rf "$STAGE"
mkdir -p "$STAGE/DEBIAN" \
  "$STAGE/usr/bin" \
  "$STAGE/usr/share/doc/$PKG" \
  "$STAGE/usr/share/keyrings" \
  "$STAGE/etc/apt/sources.list.d" \
  "$STAGE/etc/apt/preferences.d"

install -m 0755 "$ROOT/config/sartoria-cli/sartoria-browser" "$STAGE/usr/bin/sartoria-browser"
install -m 0644 "$ROOT/config/apt/sartoria-brave.sources" \
  "$STAGE/etc/apt/sources.list.d/sartoria-brave.sources"
install -m 0644 "$ROOT/config/apt/sartoria-brave.pref" \
  "$STAGE/etc/apt/preferences.d/sartoria-brave"
curl -fsSL "$KEY_URL" -o "$STAGE/usr/share/keyrings/sartoria-brave.gpg"
chmod 0644 "$STAGE/usr/share/keyrings/sartoria-brave.gpg"
[[ -s "$STAGE/usr/share/keyrings/sartoria-brave.gpg" ]] || die "failed to download Brave keyring"

cat > "$STAGE/usr/share/doc/$PKG/copyright" <<'EOF'
Format: https://www.debian.org/doc/packaging-manuals/copyright-format/1.0/
Files: *
Copyright: Kelly McCuddy
License: MIT

Files: usr/share/keyrings/sartoria-brave.gpg
Copyright: Brave Software
License: MPL-2.0
Comment: Brave Linux Release apt signing key, copied from
 https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
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
Depends: sartoria-desktop (>= 0.0.3), ca-certificates
Recommends: brave-origin
Conflicts: brave-browser
Homepage: https://github.com/kmccuddy/sartoria
Description: Sartoria Brave Origin apt overlay
 Signed Brave apt source and Origin-only pin. Not on the v0.1 ISO.
 After install: apt-get update && apt-get install brave-origin.
EOF
install -m 0755 "$ROOT/metapackages/sartoria-origin/postinst" "$STAGE/DEBIAN/postinst"

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
