#!/usr/bin/env Rscript
# Download card images from Trading Card Archives
#
# Standalone script (not part of the kayoutf package).
# Fetches card images from accessible fan sites and saves them
# to the appropriate {SET}/cards/ directories.
#
# Usage:
#   Rscript scripts/download_card_images.R
#
# Requirements:
#   install.packages(c("rvest", "httr2"))

library(rvest)
library(httr2)

# --- Configuration ---
repo_root <- normalizePath(file.path(dirname(sys.frame(1)$ofile), ".."))
rate_limit_seconds <- 1

# Trading Card Archives review pages with card images
tca_pages <- list(
  list(
    set_code = "TF01",
    url = "https://tradingcardarchives.com/2023/05/25/kayou-transformers-cards/",
    source_id = "TF01-TCA-review"
  ),
  list(
    set_code = "TF01",
    url = "https://tradingcardarchives.com/2023/06/05/kayou-transformers-cards-part-2/",
    source_id = "TF01-TCA-part2"
  ),
  list(
    set_code = "TF02",
    url = "https://tradingcardarchives.com/2023/11/01/kayou-transformers-cards-series-2/",
    source_id = "TF02-TCA-review"
  ),
  list(
    set_code = "TF03",
    url = "https://tradingcardarchives.com/2024/05/09/kayou-transformers-cards-series-3/",
    source_id = "TF03-TCA-review"
  )
)

#' Extract card image URLs from a Trading Card Archives page
#'
#' @param page_url URL of the review page
#' @return Character vector of image URLs
extract_tca_images <- function(page_url) {
  cat("Fetching:", page_url, "\n")

  page <- tryCatch(
    read_html(page_url),
    error = function(e) {
      warning("Failed to fetch: ", page_url, "\n  ", conditionMessage(e))
      return(NULL)
    }
  )
  if (is.null(page)) return(character(0))

  images <- page |>
    html_nodes("article img, .entry-content img") |>
    html_attr("src")

  # Filter to likely card images (exclude icons, logos, etc.)
  card_images <- images[grepl("\\.(jpg|jpeg|png|webp)$", images, ignore.case = TRUE)]
  card_images <- card_images[!grepl("logo|icon|banner|header|avatar", card_images,
                                     ignore.case = TRUE)]

  cat("  Found", length(card_images), "candidate card images\n")
  card_images
}

#' Download an image to local storage with rate limiting
#'
#' @param image_url URL of the image
#' @param output_path Local file path to save
#' @param delay Seconds to wait after download
#' @return Logical; TRUE if download succeeded
download_image <- function(image_url, output_path, delay = rate_limit_seconds) {
  if (file.exists(output_path)) {
    cat("  SKIP (exists):", basename(output_path), "\n")
    return(TRUE)
  }

  result <- tryCatch({
    resp <- request(image_url) |>
      req_headers("User-Agent" = "kayoutf-image-collector/1.0 (R; trading card research)") |>
      req_timeout(30) |>
      req_perform()

    writeBin(resp_body_raw(resp), output_path)
    cat("  OK:", basename(output_path), "\n")
    Sys.sleep(delay)
    TRUE
  }, error = function(e) {
    warning("  FAIL: ", basename(output_path), " - ", conditionMessage(e))
    FALSE
  })

  result
}

# --- Main ---
cat("=== Kayou Transformers Card Image Downloader ===\n\n")
cat("Repository root:", repo_root, "\n\n")

download_log <- data.frame(
  source_id = character(),
  set_code = character(),
  image_url = character(),
  local_path = character(),
  success = logical(),
  stringsAsFactors = FALSE
)

for (page in tca_pages) {
  cat("\n--- Processing:", page$source_id, "---\n")

  output_dir <- file.path(repo_root, page$set_code, "cards")
  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE)
  }

  image_urls <- extract_tca_images(page$url)

  for (i in seq_along(image_urls)) {
    image_url <- image_urls[i]
    filename <- sprintf("%s_tca_%03d%s",
                        tolower(page$set_code), i,
                        tools::file_ext(image_url) |> paste0(".") |> sub("^\\.", ".", x = _))
    # Clean up file extension
    ext <- tools::file_ext(image_url)
    if (nchar(ext) == 0) ext <- "jpg"
    filename <- sprintf("%s_tca_%03d.%s", tolower(page$set_code), i, ext)

    output_path <- file.path(output_dir, filename)
    relative_path <- file.path(page$set_code, "cards", filename)

    success <- download_image(image_url, output_path)

    download_log <- rbind(download_log, data.frame(
      source_id = page$source_id,
      set_code = page$set_code,
      image_url = image_url,
      local_path = relative_path,
      success = success,
      stringsAsFactors = FALSE
    ))
  }
}

# --- Summary ---
cat("\n=== Download Summary ===\n")
cat("Total images processed:", nrow(download_log), "\n")
cat("Successful:", sum(download_log$success), "\n")
cat("Failed:", sum(!download_log$success), "\n")

# Save log
log_path <- file.path(repo_root, "scripts", "download_log.csv")
write.csv(download_log, log_path, row.names = FALSE)
cat("Log written to:", log_path, "\n")
