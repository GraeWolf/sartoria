#!/usr/bin/env bash
# Phase D. Refuse to run on a non-Devuan host.
set -euo pipefail
if ! grep -q '^ID=devuan' /etc/os-release 2>/dev/null; then
  echo "error: build the ISO inside a Devuan Excalibur VM/chroot, not on this host." >&2
  echo "see live-build/README.md and docs/DESIGN.md §5 Phase D" >&2
  exit 1
fi
echo "error: Phase D is not implemented yet" >&2
exit 1
