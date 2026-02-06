#!/usr/bin/env Rscript
# Multi-source card image scraper for Kayou Transformers
#
# Searches and downloads card images from publicly accessible sources:
#   - eBay search results (listing images)
#   - Trading Card Archives individual card pages
#   - Baidu Image search (Chinese web aggregation)
#
# Usage:
#   Rscript scripts/scrape_card_images.R
#   Rscript scripts/scrape_card_images.R TFKB01        # specific set only
#   Rscript scripts/scrape_card_images.R TFKB01 ebay   # specific set + source
#
# Requirements:
#   install.packages(c("rvest", "httr2", "jsonlite"))

library(rvest)
library(httr2)
library(jsonlite)

# --- Configuration ---
# Resolve repo root: works from Rscript CLI and source() in RStudio
repo_root <- tryCatch(
  normalizePath(file.path(dirname(sys.frame(1)$ofile), "..")),
  error = function(e) {
    # Fallback: use commandArgs to find script path
    args <- commandArgs(trailingOnly = FALSE)
    file_arg <- grep("^--file=", args, value = TRUE)
    if (length(file_arg) > 0) {
      normalizePath(file.path(dirname(sub("^--file=", "", file_arg)), ".."))
    } else {
      normalizePath(".")
    }
  }
)
user_agent <- "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36"

# Search terms per set, organized by source
search_config <- list(
  TFKB01 = list(
    ebay = c(
      "kayou transformers TFKB01",
      "kayou transformers series B ACG",
      "kayou transformers movie card SR",
      "kayou transformers drift crosshairs barricade card"
    ),
    baidu = c(
      "\u5361\u6e38 \u53d8\u5f62\u91d1\u521a TFKB01",
      "\u5361\u6e38 \u53d8\u5f62\u91d1\u521a \u585e\u4f2f\u5766 B\u7cfb\u5217 \u7535\u5f71\u5361",
      "\u5361\u6e38 \u53d8\u5f62\u91d1\u521a \u4e8c\u5f39 \u7535\u5f71 SR HR AR"
    )
  ),
  TF01 = list(
    ebay = c("kayou transformers TF01", "kayou transformers series 1"),
    baidu = c("\u5361\u6e38 \u53d8\u5f62\u91d1\u521a \u4e00\u5f39", "\u5361\u6e38 \u53d8\u5f62\u91d1\u521a TF01")
  ),
  TF02 = list(
    ebay = c("kayou transformers TF02", "kayou transformers series 2"),
    baidu = c("\u5361\u6e38 \u53d8\u5f62\u91d1\u521a \u4e8c\u5f39", "\u5361\u6e38 \u53d8\u5f62\u91d1\u521a TF02")
  ),
  TF03 = list(
    ebay = c("kayou transformers TF03", "kayou transformers series 3"),
    baidu = c("\u5361\u6e38 \u53d8\u5f62\u91d1\u521a \u4e09\u5f39", "\u5361\u6e38 \u53d8\u5f62\u91d1\u521a TF03")
  ),
  TFH01 = list(
    ebay = c("kayou transformers TFH01", "kayou transformers headmasters"),
    baidu = c("\u5361\u6e38 \u53d8\u5f62\u91d1\u521a \u5934\u9886\u6218\u58eb", "\u5361\u6e38 \u53d8\u5f62\u91d1\u521a TFH01")
  ),
  TFO01 = list(
    ebay = c("kayou transformers TFO01", "kayou transformers one"),
    baidu = c("\u5361\u6e38 \u53d8\u5f62\u91d1\u521a \u8d77\u6e90", "\u5361\u6e38 \u53d8\u5f62\u91d1\u521a TFO01")
  ),
  TF40Y = list(
    ebay = c("kayou transformers TF40Y", "kayou transformers 40th anniversary"),
    baidu = c("\u5361\u6e38 \u53d8\u5f62\u91d1\u521a 40\u5468\u5e74", "\u5361\u6e38 \u53d8\u5f62\u91d1\u521a TF40Y")
  ),
  TFEU01 = list(
    ebay = c("kayou transformers TFEU01", "kayou transformers energon universe"),
    baidu = c(
      "\u5361\u6e38 \u53d8\u5f62\u91d1\u521a \u80fd\u91cf\u4e34\u754c",
      "\u5361\u6e38 \u53d8\u5f62\u91d1\u521a TFEU01"
    )
  )
)

