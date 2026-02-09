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
