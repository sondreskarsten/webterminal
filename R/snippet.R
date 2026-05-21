#' Generate an auto-start snippet for `.Rprofile`
#'
#' Prints a code snippet that can be pasted into `~/.Rprofile` to
#' automatically start a terminal daemon when RStudio Server starts.
#' The snippet is printed to the console; it is **never** written to
#' any file by this function.
#'
#' @details
#' The generated snippet is guarded by `interactive()` and
#' `rstudioapi::isAvailable()`, so it will not fire during
#' `Rscript`, `R CMD check`, or RMarkdown rendering. It uses
#' `try(..., silent = TRUE)` so a missing `ttyd` binary does not
#' block R startup.
#'
#' To install the snippet, open your `.Rprofile` (e.g. via
#' `usethis::edit_r_profile()`) and paste the printed text.
#' webterminal deliberately does not write to `.Rprofile` itself
#' — this is a CRAN policy requirement (packages must not write to
#' the user's home filespace without explicit confirmation).
#'
#' The snippet calls [terminal_start()], not [web_terminal()], so it
#' starts the daemon without opening a viewer. Call [web_terminal()]
#' manually when you want to see the terminal.
#'
#' @param backend Character string naming the backend.
#'   One of `"ttyd"`, `"ttyd-tmux"`, or `"shellinabox"`.
#'   Defaults to `getOption("webterminal.backend", "ttyd")`.
#'
#' @returns The snippet as an invisible character string (valid R
#'   code that can be parsed with [parse()]).
#'
#' @seealso
#' [terminal_start()] which the snippet calls,
#' [webterminal_doctor()] which also prints the snippet when no
#' backend is installed.
#'
#' @family webterminal helpers
#' @export
#' @examples
#' # This runs without system dependencies
#' snippet <- webterminal_snippet("ttyd")
#' cat(snippet)
#'
#' # Verify the snippet is valid R
#' parse(text = snippet)
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
