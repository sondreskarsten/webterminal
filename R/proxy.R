open_viewer <- function(url, viewer = c("auto", "rstudio", "browser", "url")) {
  viewer <- match.arg(viewer)
  if (viewer == "url") return(invisible(url))
  is_rs <- rstudioapi::isAvailable()
  if (viewer == "auto") viewer <- if (is_rs) "rstudio" else "browser"
  if (viewer == "rstudio") {
    if (!is_rs) {
      raise_webterminal_error(
        "webterminal_rstudio_proxy_unavailable",
        "RStudio API not available. Use viewer = 'browser' instead.",
        "open_viewer"
      )
    }
    rstudioapi::viewer(url)
  } else {
    browseURL(url)
  }
  invisible(url)
}
