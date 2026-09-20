#!/usr/bin/env bash
# Orchestrate Phase D ISO build inside the sartoria-c Devuan VM.
set -euo pipefail
export LAB_NAME="${LAB_NAME:-sartoria-c}"
source "$(cd "$(dirname "$0")" && pwd)/lab-common.sh"

DEB="${DEB:-$CACHE/sartoria-desktop_0.0.2_all.deb}"
VARIANT="${BUILD_VARIANT:-test}"
REMOTE_WORK="/home/sartoria/sartoria-src"

ssh_c() {
  ssh \
    -o StrictHostKeyChecking=no \
    -o UserKnownHostsFile="$SSH_DIR/known_hosts" \
    -o IdentitiesOnly=yes \
    -o ConnectTimeout=8 \
    -p "$SSH_PORT" \
    -i "$SSH_KEY" \
    sartoria@127.0.0.1 "$@"
}

[[ -f "$DEB" ]] || die "build the desktop deb first: ./scripts/build-sartoria-desktop.sh"
"$ROOT/scripts/lab-run.sh"
ssh_c true || die "VM SSH down"

echo "syncing tree to $LAB_NAME"
ssh_c "mkdir -p $REMOTE_WORK && rm -rf $REMOTE_WORK/* $REMOTE_WORK/.[!.]* 2>/dev/null || true"
tar -C "$ROOT" --exclude='.git' --exclude='lab/images' --exclude='lab/iso' \
  --exclude='lab/cache' --exclude='lab/ssh' --exclude='lab/*.log' --exclude='lab/*.pid' \
  -cf - . | ssh_c "tar -C $REMOTE_WORK -xf -"
scp \
  -o StrictHostKeyChecking=no \
  -o UserKnownHostsFile="$SSH_DIR/known_hosts" \
  -o IdentitiesOnly=yes \
  -P "$SSH_PORT" \
  -i "$SSH_KEY" \
  "$DEB" sartoria@127.0.0.1:/tmp/sartoria-desktop.deb

echo "building ISO in the Devuan VM (minutes)"
ssh_c bash -s <<EOF
set -euo pipefail
sudo_pw() { printf '%s\\n' 'sartoria' | sudo -S -p '' "\$@"; }
sudo_pw env BUILD_VARIANT='$VARIANT' \
  SARTORIA_DESKTOP_DEB=/tmp/sartoria-desktop.deb \
  SARTORIA_ISO_OUT=/tmp/sartoria-0.0.1-amd64.iso \
  bash $REMOTE_WORK/scripts/build-iso.sh
sudo_pw chown sartoria:sartoria /tmp/sartoria-0.0.1-amd64.iso
EOF

mkdir -p "$ISO_DIR"
scp \
  -o StrictHostKeyChecking=no \
  -o UserKnownHostsFile="$SSH_DIR/known_hosts" \
  -o IdentitiesOnly=yes \
  -P "$SSH_PORT" \
  -i "$SSH_KEY" \
  sartoria@127.0.0.1:/tmp/sartoria-0.0.1-amd64.iso \
  "$ISO_DIR/sartoria-0.0.1-amd64.iso"
ls -lh "$ISO_DIR/sartoria-0.0.1-amd64.iso"
echo "ISO at $ISO_DIR/sartoria-0.0.1-amd64.iso"
