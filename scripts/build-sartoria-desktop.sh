#!/usr/bin/env bash
# Build sartoria-desktop_*.deb on the host (dpkg-deb or ar+tar).
set -euo pipefail
source "$(cd "$(dirname "$0")" && pwd)/lab-common.sh"

VERSION="${SARTORIA_DESKTOP_VERSION:-0.0.1}"
PKG=sartoria-desktop
STAGE="$CACHE/deb-stage/${PKG}"
OUTDIR="${OUTDIR:-$CACHE}"
DEB="$OUTDIR/${PKG}_${VERSION}_all.deb"
KEY_URL="https://mrchicken.nexussfan.cz/publickey.asc"
FONT_ZIP="$CACHE/JetBrainsMonoNerdFont.zip"

need tar
need gzip
need find
need curl

rm -rf "$STAGE"
mkdir -p "$STAGE/DEBIAN" \
  "$STAGE/usr/bin" \
  "$STAGE/usr/lib/sartoria" \
  "$STAGE/usr/share/sartoria/config" \
  "$STAGE/usr/share/sartoria/skel/.config" \
  "$STAGE/usr/share/doc/$PKG" \
  "$STAGE/usr/share/keyrings" \
  "$STAGE/usr/share/fonts/truetype/sartoria" \
  "$STAGE/etc/apt/sources.list.d" \
  "$STAGE/etc/skel/.config" \
  "$STAGE/etc/X11/xorg.conf.d" \
  "$STAGE/etc/modprobe.d"

# Data
cp -a "$ROOT/config/herbstluftwm" "$ROOT/config/polybar" "$ROOT/config/picom" \
  "$ROOT/config/rofi" "$ROOT/config/dunst" "$ROOT/config/alacritty" \
  "$ROOT/config/gtk-3.0" \
  "$STAGE/usr/share/sartoria/config/"
cp -a "$ROOT/config/herbstluftwm" "$ROOT/config/polybar" "$ROOT/config/picom" \
  "$ROOT/config/rofi" "$ROOT/config/dunst" "$ROOT/config/alacritty" \
  "$ROOT/config/gtk-3.0" \
  "$STAGE/usr/share/sartoria/skel/.config/"
install -m 0755 "$ROOT/config/x11/xinitrc" "$STAGE/usr/share/sartoria/skel/.xinitrc"
install -m 0644 "$ROOT/config/x11/bash_profile" "$STAGE/usr/share/sartoria/skel/.bash_profile"
install -m 0644 "$ROOT/config/x11/Xresources" "$STAGE/usr/share/sartoria/skel/.Xresources"
cp -a "$STAGE/usr/share/sartoria/skel/." "$STAGE/etc/skel/"

install -m 0755 "$ROOT/config/sartoria-cli/sartoria" "$STAGE/usr/bin/sartoria"
install -m 0755 "$ROOT/config/sartoria-cli/sartoria-session" "$STAGE/usr/bin/sartoria-session"
install -m 0755 "$ROOT/metapackages/sartoria-desktop/seed-user-config" \
  "$STAGE/usr/lib/sartoria/seed-user-config"

install -m 0644 "$ROOT/config/x11/xorg.conf.d/10-igpu.conf" \
  "$STAGE/etc/X11/xorg.conf.d/10-igpu.conf"
install -m 0644 "$ROOT/config/modprobe.d/sartoria-hybrid.conf" \
  "$STAGE/etc/modprobe.d/sartoria-hybrid.conf"
install -m 0644 "$ROOT/metapackages/sartoria-desktop/xlibre-debian.sources" \
  "$STAGE/etc/apt/sources.list.d/xlibre-debian.sources"

curl -fsSL "$KEY_URL" | gpg --dearmor > "$STAGE/usr/share/keyrings/sartoria-xlibre.pgp"
chmod 0644 "$STAGE/usr/share/keyrings/sartoria-xlibre.pgp"

if [[ -s "$FONT_ZIP" ]]; then
  unzip -o -j "$FONT_ZIP" \
    JetBrainsMonoNerdFont-Regular.ttf \
    JetBrainsMonoNerdFont-Bold.ttf \
    -d "$STAGE/usr/share/fonts/truetype/sartoria" >/dev/null
fi

cat > "$STAGE/usr/share/doc/$PKG/copyright" <<'EOF'
Format: https://www.debian.org/doc/packaging-manuals/copyright-format/1.0/
Files: *
Copyright: Kelly McCuddy
License: MIT
EOF

# Control
installed_kb="$(du -sk "$STAGE" --exclude=DEBIAN | awk '{print $1}')"
cat > "$STAGE/DEBIAN/control" <<EOF
Package: $PKG
Version: $VERSION
Section: metapackages
Priority: optional
Architecture: all
Maintainer: Kelly McCuddy <graewolf@use.startmail.com>
Installed-Size: $installed_kb
Depends: herbstluftwm, xinit, alacritty, polybar, rofi, dunst, picom, neovim, fonts-jetbrains-mono, gnome-themes-extra, dbus-x11, pipewire, pipewire-pulse, wireplumber, network-manager, libnotify-bin, xdg-utils, xclip, x11-xserver-utils, sudo, ca-certificates, curl, gnupg, firmware-amd-graphics, elogind, libpam-elogind
Recommends: xlibre, xlibre-archive-keyring
Homepage: https://github.com/kmccuddy/sartoria
Description: Sartoria desktop metapackage
 Keyboard-first herbstluftwm session for Sartoria (Devuan remix).
EOF
install -m 0755 "$ROOT/metapackages/sartoria-desktop/postinst" "$STAGE/DEBIAN/postinst"

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
