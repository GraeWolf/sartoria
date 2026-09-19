#!/usr/bin/env bash
# Phase C: install sartoria-desktop on a fresh Devuan VM (sartoria-c).
# Does not touch the Phase A/B disk.
set -euo pipefail
export LAB_NAME=sartoria-c
source "$(cd "$(dirname "$0")" && pwd)/lab-common.sh"

DEB="${DEB:-$CACHE/sartoria-desktop_0.0.1_all.deb}"

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

[[ -f "$SSH_KEY" ]] || die "lab SSH key missing"
[[ -f "$DISK" ]] || die "no $DISK — run LAB_NAME=sartoria-c ./scripts/lab-install.sh first"
[[ -f "$DEB" ]] || die "no $DEB — run ./scripts/build-sartoria-desktop.sh first"

"$ROOT/scripts/lab-run.sh"
echo "waiting for SSH on :$SSH_PORT"
for i in $(seq 1 60); do
  if ssh_c true >/dev/null 2>&1; then
    break
  fi
  sleep 2
done
ssh_c true || die "fresh VM SSH did not come up"

echo "copying $DEB"
scp \
  -o StrictHostKeyChecking=no \
  -o UserKnownHostsFile="$SSH_DIR/known_hosts" \
  -o IdentitiesOnly=yes \
  -P "$SSH_PORT" \
  -i "$SSH_KEY" \
  "$DEB" sartoria@127.0.0.1:/tmp/sartoria-desktop.deb

echo "installing sartoria-desktop (one metapackage + XLibre from shipped source)"
ssh_c bash -s <<'EOF'
set -euo pipefail
sudo_pw() { printf '%s\n' 'sartoria' | sudo -S -p '' "$@"; }
sudo_pw sed -i 's/^deb cdrom:/# deb cdrom:/' /etc/apt/sources.list
sudo_pw apt-get update
# Resolves Depends from Devuan. The package also drops the XLibre source;
# a second update+install is required because apt holds the lock in postinst.
sudo_pw DEBIAN_FRONTEND=noninteractive apt-get install -y /tmp/sartoria-desktop.deb
sudo_pw apt-get update
sudo_pw DEBIAN_FRONTEND=noninteractive apt-get install -y xlibre xlibre-archive-keyring
dpkg -s sartoria-desktop | grep -E '^(Package|Status|Version)'
command -v sartoria-session
command -v sartoria
test -f /home/sartoria/.xinitrc
test -x /home/sartoria/.config/herbstluftwm/autostart
echo C_PACKAGE_OK
EOF

echo "starting session on :1 to prove the packaged desktop"
ssh_c bash -s <<'EOF'
set -eu
sudo_pw() { printf '%s\n' 'sartoria' | sudo -S -p '' "$@"; }
export DISPLAY=:1
herbstclient quit >/dev/null 2>&1 || true
sudo_pw pkill Xorg || true
sleep 1
if [ -f /etc/X11/Xwrapper.config ]; then
  sudo_pw sed -i 's/^allowed_users=.*/allowed_users=anybody/' /etc/X11/Xwrapper.config || true
fi
sudo_pw sh -c 'nohup Xorg :1 vt8 -nolisten tcp >/tmp/xorg-phase-c.log 2>&1 &'
sleep 3
if ! xdpyinfo >/dev/null 2>&1; then
  sudo_pw tail -n 50 /tmp/xorg-phase-c.log >&2
  exit 1
fi
sudo_pw xhost +SI:localuser:sartoria >/dev/null
xrdb -merge "$HOME/.Xresources" >/dev/null 2>&1 || true
eval "$(dbus-launch --sh-syntax)"
export DBUS_SESSION_BUS_ADDRESS DISPLAY
sartoria-session >/tmp/hlwm-phase-c.log 2>&1 &
sleep 4
echo '=== pid1 ==='
cat /proc/1/comm
readlink -f /sbin/init
echo '=== display ==='
xdpyinfo | awk -F': ' '/vendor string|name of display/ {print}'
echo '=== herbstluftwm ==='
herbstclient version | sed -n '1p'
herbstclient list_monitors
echo '=== helpers ==='
for p in polybar picom dunst pipewire; do
  if pgrep -u "$USER" -x "$p" >/dev/null; then echo "$p up"; else echo "$p DOWN"; fi
done
echo '=== sartoria ==='
sartoria version
DISPLAY=:1 sartoria status
herbstclient spawn alacritty
sleep 2
herbstclient dump
echo PHASE_C_SESSION_OK
EOF