# Rate limits per source (seconds between requests)
rate_limits <- list(
  ebay = 2,
  tca = 2,
  baidu = 3
)

# --- Download log ---
init_log <- function() {
  data.frame(
    timestamp = character(),
    source = character(),
    set_code = character(),
    search_term = character(),
    image_url = character(),
    local_path = character(),
    success = logical(),
    stringsAsFactors = FALSE
  )
}

append_log <- function(log_df, source, set_code, search_term, image_url,
                       local_path, success) {
  rbind(log_df, data.frame(
    timestamp = format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
    source = source,
    set_code = set_code,
    search_term = search_term,
    image_url = image_url,
    local_path = local_path,
    success = success,
    stringsAsFactors = FALSE
  ))
}

# --- Shared helpers ---

#' Download an image to local storage
#'
#' @param image_url URL of the image
#' @param output_path Local file path to save
#' @param delay Seconds to wait after download
#' @return Logical; TRUE if download succeeded
download_image <- function(image_url, output_path, delay = 1) {
  if (file.exists(output_path)) {
    cat("  SKIP (exists):", basename(output_path), "\n")
    return(TRUE)
  }

  tryCatch({
    resp <- request(image_url) |>
      req_headers("User-Agent" = user_agent) |>
      req_timeout(30) |>
      req_perform()

    writeBin(resp_body_raw(resp), output_path)
    file_size_kb <- round(file.size(output_path) / 1024, 1)
    cat("  OK:", basename(output_path), paste0("(", file_size_kb, " KB)"), "\n")
    Sys.sleep(delay)
    TRUE
  }, error = function(e) {
    warning("  FAIL: ", basename(output_path), " - ", conditionMessage(e),
            call. = FALSE)
    FALSE
  })
}

#' Ensure output directory exists for a set
#'
#' @param set_code Set code like "TFKB01"
#' @return Path to the cards directory
ensure_cards_dir <- function(set_code) {
  cards_dir <- file.path(repo_root, set_code, "cards")
  if (!dir.exists(cards_dir)) {
    dir.create(cards_dir, recursive = TRUE)
  }
  cards_dir
}

#' Extract file extension from a URL, defaulting to jpg
#'
#' @param url Image URL
#' @return File extension string (without dot)
url_extension <- function(url) {
  # Strip query parameters before extracting extension
  clean_url <- sub("\\?.*$", "", url)
  ext <- tools::file_ext(clean_url)
  if (nchar(ext) == 0 || !ext %in% c("jpg", "jpeg", "png", "webp", "gif")) {
    ext <- "jpg"
  }
  ext
}

# ===========================================================================
# Source 1: eBay (two-step: search for IDs, then fetch listing pages)
# ===========================================================================

#' Extract listing IDs from eBay search results page
#'
#' eBay renders search results client-side, but embeds listing IDs
#' in the page source as JSON data. This extracts those IDs.
#'
#' @param query Search query string
#' @return Character vector of listing IDs
ebay_search_listing_ids <- function(query) {
  cat("  eBay search:", query, "\n")

  body <- tryCatch(
    {
      resp <- request("https://www.ebay.com/sch/i.html") |>
        req_url_query(`_nkw` = query, `_sacat` = "0",
                      LH_BIN = "1", `_ipg` = "48") |>
        req_headers("User-Agent" = user_agent) |>
        req_timeout(30) |>
        req_perform()
      resp_body_string(resp)
    },
    error = function(e) {
      warning("  Failed to fetch eBay search: ", conditionMessage(e),
              call. = FALSE)
      return(NULL)
    }
  )
  if (is.null(body)) return(character(0))

  # Extract listing IDs embedded in the page's JavaScript data
  id_matches <- regmatches(body,
    gregexpr('"listingId"\\s*:\\s*"(\\d+)"', body))[[1]]
  listing_ids <- unique(gsub("[^0-9]", "", id_matches))

  cat("    Found", length(listing_ids), "listing IDs\n")
  listing_ids
}

