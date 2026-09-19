#!/usr/bin/env bash
# A5: XLibre from xlibre-debian/devuan (Excalibur needs backports).
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

ssh_lab bash -s <<'EOF'
set -euo pipefail
sudo_pw() { printf '%s\n' 'sartoria' | sudo -S -p '' "$@"; }

sudo_pw apt-get update
sudo_pw DEBIAN_FRONTEND=noninteractive apt-get install -y ca-certificates curl gnupg
sudo_pw install -m 0755 -d /usr/share/keyrings
curl -fsSL https://mrchicken.nexussfan.cz/publickey.asc | gpg --dearmor > /tmp/NexusSfan.pgp
sudo_pw install -m 0644 /tmp/NexusSfan.pgp /usr/share/keyrings/NexusSfan.pgp
rm -f /tmp/NexusSfan.pgp

cat > /tmp/xlibre-debian.sources <<'SRC'
Types: deb
URIs: https://xlibre-debian.github.io/devuan/
Suites: main
Components: stable
Architectures: amd64 arm64
Signed-By: /usr/share/keyrings/NexusSfan.pgp
SRC
sudo_pw install -m 0644 /tmp/xlibre-debian.sources /etc/apt/sources.list.d/xlibre-debian.sources

if ! grep -Rqs 'excalibur-backports' /etc/apt/sources.list /etc/apt/sources.list.d 2>/dev/null; then
  echo 'deb http://deb.devuan.org/merged excalibur-backports main contrib non-free non-free-firmware' > /tmp/excalibur-backports.list
  sudo_pw install -m 0644 /tmp/excalibur-backports.list /etc/apt/sources.list.d/excalibur-backports.list
fi

sudo_pw apt-get update
sudo_pw DEBIAN_FRONTEND=noninteractive apt-get install -y xlibre xlibre-archive-keyring
Xorg -version 2>&1 | head -20 || true
EOF

echo "A5 attempted. Confirm XLibre with: ./scripts/lab-ssh.sh 'Xorg -version'"
echo "Session: VNC login on tty1 → auto-startx → herbstluftwm on XLibre."
