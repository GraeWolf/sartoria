#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "$0")" && pwd)/lab-common.sh"
[[ -f "$SSH_KEY" ]] || die "no lab key — run ./scripts/lab-install.sh first"
exec ssh \
  -o StrictHostKeyChecking=no \
  -o UserKnownHostsFile="$SSH_DIR/known_hosts" \
  -o IdentitiesOnly=yes \
  -o ConnectTimeout=8 \
  -p "$SSH_PORT" \
  -i "$SSH_KEY" \
  sartoria@127.0.0.1 "$@"
