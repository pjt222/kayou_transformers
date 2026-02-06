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
#' Walks up from the current working directory looking for `CLAUDE.md` as a
#' marker file. Returns `NULL` if not found within 10 levels.
#'
#' @return Character path to repo root, or `NULL`.
#' @keywords internal
find_repo_root <- function() {
  dir <- getwd()
  for (i in seq_len(10)) {
    if (file.exists(file.path(dir, "CLAUDE.md"))) {
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

  # Build portable relative path: {current_directory}/cards/{filename}
  classification_data$image_relative <- file.path(
    classification_data$current_directory, "cards", classification_data$filename
  )

  classification_data
}
