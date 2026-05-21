#!/usr/bin/env bash
set -euo pipefail

PORT="${WEBTERMINAL_PORT:-7682}"
BIN="${WEBTERMINAL_BIN:-ttyd}"
SESSION="web"

ATTACH_SCRIPT="$(dirname "$0")/tmux-web-attach.sh"
if [ ! -x "$ATTACH_SCRIPT" ]; then
  chmod +x "$ATTACH_SCRIPT" 2>/dev/null || true
fi

nohup "$BIN" \
  --interface 127.0.0.1 \
  --writable \
  --check-origin \
  --max-clients 5 \
  --terminal-type xterm-256color \
  --ping-interval 20 \
  --port "$PORT" \
  -t titleFixed=webterminal-tmux \
  -t fontSize=14 \
  bash -c "$ATTACH_SCRIPT" \
  > /tmp/webterminal-ttyd-tmux-"$PORT".log 2>&1 &

echo $!
