# --- scan_image_directories ---

test_that("scan_image_directories returns correct columns", {
  temp_dir <- tempfile()
  dir.create(file.path(temp_dir, "TF01", "cards"), recursive = TRUE)
  file.create(file.path(temp_dir, "TF01", "cards", "img1.jpg"))
  file.create(file.path(temp_dir, "TF01", "cards", "img2.png"))

  result <- scan_image_directories(temp_dir)
  expect_s3_class(result, "data.frame")
  expect_true(all(c("filename", "directory", "full_path") %in% names(result)))
  expect_equal(nrow(result), 2)
  expect_equal(sort(result$filename), c("img1.jpg", "img2.png"))
  expect_true(all(result$directory == "TF01"))
  unlink(temp_dir, recursive = TRUE)
})

test_that("scan_image_directories finds multiple directories", {
  temp_dir <- tempfile()
  dir.create(file.path(temp_dir, "TF01", "cards"), recursive = TRUE)
  dir.create(file.path(temp_dir, "TF02", "cards"), recursive = TRUE)
  dir.create(file.path(temp_dir, "reference_images", "cards"), recursive = TRUE)
  file.create(file.path(temp_dir, "TF01", "cards", "a.jpg"))
  file.create(file.path(temp_dir, "TF02", "cards", "b.jpeg"))
  file.create(file.path(temp_dir, "reference_images", "cards", "c.webp"))

  result <- scan_image_directories(temp_dir)
  expect_equal(nrow(result), 3)
  expect_equal(sort(result$directory),
               c("TF01", "TF02", "reference_images"))
  unlink(temp_dir, recursive = TRUE)
})

test_that("scan_image_directories ignores non-image files", {
  temp_dir <- tempfile()
  dir.create(file.path(temp_dir, "TF01", "cards"), recursive = TRUE)
  file.create(file.path(temp_dir, "TF01", "cards", "img.jpg"))
  file.create(file.path(temp_dir, "TF01", "cards", "readme.txt"))
  file.create(file.path(temp_dir, "TF01", "cards", "data.csv"))

  result <- scan_image_directories(temp_dir)
  expect_equal(nrow(result), 1)
  expect_equal(result$filename, "img.jpg")
  unlink(temp_dir, recursive = TRUE)
})

test_that("scan_image_directories returns empty for nonexistent dir", {
  result <- scan_image_directories("/nonexistent/path/12345")
  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 0)
})

test_that("scan_image_directories returns empty when no cards dirs exist", {
  temp_dir <- tempfile()
  dir.create(temp_dir)
  result <- scan_image_directories(temp_dir)
  expect_equal(nrow(result), 0)
  unlink(temp_dir, recursive = TRUE)
})

# --- build_gallery_data ---

test_that("build_gallery_data returns NULL when no images found", {
  temp_dir <- tempfile()
  dir.create(temp_dir)
  result <- build_gallery_data(temp_dir)
  expect_null(result)
  unlink(temp_dir, recursive = TRUE)
})

test_that("build_gallery_data marks unclassified images", {
  temp_dir <- tempfile()
  dir.create(file.path(temp_dir, "TF01", "cards"), recursive = TRUE)
  dir.create(file.path(temp_dir, "scripts"), recursive = TRUE)
  file.create(file.path(temp_dir, "TF01", "cards", "unclassified.jpg"))

  result <- build_gallery_data(temp_dir)
  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 1)
  expect_equal(result$source, "unclassified")
  expect_true("image_relative" %in% names(result))
  unlink(temp_dir, recursive = TRUE)
})

test_that("build_gallery_data merges classification data", {
  temp_dir <- tempfile()
  dir.create(file.path(temp_dir, "TF01", "cards"), recursive = TRUE)
  dir.create(file.path(temp_dir, "scripts"), recursive = TRUE)

  # Create images
  file.create(file.path(temp_dir, "TF01", "cards", "classified.jpg"))
  file.create(file.path(temp_dir, "TF01", "cards", "extra.jpg"))

  # Create classification CSV
  csv_data <- data.frame(
    filename = "classified.jpg",
    current_directory = "TF01",
    is_card = TRUE,
    rarity_code = "SR",
    character_name = "Optimus",
    confidence = "high",
    stringsAsFactors = FALSE
  )
  utils::write.csv(csv_data,
                    file.path(temp_dir, "scripts", "classification_results.csv"),
                    row.names = FALSE)

  result <- build_gallery_data(temp_dir)
  expect_equal(nrow(result), 2)

  classified_row <- result[result$filename == "classified.jpg", ]
  expect_equal(classified_row$source, "classified")

  extra_row <- result[result$filename == "extra.jpg", ]
  expect_equal(extra_row$source, "unclassified")
  expect_true(is.na(extra_row$is_card))
  unlink(temp_dir, recursive = TRUE)
})

