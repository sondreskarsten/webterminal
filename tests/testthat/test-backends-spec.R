test_that("BACKENDS has expected structure", {
  expect_s3_class(webterminal:::BACKENDS, "data.frame")
  expect_true(all(c("backend", "port_offset", "transport", "persistent",
                     "script", "binary", "needs_tmux") %in% names(webterminal:::BACKENDS)))
  expect_equal(nrow(webterminal:::BACKENDS), 3L)
})

test_that("backend_spec returns correct backend", {
  spec <- webterminal:::backend_spec("ttyd")
  expect_equal(spec$backend, "ttyd")
  expect_equal(spec$binary, "ttyd")
  expect_false(spec$needs_tmux)
})

test_that("backend_spec validates input", {
  expect_error(webterminal:::backend_spec("nonexistent"), "arg")
})

test_that("default backend respects option", {
  withr::local_options(webterminal.backend = "shellinabox")
  spec <- webterminal:::backend_spec()
  expect_equal(spec$backend, "shellinabox")
})
