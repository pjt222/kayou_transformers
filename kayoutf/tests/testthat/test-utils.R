# --- ID generation functions ---

test_that("make_card_id formats correctly", {
  expect_equal(make_card_id("TFEU01", "SSR", 1), "TFEU01-SSR-001")
  expect_equal(make_card_id("TF01", "R", 36), "TF01-R-036")
  expect_equal(make_card_id("TF40Y", "XR", 100), "TF40Y-XR-100")
})

test_that("make_card_id zero-pads to 3 digits", {
  expect_equal(make_card_id("TF01", "BP", 1), "TF01-BP-001")
  expect_equal(make_card_id("TF01", "BP", 10), "TF01-BP-010")
  expect_equal(make_card_id("TF01", "BP", 999), "TF01-BP-999")
})

test_that("make_card_id coerces character number", {
  expect_equal(make_card_id("TF01", "SR", "5"), "TF01-SR-005")
})

test_that("make_rarity_id formats correctly", {
  expect_equal(make_rarity_id("TFEU01", "SSR"), "TFEU01-SSR")
  expect_equal(make_rarity_id("TF01", "BP"), "TF01-BP")
})

test_that("make_product_id formats correctly", {
  expect_equal(make_product_id("TFEU01", "super"), "TFEU01-super")
  expect_equal(make_product_id("TFEU01", "elite"), "TFEU01-elite")
})

# --- find_repo_root ---

test_that("find_repo_root returns a path or NULL", {
  result <- find_repo_root()
  # We're running inside the package, so either we find the root or we don't

  if (!is.null(result)) {
    expect_true(is.character(result))
    expect_true(dir.exists(result))
    expect_true(dir.exists(file.path(result, ".git")))
  } else {
    expect_null(result)
  }
})

# --- load_classification_data ---

test_that("load_classification_data returns NULL for missing CSV", {
  temp_dir <- tempdir()
  result <- load_classification_data(temp_dir)
  expect_null(result)
})

test_that("load_classification_data returns NULL with warning for invalid CSV", {
  temp_dir <- tempfile()
  dir.create(file.path(temp_dir, "scripts"), recursive = TRUE)
  csv_path <- file.path(temp_dir, "scripts", "classification_results.csv")
  write.csv(
    data.frame(bad_col = "x", stringsAsFactors = FALSE),
    csv_path, row.names = FALSE
  )
  expect_warning(
    result <- load_classification_data(temp_dir),
    "missing columns"
  )
  expect_null(result)
  unlink(temp_dir, recursive = TRUE)
})

test_that("load_classification_data reads CSV and builds image_relative", {
  temp_dir <- tempfile()
  dir.create(file.path(temp_dir, "scripts"), recursive = TRUE)
  csv_path <- file.path(temp_dir, "scripts", "classification_results.csv")
  write.csv(
    data.frame(
      filename = c("card1.jpg", "card2.jpg"),
      current_directory = c("TF01", "TF02"),
      set_code = c("TF01", "TF02"),
      stringsAsFactors = FALSE
    ),
    csv_path, row.names = FALSE
  )
  result <- load_classification_data(temp_dir)
  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 2)
  expect_true("image_relative" %in% names(result))
  expect_equal(result$image_relative[1], file.path("TF01", "cards", "card1.jpg"))
  unlink(temp_dir, recursive = TRUE)
})

# --- load_feedback_data ---

test_that("load_feedback_data returns empty data.frame for missing CSV", {
  temp_dir <- tempdir()
  result <- load_feedback_data(temp_dir)
  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 0)
  expect_true(all(c("filename", "current_directory", "is_correct", "timestamp")
                   %in% names(result)))
})

test_that("load_feedback_data reads existing CSV", {
  temp_dir <- tempfile()
  dir.create(file.path(temp_dir, "scripts"), recursive = TRUE)
  csv_path <- file.path(temp_dir, "scripts", "classification_feedback.csv")
  write.csv(
    data.frame(
      filename = "card1.jpg",
      current_directory = "TF01",
      is_correct = TRUE,
      timestamp = "2025-01-01T12:00:00",
      stringsAsFactors = FALSE
    ),
    csv_path, row.names = FALSE
  )
  result <- load_feedback_data(temp_dir)
  expect_equal(nrow(result), 1)
  expect_equal(result$filename, "card1.jpg")
  expect_true(result$is_correct)
  unlink(temp_dir, recursive = TRUE)
})

# --- save_feedback ---

test_that("save_feedback creates file with header on first write", {
  temp_dir <- tempfile()
  dir.create(file.path(temp_dir, "scripts"), recursive = TRUE)
  save_feedback(temp_dir, "card1.jpg", "TF01", TRUE)
  csv_path <- file.path(temp_dir, "scripts", "classification_feedback.csv")
  expect_true(file.exists(csv_path))
  data <- utils::read.csv(csv_path, stringsAsFactors = FALSE)
  expect_equal(nrow(data), 1)
  expect_equal(data$filename, "card1.jpg")
  expect_true(data$is_correct)
  unlink(temp_dir, recursive = TRUE)
})

test_that("save_feedback appends rows without duplicating header", {
  temp_dir <- tempfile()
  dir.create(file.path(temp_dir, "scripts"), recursive = TRUE)
  save_feedback(temp_dir, "card1.jpg", "TF01", TRUE)
  save_feedback(temp_dir, "card2.jpg", "TF02", FALSE)
  csv_path <- file.path(temp_dir, "scripts", "classification_feedback.csv")
  data <- utils::read.csv(csv_path, stringsAsFactors = FALSE)
  expect_equal(nrow(data), 2)
  expect_equal(data$filename, c("card1.jpg", "card2.jpg"))
  expect_equal(data$is_correct, c(TRUE, FALSE))
  unlink(temp_dir, recursive = TRUE)
})

test_that("save_feedback returns invisible NULL", {
  temp_dir <- tempfile()
  dir.create(file.path(temp_dir, "scripts"), recursive = TRUE)
  result <- save_feedback(temp_dir, "card1.jpg", "TF01", TRUE)
  expect_null(result)
  unlink(temp_dir, recursive = TRUE)
})
