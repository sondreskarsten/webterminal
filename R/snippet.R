#' Generate an auto-start snippet for `.Rprofile`
#'
#' Prints a code snippet that can be pasted into `~/.Rprofile` to
#' automatically start a terminal daemon when RStudio Server starts.
#' The snippet is printed to the console; it is **never** written to
#' any file by this function.
#'
#' @param backend Character string naming the backend.
#'   One of `"ttyd"`, `"ttyd-tmux"`, or `"shellinabox"`.
#'   Defaults to `getOption("webterminal.backend", "ttyd")`.
#'
#' @returns The snippet as an invisible character string.
#'
#' @family webterminal helpers
#' @export
#' @examples
#' snippet <- webterminal_snippet("ttyd")
#' cat(snippet)
webterminal_snippet <- function(backend = NULL) {
  backend <- backend %||% getOption("webterminal.backend", "ttyd")
  backend <- match.arg(backend, BACKENDS$backend)
  snippet <- paste0(
    "if (interactive() && requireNamespace(\"rstudioapi\", quietly = TRUE) &&\n",
    "    rstudioapi::isAvailable()) {\n",
    "  try(webterminal::terminal_start(\"", backend, "\"), silent = TRUE)\n",
    "}\n"
  )
  message("Add to ~/.Rprofile (e.g. via usethis::edit_r_profile()):\n")
  cat(snippet)
  invisible(snippet)
}
