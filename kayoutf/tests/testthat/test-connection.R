test_that("kt_connection returns a DBI connection", {
  con <- kt_connection()
  expect_true(DBI::dbIsValid(con))
})

test_that("DuckDB tables are registered", {
  con <- kt_connection()
  tables <- DBI::dbListTables(con)
  expect_true("cards" %in% tables)
  expect_true("sets" %in% tables)
  expect_true("products" %in% tables)
  expect_true("rarities" %in% tables)
  expect_true("characters" %in% tables)
})

test_that("kt_connection returns same singleton", {
  con1 <- kt_connection()
  con2 <- kt_connection()
  expect_identical(con1, con2)
})

test_that("kt_connection recovers from stale connection", {
  # Get a valid connection
  con <- kt_connection()
  expect_true(DBI::dbIsValid(con))

  # Forcibly invalidate it behind the singleton's back
  DBI::dbDisconnect(con, shutdown = TRUE)
  expect_false(DBI::dbIsValid(.kt_env$con))

  # kt_connection should detect the stale connection and create a new one
  new_con <- kt_connection()
  expect_true(DBI::dbIsValid(new_con))
  expect_true("cards" %in% DBI::dbListTables(new_con))
})
