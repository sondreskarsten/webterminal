#' Open a web terminal in the RStudio viewer
#'
#' Opens a browser-based terminal connected to a locally running
#' `ttyd` or `shellinabox` daemon. If the daemon is not running and
#' `start` is `TRUE` (or `NA` in an interactive session), it will be
#' started automatically.
#'
#' @param backend Character string naming the backend.
#'   One of `"ttyd"`, `"ttyd-tmux"`, or `"shellinabox"`.
#'   Defaults to `getOption("webterminal.backend", "ttyd")`.
#' @param viewer How to open the terminal. `"auto"` uses the RStudio
#'   viewer pane when available, otherwise `browseURL()`. `"rstudio"`
#'   forces the viewer pane (errors if unavailable). `"browser"` forces
#'   the system browser. `"url"` returns the URL without opening
#'   anything.
#' @param start Whether to start the daemon if it is not running.
#'   `NA` (default) starts in interactive sessions and errors in
#'   non-interactive sessions. `TRUE` always starts. `FALSE` never
#'   starts.
#'
#' @returns The terminal URL, invisibly.
#'
#' @family webterminal
#' @export
#' @examples
#' \dontrun{
#' web_terminal()
#' web_terminal("ttyd-tmux")
#' url <- web_terminal(viewer = "url")
#' }
web_terminal <- function(backend = NULL,
                         viewer = c("auto", "rstudio", "browser", "url"),
                         start = NA) {
  viewer <- match.arg(viewer)
  spec <- backend_spec(backend)
  port <- terminal_port(spec$backend)

  if (!port_listening(port)) {
    should_start <- if (is.na(start)) interactive() else isTRUE(start)
    if (!should_start) {
      raise_webterminal_error(
        "webterminal_daemon_unreachable",
        paste0(
          spec$backend, " is not running on port ", port, ".\n",
          "Start it with: webterminal::terminal_start(\"", spec$backend, "\")"
        ),
        "web_terminal"
      )
    }
    spawn_daemon(spec$backend, port)
  }

  url <- sprintf("http://127.0.0.1:%d/", port)
  open_viewer(url, viewer)
}
