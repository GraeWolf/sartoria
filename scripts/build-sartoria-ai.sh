#!/usr/bin/env bash
# Build sartoria-ai_*.deb on the host (dpkg-deb or ar+tar).
set -euo pipefail
source "$(cd "$(dirname "$0")" && pwd)/lab-common.sh"

VERSION="${SARTORIA_AI_VERSION:-0.0.1}"
PKG=sartoria-ai
STAGE="$CACHE/deb-stage/${PKG}"
OUTDIR="${OUTDIR:-$CACHE}"
DEB="$OUTDIR/${PKG}_${VERSION}_all.deb"

need tar
need gzip
need find

rm -rf "$STAGE"
mkdir -p "$STAGE/DEBIAN" \
  "$STAGE/usr/bin" \
  "$STAGE/usr/lib/sartoria" \
  "$STAGE/usr/share/sartoria/ai" \
  "$STAGE/usr/share/doc/$PKG"

install -m 0755 "$ROOT/config/sartoria-cli/sartoria-ai" "$STAGE/usr/bin/sartoria-ai"
install -m 0755 "$ROOT/config/sartoria-cli/sartoria-ai-recipe" \
  "$STAGE/usr/lib/sartoria/sartoria-ai-recipe"
install -m 0644 "$ROOT/config/ai/policy.txt" \
  "$STAGE/usr/share/sartoria/ai/policy.txt"

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
Depends: sartoria-desktop (>= 0.0.9), python3, curl, ca-certificates
Homepage: https://github.com/kmccuddy/sartoria
Description: Sartoria optional AI recipe (Phase F7)
 One terminal recipe. Off until a key exists. Not on the v0.1 ISO.
 Does not change the bootloader, LUKS, or apt sources.
EOF
install -m 0755 "$ROOT/metapackages/sartoria-ai/postinst" "$STAGE/DEBIAN/postinst"

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
