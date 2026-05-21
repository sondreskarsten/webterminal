#' Show status of terminal backends
#'
#' Checks each configured backend's port and reports whether a daemon
#' is listening. Returns a data frame invisibly for programmatic use.
#'
#' @param backend Which backend(s) to check. `"all"` checks every
#'   known backend. Otherwise, one of `"ttyd"`, `"ttyd-tmux"`, or
#'   `"shellinabox"`.
#'
#' @returns A data frame with columns `backend`, `port`, `running`,
#'   `pid`, invisibly.
#'
#' @family webterminal
#' @export
#' @examples
#' \dontrun{
#' terminal_status()
#' terminal_status("ttyd")
#' }
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
