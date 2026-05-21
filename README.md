
<!-- README.md is generated from README.Rmd. Please edit that file -->

# webterminal

<!-- badges: start -->

[![R-CMD-check](https://github.com/sondreskarsten/webterminal/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/sondreskarsten/webterminal/actions/workflows/R-CMD-check.yaml)
[![integration-test](https://github.com/sondreskarsten/webterminal/actions/workflows/integration-test.yaml/badge.svg)](https://github.com/sondreskarsten/webterminal/actions/workflows/integration-test.yaml)
<!-- badges: end -->

A fast, browser-based terminal for RStudio Server. Launches a
[ttyd](https://github.com/tsl0922/ttyd) or
[shellinabox](https://github.com/shellinabox/shellinabox) daemon on
localhost and opens it in the RStudio Viewer pane through the built-in
`/p/<hex>/` reverse proxy — no new ports, no outbound connections, no
SSH.

## Why

RStudio Server’s built-in terminal pane routes keystrokes through the
IDE’s RPC subsystem, adding noticeable input lag. webterminal bypasses
this entirely: ttyd’s native WebSocket transport connects xterm.js
directly to a pty, giving you a terminal that feels like a local SSH
session.

| Feature             | RStudio terminal         | webterminal (ttyd) |
|---------------------|--------------------------|--------------------|
| Transport           | RPC / WebSocket fallback | Native WebSocket   |
| Copy/paste          | Broken in some setups    | Native browser     |
| Persistent sessions | No                       | Yes (tmux)         |
| Survives R restart  | No                       | Yes                |
| New ports needed    | No                       | No                 |

## Installation

``` r
# install.packages("pak")
pak::pak("sondreskarsten/webterminal")
```

### System dependencies

Install once on the RStudio Server host:

``` bash
# Ubuntu / Debian
sudo apt-get install ttyd tmux iproute2

# Fedora / RHEL
sudo dnf install ttyd tmux iproute

# macOS (Homebrew)
brew install ttyd tmux
```

See `vignette("installing-ttyd")` for per-distro details, corporate
Nexus mirrors, and Docker recipes.

## Quick start

``` r
library(webterminal)

# Check your setup
webterminal_doctor()

# Open a terminal in the RStudio Viewer
web_terminal()
```

The terminal opens in the Viewer pane. Click **Show in new window** to
pop it out into a full browser tab.

## Backends

webterminal ships three backends. Choose by name:

``` r
library(webterminal)
terminal_backends()
#> ttyd: websocket transport, ephemeral, ttyd (installed)
#> ttyd-tmux: websocket transport, persistent, ttyd (installed)
#> shellinabox: ajax transport, persistent, shellinaboxd (not found)
```

| Backend       | Transport | Persistent | Best for                        |
|---------------|-----------|------------|---------------------------------|
| `ttyd`        | WebSocket | No         | Quick throwaway shells          |
| `ttyd-tmux`   | WebSocket | Yes        | Daily work — survives tab close |
| `shellinabox` | AJAX      | Yes        | Fallback when ttyd unavailable  |

``` r
web_terminal("ttyd-tmux")
```

## Daemon lifecycle

Daemons are detached processes — they survive R session restarts,
`rstudio-server` restarts, and browser tab closures.

``` r
# Start explicitly
terminal_start("ttyd-tmux")

# Check what's running
terminal_status()

# Open in viewer (daemon already up — instant)
web_terminal("ttyd-tmux")

# Stop explicitly
terminal_stop("ttyd-tmux")
```

## Auto-start on login

webterminal never writes to your `.Rprofile`. It prints a snippet you
paste yourself:

``` r
webterminal_snippet("ttyd-tmux")
#> Add to ~/.Rprofile (e.g. via usethis::edit_r_profile()):
#> if (interactive() && requireNamespace("rstudioapi", quietly = TRUE) &&
#>     rstudioapi::isAvailable()) {
#>   try(webterminal::terminal_start("ttyd-tmux"), silent = TRUE)
#> }
```

## How it works

    Browser tab
        │
        ▼
    ALB / reverse proxy (existing)
        │
        ▼
    rserver (port 8787)
        │   validates auth cookie + port token
        │   forwards via /p/<hex>/ proxy
        ▼
    ttyd (127.0.0.1:<port>)
        │   xterm.js ↔ pty via WebSocket
        ▼
    bash / tmux session

1.  `terminal_start()` launches ttyd bound to `127.0.0.1` via the
    bundled shell script in `inst/scripts/`.
2.  `web_terminal()` calls `rstudioapi::viewer()` with the localhost
    URL.
3.  RStudio Server’s `rserver` process (controlled by
    `www-proxy-localhost=1` in `/etc/rstudio/rserver.conf`) rewrites
    this to a `/p/<hex>/` proxy URL and forwards HTTP + WebSocket
    Upgrade to the daemon.
4.  The terminal renders in your browser — native copy/paste, full
    color, no IDE overhead.

See `vignette("architecture")` for the full technical deep-dive
including security model, cross-user isolation, and load balancer
configuration.

## Configuration

| Option / env var                             | Purpose                        | Default                     |
|----------------------------------------------|--------------------------------|-----------------------------|
| `options(webterminal.backend = "ttyd-tmux")` | Default backend                | `"ttyd"`                    |
| `options(webterminal.port = 7681L)`          | Override base port             | Deterministic from `$USER`  |
| `WEBTERMINAL_PORT`                           | Override base port (env var)   | —                           |
| `WEBTERMINAL_TTYD`                           | Force ttyd binary path         | `Sys.which("ttyd")`         |
| `WEBTERMINAL_SHELLINABOXD`                   | Force shellinaboxd binary path | `Sys.which("shellinaboxd")` |

## Diagnostics

``` r
webterminal_doctor()
```

    ── webterminal doctor ───────────────────────
    [ok] ttyd:         /usr/bin/ttyd
        version:      ttyd version 1.7.4
    [!!] shellinaboxd: [NOT FOUND]
    [ok] tmux:         /usr/bin/tmux
        version:      tmux 3.4
    [ok] bash:         /usr/bin/bash
    [ok] ss:           /usr/bin/ss
    [ok] RStudio:      available

    No daemons running.
    ─────────────────────────────────────────────

## Related work

- [servr](https://github.com/yihui/servr) — in-process HTTP server for
  static files (similar port-management patterns)
- [httpgd](https://github.com/nx10/httpgd) — HTTP graphics device
  (similar `rstudioapi::viewer()` integration)
- [rstudioapi](https://rstudio.github.io/rstudioapi/) — the API that
  makes the `/p/<hex>/` viewer proxy work

## License

MIT
