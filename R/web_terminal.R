#' Open a web terminal in the RStudio viewer
#'
#' Opens a browser-based terminal connected to a locally running
#' `ttyd` or `shellinabox` daemon. If the daemon is not running and
#' `start` is `TRUE` (or `NA` in an interactive session), it will be
#' started automatically.
#'
#' @details
#' `web_terminal()` is the primary user-facing entry point. It
#' combines daemon management and viewer dispatch in a single call:
#'
#' 1. Resolves the backend (from the argument, then
#'    `getOption("webterminal.backend")`, then `"ttyd"`).
#' 2. Computes the deterministic port for that backend and user
#'    (see [terminal_start()] for the port-allocation scheme).
#' 3. Probes the port via TCP `socketConnection()`. If the daemon is
#'    not listening and `start` permits, launches it via the bundled
#'    shell script in `inst/scripts/`.
#' 4. Calls [rstudioapi::viewer()] (or [utils::browseURL()] outside
#'    RStudio) with `http://127.0.0.1:<port>/`. On RStudio Server,
#'    the IDE rewrites this to a `/p/<hex>/` proxy URL that forwards
#'    through the existing ingress port.
#'
#' ## The `/p/<hex>/` proxy
#'
#' Open-source RStudio Server includes a built-in reverse proxy for
#' localhost ports, controlled by `www-proxy-localhost=1` in
#' `/etc/rstudio/rserver.conf` (on by default). When
#' [rstudioapi::viewer()] receives a `http://127.0.0.1:<port>/` URL,
#' the server computes a scrambled 8–9 hex-digit token from a
#' per-user port cookie and the port number, then serves the proxied
#' content at `https://<host>/p/<hex>/`. Both HTTP and WebSocket
#' Upgrade are forwarded. This is the same mechanism that powers
#' Shiny apps and Plumber APIs in the Viewer pane.
#'
#' The proxy inherits RStudio Server's authentication — requests
#' without a valid session cookie are redirected to the login page.
#' Cross-user access is prevented by UID validation on the
#' per-user Unix-domain socket. The daemon **must** bind to
#' `127.0.0.1` (not `0.0.0.0`) so it is only reachable through the
#' proxy, never directly from the network.
#'
#' ## Daemon lifecycle
#'
#' The daemon is a **detached process** — it survives R session exit,
#' `q()`, and even `rstudio-server` restarts. Stop it explicitly
#' with [terminal_stop()] or by killing the PID shown in
#' [terminal_status()].
#'
#' When `viewer = "url"`, no viewer or browser is opened; the URL is
#' returned invisibly. This is useful for scripting or passing the URL
#' to another tool.
#'
#' @param backend Character string naming the backend.
#'   One of `"ttyd"`, `"ttyd-tmux"`, or `"shellinabox"`.
#'   Defaults to `getOption("webterminal.backend", "ttyd")`.
#'   See [terminal_backends()] for a comparison of transport,
#'   persistence, and system requirements.
#' @param viewer How to open the terminal:
#'   \describe{
#'     \item{`"auto"`}{(default) Uses the RStudio Viewer pane when
#'       [rstudioapi::isAvailable()] is `TRUE`, otherwise falls back
#'       to [utils::browseURL()].}
#'     \item{`"rstudio"`}{Forces the Viewer pane. Raises
#'       `webterminal_rstudio_proxy_unavailable` if RStudio is not
#'       detected.}
#'     \item{`"browser"`}{Forces the system browser via
#'       [utils::browseURL()].}
#'     \item{`"url"`}{Returns the URL invisibly without opening
#'       anything. Useful for piping or programmatic use.}
#'   }
#' @param start Whether to start the daemon if it is not running:
#'   \describe{
#'     \item{`NA`}{(default) Starts the daemon in interactive
#'       sessions; raises `webterminal_daemon_unreachable` in
#'       non-interactive sessions (e.g. `Rscript`, `R CMD check`).}
#'     \item{`TRUE`}{Always starts the daemon, even
#'       non-interactively.}
#'     \item{`FALSE`}{Never starts the daemon; errors if not already
#'       running.}
#'   }
#'
#' @returns The terminal URL as a character string, invisibly.
#'
#' @seealso
#' [terminal_start()] and [terminal_stop()] for explicit daemon
#' lifecycle control, [terminal_status()] to check running daemons,
#' [webterminal_doctor()] to diagnose the setup,
#' [webterminal_snippet()] for `.Rprofile` auto-start.
#'
#' @family webterminal
#' @export
#' @examples
#' # Always runs — no system deps needed
#' terminal_backends()
#'
#' @examplesIf interactive() && nzchar(Sys.which("ttyd"))
#' # Start ttyd, get the URL, then stop
#' url <- web_terminal("ttyd", viewer = "url", start = TRUE)
#' url
#' terminal_stop("ttyd")
#'
#' # Persistent terminal with tmux
#' web_terminal("ttyd-tmux", viewer = "url", start = TRUE)
#' terminal_stop("ttyd-tmux")
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
