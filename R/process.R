wtEnv <- new.env(parent = emptyenv())
wtEnv$daemons <- list()

daemon_cache_path <- function() {
  dir <- R_user_dir("webterminal", "cache")
  if (!dir.exists(dir)) dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  file.path(dir, "daemons.rds")
}

load_daemon_cache <- function() {
  path <- daemon_cache_path()
  if (file.exists(path)) {
    tryCatch(readRDS(path), error = function(e) list())
  } else {
    list()
  }
}

save_daemon_cache <- function(daemons) {
  tryCatch(
    saveRDS(daemons, daemon_cache_path()),
    error = function(e) NULL
  )
}

pid_alive <- function(pid) {
  tryCatch(pskill(pid, signal = 0L), error = function(e) FALSE)
}

prune_dead <- function(daemons) {
  alive <- vapply(daemons, function(d) pid_alive(d$pid), logical(1))
  daemons[alive]
}

register_daemon <- function(pid, port, backend, url = NULL) {
  d <- list(
    pid = as.integer(pid),
    port = as.integer(port),
    backend = backend,
    url = url,
    started = Sys.time()
  )
  daemons <- load_daemon_cache()
  daemons <- prune_dead(daemons)
  daemons[[length(daemons) + 1L]] <- d
  save_daemon_cache(daemons)
  wtEnv$daemons <- daemons
  invisible(d)
}

unregister_daemon <- function(port) {
  daemons <- load_daemon_cache()
  daemons <- Filter(function(d) d$port != port, daemons)
  save_daemon_cache(daemons)
  wtEnv$daemons <- daemons
  invisible(NULL)
}

find_daemon <- function(port) {
  daemons <- prune_dead(load_daemon_cache())
  save_daemon_cache(daemons)
  wtEnv$daemons <- daemons
  matches <- Filter(function(d) d$port == port, daemons)
  if (length(matches)) matches[[1L]] else NULL
}

spawn_daemon <- function(backend = NULL, port = NULL) {
  spec <- backend_spec(backend)
  if (is.null(port)) port <- terminal_port(spec$backend)

  if (spec$needs_tmux) {
    require_binary("tmux", install_hint = "sudo apt-get install tmux")
  }

  bin <- require_binary(
    spec$binary,
    env_var = if (spec$binary == "ttyd") "WEBTERMINAL_TTYD" else "WEBTERMINAL_SHELLINABOXD",
    install_hint = paste0("sudo apt-get install ", spec$binary)
  )

  script <- system.file("scripts", spec$script, package = "webterminal")
  if (!nzchar(script) || !file.exists(script)) {
    raise_webterminal_error(
      "webterminal_script_missing",
      paste0("Launcher script '", spec$script, "' not found in package installation."),
      "spawn_daemon"
    )
  }

  Sys.setenv(WEBTERMINAL_PORT = as.character(port))
  if (!is.null(bin$path)) Sys.setenv(WEBTERMINAL_BIN = bin$path)

  system2("bash", script, wait = FALSE, stdout = FALSE, stderr = FALSE)
  Sys.sleep(1)

  if (!port_listening(port)) {
    Sys.sleep(2)
    if (!port_listening(port)) {
      raise_webterminal_error(
        "webterminal_daemon_unreachable",
        paste0(
          "Daemon '", spec$backend, "' was launched but port ", port,
          " is not responding after 3 seconds."
        ),
        "spawn_daemon"
      )
    }
  }

  pid <- find_pid_on_port(port)
  register_daemon(pid = pid, port = port, backend = spec$backend)
}

find_pid_on_port <- function(port) {
  ss_info <- find_ss()
  if (is.null(ss_info)) return(NA_integer_)
  out <- tryCatch(
    system2(
      ss_info$path,
      c("-tlnp", paste0("sport = :", port)),
      stdout = TRUE, stderr = FALSE
    ),
    error = function(e) character(0)
  )
  if (length(out) < 2L) return(NA_integer_)
  m <- regmatches(out, regexpr("pid=([0-9]+)", out))
  if (length(m) == 0L) return(NA_integer_)
  as.integer(sub("pid=", "", m[[1L]]))
}

kill_daemon <- function(port) {
  d <- find_daemon(port)
  if (is.null(d)) {
    pid <- find_pid_on_port(port)
    if (is.na(pid)) return(invisible(FALSE))
  } else {
    pid <- d$pid
  }
  if (!is.na(pid)) pskill(pid, SIGTERM)
  Sys.sleep(0.5)
  unregister_daemon(port)
  invisible(TRUE)
}
