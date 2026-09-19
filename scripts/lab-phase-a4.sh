#!/usr/bin/env bash
# A4: stock Xorg + herbstluftwm via startx (not XLibre yet).
set -euo pipefail
source "$(cd "$(dirname "$0")" && pwd)/lab-common.sh"

ssh_lab() {
  ssh \
    -o StrictHostKeyChecking=no \
    -o UserKnownHostsFile="$SSH_DIR/known_hosts" \
    -o IdentitiesOnly=yes \
    -o ConnectTimeout=8 \
    -p "$SSH_PORT" \
    -i "$SSH_KEY" \
    sartoria@127.0.0.1 "$@"
}

[[ -f "$SSH_KEY" ]] || die "run lab-install + lab-run first"
ssh_lab true || die "VM not up — ./scripts/lab-run.sh"

# Password sudo is required by design; feed it on stdin for this lab script only.
ssh_lab bash -s <<'EOF'
set -euo pipefail
sudo_pw() { printf '%s\n' 'sartoria' | sudo -S -p '' "$@"; }
sudo_pw sed -i 's/^deb cdrom:/# deb cdrom:/' /etc/apt/sources.list
sudo_pw apt-get update
sudo_pw DEBIAN_FRONTEND=noninteractive apt-get install -y \
  xorg xinit herbstluftwm xterm
install -d "$HOME"
cat > "$HOME/.xinitrc" <<'X'
#!/bin/sh
exec herbstluftwm
X
chmod +x "$HOME/.xinitrc"
if ! grep -q 'SARTORIA_AUTO_STARTX' "$HOME/.bash_profile" 2>/dev/null; then
  cat >> "$HOME/.bash_profile" <<'P'
# SARTORIA_AUTO_STARTX
if [ -z "$DISPLAY" ] && [ "$(tty 2>/dev/null)" = "/dev/tty1" ]; then
  exec startx
fi
P
fi
EOF

echo "A4 packages installed. Graphical check needs a VT; SSH cannot startx."
echo "On the VM console (VNC 127.0.0.1:5901) log in as sartoria/sartoria on tty1."
echo "Then: herbstclient version  (from a terminal inside X) or wait for Phase A5."
