#' Diagnose the webterminal setup
#'
#' Checks for required system binaries, RStudio Server availability,
#' port status, and prints a structured report with actionable hints
#' for anything missing.
#'
#' @details
#' `webterminal_doctor()` is the recommended first function to call
#' after installing the package. It performs the following checks:
#'
#' \describe{
#'   \item{Binary detection}{Searches for `ttyd`, `shellinaboxd`,
#'     `tmux`, `bash`, and `ss` using the same precedence as
#'     [terminal_start()]: environment variable override (e.g.
#'     `WEBTERMINAL_TTYD`), then `Sys.which()`. Reports the path and
#'     version of each found binary.}
#'   \item{RStudio detection}{Calls
#'     [rstudioapi::isAvailable()] to determine whether the
#'     `/p/<hex>/` viewer proxy will work.}
#'   \item{Daemon inventory}{Reads the daemon registry from
#'     `tools::R_user_dir("webterminal", "cache")/daemons.rds`,
#'     prunes dead PIDs, and lists surviving daemons with their port,
#'     PID, and start time.}
#'   \item{Install hints}{If no backend binary is found, prints the
#'     `apt-get install` command and a `.Rprofile` auto-start snippet.}
#' }
#'
#' The return value is a list of class `"webterminal_config"` with a
#' custom `format()` method that produces the printed report. The
#' object can be stored and re-printed, or its elements accessed
#' programmatically:
#'
#' ```
#' cfg <- webterminal_doctor()
#' cfg$ttyd$path       # "/usr/bin/ttyd" or NA
#' cfg$ttyd$version    # "ttyd version 1.7.4" or NA
#' cfg$ttyd$forced_by  # "WEBTERMINAL_TTYD" or NULL
#' cfg$rstudio$available  # TRUE or FALSE
#' cfg$daemons            # list of daemon records
#' ```
#'
#' @returns A list of class `"webterminal_config"` with elements:
#' \describe{
#'   \item{`ttyd`}{List with `path`, `version`, `forced_by`.}
#'   \item{`shellinaboxd`}{List with `path`, `version`, `forced_by`.}
#'   \item{`tmux`}{List with `path`, `version`.}
#'   \item{`bash`}{List with `path`.}
#'   \item{`ss`}{List with `path`.}
#'   \item{`rstudio`}{List with `available` (logical).}
#'   \item{`daemons`}{List of daemon records (each a list with `pid`,
#'     `port`, `backend`, `url`, `started`). Empty list if none
#'     running.}
#'   \item{`platform`}{Character. Operating system name from
#'     `Sys.info()`.}
#' }
#' Returned invisibly; the report is printed as a side effect.
#'
#' @seealso
#' [terminal_backends()] for a quick backend overview without system
#' probing, [terminal_status()] for daemon-only status,
#' [webterminal_snippet()] for the `.Rprofile` auto-start snippet.
#'
#' @family webterminal helpers
#' @export
#' @examples
#' # Runs without system deps — reports what's found and what's missing
#' cfg <- webterminal_doctor()
#'
#' # Access programmatically
#' cfg$ttyd$path
#' cfg$rstudio$available
#' length(cfg$daemons)
webterminal_doctor <- function() {
  ttyd <- find_ttyd()
  shellinaboxd <- find_shellinaboxd()
  tmux <- find_tmux()
  bash_info <- find_binary("bash")
  ss <- find_ss()

  ttyd_ver <- if (!is.null(ttyd)) binary_version(ttyd$path, "--version") else NA_character_
  shellinaboxd_ver <- if (!is.null(shellinaboxd)) binary_version(shellinaboxd$path, "--version") else NA_character_
  tmux_ver <- if (!is.null(tmux)) binary_version(tmux$path, "-V") else NA_character_

  is_rs <- rstudioapi::isAvailable()

  daemons <- prune_dead(load_daemon_cache())
  save_daemon_cache(daemons)

  config <- structure(
    list(
      ttyd = list(
        path = if (!is.null(ttyd)) ttyd$path else NA_character_,
        version = ttyd_ver,
        forced_by = if (!is.null(ttyd)) ttyd$forced_by else NULL
      ),
      shellinaboxd = list(
        path = if (!is.null(shellinaboxd)) shellinaboxd$path else NA_character_,
        version = shellinaboxd_ver,
        forced_by = if (!is.null(shellinaboxd)) shellinaboxd$forced_by else NULL
      ),
      tmux = list(
        path = if (!is.null(tmux)) tmux$path else NA_character_,
        version = tmux_ver
      ),
      bash = list(path = if (!is.null(bash_info)) bash_info$path else NA_character_),
      ss = list(path = if (!is.null(ss)) ss$path else NA_character_),
      rstudio = list(available = is_rs),
      daemons = daemons,
      platform = Sys.info()[["sysname"]]
    ),
    class = "webterminal_config"
  )

  print(config)
  invisible(config)
}

