#' Show status of terminal backends
#'
#' Checks each configured backend's port and reports whether a daemon
#' is listening. Returns a data frame invisibly for programmatic use.
#'
#' @details
#' For each backend, `terminal_status()` computes the deterministic
#' port, probes it via TCP `socketConnection()`, and looks up the PID
#' from the daemon registry (see [terminal_start()] for registry
#' details). Dead PIDs are pruned automatically.
#'
#' The printed output uses `[+]` for running daemons and `[-]` for
#' stopped ones, with the PID shown in parentheses when available.
#'
#' The returned data frame has one row per checked backend with
#' columns:
#' \describe{
#'   \item{`backend`}{Character. Backend name.}
#'   \item{`port`}{Integer. The port checked.}
#'   \item{`running`}{Logical. `TRUE` if something is listening.}
#'   \item{`pid`}{Integer. The daemon's PID from the registry, or
#'     `NA` if not tracked or not running.}
#' }
#'
#' @param backend Which backend(s) to check. `"all"` (default) checks
#'   every known backend. Otherwise, one of `"ttyd"`, `"ttyd-tmux"`,
#'   or `"shellinabox"`. See [terminal_backends()] for the full list.
#'
#' @returns A data frame with columns `backend`, `port`, `running`,
#'   `pid`, invisibly. Can be used programmatically, e.g.
#'   `subset(terminal_status(), running)`.
#'
#' @seealso
#' [terminal_start()] and [terminal_stop()] for daemon lifecycle,
#' [web_terminal()] to open a running daemon in the viewer,
#' [webterminal_doctor()] for a full diagnostic report.
#'
#' @family webterminal
#' @export
#' @examples
#' # Runs without system deps — reports all backends as stopped
#' terminal_status()
#' terminal_status("ttyd")
#'
#' # Use programmatically
#' s <- terminal_status()
#' s[s$running, ]
terminal_status <- function(backend = "all") {
  if (identical(backend, "all")) {
    backends <- BACKENDS$backend
  } else {
    backends <- match.arg(backend, BACKENDS$backend)
  }

  rows <- lapply(backends, function(b) {
    port <- terminal_port(b)
    running <- port_listening(port)
    d <- if (running) find_daemon(port) else NULL
    pid <- if (!is.null(d)) d$pid else NA_integer_
    data.frame(
      backend = b,
      port = port,
      running = running,
      pid = pid,
      stringsAsFactors = FALSE
    )
  })
  out <- do.call(rbind, rows)

  for (i in seq_len(nrow(out))) {
    icon <- if (out$running[i]) "[+]" else "[-]"
    pid_str <- if (!is.na(out$pid[i])) paste0(" (pid ", out$pid[i], ")") else ""
    message(icon, " ", out$backend[i], " port ", out$port[i], pid_str)
  }

  invisible(out)
}
