#!/usr/bin/env Rscript
# Extract eBay image URLs and titles using regex on embedded data
library(httr2)
library(rvest)

ua <- "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36"

resp <- request("https://www.ebay.com/sch/i.html") |>
  req_url_query(`_nkw` = "kayou transformers card", `_sacat` = "0",
                LH_BIN = "1", `_ipg` = "48") |>
  req_headers(`User-Agent` = ua) |>
  req_timeout(30) |>
  req_perform()

body <- resp_body_string(resp)

# Extract listing IDs
listing_ids <- unique(regmatches(body,
  gregexpr('"listingId"\\s*:\\s*"(\\d+)"', body))[[1]])
listing_ids <- gsub('"listingId"\\s*:\\s*"', "", listing_ids)
listing_ids <- gsub('"', "", listing_ids)
cat("Listing IDs found:", length(listing_ids), "\n")
cat(paste(listing_ids, collapse = ", "), "\n\n")

# Extract image URLs from the page (eBay uses i.ebayimg.com)
image_urls <- unique(regmatches(body,
  gregexpr("https://i\\.ebayimg\\.com/images/g/[^\"'\\s]+", body))[[1]])
cat("eBay image URLs found:", length(image_urls), "\n")

# Filter to likely product images (not icons/thumbnails)
product_images <- image_urls[grepl("s-l\\d+", image_urls)]
cat("Product images (s-l* pattern):", length(product_images), "\n")

# Show first few
if (length(product_images) > 0) {
  cat("\nFirst 10 images:\n")
  for (img in head(product_images, 10)) {
    cat("  ", img, "\n")
  }

  # Upgrade to larger size
  large_images <- sub("/s-l\\d+\\.", "/s-l800.", product_images)
  large_images <- unique(large_images)
  cat("\nUnique large images:", length(large_images), "\n")
}

# Also try to extract titles paired with images
# Look for "textSpans" or aria-label patterns near listing content
title_matches <- regmatches(body,
  gregexpr('"textSpans"\\s*:\\s*\\[\\{"text"\\s*:\\s*"[^"]{10,200}"', body))[[1]]
if (length(title_matches) > 0) {
  titles <- gsub('.*"text"\\s*:\\s*"', "", title_matches)
  titles <- gsub('"$', "", titles)
  titles <- unique(titles)
  titles <- titles[grepl("kayou|transformers|card", titles, ignore.case = TRUE)]
  cat("\nProduct titles found:", length(titles), "\n")
  for (t in head(titles, 10)) {
    cat("  ", t, "\n")
  }
}
