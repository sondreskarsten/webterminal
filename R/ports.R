terminal_port <- function(backend = NULL) {
  spec <- backend_spec(backend)
  base <- getOption("webterminal.port", NULL)
  if (!is.null(base)) return(as.integer(base) + spec$port_offset)
  port_env <- Sys.getenv("WEBTERMINAL_PORT", "")
  if (nzchar(port_env)) return(as.integer(port_env) + spec$port_offset)
  user <- Sys.getenv("USER", Sys.getenv("LOGNAME", "default"))
  hash <- sum(utf8ToInt(user)) %% 90L
  4200L + hash + spec$port_offset
}

port_available <- function(port, host = "127.0.0.1") {
  tryCatch({
    con <- suppressWarnings(socketConnection(
      host = host, port = port, open = "r",
      blocking = TRUE, timeout = 1L
    ))
    close(con)
    FALSE
  }, error = function(e) {
    if (grepl("refused", conditionMessage(e), ignore.case = TRUE)) return(TRUE)
    if (grepl("timed out|timeout", conditionMessage(e), ignore.case = TRUE)) return(TRUE)
    TRUE
  })
}

port_listening <- function(port, host = "127.0.0.1") {
  !port_available(port, host)
}