#' @rdname webterminal_doctor
#' @param x A `webterminal_config` object returned by
#'   [webterminal_doctor()].
#' @param ... Additional arguments (currently unused).
#' @export
print.webterminal_config <- function(x, ...) {
  cat(format(x, ...), sep = "")
  invisible(x)
}

#' @rdname webterminal_doctor
#' @export
format.webterminal_config <- function(x, ...) {
  ok <- function(v) !is.na(v) && nzchar(v)
  icon <- function(test) if (test) "[ok]" else "[!!]"
  out <- "-- webterminal doctor -----------------------\n"
  out <- paste0(out, icon(ok(x$ttyd$path)), " ttyd:         ",
                if (ok(x$ttyd$path)) x$ttyd$path else "[NOT FOUND]", "\n")
  if (ok(x$ttyd$version))
    out <- paste0(out, "    version:      ", x$ttyd$version, "\n")
  if (!is.null(x$ttyd$forced_by))
    out <- paste0(out, "\nNOTE: ttyd path was forced by ", x$ttyd$forced_by, "\n\n")
  out <- paste0(out, icon(ok(x$shellinaboxd$path)), " shellinaboxd: ",
                if (ok(x$shellinaboxd$path)) x$shellinaboxd$path else "[NOT FOUND]", "\n")
  out <- paste0(out, icon(ok(x$tmux$path)), " tmux:         ",
                if (ok(x$tmux$path)) x$tmux$path else "[NOT FOUND]", "\n")
  if (ok(x$tmux$version))
    out <- paste0(out, "    version:      ", x$tmux$version, "\n")
  out <- paste0(out, icon(ok(x$bash$path)), " bash:         ",
                if (ok(x$bash$path)) x$bash$path else "[NOT FOUND]", "\n")
  out <- paste0(out, icon(ok(x$ss$path)), " ss:           ",
                if (ok(x$ss$path)) x$ss$path else "[NOT FOUND]", "\n")
  out <- paste0(out, icon(x$rstudio$available), " RStudio:      ",
                if (x$rstudio$available) "available" else "not detected", "\n")

  if (!ok(x$ttyd$path) && !ok(x$shellinaboxd$path)) {
    out <- paste0(out, "\nNo backend found. Install with:\n",
                  "  sudo apt-get install ttyd tmux iproute2\n")
  }

  nd <- length(x$daemons)
  if (nd > 0L) {
    out <- paste0(out, "\nRunning daemons (", nd, "):\n")
    for (d in x$daemons) {
      out <- paste0(out, "  ", d$backend, " port ", d$port,
                    " pid ", d$pid, " since ", format(d$started), "\n")
    }
  } else {
    out <- paste0(out, "\nNo daemons running.\n")
  }

  out <- paste0(out, "--------------------------------------------\n")

  if (!ok(x$ttyd$path) && !ok(x$shellinaboxd$path)) {
    out <- paste0(out, "\nAuto-start snippet for ~/.Rprofile:\n\n",
                  "  if (interactive() && requireNamespace(\"rstudioapi\", quietly = TRUE) &&\n",
                  "      rstudioapi::isAvailable()) {\n",
                  "    try(webterminal::terminal_start(\"ttyd\"), silent = TRUE)\n",
                  "  }\n")
  }

  out
}
