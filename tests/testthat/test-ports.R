test_that("terminal_port is deterministic", {
  p1 <- webterminal:::terminal_port("ttyd")
  p2 <- webterminal:::terminal_port("ttyd")
  expect_identical(p1, p2)
})

test_that("different backends get different ports", {
  p_ttyd <- webterminal:::terminal_port("ttyd")
  p_tmux <- webterminal:::terminal_port("ttyd-tmux")
  p_sib <- webterminal:::terminal_port("shellinabox")
  expect_true(length(unique(c(p_ttyd, p_tmux, p_sib))) == 3L)
})

test_that("port option overrides default", {
  withr::local_options(webterminal.port = 9999L)
  expect_equal(webterminal:::terminal_port("ttyd"), 9999L)
  expect_equal(webterminal:::terminal_port("ttyd-tmux"), 10000L)
})

test_that("WEBTERMINAL_PORT env var overrides default", {
  withr::local_envvar(WEBTERMINAL_PORT = "8888")
  withr::local_options(webterminal.port = NULL)
  expect_equal(webterminal:::terminal_port("ttyd"), 8888L)
})

test_that("port_available returns TRUE for unused high port", {
  expect_true(webterminal:::port_available(59123L))
})
