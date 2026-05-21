#' Start or stop the terminal daemon
#'
#' `terminal_start()` launches a `ttyd` or `shellinabox` daemon bound
#' to `127.0.0.1` on a deterministic port. The daemon survives the R
#' session and must be stopped explicitly with `terminal_stop()`.
#'
#' `terminal_stop()` sends `SIGTERM` to the daemon on the given port
#' and removes it from the daemon registry.
#'
#' @details
#' ## Daemon lifecycle
#'
#' Daemons are launched via `system2("bash", script, wait = FALSE)`
#' where the script (shipped in `inst/scripts/`) calls `nohup ttyd
#' ... &`. The forked process is **reparented to PID 1** — it is not
#' a child of the R process and is not affected by R session exit,
#' [q()], or `rstudio-server` restarts.
#'
#' The daemon's PID and metadata are recorded in a file at
#' `tools::R_user_dir("webterminal", "cache")/daemons.rds`. This
#' allows [terminal_status()] and `terminal_stop()` to find daemons
#' started in a previous R session. Dead PIDs are pruned
#' automatically on every status check.
#'
#' ## Port allocation
#'
#' When `port` is `NULL` (the default), the port is computed
#' deterministically:
#'
#' ```
#' base = 4200 + (sum of UTF-8 codepoints in $USER) mod 90
#' port = base + backend_offset
#' ```
#'
#' where `backend_offset` is 0 for `ttyd`, 1 for `ttyd-tmux`, and 2
#' for `shellinabox`. This means different backends for the same user
#' and different users on the same host get non-overlapping ports
#' without coordination.
#'
#' Override the base port with `options(webterminal.port = 7681L)` or
#' `Sys.setenv(WEBTERMINAL_PORT = "7681")`.
#'
#' ## Idempotency
#'
#' Calling `terminal_start()` when the daemon is already running
#' returns the existing daemon record and prints a message — it does
#' not launch a second instance.
#'
#' If the port is occupied by a process *not* managed by webterminal
#' (i.e. not in the daemon registry), `terminal_start()` prints a
#' warning and returns `NULL` invisibly.
#'
#' ## What terminal_stop does
#'
#' `terminal_stop()` resolves the port for the given backend, looks up
#' the PID (from the registry or via `ss -tlnp`), sends `SIGTERM` via
#' [tools::pskill()], waits 0.5 seconds, and removes the entry from
#' the registry. If the backend is `ttyd-tmux`, the underlying `tmux`
#' session is **not** killed — only the `ttyd` process is stopped. The
#' tmux session can be reattached by calling `terminal_start()` again.
#'
#' @param backend Character string naming the backend.
#'   One of `"ttyd"`, `"ttyd-tmux"`, or `"shellinabox"`.
#'   Defaults to `getOption("webterminal.backend", "ttyd")`.
#'   See [terminal_backends()] for backend properties.
#' @param port Integer port to bind. `NULL` (default) computes the
#'   deterministic port from the current username and backend offset.
#'   Specify explicitly to override, e.g. when running multiple
#'   instances of the same backend.
#' @param ... Reserved for future use.
#'
#' @returns For `terminal_start()`, the daemon record (a named list
#'   with elements `pid` (integer), `port` (integer), `backend`
#'   (character), `url` (character or `NULL`), and `started`
#'   (POSIXct)), invisibly. Returns `NULL` invisibly if the port is
#'   occupied by a non-webterminal process.
#'
#'   For `terminal_stop()`, `TRUE` if a daemon was found and stopped,
#'   `FALSE` otherwise, invisibly.
#'
#' @seealso
#' [web_terminal()] to start and open in one call,
#' [terminal_status()] to inspect running daemons,
#' [terminal_backends()] for backend comparison,
#' [webterminal_snippet()] for `.Rprofile` auto-start.
#'
#' @family webterminal
#' @export
#' @examples
#' \dontrun{
#' # Start the default backend
#' d <- terminal_start()
#' d$pid
#' d$port
#'
#' # Start a persistent terminal with tmux
#' terminal_start("ttyd-tmux")
#'
#' # Start on a specific port
#' terminal_start("ttyd", port = 9999L)
#'
#' # Check what's running
#' terminal_status()
#'
#' # Stop a specific backend
#' terminal_stop("ttyd")
#'
#' # Stop the tmux-backed terminal (tmux session survives)
#' terminal_stop("ttyd-tmux")
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
