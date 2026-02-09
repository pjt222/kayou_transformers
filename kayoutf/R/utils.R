#' Generate a card ID
#'
#' @param set_code Set code (e.g. "TFEU01")
#' @param rarity_code Rarity code (e.g. "SSR")
#' @param number Card number (integer or character)
#'
#' @return Character string card ID (e.g. "TFEU01-SSR-001")
#' @keywords internal
make_card_id <- function(set_code, rarity_code, number) {
  paste0(set_code, "-", rarity_code, "-", sprintf("%03d", as.integer(number)))
}

#' Generate a rarity ID
#'
#' @param set_code Set code
#' @param rarity_code Rarity code
#'
#' @return Character string rarity ID
#' @keywords internal
make_rarity_id <- function(set_code, rarity_code) {
  paste0(set_code, "-", rarity_code)
}

#' Generate a product ID
#'
#' @param set_code Set code
#' @param product_suffix Product suffix (e.g. "super", "elite")
#'
#' @return Character string product ID
#' @keywords internal
make_product_id <- function(set_code, product_suffix) {
  paste0(set_code, "-", product_suffix)
}

#' Find the repository root directory
#'
#' Walks up from the current working directory looking for a `.git` directory
#' as a marker. Returns `NULL` if not found within 10 levels.
#'
#' @return Character path to repo root, or `NULL`.
#' @keywords internal
find_repo_root <- function() {
  dir <- getwd()
  for (i in seq_len(10)) {
    if (dir.exists(file.path(dir, ".git"))) {
      return(dir)
    }
    parent <- dirname(dir)
    if (parent == dir) break
    dir <- parent
  }
  NULL
}

#' Load classification results from the scraped images CSV
#'
#' Reads `scripts/classification_results.csv` from the repo root and builds
#' portable relative image paths from `current_directory` + `filename`.
#'
#' @param repo_root Character path to the repository root.
#' @return A data.frame with classification data and an `image_relative` column,
#'   or `NULL` if the CSV does not exist.
#' @keywords internal
load_classification_data <- function(repo_root) {
  csv_path <- file.path(repo_root, "scripts", "classification_results.csv")
  if (!file.exists(csv_path)) return(NULL)

  classification_data <- utils::read.csv(csv_path, stringsAsFactors = FALSE)

  # Validate expected columns
  required_cols <- c("filename", "current_directory")
  missing_cols <- setdiff(required_cols, names(classification_data))
  if (length(missing_cols) > 0) {
    warning("classification_results.csv missing columns: ",
            paste(missing_cols, collapse = ", "), ". Returning NULL.",
            call. = FALSE)
    return(NULL)
  }

  # Build portable relative path: {current_directory}/cards/{filename}
  classification_data$image_relative <- file.path(
    classification_data$current_directory, "cards", classification_data$filename
  )

  classification_data
}

#' Load human feedback data for classified card images
#'
#' Reads `scripts/classification_feedback.csv` from the repo root. Returns an
#' empty data.frame with the expected columns if the file does not exist yet.
#'
#' @param repo_root Character path to the repository root.
#' @return A data.frame with columns `filename`, `current_directory`,
#'   `is_correct`, and `timestamp`.
#' @keywords internal
load_feedback_data <- function(repo_root) {
  csv_path <- file.path(repo_root, "scripts", "classification_feedback.csv")
  if (!file.exists(csv_path)) {
    return(data.frame(
      filename = character(),
      current_directory = character(),
      is_correct = logical(),
      timestamp = character(),
      stringsAsFactors = FALSE
    ))
  }
  utils::read.csv(csv_path, stringsAsFactors = FALSE)
}

#' Save a single feedback row for a classified card image
#'
#' Appends one row to `scripts/classification_feedback.csv`. Creates the file
#' with a header row if it does not exist yet. Rows are append-only; the latest
#' row per image wins when there are duplicates.
#'
#' @param repo_root Character path to the repository root.
#' @param filename Image filename.
#' @param current_directory Set directory (e.g. `"TF01"`).
#' @param is_correct Logical, `TRUE` if the classification is correct.
#' @return Invisible `NULL`.
#' @keywords internal
save_feedback <- function(repo_root, filename, current_directory, is_correct) {
  csv_path <- file.path(repo_root, "scripts", "classification_feedback.csv")
  row <- data.frame(
    filename = filename,
    current_directory = current_directory,
    is_correct = is_correct,
    timestamp = format(Sys.time(), "%Y-%m-%dT%H:%M:%S"),
    stringsAsFactors = FALSE
  )
  write_header <- !file.exists(csv_path)
  utils::write.table(
    row, csv_path,
    sep = ",", row.names = FALSE,
    col.names = write_header,
    append = !write_header,
    quote = TRUE
  )
  invisible(NULL)
}

#' Scan image directories under a repo root
#'
#' Finds image files (jpg, jpeg, png, webp) in all `*/cards/` directories,
#' `reference_images/cards/`, and `manual_downloads/cards/`.
#'
#' @param repo_root Character path to the repository root.
#' @return A data.frame with columns `filename`, `directory`, and `full_path`.
#' @keywords internal
scan_image_directories <- function(repo_root) {
  if (!dir.exists(repo_root)) {
    return(data.frame(
      filename = character(), directory = character(),
      full_path = character(), stringsAsFactors = FALSE
    ))
  }

  image_extensions <- "\\.(jpg|jpeg|png|webp)$"
  results <- list()

  # Find all */cards/ directories at the top level
  top_dirs <- list.dirs(repo_root, recursive = FALSE, full.names = TRUE)
  cards_dirs <- file.path(top_dirs, "cards")
  cards_dirs <- cards_dirs[dir.exists(cards_dirs)]

  for (cards_dir in cards_dirs) {
    files <- list.files(cards_dir, pattern = image_extensions,
                        ignore.case = TRUE, full.names = FALSE)
    if (length(files) > 0) {
      parent_name <- basename(dirname(cards_dir))
      results[[length(results) + 1]] <- data.frame(
        filename = files,
        directory = parent_name,
        full_path = file.path(cards_dir, files),
        stringsAsFactors = FALSE
      )
    }
  }

  if (length(results) == 0) {
    return(data.frame(
      filename = character(), directory = character(),
      full_path = character(), stringsAsFactors = FALSE
    ))
  }

  do.call(rbind, results)
}

