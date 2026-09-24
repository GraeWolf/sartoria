#!/usr/bin/env bash
# Build sartoria-desktop_*.deb on the host (dpkg-deb or ar+tar).
set -euo pipefail
source "$(cd "$(dirname "$0")" && pwd)/lab-common.sh"

VERSION="${SARTORIA_DESKTOP_VERSION:-0.0.7}"
PKG=sartoria-desktop
STAGE="$CACHE/deb-stage/${PKG}"
OUTDIR="${OUTDIR:-$CACHE}"
DEB="$OUTDIR/${PKG}_${VERSION}_all.deb"
KEY_URL="https://mrchicken.nexussfan.cz/publickey.asc"
FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/JetBrainsMono.zip"
FONT_ZIP="$CACHE/JetBrainsMonoNerdFont.zip"
FONT_FILES=(
  JetBrainsMonoNerdFont-Regular.ttf
  JetBrainsMonoNerdFont-Bold.ttf
  JetBrainsMonoNerdFontMono-Regular.ttf
  JetBrainsMonoNerdFontMono-Bold.ttf
)

need tar
need gzip
need find
need curl
need python3

rm -rf "$STAGE"
mkdir -p "$STAGE/DEBIAN" \
  "$STAGE/usr/bin" \
  "$STAGE/usr/lib/sartoria" \
  "$STAGE/usr/share/sartoria/config" \
  "$STAGE/usr/share/sartoria/skel/.config" \
  "$STAGE/usr/share/doc/$PKG" \
  "$STAGE/usr/share/keyrings" \
  "$STAGE/usr/share/fonts/truetype/sartoria" \
  "$STAGE/etc/fonts/conf.d" \
  "$STAGE/etc/apt/sources.list.d" \
  "$STAGE/etc/apt/preferences.d" \
  "$STAGE/etc/skel/.config" \
  "$STAGE/etc/X11/xorg.conf.d" \
  "$STAGE/etc/modprobe.d" \
  "$STAGE/etc/udev/rules.d"

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
install -m 0755 "$ROOT/config/sartoria-cli/sartoria-brightness" "$STAGE/usr/bin/sartoria-brightness"
install -m 0755 "$ROOT/config/sartoria-cli/sartoria-keys" "$STAGE/usr/bin/sartoria-keys"
install -m 0755 "$ROOT/config/sartoria-cli/sartoria-dpi" "$STAGE/usr/bin/sartoria-dpi"
install -m 0755 "$ROOT/metapackages/sartoria-desktop/seed-user-config" \
  "$STAGE/usr/lib/sartoria/seed-user-config"

install -m 0644 "$ROOT/config/x11/xorg.conf.d/10-igpu.conf" \
  "$STAGE/etc/X11/xorg.conf.d/10-igpu.conf"
install -m 0644 "$ROOT/config/modprobe.d/sartoria-hybrid.conf" \
  "$STAGE/etc/modprobe.d/sartoria-hybrid.conf"
install -m 0644 "$ROOT/config/udev/rules.d/80-sartoria-mm-ignore.rules" \
  "$STAGE/etc/udev/rules.d/80-sartoria-mm-ignore.rules"
install -m 0644 "$ROOT/metapackages/sartoria-desktop/xlibre-debian.sources" \
  "$STAGE/etc/apt/sources.list.d/xlibre-debian.sources"
install -m 0644 "$ROOT/config/apt/sartoria-no-hyprland.pref" \
  "$STAGE/etc/apt/preferences.d/sartoria-no-hyprland"
install -m 0644 "$ROOT/config/fontconfig/50-sartoria-fonts.conf" \
  "$STAGE/etc/fonts/conf.d/50-sartoria-fonts.conf"

curl -fsSL "$KEY_URL" | gpg --dearmor > "$STAGE/usr/share/keyrings/sartoria-xlibre.pgp"
chmod 0644 "$STAGE/usr/share/keyrings/sartoria-xlibre.pgp"

mkdir -p "$CACHE"
if [[ ! -s "$FONT_ZIP" ]]; then
  echo "downloading JetBrainsMono Nerd Font"
  curl -fL --retry 3 --retry-delay 2 -o "$FONT_ZIP.part" "$FONT_URL"
  mv "$FONT_ZIP.part" "$FONT_ZIP"
fi
python3 - "$FONT_ZIP" "$STAGE/usr/share/fonts/truetype/sartoria" "${FONT_FILES[@]}" <<'PY'
import shutil, sys, zipfile
from pathlib import Path
zip_path, dest = Path(sys.argv[1]), Path(sys.argv[2])
want = sys.argv[3:]
dest.mkdir(parents=True, exist_ok=True)
with zipfile.ZipFile(zip_path) as zf:
    names = {Path(n).name: n for n in zf.namelist()}
    missing = [n for n in want if n not in names]
    if missing:
        raise SystemExit("nerd font zip missing: " + ", ".join(missing))
    for n in want:
        with zf.open(names[n]) as src, open(dest / n, "wb") as out:
            shutil.copyfileobj(src, out)
PY
for f in "${FONT_FILES[@]}"; do
  [[ -s "$STAGE/usr/share/fonts/truetype/sartoria/$f" ]] || die "failed to extract $f"
done

cat > "$STAGE/usr/share/doc/$PKG/copyright" <<'EOF'
Format: https://www.debian.org/doc/packaging-manuals/copyright-format/1.0/
Files: *
Copyright: Kelly McCuddy
License: MIT

Files: usr/share/fonts/truetype/sartoria/*
Copyright: 2020 The JetBrains Mono Project Authors
           2014-2025 Ryan L McIntyre (Nerd Fonts)
License: OFL-1.1
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
Depends: herbstluftwm, xinit, alacritty, polybar, rofi, gum, dunst, picom, neovim, fonts-jetbrains-mono, gnome-themes-extra, dbus-x11, pipewire, pipewire-pulse, wireplumber, network-manager, libnotify-bin, xdg-utils, xclip, x11-xserver-utils, sudo, ca-certificates, curl, gnupg, firmware-amd-graphics, firmware-iwlwifi, firmware-realtek, firmware-mediatek, firmware-misc-nonfree, firmware-atheros, firmware-brcm80211, wpasupplicant, wireless-regdb, iw, rfkill, elogind, libpam-elogind, rsyslog
Recommends: xlibre, xlibre-archive-keyring
Homepage: https://github.com/kmccuddy/sartoria
Description: Sartoria desktop metapackage
 Keyboard-first herbstluftwm session for Sartoria (Devuan remix).
 On a panel at or above 140 DPI, sartoria-dpi sets Xft.dpi to 144
 at session start. Displays near 96 DPI, including the VM, stay at 96.
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
