test_that("open_viewer returns URL invisibly with viewer = 'url'", {
  url <- webterminal:::open_viewer("http://127.0.0.1:7681/", "url")
  expect_equal(url, "http://127.0.0.1:7681/")
})

test_that("open_viewer errors on rstudio viewer when not available", {
  local_mocked_bindings(
    isAvailable = function() FALSE,
    .package = "rstudioapi"
  )
  expect_error(
    webterminal:::open_viewer("http://127.0.0.1:7681/", "rstudio"),
    class = "webterminal_rstudio_proxy_unavailable"
  )
})

test_that("open_viewer falls back to browseURL when auto + no rstudio", {
  browser_called <- FALSE
  local_mocked_bindings(
    isAvailable = function() FALSE,
    .package = "rstudioapi"
  )
  local_mocked_bindings(
    browseURL = function(...) { browser_called <<- TRUE },
    .package = "webterminal"
  )
  webterminal:::open_viewer("http://127.0.0.1:7681/", "auto")
  expect_true(browser_called)
})

test_that("open_viewer calls rstudioapi::viewer when auto + rstudio available", {
  viewer_called <- FALSE
  local_mocked_bindings(
    isAvailable = function() TRUE,
    viewer = function(...) { viewer_called <<- TRUE },
    .package = "rstudioapi"
  )
  webterminal:::open_viewer("http://127.0.0.1:7681/", "auto")
  expect_true(viewer_called)
})