#' Build gallery data from scanned images and classification CSV
#'
#' Merges scanned image files with classification results. Unmatched images
#' get `source = "unclassified"`; classification-matched images get
#' `source = "classified"`.
#'
#' @param repo_root Character path to the repository root.
#' @return A data.frame with all images and an `image_relative` column,
#'   or `NULL` if no images are found.
#' @keywords internal
build_gallery_data <- function(repo_root) {
  scanned <- scan_image_directories(repo_root)
  if (nrow(scanned) == 0) return(NULL)

  # Build image_relative for all scanned images
  scanned$image_relative <- file.path(scanned$directory, "cards",
                                       scanned$filename)

  classification <- load_classification_data(repo_root)

  if (!is.null(classification)) {
    # Match on filename + directory (current_directory in classification)
    scanned$match_key <- paste0(scanned$filename, "|", scanned$directory)
    classification$match_key <- paste0(classification$filename, "|",
                                        classification$current_directory)

    matched <- scanned$match_key %in% classification$match_key
    unmatched <- scanned[!matched, , drop = FALSE]

    # Add source column to classification data
    classification$source <- "classified"
    classification$directory <- classification$current_directory

    # Build unclassified rows with NA columns matching classification
    if (nrow(unmatched) > 0) {
      # Get classification columns we need to fill
      class_cols <- setdiff(names(classification),
                            c("filename", "directory", "image_relative",
                              "source", "match_key"))
      unmatched$source <- "unclassified"
      unmatched$current_directory <- unmatched$directory
      for (col in class_cols) {
        unmatched[[col]] <- NA
      }
    }

    # Combine: classification rows + unmatched scanned rows
    common_cols <- intersect(names(classification), names(unmatched))
    result <- rbind(
      classification[, common_cols, drop = FALSE],
      unmatched[, common_cols, drop = FALSE]
    )
    result$match_key <- NULL
    result$full_path <- NULL
  } else {
    # No classification data at all — everything is unclassified
    scanned$source <- "unclassified"
    scanned$current_directory <- scanned$directory
    scanned$is_card <- NA
    scanned$rarity_code <- NA
    scanned$character_name <- NA
    scanned$confidence <- NA
    result <- scanned
    result$full_path <- NULL
  }

  result
}

#' Load image tags from CSV
#'
#' Reads `scripts/image_tags.csv` from the repo root. Returns an empty
#' data.frame with the expected columns if the file does not exist.
#'
#' @param repo_root Character path to the repository root.
#' @return A data.frame with columns `filename`, `directory`, `tag`,
#'   and `timestamp`.
#' @keywords internal
load_tags <- function(repo_root) {
  csv_path <- file.path(repo_root, "scripts", "image_tags.csv")
  if (!file.exists(csv_path)) {
    return(data.frame(
      filename = character(), directory = character(),
      tag = character(), timestamp = character(),
      stringsAsFactors = FALSE
    ))
  }
  utils::read.csv(csv_path, stringsAsFactors = FALSE)
}

#' Save a tag for an image
#'
#' Appends one row to `scripts/image_tags.csv`. Creates the file with a
#' header row if it does not exist yet.
#'
#' @param repo_root Character path to the repository root.
#' @param filename Image filename.
#' @param directory Directory name (e.g. `"TF01"`).
#' @param tag Character string tag.
#' @return Invisible `NULL`.
#' @keywords internal
save_tag <- function(repo_root, filename, directory, tag) {
  csv_path <- file.path(repo_root, "scripts", "image_tags.csv")
  row <- data.frame(
    filename = filename,
    directory = directory,
    tag = tag,
    timestamp = format(Sys.time(), "%Y-%m-%dT%H:%M:%S"),
    stringsAsFactors = FALSE
  )
  write_header <- !file.exists(csv_path)
  utils::write.table(
    row, csv_path,
    sep = ",", row.names = FALSE,
    col.names = write_header,
    append = !write_header,
    quote = TRUE
  )
  invisible(NULL)
}

#' Remove a tag from an image
#'
#' Removes all rows matching the given filename, directory, and tag from
#' `scripts/image_tags.csv`. Rewrites the file without the matching rows.
#'
#' @param repo_root Character path to the repository root.
#' @param filename Image filename.
#' @param directory Directory name (e.g. `"TF01"`).
#' @param tag Character string tag to remove.
#' @return Invisible `NULL`.
#' @keywords internal
remove_tag <- function(repo_root, filename, directory, tag) {
  csv_path <- file.path(repo_root, "scripts", "image_tags.csv")
  if (!file.exists(csv_path)) return(invisible(NULL))

  data <- utils::read.csv(csv_path, stringsAsFactors = FALSE)
  keep <- !(data$filename == filename &
              data$directory == directory &
              data$tag == tag)
  data <- data[keep, , drop = FALSE]
  utils::write.csv(data, csv_path, row.names = FALSE, quote = TRUE)
  invisible(NULL)
}
