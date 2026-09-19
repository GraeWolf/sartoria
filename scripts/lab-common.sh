# shellcheck shell=bash
# Shared paths for Phase A lab scripts. Source from repo-root scripts.

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LAB="$ROOT/lab"
ISO_DIR="$LAB/iso"
IMG_DIR="$LAB/images"
CACHE="$LAB/cache"
SSH_DIR="$LAB/ssh"

ISO_NAME="devuan_excalibur_6.1.1_amd64_netinstall.iso"
ISO_URL="https://ftp.fau.de/devuan-cd/devuan_excalibur/installer-iso/${ISO_NAME}"
ISO_SHA256="87be42bfcec010f90f86444b404c1efeefbdc9b08a2e82f766d6defefdf654e4"
ISO_PATH="$ISO_DIR/$ISO_NAME"

LAB_NAME="${LAB_NAME:-sartoria-lab}"
DISK="${DISK:-$IMG_DIR/${LAB_NAME}.qcow2}"
DISK_SIZE="${DISK_SIZE:-20G}"
SSH_KEY="${SSH_KEY:-$SSH_DIR/sartoria-lab}"
case "$LAB_NAME" in
  sartoria-lab)
    SSH_PORT="${SSH_PORT:-2222}"
    VNC_DISPLAY="${VNC_DISPLAY:-1}"
    QEMU_PIDFILE="${QEMU_PIDFILE:-$LAB/qemu.pid}"
    SERIAL_LOG="${SERIAL_LOG:-$LAB/serial.log}"
    ;;
  *)
    SSH_PORT="${SSH_PORT:-2223}"
    VNC_DISPLAY="${VNC_DISPLAY:-2}"
    QEMU_PIDFILE="${QEMU_PIDFILE:-$LAB/${LAB_NAME}.pid}"
    SERIAL_LOG="${SERIAL_LOG:-$LAB/${LAB_NAME}-serial.log}"
    ;;
esac
QEMU_BIN="${QEMU_BIN:-/usr/bin/qemu-system-x86_64}"

die() { echo "error: $*" >&2; exit 1; }

need() {
  command -v "$1" >/dev/null 2>&1 || die "missing command: $1"
}

ssh_opts() {
  echo -o StrictHostKeyChecking=no \
       -o UserKnownHostsFile="$SSH_DIR/known_hosts" \
       -o IdentitiesOnly=yes \
       -o ConnectTimeout=5 \
       -p "$SSH_PORT" \
       -i "$SSH_KEY"
}
