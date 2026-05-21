#' Start or stop the terminal daemon
#'
#' `terminal_start()` launches a `ttyd` or `shellinabox` daemon bound
#' to `127.0.0.1` on a deterministic port. The daemon survives the R
#' session and must be stopped explicitly with `terminal_stop()`.
#'
#' `terminal_stop()` sends `SIGTERM` to the daemon on the given port
#' and removes it from the daemon registry.
#'
#' @param backend Character string naming the backend.
#'   One of `"ttyd"`, `"ttyd-tmux"`, or `"shellinabox"`.
#'   Defaults to `getOption("webterminal.backend", "ttyd")`.
#' @param port Integer port to bind. Defaults to the deterministic
#'   port computed from the current username and backend offset.
#' @param ... Reserved for future use.
#'
#' @returns For `terminal_start()`, the daemon record (a list with
#'   `pid`, `port`, `backend`, `started`), invisibly.
#'   For `terminal_stop()`, `TRUE` if a daemon was stopped, `FALSE`
#'   otherwise, invisibly.
#'
#' @family webterminal
#' @export
#' @examples
#' \dontrun{
#' terminal_start("ttyd")
#' terminal_stop("ttyd")
#' }
terminal_start <- function(backend = NULL, port = NULL, ...) {
  spec <- backend_spec(backend)
  if (is.null(port)) port <- terminal_port(spec$backend)
  if (port_listening(port)) {
    d <- find_daemon(port)
    if (!is.null(d)) {
      message(spec$backend, " already running on port ", port, " (pid ", d$pid, ")")
      return(invisible(d))
    }
    message("Port ", port, " is in use (not managed by webterminal)")
    return(invisible(NULL))
  }
  d <- spawn_daemon(spec$backend, port)
  message(spec$backend, " started on port ", port, " (pid ", d$pid, ")")
  if (interactive()) {
    message("Stop with: webterminal::terminal_stop(\"", spec$backend, "\")")
  }
  invisible(d)
}

#' @rdname terminal_start
#' @export
terminal_stop <- function(backend = NULL) {
  spec <- backend_spec(backend)
  port <- terminal_port(spec$backend)
  stopped <- kill_daemon(port)
  if (stopped) {
    message(spec$backend, " on port ", port, " stopped.")
  } else {
    message("No daemon found on port ", port, ".")
  }
  invisible(stopped)
}