#' Fetch an individual eBay listing page and extract images
#'
#' Individual listing pages are server-rendered and contain real image URLs.
#'
#' @param listing_id eBay listing ID
#' @return Data frame with columns: listing_id, image_url, title
ebay_fetch_listing_images <- function(listing_id) {
  listing_url <- paste0("https://www.ebay.com/itm/", listing_id)

  body <- tryCatch(
    {
      resp <- request(listing_url) |>
        req_headers("User-Agent" = user_agent) |>
        req_timeout(30) |>
        req_perform()
      resp_body_string(resp)
    },
    error = function(e) {
      warning("  Failed to fetch listing ", listing_id, ": ",
              conditionMessage(e), call. = FALSE)
      return(NULL)
    }
  )
  if (is.null(body)) return(data.frame())

  page <- read_html(body)

  # Get title
  title <- html_text(
    html_node(page, "h1.x-item-title__mainTitle, h1[itemprop='name'], .x-item-title span"),
    trim = TRUE
  )
  if (is.na(title)) title <- ""

  # Get primary image via og:image meta tag (most reliable)
  og_image <- html_attr(html_node(page, "meta[property='og:image']"), "content")

  # Also extract all product images from page source
  all_imgs <- regmatches(body,
    gregexpr("https://i\\.ebayimg\\.com/images/g/[A-Za-z0-9~_-]+/s-l[0-9]+\\.(?:jpg|png|webp)",
             body, perl = TRUE))[[1]]
  all_imgs <- unique(all_imgs)

  # Upgrade all to large size (s-l1600)
  all_imgs <- sub("/s-l\\d+\\.", "/s-l1600.", all_imgs)
  all_imgs <- unique(all_imgs)

  # If og:image exists and not in list, add it first
  if (!is.na(og_image) && nchar(og_image) > 0) {
    og_large <- sub("/s-l\\d+\\.", "/s-l1600.", og_image)
    all_imgs <- unique(c(og_large, all_imgs))
  }

  if (length(all_imgs) == 0) return(data.frame())

  data.frame(
    listing_id = listing_id,
    image_url = all_imgs,
    title = title,
    stringsAsFactors = FALSE
  )
}

#' Run eBay scraping for a set
#'
#' Two-step approach: (1) search for listing IDs, (2) fetch each listing page.
#'
#' @param set_code Set code
#' @param search_terms Character vector of search queries
#' @param log_df Current download log
#' @return Updated download log
scrape_ebay_for_set <- function(set_code, search_terms, log_df) {
  cards_dir <- ensure_cards_dir(set_code)

  # Step 1: Collect all unique listing IDs across search terms
  all_listing_ids <- character()
  for (query in search_terms) {
    ids <- ebay_search_listing_ids(query)
    all_listing_ids <- unique(c(all_listing_ids, ids))
    Sys.sleep(rate_limits$ebay)
  }

  if (length(all_listing_ids) == 0) {
    cat("  No eBay listings found\n")
    return(log_df)
  }

  cat("  Total unique listings to fetch:", length(all_listing_ids), "\n")

  # Step 2: Fetch each listing page for images
  for (listing_id in all_listing_ids) {
    cat("  Listing:", listing_id, "")
    results <- ebay_fetch_listing_images(listing_id)

    if (nrow(results) == 0) {
      cat("(no images)\n")
      log_df <- append_log(log_df, "ebay", set_code, listing_id,
                           NA_character_, NA_character_, FALSE)
      Sys.sleep(rate_limits$ebay)
      next
    }

    cat("- ", results$title[1], " (", nrow(results), " images)\n", sep = "")

    for (i in seq_len(nrow(results))) {
      row <- results[i, ]
      ext <- url_extension(row$image_url)
      filename <- sprintf("ebay_%s_%02d.%s", listing_id, i, ext)
      output_path <- file.path(cards_dir, filename)
      relative_path <- file.path(set_code, "cards", filename)

      success <- download_image(row$image_url, output_path,
                                delay = rate_limits$ebay)

      log_df <- append_log(log_df, "ebay", set_code, listing_id,
                           row$image_url, relative_path, success)
    }

    Sys.sleep(rate_limits$ebay)
  }

  log_df
}

