test_that(".kt_env exists and has emptyenv parent", {
  expect_true(environmentName(.kt_env) == "")
  expect_identical(parent.env(.kt_env), emptyenv())
})

test_that(".kt_env has expected fields after load", {
  expect_true("con" %in% ls(.kt_env, all.names = TRUE))
  expect_true("tables_registered" %in% ls(.kt_env, all.names = TRUE))
})

test_that("kt_disconnect handles NULL connection gracefully", {
  # Save current state
  saved_con <- .kt_env$con
  saved_reg <- .kt_env$tables_registered

  # Set to NULL and disconnect (should be a no-op)
  .kt_env$con <- NULL
  .kt_env$tables_registered <- FALSE
  expect_silent(kt_disconnect())
  expect_null(.kt_env$con)

  # Restore

  .kt_env$con <- saved_con
  .kt_env$tables_registered <- saved_reg
})

test_that("kt_disconnect closes active connection", {
  # Force a fresh connection
  con <- kt_connection()
  expect_true(DBI::dbIsValid(con))

  kt_disconnect()
  expect_null(.kt_env$con)
  expect_false(.kt_env$tables_registered)

  # Re-establish for other tests
  new_con <- kt_connection()
  expect_true(DBI::dbIsValid(new_con))
})
