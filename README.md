# webterminal

<!-- badges: start -->
<!-- badges: end -->

Fast browser-based terminal for RStudio Server using `ttyd` or
`shellinabox`, accessible through the built-in localhost URL proxy.

## Installation

```r
# From GitHub
pak::pak("sondreskarsten/webterminal")
```

System dependencies (install once):

```bash
sudo apt-get install ttyd tmux iproute2
```

## Usage

```r
library(webterminal)

# Check setup
webterminal_doctor()

# Open a terminal in the RStudio viewer
web_terminal()

# Explicit lifecycle
terminal_start("ttyd-tmux")
terminal_status()
terminal_stop("ttyd-tmux")

# Show .Rprofile auto-start snippet
webterminal_snippet()
```

## How it works

1. `terminal_start()` launches `ttyd` (or `shellinaboxd`) bound to
   `127.0.0.1` on a deterministic port.
2. `web_terminal()` calls `rstudioapi::viewer()` with the localhost URL.
3. RStudio Server's built-in `/p/<hex>/` reverse proxy forwards the
   request to the daemon.
4. The terminal opens in your browser — native copy/paste, WebSocket
   transport, optional `tmux` persistence.

## License

MIT
