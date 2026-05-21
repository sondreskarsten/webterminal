test_that("web_terminal errors when daemon not running and start = FALSE", {
  local_mocked_bindings(
    port_listening = function(...) FALSE,
    .package = "webterminal"
  )
  expect_error(
    web_terminal("ttyd", viewer = "url", start = FALSE),
    class = "webterminal_daemon_unreachable"
  )
})

test_that("web_terminal errors when daemon not running in non-interactive + start = NA", {
  local_mocked_bindings(
    port_listening = function(...) FALSE,
    .package = "webterminal"
  )
  expect_error(
    web_terminal("ttyd", viewer = "url", start = NA),
    class = "webterminal_daemon_unreachable"
  )
})

test_that("web_terminal returns URL when daemon is running", {
  local_mocked_bindings(
    port_listening = function(...) TRUE,
    open_viewer = function(url, ...) invisible(url),
    .package = "webterminal"
  )
  url <- web_terminal("ttyd", viewer = "url")
  expect_match(url, "^http://127\\.0\\.0\\.1:\\d+/$")
})

test_that("web_terminal respects backend option", {
  withr::local_options(webterminal.backend = "shellinabox")
  local_mocked_bindings(
    port_listening = function(...) TRUE,
    open_viewer = function(url, ...) invisible(url),
    .package = "webterminal"
  )
  url <- web_terminal(viewer = "url")
  port <- webterminal:::terminal_port("shellinabox")
  expect_match(url, as.character(port), fixed = TRUE)
})

test_that("web_terminal spawns daemon when start = TRUE and daemon down", {
  spawn_called <- FALSE
  local_mocked_bindings(
    port_listening = function(...) FALSE,
    spawn_daemon = function(...) { spawn_called <<- TRUE; list(pid = 999L) },
    open_viewer = function(url, ...) invisible(url),
    .package = "webterminal"
  )
  web_terminal("ttyd", viewer = "url", start = TRUE)
  expect_true(spawn_called)
})
