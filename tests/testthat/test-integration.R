test_that("terminal_start launches ttyd and terminal_stop kills it", {
  skip_on_cran()
  skip_if_no_ttyd()

  withr::local_options(webterminal.port = 59100L)
  withr::defer(try(terminal_stop("ttyd"), silent = TRUE))

  d <- terminal_start("ttyd", port = 59100L)
  expect_type(d, "list")
  expect_equal(d$port, 59100L)
  expect_true(webterminal:::port_listening(59100L))

  stopped <- terminal_stop("ttyd")
  expect_true(stopped)
  Sys.sleep(1)
  expect_false(webterminal:::port_listening(59100L))
})

test_that("terminal_status reports running daemon", {
  skip_on_cran()
  skip_if_no_ttyd()

  withr::local_options(webterminal.port = 59101L)
  withr::defer(try(terminal_stop("ttyd"), silent = TRUE))

  terminal_start("ttyd", port = 59101L)
  status <- terminal_status("ttyd")
  expect_true(status$running[status$backend == "ttyd"])
  terminal_stop("ttyd")
})

test_that("web_terminal returns URL with viewer = 'url'", {
  skip_on_cran()
  skip_if_no_ttyd()

  withr::local_options(webterminal.port = 59102L)
  withr::defer(try(terminal_stop("ttyd"), silent = TRUE))

  url <- web_terminal("ttyd", viewer = "url", start = TRUE)
  expect_match(url, "^http://127\\.0\\.0\\.1:59102/$")
  terminal_stop("ttyd")
})
