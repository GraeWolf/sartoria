#!/usr/bin/env bash
# A3: PID 1 is sysvinit; reboot twice; refuse systemd/runit/openrc.
set -euo pipefail
source "$(cd "$(dirname "$0")" && pwd)/lab-common.sh"

need ssh
[[ -f "$DISK" ]] || die "no disk — run ./scripts/lab-install.sh first"
[[ -f "$SSH_KEY" ]] || die "no lab key — run ./scripts/lab-install.sh first"

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

wait_ssh() {
  local tries="${1:-60}"
  local i
  for i in $(seq 1 "$tries"); do
    if ssh_lab true >/dev/null 2>&1; then
      return 0
    fi
    sleep 2
  done
  die "SSH did not come up on 127.0.0.1:${SSH_PORT} (see $SERIAL_LOG)"
}

check_init() {
  local comm path
  comm="$(ssh_lab cat /proc/1/comm)"
  path="$(ssh_lab readlink -f /sbin/init)"
  echo "PID 1 comm=${comm} init=${path}"
  case "$comm" in
    init) ;;
    *) die "PID 1 comm is '$comm' (want init / sysvinit)" ;;
  esac
  case "$path" in
    *systemd*) die "systemd is PID 1: $path" ;;
    *runit*) die "runit is PID 1: $path" ;;
    *openrc*) die "openrc is PID 1: $path" ;;
  esac
  ssh_lab dpkg -s sysvinit-core >/dev/null
}

"$ROOT/scripts/lab-run.sh"
wait_ssh 90
echo "== first boot =="
check_init
ssh_lab 'echo sartoria | sudo -S reboot' >/dev/null 2>&1 || true
sleep 5
wait_ssh 90
echo "== after reboot 1 =="
check_init
ssh_lab 'echo sartoria | sudo -S reboot' >/dev/null 2>&1 || true
sleep 5
wait_ssh 90
echo "== after reboot 2 =="
check_init

{
  echo "# Phase A3 $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "pid1_comm=$(ssh_lab cat /proc/1/comm)"
  echo "pid1_exe=$(ssh_lab readlink -f /sbin/init)"
  echo "os=$(ssh_lab cat /etc/os-release | tr '\n' ' ')"
} | tee "$LAB/phase-a3.status"

echo "A3 ok: sysvinit survived two reboots"
