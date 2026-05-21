#' List available terminal backends
#'
#' Returns the backend specification table showing each backend's
#' name, transport type, persistence, required binary, and launcher
#' script. Also checks whether each binary is installed.
#'
#' @details
#' webterminal supports three backends:
#'
#' \describe{
#'   \item{`ttyd`}{Lightweight web terminal using WebSocket transport
#'     via libwebsockets. Ephemeral — closing the browser tab ends the
#'     shell. Fastest option.}
#'   \item{`ttyd-tmux`}{Same `ttyd` daemon, but wrapping a `tmux`
#'     session. Persistent — closing the tab does not kill the shell;
#'     reconnecting reattaches with full scrollback. Recommended for
#'     daily use.}
#'   \item{`shellinabox`}{AJAX long-polling transport. Persistent via
#'     `tmux`. Noticeably slower than `ttyd`; use only when `ttyd` is
#'     unavailable. Last upstream release: v2.21 (2018).}
#' }
#'
#' The printed output shows the transport type, persistence mode, and
#' whether each binary is found on `PATH`. The returned data frame
#' includes the script name and binary name for each backend.
#'
#' @returns A data frame with columns `backend`, `port_offset`,
#'   `transport`, `persistent`, `script`, `binary`, `needs_tmux`,
#'   invisibly.
#'
#' @seealso
#' [web_terminal()] to open a terminal, [terminal_start()] to launch
#' a specific backend, [webterminal_doctor()] for a full diagnostic.
#'
#' @family webterminal
#' @export
#' @examples
#' # This runs without system dependencies
#' terminal_backends()
terminal_backends <- function() {
  out <- BACKENDS
  for (i in seq_len(nrow(out))) {
    bin <- find_binary(out$binary[i])
    installed <- if (!is.null(bin)) "installed" else "not found"
    message(
      out$backend[i], ": ",
      out$transport[i], " transport, ",
      if (out$persistent[i]) "persistent" else "ephemeral", ", ",
      out$binary[i], " (", installed, ")"
    )
  }
  invisible(out)
}
