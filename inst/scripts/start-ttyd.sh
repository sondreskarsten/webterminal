#!/usr/bin/env bash
set -euo pipefail

PORT="${WEBTERMINAL_PORT:-7681}"
BIN="${WEBTERMINAL_BIN:-ttyd}"

nohup "$BIN" \
  --interface 127.0.0.1 \
  --writable \
  --check-origin \
  --max-clients 5 \
  --terminal-type xterm-256color \
  --ping-interval 20 \
  --port "$PORT" \
  -t titleFixed=webterminal \
  -t fontSize=14 \
  bash -l \
  > /tmp/webterminal-ttyd-"$PORT".log 2>&1 &

echo $!
