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
