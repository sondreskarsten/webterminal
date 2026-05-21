#!/usr/bin/env bash
set -euo pipefail

SESSION="${WEBTERMINAL_TMUX_SESSION:-web}"

if tmux has-session -t "$SESSION" 2>/dev/null; then
  exec tmux attach-session -t "$SESSION"
else
  exec tmux new-session -s "$SESSION"
fi
