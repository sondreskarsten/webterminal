test_that("terminal_start returns existing daemon when already running", {
  local_mocked_bindings(
    port_listening = function(...) TRUE,
    find_daemon = function(...) list(pid = 42L, port = 4221L, backend = "ttyd"),
    .package = "webterminal"
  )
  d <- terminal_start("ttyd")
  expect_equal(d$pid, 42L)
})

test_that("terminal_start returns NULL when port occupied by non-webterminal process", {
  local_mocked_bindings(
    port_listening = function(...) TRUE,
    find_daemon = function(...) NULL,
    .package = "webterminal"
  )
  d <- terminal_start("ttyd")
  expect_null(d)
})

test_that("terminal_start calls spawn_daemon when port is free", {
  spawn_called <- FALSE
  local_mocked_bindings(
    port_listening = function(...) FALSE,
    spawn_daemon = function(backend, port) {
      spawn_called <<- TRUE
      list(pid = 123L, port = port, backend = backend, started = Sys.time())
    },
    .package = "webterminal"
  )
  d <- terminal_start("ttyd")
  expect_true(spawn_called)
  expect_equal(d$pid, 123L)
})

test_that("terminal_stop calls kill_daemon", {
  kill_called <- FALSE
  local_mocked_bindings(
    kill_daemon = function(...) { kill_called <<- TRUE; TRUE },
    .package = "webterminal"
  )
  result <- terminal_stop("ttyd")
  expect_true(kill_called)
  expect_true(result)
})

test_that("terminal_stop returns FALSE when no daemon found", {
  local_mocked_bindings(
    kill_daemon = function(...) FALSE,
    .package = "webterminal"
  )
  result <- terminal_stop("ttyd")
  expect_false(result)
})
