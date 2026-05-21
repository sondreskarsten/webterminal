BACKENDS <- data.frame(
  backend     = c("ttyd", "ttyd-tmux", "shellinabox"),
  port_offset = c(0L, 1L, 2L),
  transport   = c("websocket", "websocket", "ajax"),
  persistent  = c(FALSE, TRUE, TRUE),
  script      = c("start-ttyd.sh", "start-ttyd-tmux.sh", "start-shellinabox.sh"),
  binary      = c("ttyd", "ttyd", "shellinaboxd"),
  needs_tmux  = c(FALSE, TRUE, TRUE),
  stringsAsFactors = FALSE
)

backend_spec <- function(backend = NULL) {
  backend <- backend %||% getOption("webterminal.backend", "ttyd")
  backend <- match.arg(backend, BACKENDS$backend)
  as.list(BACKENDS[BACKENDS$backend == backend, ])
}

`%||%` <- function(x, y) if (is.null(x)) y else x
