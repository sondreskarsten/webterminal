test_that("find_binary finds bash", {
  info <- webterminal:::find_binary("bash")
  expect_type(info, "list")
  expect_true(nzchar(info$path))
  expect_null(info$forced_by)
})

test_that("find_binary returns NULL for missing binary", {
  info <- webterminal:::find_binary("totally_nonexistent_binary_xyz")
  expect_null(info)
})

test_that("find_binary respects env var override", {
  withr::local_envvar(MY_TEST_BIN = "/usr/bin/bash")
  info <- webterminal:::find_binary("nonexistent", env_var = "MY_TEST_BIN")
  expect_equal(info$path, "/usr/bin/bash")
  expect_equal(info$forced_by, "MY_TEST_BIN")
})

test_that("require_binary raises classed error when missing", {
  expect_error(
    webterminal:::require_binary("totally_nonexistent_xyz"),
    class = "webterminal_totally_nonexistent_xyz_not_found"
  )
})

test_that("raise_webterminal_error produces correct class", {
  err <- tryCatch(
    webterminal:::raise_webterminal_error("webterminal_test_err", "boom", "test"),
    error = identity
  )
  expect_s3_class(err, "webterminal_test_err")
  expect_s3_class(err, "webterminal_error")
  expect_equal(err$message, "boom")
})
