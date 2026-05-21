#' List available terminal backends
#'
#' Returns the backend specification table showing each backend's
#' name, transport type, persistence, required binary, and launcher
#' script.
#'
#' @returns A data frame with one row per backend, invisibly.
#'
#' @family webterminal
#' @export
#' @examples
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
