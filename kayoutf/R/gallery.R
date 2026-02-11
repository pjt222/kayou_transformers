#' Load classification results from the scraped images CSV
#'
#' Reads `scripts/classification_results.csv` from the repo root and builds
#' portable relative image paths from `current_directory` + `filename`.
#'
#' @param repo_root Character path to the repository root.
#' @return A data.frame with classification data and an `image_relative` column.
#'   Returns an empty data.frame if the CSV does not exist or is malformed.
#' @keywords internal
load_classification_data <- function(repo_root) {
  csv_path <- file.path(repo_root, "scripts", "classification_results.csv")
  if (!file.exists(csv_path)) {
    return(data.frame(
      filename = character(), current_directory = character(),
      image_relative = character(), stringsAsFactors = FALSE
    ))
  }

  classification_data <- utils::read.csv(csv_path, stringsAsFactors = FALSE)

  # Validate expected columns
  required_cols <- c("filename", "current_directory")
  missing_cols <- setdiff(required_cols, names(classification_data))
  if (length(missing_cols) > 0) {
    warning("classification_results.csv missing columns: ",
            paste(missing_cols, collapse = ", "), ". Returning empty data.frame.",
            call. = FALSE)
    return(data.frame(
      filename = character(), current_directory = character(),
      image_relative = character(), stringsAsFactors = FALSE
    ))
  }

  # Build portable relative path: {current_directory}/cards/{filename}
  classification_data$image_relative <- file.path(
    classification_data$current_directory, "cards", classification_data$filename
  )

  classification_data
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
#' @return A data.frame with all images and an `image_relative` column.
#'   Returns an empty data.frame if no images are found.
#' @keywords internal
build_gallery_data <- function(repo_root) {
  scanned <- scan_image_directories(repo_root)
  if (nrow(scanned) == 0) {
    return(data.frame(
      filename = character(), directory = character(),
      image_relative = character(), source = character(),
      stringsAsFactors = FALSE
    ))
  }

  # Build image_relative for all scanned images
  scanned$image_relative <- file.path(scanned$directory, "cards",
                                       scanned$filename)

  classification <- load_classification_data(repo_root)

  if (nrow(classification) > 0) {
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