# ===========================================================================
# Source 2: Trading Card Archives (individual card pages)
# ===========================================================================

#' Scrape TCA category page to find individual card page URLs
#'
#' @param category_url URL of the TCA Kayou category page
#' @return Character vector of card page URLs
scrape_tca_card_pages <- function(category_url =
    "https://tradingcardarchives.com/product-category/transformers/kayou/") {
  cat("  Fetching TCA category:", category_url, "\n")

  page <- tryCatch(
    {
      resp <- request(category_url) |>
        req_headers("User-Agent" = user_agent) |>
        req_timeout(30) |>
        req_perform()
      read_html(resp_body_string(resp))
    },
    error = function(e) {
      warning("  Failed to fetch TCA category: ", conditionMessage(e),
              call. = FALSE)
      return(NULL)
    }
  )
  if (is.null(page)) return(character(0))

  # TCA product pages are linked from the category listing
  product_links <- page |>
    html_nodes("a.woocommerce-LoopProduct-link, .products a[href*='product']") |>
    html_attr("href")

  product_links <- unique(product_links)
  product_links <- product_links[grepl("kayou-transformers", product_links)]

  cat("  Found", length(product_links), "TCA card pages\n")

  # Check for pagination
  pagination_links <- page |>
    html_nodes(".woocommerce-pagination a.page-numbers, .pagination a") |>
    html_attr("href")
  next_pages <- unique(pagination_links[grepl("page/\\d+", pagination_links)])
  # Exclude "previous" links by keeping only pages > 1
  next_pages <- next_pages[!grepl("page/1/?$", next_pages)]

  for (next_url in next_pages) {
    cat("  Fetching TCA page:", next_url, "\n")
    Sys.sleep(rate_limits$tca)

    next_page <- tryCatch(
      {
        resp <- request(next_url) |>
          req_headers("User-Agent" = user_agent) |>
          req_timeout(30) |>
          req_perform()
        read_html(resp_body_string(resp))
      },
      error = function(e) {
        warning("  Failed to fetch TCA page: ", conditionMessage(e),
                call. = FALSE)
        return(NULL)
      }
    )
    if (is.null(next_page)) next

    more_links <- next_page |>
      html_nodes("a.woocommerce-LoopProduct-link, .products a[href*='product']") |>
      html_attr("href")
    more_links <- unique(more_links)
    more_links <- more_links[grepl("kayou-transformers", more_links)]
    product_links <- unique(c(product_links, more_links))
  }

  cat("  Total TCA card pages found:", length(product_links), "\n")
  product_links
}

#' Extract the set code from a TCA card page URL
#'
#' @param page_url TCA product page URL
#' @return Set code string or NA
tca_url_to_set_code <- function(page_url) {
  # URLs like /product/kayou-transformers-tf02-ssr-007/
  match <- regmatches(page_url,
                      regexpr("kayou-transformers-(tf[a-z0-9]+)-",
                              page_url, ignore.case = TRUE))
  if (length(match) == 0 || nchar(match) == 0) return(NA_character_)
  set_code <- sub("kayou-transformers-", "", match)
  set_code <- sub("-$", "", set_code)
  toupper(set_code)
}

