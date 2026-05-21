#!/usr/bin/env bash
set -euo pipefail

PORT="${WEBTERMINAL_PORT:-4202}"
BIN="${WEBTERMINAL_BIN:-shellinaboxd}"
USER_NAME="$(id -un)"
GROUP_NAME="$(id -gn)"

ATTACH_SCRIPT="$(dirname "$0")/tmux-web-attach.sh"
if [ ! -x "$ATTACH_SCRIPT" ]; then
  chmod +x "$ATTACH_SCRIPT" 2>/dev/null || true
fi

"$BIN" \
  --no-beep \
  --disable-ssl \
  -b \
  --localhost-only \
  --port "$PORT" \
  -s "/:${USER_NAME}:${GROUP_NAME}:${HOME}:${ATTACH_SCRIPT}"

echo $!