# --- load_tags ---

test_that("load_tags returns empty data.frame when no file exists", {
  temp_dir <- tempdir()
  result <- load_tags(temp_dir)
  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 0)
  expect_true(all(c("filename", "directory", "tag", "timestamp")
                   %in% names(result)))
})

test_that("load_tags reads existing CSV", {
  temp_dir <- tempfile()
  dir.create(file.path(temp_dir, "scripts"), recursive = TRUE)
  csv_path <- file.path(temp_dir, "scripts", "image_tags.csv")
  utils::write.csv(
    data.frame(
      filename = "card1.jpg",
      directory = "TF01",
      tag = "favorite",
      timestamp = "2025-01-01T12:00:00",
      stringsAsFactors = FALSE
    ),
    csv_path, row.names = FALSE
  )
  result <- load_tags(temp_dir)
  expect_equal(nrow(result), 1)
  expect_equal(result$tag, "favorite")
  unlink(temp_dir, recursive = TRUE)
})

# --- save_tag ---

test_that("save_tag creates file with header on first write", {
  temp_dir <- tempfile()
  dir.create(file.path(temp_dir, "scripts"), recursive = TRUE)
  save_tag(temp_dir, "card1.jpg", "TF01", "favorite")
  csv_path <- file.path(temp_dir, "scripts", "image_tags.csv")
  expect_true(file.exists(csv_path))
  data <- utils::read.csv(csv_path, stringsAsFactors = FALSE)
  expect_equal(nrow(data), 1)
  expect_equal(data$filename, "card1.jpg")
  expect_equal(data$tag, "favorite")
  unlink(temp_dir, recursive = TRUE)
})

test_that("save_tag appends without duplicating header", {
  temp_dir <- tempfile()
  dir.create(file.path(temp_dir, "scripts"), recursive = TRUE)
  save_tag(temp_dir, "card1.jpg", "TF01", "favorite")
  save_tag(temp_dir, "card2.jpg", "TF02", "rare")
  csv_path <- file.path(temp_dir, "scripts", "image_tags.csv")
  data <- utils::read.csv(csv_path, stringsAsFactors = FALSE)
  expect_equal(nrow(data), 2)
  expect_equal(data$tag, c("favorite", "rare"))
  unlink(temp_dir, recursive = TRUE)
})

test_that("save_tag returns invisible NULL", {
  temp_dir <- tempfile()
  dir.create(file.path(temp_dir, "scripts"), recursive = TRUE)
  result <- save_tag(temp_dir, "card1.jpg", "TF01", "test")
  expect_null(result)
  unlink(temp_dir, recursive = TRUE)
})

# --- remove_tag ---

test_that("remove_tag removes matching rows", {
  temp_dir <- tempfile()
  dir.create(file.path(temp_dir, "scripts"), recursive = TRUE)
  save_tag(temp_dir, "card1.jpg", "TF01", "favorite")
  save_tag(temp_dir, "card1.jpg", "TF01", "rare")
  save_tag(temp_dir, "card2.jpg", "TF01", "favorite")

  remove_tag(temp_dir, "card1.jpg", "TF01", "favorite")
  data <- load_tags(temp_dir)
  expect_equal(nrow(data), 2)
  expect_false(any(data$filename == "card1.jpg" & data$tag == "favorite"))
  expect_true(any(data$filename == "card1.jpg" & data$tag == "rare"))
  expect_true(any(data$filename == "card2.jpg" & data$tag == "favorite"))
  unlink(temp_dir, recursive = TRUE)
})

test_that("remove_tag handles nonexistent file gracefully", {
  temp_dir <- tempdir()
  result <- remove_tag(temp_dir, "card1.jpg", "TF01", "test")
  expect_null(result)
})

test_that("remove_tag returns invisible NULL", {
  temp_dir <- tempfile()
  dir.create(file.path(temp_dir, "scripts"), recursive = TRUE)
  save_tag(temp_dir, "card1.jpg", "TF01", "test")
  result <- remove_tag(temp_dir, "card1.jpg", "TF01", "test")
  expect_null(result)
  unlink(temp_dir, recursive = TRUE)
})
