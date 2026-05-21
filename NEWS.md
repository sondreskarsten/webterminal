# webterminal 0.0.0.9000

## New features

* Core functions: `web_terminal()`, `terminal_start()`, `terminal_stop()`,
  `terminal_status()`, `terminal_backends()`, `webterminal_doctor()`,
  `webterminal_snippet()`.
* Backends supported: `ttyd`, `ttyd-tmux` (persistent via tmux), `shellinabox`.
* Daemon registry persisted to `tools::R_user_dir("webterminal", "cache")`.
* No system software installation; actionable error messages with install hints.
