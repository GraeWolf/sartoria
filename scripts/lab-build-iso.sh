#!/usr/bin/env bash
# Build the Sartoria ISO on this Devuan machine.
# The image is a debootstrap chroot under /var/tmp/sartoria-iso.
# That chroot is not this laptop's root disk.
set -euo pipefail
source "$(cd "$(dirname "$0")" && pwd)/lab-common.sh"

VERSION="${SARTORIA_ISO_VERSION:-0.0.1}"
VARIANT="${BUILD_VARIANT:-release}"
if [[ -z "${DEB:-}" ]]; then
  DEB="$(ls -1 "$CACHE"/sartoria-desktop_*.deb 2>/dev/null | sort -V | tail -n1 || true)"
fi
[[ -n "${DEB:-}" && -f "$DEB" ]] || die "build the desktop deb first: ./scripts/build-sartoria-desktop.sh"

case "$VARIANT" in
  release) OUT_NAME="sartoria-${VERSION}-amd64.iso" ;;
  test) OUT_NAME="sartoria-${VERSION}-amd64-auto.iso" ;;
  *) die "BUILD_VARIANT must be release or test" ;;
esac

mkdir -p "$ISO_DIR"
OUT="$ISO_DIR/$OUT_NAME"

echo "building $VARIANT ISO on this machine"
echo "desktop deb: $DEB"
echo "output: $OUT"

run=(env
  BUILD_VARIANT="$VARIANT"
  SARTORIA_DESKTOP_DEB="$DEB"
  SARTORIA_ISO_OUT="$OUT"
  SARTORIA_ISO_VERSION="$VERSION"
  bash "$ROOT/scripts/build-iso.sh")

if [[ "$(id -u)" -eq 0 ]]; then
  "${run[@]}"
else
  sudo "${run[@]}"
fi

ls -lh "$OUT"
echo "ISO at $OUT"
