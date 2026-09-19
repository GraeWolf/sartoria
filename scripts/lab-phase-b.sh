#!/usr/bin/env bash
# Phase B: opinionated desktop on the existing lab VM.
set -euo pipefail
source "$(cd "$(dirname "$0")" && pwd)/lab-common.sh"

FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/JetBrainsMono.zip"
FONT_ZIP="$CACHE/JetBrainsMonoNerdFont.zip"

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

scp_lab() {
  scp \
    -o StrictHostKeyChecking=no \
    -o UserKnownHostsFile="$SSH_DIR/known_hosts" \
    -o IdentitiesOnly=yes \
    -P "$SSH_PORT" \
    -i "$SSH_KEY" \
    "$@"
}

[[ -f "$SSH_KEY" ]] || die "run lab-install first"
ssh_lab true || die "VM not up — ./scripts/lab-run.sh"

mkdir -p "$CACHE"
if [[ ! -s "$FONT_ZIP" ]]; then
  echo "downloading JetBrainsMono Nerd Font"
  curl -fL --retry 3 --retry-delay 2 -o "$FONT_ZIP.part" "$FONT_URL"
  mv "$FONT_ZIP.part" "$FONT_ZIP"
fi

echo "installing packages"
ssh_lab bash -s <<'EOF'
set -euo pipefail
sudo_pw() { printf '%s\n' 'sartoria' | sudo -S -p '' "$@"; }
sudo_pw sed -i 's/^deb cdrom:/# deb cdrom:/' /etc/apt/sources.list
sudo_pw apt-get update
sudo_pw DEBIAN_FRONTEND=noninteractive apt-get install -y \
  alacritty polybar rofi dunst picom neovim \
  fonts-jetbrains-mono gnome-themes-extra dbus-x11 \
  pipewire pipewire-pulse wireplumber \
  network-manager \
  libnotify-bin xdg-utils xclip unzip \
  x11-xserver-utils
if [ -x /etc/init.d/network-manager ]; then
  sudo_pw update-rc.d network-manager defaults >/dev/null 2>&1 || true
  sudo_pw service network-manager start >/dev/null 2>&1 || true
fi
EOF

echo "deploying configs"
ssh_lab 'mkdir -p ~/.config ~/.local/share/fonts ~/.local/bin'
tar -C "$ROOT/config" -cf - \
  herbstluftwm polybar picom rofi dunst alacritty gtk-3.0 \
  | ssh_lab 'tar -C "$HOME/.config" -xf -'
scp_lab "$ROOT/config/x11/xinitrc" sartoria@127.0.0.1:.xinitrc
scp_lab "$ROOT/config/x11/bash_profile" sartoria@127.0.0.1:.bash_profile
scp_lab "$ROOT/config/x11/Xresources" sartoria@127.0.0.1:.Xresources
scp_lab "$ROOT/config/sartoria-cli/sartoria" sartoria@127.0.0.1:.local/bin/sartoria
ssh_lab bash -s <<'EOF'
set -euo pipefail
sudo_pw() { printf '%s\n' 'sartoria' | sudo -S -p '' "$@"; }
chmod +x "$HOME/.xinitrc" "$HOME/.config/herbstluftwm/autostart" "$HOME/.local/bin/sartoria"
sudo_pw install -m 0755 "$HOME/.local/bin/sartoria" /usr/local/bin/sartoria
# Keep .profile PATH bits; bash_profile already sources it.
grep -q 'HOME/.local/bin' "$HOME/.profile" 2>/dev/null || \
  echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.profile"
EOF

echo "installing Nerd Font"
scp_lab "$FONT_ZIP" sartoria@127.0.0.1:/tmp/JetBrainsMonoNerdFont.zip
ssh_lab bash -s <<'EOF'
set -euo pipefail
mkdir -p "$HOME/.local/share/fonts"
unzip -o -j /tmp/JetBrainsMonoNerdFont.zip \
  JetBrainsMonoNerdFont-Regular.ttf \
  JetBrainsMonoNerdFont-Bold.ttf \
  -d "$HOME/.local/share/fonts"
fc-cache -f "$HOME/.local/share/fonts" >/dev/null
fc-list | grep -i 'JetBrains' | head -5
EOF

echo "starting Phase B session on :1"
ssh_lab bash -s <<'EOF'
set -euo pipefail
sudo_pw() { printf '%s\n' 'sartoria' | sudo -S -p '' "$@"; }
# Stop any leftover A4/A5 X
herbstclient quit >/dev/null 2>&1 || true
sudo_pw pkill Xorg || true
pkill -u "$USER" -x polybar || true
pkill -u "$USER" -x picom || true
pkill -u "$USER" -x dunst || true
sleep 1
if [ -f /etc/X11/Xwrapper.config ]; then
  sudo_pw sed -i 's/^allowed_users=.*/allowed_users=anybody/' /etc/X11/Xwrapper.config || true
fi
sudo_pw sh -c 'nohup Xorg :1 vt8 -nolisten tcp >/tmp/xorg-phase-b.log 2>&1 &'
sleep 3
export DISPLAY=:1
if ! xdpyinfo >/dev/null 2>&1; then
  echo 'X failed:' >&2
  sudo_pw tail -n 50 /tmp/xorg-phase-b.log >&2
  exit 1
fi
sudo_pw xhost +SI:localuser:sartoria >/dev/null
xrdb -merge "$HOME/.Xresources" >/dev/null 2>&1 || true
# dbus session for dunst/pipewire
if [ -z "${DBUS_SESSION_BUS_ADDRESS:-}" ]; then
  eval "$(dbus-launch --sh-syntax)"
  export DBUS_SESSION_BUS_ADDRESS DISPLAY
fi
herbstluftwm --locked >/tmp/hlwm-phase-b.log 2>&1 &
sleep 3
echo '=== pid1 ==='
cat /proc/1/comm
readlink -f /sbin/init
echo '=== display ==='
xdpyinfo | awk -F': ' '/vendor string|name of display/ {print}'
echo '=== herbstluftwm ==='
herbstclient version | sed -n '1p'
herbstclient list_monitors
echo '=== keybinds (subset) ==='
herbstclient list_keybinds | grep -E 'Mod4-(Return|space|q|Shift-e|o|u)' || herbstclient list_keybinds | head
echo '=== helpers ==='
for p in polybar picom dunst pipewire; do
  if pgrep -u "$USER" -x "$p" >/dev/null; then echo "$p up"; else echo "$p DOWN"; fi
done
echo '=== sartoria ==='
sartoria version
DISPLAY=:1 sartoria status
echo '=== spawn terminal ==='
herbstclient spawn alacritty
sleep 2
herbstclient attr clients | head -n 20 || true
herbstclient dump
echo '=== notify ==='
notify-send 'Sartoria' 'Phase B session' || true
sleep 1
echo PHASE_B_SESSION_OK
EOF

echo "Phase B deployed. VNC 127.0.0.1:5901 — log in on tty1 for auto-startx."
