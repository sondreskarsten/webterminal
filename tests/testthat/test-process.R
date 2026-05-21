test_that("daemon_cache_path creates directory if missing", {
  withr::local_envvar(R_USER_CACHE_DIR = tempdir())
  path <- webterminal:::daemon_cache_path()
  expect_true(dir.exists(dirname(path)))
  expect_match(basename(path), "daemons.rds")
})

test_that("register and find daemon round-trips", {
  withr::local_envvar(R_USER_CACHE_DIR = withr::local_tempdir())
  local_mocked_bindings(
    pid_alive = function(pid) pid == 99999L,
    .package = "webterminal"
  )
  webterminal:::register_daemon(pid = 99999L, port = 55555L, backend = "ttyd")
  d <- webterminal:::find_daemon(55555L)
  expect_equal(d$pid, 99999L)
  expect_equal(d$port, 55555L)
  expect_equal(d$backend, "ttyd")
})

test_that("unregister_daemon removes entry", {
  withr::local_envvar(R_USER_CACHE_DIR = withr::local_tempdir())
  local_mocked_bindings(
    pid_alive = function(pid) TRUE,
    .package = "webterminal"
  )
  webterminal:::register_daemon(pid = 99998L, port = 55554L, backend = "ttyd")
  webterminal:::unregister_daemon(55554L)
  d <- webterminal:::find_daemon(55554L)
  expect_null(d)
})

test_that("prune_dead removes nonexistent PIDs", {
  daemons <- list(
    list(pid = 999999999L, port = 55550L, backend = "ttyd", started = Sys.time())
  )
  pruned <- webterminal:::prune_dead(daemons)
  expect_length(pruned, 0L)
})

test_that("pid_alive returns FALSE for nonexistent PID", {
  expect_false(webterminal:::pid_alive(999999999L))
})

test_that("find_pid_on_port returns NA when ss not available", {
  local_mocked_bindings(
    find_ss = function() NULL,
    .package = "webterminal"
  )
  pid <- webterminal:::find_pid_on_port(55555L)
  expect_true(is.na(pid))
})
