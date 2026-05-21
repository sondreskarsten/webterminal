test_that("webterminal_snippet returns valid R code", {
  s <- webterminal_snippet("ttyd")
  expect_type(s, "character")
  expect_match(s, "webterminal::terminal_start")
  expect_match(s, "interactive()")
  parsed <- tryCatch(parse(text = s), error = identity)
  expect_false(inherits(parsed, "error"))
})

test_that("terminal_backends returns data.frame with correct rows", {
  out <- terminal_backends()
  expect_s3_class(out, "data.frame")
  expect_equal(nrow(out), 3L)
  expect_true("ttyd" %in% out$backend)
})

test_that("webterminal_doctor returns webterminal_config class", {
  skip_on_cran()
  config <- webterminal_doctor()
  expect_s3_class(config, "webterminal_config")
  expect_true(is.list(config$ttyd))
  expect_true(is.list(config$rstudio))
  expect_true(is.list(config$daemons))
})

test_that("format.webterminal_config produces readable output", {
  skip_on_cran()
  config <- webterminal_doctor()
  formatted <- format(config)
  expect_type(formatted, "character")
  expect_match(formatted, "webterminal doctor")
  expect_match(formatted, "ttyd:")
  expect_match(formatted, "bash:")
})
