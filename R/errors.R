raise_webterminal_error <- function(code, message, where = "") {
  cl <- if (nzchar(where)) call("::", quote(webterminal), as.name(where)) else NULL
  e <- structure(
    class = c(code, "webterminal_error", "error", "condition"),
    list(message = message, call = cl)
  )
  stop(e)
}
