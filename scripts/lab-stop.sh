#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "$0")" && pwd)/lab-common.sh"
if [[ -f "$QEMU_PIDFILE" ]]; then
  pid="$(cat "$QEMU_PIDFILE")"
  if kill -0 "$pid" 2>/dev/null; then
    kill "$pid"
    for _ in $(seq 1 20); do
      kill -0 "$pid" 2>/dev/null || break
      sleep 0.5
    done
    if kill -0 "$pid" 2>/dev/null; then
      kill -9 "$pid" || true
    fi
  fi
  rm -f "$QEMU_PIDFILE"
  echo "lab VM stopped"
else
  echo "lab VM was not running"
fi
