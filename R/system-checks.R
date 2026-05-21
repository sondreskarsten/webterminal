find_binary <- function(name, env_var = NULL) {
  if (!is.null(env_var)) {
    forced <- Sys.getenv(env_var, "")
    if (nzchar(forced) && file.exists(forced)) {
      return(list(path = forced, forced_by = env_var))
    }
  }
  path <- Sys.which(name)
  if (nzchar(path)) return(list(path = unname(path), forced_by = NULL))
  NULL
}

find_ttyd <- function() {
  find_binary("ttyd", "WEBTERMINAL_TTYD")
}

find_shellinaboxd <- function() {
  find_binary("shellinaboxd", "WEBTERMINAL_SHELLINABOXD")
}

find_tmux <- function() {
  find_binary("tmux")
}

find_ss <- function() {
  find_binary("ss")
}

binary_version <- function(path, flag = "--version") {
  tryCatch({
    out <- system2(path, flag, stdout = TRUE, stderr = TRUE)
    paste(out, collapse = " ")
  }, error = function(e) NA_character_)
}

require_binary <- function(name, env_var = NULL, install_hint = NULL) {
  info <- find_binary(name, env_var)
  if (!is.null(info)) return(info)
  hint <- if (!is.null(install_hint)) {
    paste0("\nInstall with: ", install_hint)
  } else {
    ""
  }
  raise_webterminal_error(
    code = paste0("webterminal_", gsub("[^a-z]", "_", name), "_not_found"),
    message = paste0("'", name, "' not found on PATH.", hint),
    where = "require_binary"
  )
}