#' Extract the card identifier from a TCA card page URL
#'
#' @param page_url TCA product page URL
#' @return Card identifier string (e.g., "ssr-007")
tca_url_to_card_id <- function(page_url) {
  # Extract everything after the set code
  slug <- sub(".*/product/kayou-transformers-[a-z0-9]+-", "", page_url)
  slug <- sub("/$", "", slug)
  slug
}

#' Scrape a single TCA card page for the high-res card image
#'
#' @param page_url TCA product page URL
#' @return Image URL or NA
scrape_tca_card_image <- function(page_url) {
  page <- tryCatch(
    {
      resp <- request(page_url) |>
        req_headers("User-Agent" = user_agent) |>
        req_timeout(30) |>
        req_perform()
      read_html(resp_body_string(resp))
    },
    error = function(e) {
      warning("  Failed to fetch TCA card page: ", conditionMessage(e),
              call. = FALSE)
      return(NA_character_)
    }
  )
  if (is.character(page)) return(page) # NA from error

  # TCA product pages show the card image in the product gallery
  image_url <- page |>
    html_node(".woocommerce-product-gallery__image img,
               .product-images img,
               .wp-post-image") |>
    html_attr("src")

  # Try data-large_image for full resolution
  large_image <- page |>
    html_node(".woocommerce-product-gallery__image") |>
    html_attr("data-thumb")

  full_image <- page |>
    html_node(".woocommerce-product-gallery__image a") |>
    html_attr("href")

  # Prefer the full-size link, then large image, then default
  if (!is.na(full_image) && nchar(full_image) > 0) {
    return(full_image)
  }
  if (!is.na(large_image) && nchar(large_image) > 0) {
    return(large_image)
  }
  if (!is.na(image_url) && nchar(image_url) > 0) {
    return(image_url)
  }

  NA_character_
}

#' Run TCA individual card page scraping
#'
#' @param target_sets Character vector of set codes to scrape (NULL for all)
#' @param log_df Current download log
#' @return Updated download log
scrape_tca_cards <- function(target_sets = NULL, log_df) {
  card_pages <- scrape_tca_card_pages()
  if (length(card_pages) == 0) return(log_df)

  for (page_url in card_pages) {
    set_code <- tca_url_to_set_code(page_url)
    if (is.na(set_code)) next

    # Filter to target sets if specified
    if (!is.null(target_sets) && !set_code %in% target_sets) next

    card_id <- tca_url_to_card_id(page_url)
    cards_dir <- ensure_cards_dir(set_code)

    cat("  TCA card:", set_code, card_id, "\n")

    image_url <- scrape_tca_card_image(page_url)
    if (is.na(image_url)) {
      log_df <- append_log(log_df, "tca", set_code, page_url,
                           NA_character_, NA_character_, FALSE)
      Sys.sleep(rate_limits$tca)
      next
    }

    ext <- url_extension(image_url)
    filename <- paste0("tca_", card_id, ".", ext)
    output_path <- file.path(cards_dir, filename)
    relative_path <- file.path(set_code, "cards", filename)

    success <- download_image(image_url, output_path, delay = rate_limits$tca)

    log_df <- append_log(log_df, "tca", set_code, page_url,
                         image_url, relative_path, success)
  }

  log_df
}

# ===========================================================================
# Source 3: Baidu Image Search
# ===========================================================================

#' Search Baidu Images and extract image URLs
#'
#' @param query Search query string (Chinese characters supported)
#' @param max_results Maximum number of results to return
#' @return Data frame with columns: image_url, thumb_url, title
scrape_baidu_images <- function(query, max_results = 30) {
  # Baidu Image search JSON API endpoint
  encoded_query <- utils::URLencode(query)
  search_url <- paste0(
    "https://image.baidu.com/search/acjson",
    "?tn=resultjson_com",
    "&word=", encoded_query,
    "&pn=0",
    "&rn=", max_results,
    "&ie=utf-8"
  )

  cat("  Baidu image search:", query, "\n")

  response <- tryCatch(
    {
      resp <- request(search_url) |>
        req_headers(
          "User-Agent" = user_agent,
          "Accept" = "application/json",
          "Referer" = "https://image.baidu.com/"
        ) |>
        req_timeout(30) |>
        req_perform()
      resp_body_string(resp)
    },
    error = function(e) {
      warning("  Failed Baidu image search: ", conditionMessage(e),
              call. = FALSE)
      return(NULL)
    }
  )
  if (is.null(response)) return(data.frame())

  # Parse JSON response
  parsed <- tryCatch(
    fromJSON(response, simplifyVector = FALSE),
    error = function(e) NULL
  )

  # Check for spider block
  if (!is.null(parsed) && !is.null(parsed$antiFlag)) {
    cat("    Baidu blocked request:", parsed$message, "\n")
    return(data.frame())
  }

  if (is.null(parsed)) return(data.frame())

  # Extract image data from results
  image_data <- parsed$data
  if (is.null(image_data) || length(image_data) == 0) {
    cat("    No results\n")
    return(data.frame())
  }

  results <- lapply(image_data, function(item) {
    # Baidu returns various URL fields
    image_url <- item$objURL %||% item$middleURL %||% item$thumbURL
    thumb_url <- item$thumbURL %||% NA_character_
    title <- item$fromPageTitle %||% ""

    # objURL is often encoded, decode it
    if (!is.null(image_url) && nchar(image_url) > 0) {
      image_url <- tryCatch(
        baidu_decode_url(image_url),
        error = function(e) image_url
      )
    }

    if (is.null(image_url) || nchar(image_url) == 0) {
      return(NULL)
    }

    data.frame(
      image_url = image_url,
      thumb_url = thumb_url,
      title = title,
      stringsAsFactors = FALSE
    )
  })

  results <- results[!vapply(results, is.null, logical(1))]
  if (length(results) == 0) return(data.frame())

  results_df <- do.call(rbind, results)
  # Remove HTML tags from titles
  results_df$title <- gsub("<[^>]+>", "", results_df$title)

  cat("    Found", nrow(results_df), "images\n")
  results_df
}

#' Decode Baidu's obfuscated image URLs
#'
#' Baidu encodes objURL with a simple character substitution cipher.
#' @param encoded_url The obfuscated URL string
#' @return Decoded URL string
baidu_decode_url <- function(encoded_url) {
  # Baidu uses a character substitution table
  cipher_from <- "0123456789abcdefghijklmnopqrstuvwxyz"
  cipher_to   <- "e]gdvbknstuxociarpmhyfwlj.qz[2+9/3"

  chars <- strsplit(encoded_url, "")[[1]]
  decoded <- vapply(chars, function(ch) {
    pos <- regexpr(ch, cipher_from, fixed = TRUE)
    if (pos > 0) {
      substr(cipher_to, pos, pos)
    } else {
      pos2 <- regexpr(ch, cipher_to, fixed = TRUE)
      if (pos2 > 0) {
        substr(cipher_from, pos2, pos2)
      } else {
        ch
      }
    }
  }, character(1), USE.NAMES = FALSE)

  paste0(decoded, collapse = "")
}

#' Run Baidu image scraping for a set
#'
#' @param set_code Set code
#' @param search_terms Character vector of search queries
#' @param log_df Current download log
#' @return Updated download log
scrape_baidu_for_set <- function(set_code, search_terms, log_df) {
  cards_dir <- ensure_cards_dir(set_code)
  seen_urls <- character()
  image_counter <- 0

  for (query in search_terms) {
    results <- scrape_baidu_images(query)
    if (nrow(results) == 0) next

    for (i in seq_len(nrow(results))) {
      row <- results[i, ]

      # Skip duplicates across search terms
      if (row$image_url %in% seen_urls) next
      seen_urls <- c(seen_urls, row$image_url)

      image_counter <- image_counter + 1
      ext <- url_extension(row$image_url)
      filename <- sprintf("baidu_%03d.%s", image_counter, ext)
      output_path <- file.path(cards_dir, filename)
      relative_path <- file.path(set_code, "cards", filename)

      success <- download_image(row$image_url, output_path,
                                delay = rate_limits$baidu)

      log_df <- append_log(log_df, "baidu", set_code, query,
                           row$image_url, relative_path, success)
    }

    Sys.sleep(rate_limits$baidu)
  }

  log_df
}

# ===========================================================================
# Main
# ===========================================================================

# Parse command line arguments
cli_args <- commandArgs(trailingOnly = TRUE)
target_set <- if (length(cli_args) >= 1) toupper(cli_args[1]) else NULL
target_source <- if (length(cli_args) >= 2) tolower(cli_args[2]) else NULL

# Validate arguments
valid_sources <- c("ebay", "tca", "baidu")
if (!is.null(target_source) && !target_source %in% valid_sources) {
  stop("Unknown source '", target_source, "'. Valid sources: ",
       paste(valid_sources, collapse = ", "))
}

if (!is.null(target_set) && !target_set %in% names(search_config)) {
  stop("Unknown set '", target_set, "'. Valid sets: ",
       paste(names(search_config), collapse = ", "))
}

cat("=== Kayou Transformers Multi-Source Card Image Scraper ===\n\n")
cat("Repository root:", repo_root, "\n")
if (!is.null(target_set)) cat("Target set:", target_set, "\n")
if (!is.null(target_source)) cat("Target source:", target_source, "\n")
cat("\n")

log_df <- init_log()

# Determine which sets to process
sets_to_process <- if (!is.null(target_set)) target_set else names(search_config)

# --- eBay ---
if (is.null(target_source) || target_source == "ebay") {
  cat("\n========== Source: eBay ==========\n")
  for (set_code in sets_to_process) {
    terms <- search_config[[set_code]]$ebay
    if (is.null(terms) || length(terms) == 0) next
    cat("\n--- eBay:", set_code, "---\n")
    log_df <- scrape_ebay_for_set(set_code, terms, log_df)
  }
}

# --- TCA individual cards ---
if (is.null(target_source) || target_source == "tca") {
  cat("\n========== Source: Trading Card Archives ==========\n")
  log_df <- scrape_tca_cards(target_sets = sets_to_process, log_df)
}

# --- Baidu Images ---
if (is.null(target_source) || target_source == "baidu") {
  cat("\n========== Source: Baidu Images ==========\n")
  for (set_code in sets_to_process) {
    terms <- search_config[[set_code]]$baidu
    if (is.null(terms) || length(terms) == 0) next
    cat("\n--- Baidu:", set_code, "---\n")
    log_df <- scrape_baidu_for_set(set_code, terms, log_df)
  }
}

# --- Summary ---
cat("\n\n=== Scrape Summary ===\n")
cat("Total images processed:", nrow(log_df), "\n")
if (nrow(log_df) > 0) {
  cat("Successful:", sum(log_df$success, na.rm = TRUE), "\n")
  cat("Failed:", sum(!log_df$success, na.rm = TRUE), "\n")

  cat("\nBy source:\n")
  source_summary <- tapply(log_df$success, log_df$source, function(x) {
    paste0(sum(x), "/", length(x))
  })
  for (src in names(source_summary)) {
    cat("  ", src, ":", source_summary[src], "\n")
  }

  cat("\nBy set:\n")
  set_summary <- tapply(log_df$success, log_df$set_code, function(x) {
    paste0(sum(x), "/", length(x))
  })
  for (sc in names(set_summary)) {
    cat("  ", sc, ":", set_summary[sc], "\n")
  }
}

# Save log
log_path <- file.path(repo_root, "scripts", "scrape_log.csv")
write.csv(log_df, log_path, row.names = FALSE)
cat("\nLog written to:", log_path, "\n")
