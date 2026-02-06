#!/usr/bin/env Rscript
# Test fetching an individual eBay listing page for images
library(httr2)
library(rvest)

ua <- "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36"

# First get listing IDs from search
resp <- request("https://www.ebay.com/sch/i.html") |>
  req_url_query(`_nkw` = "kayou transformers card", `_sacat` = "0",
                LH_BIN = "1", `_ipg` = "48") |>
  req_headers(`User-Agent` = ua) |>
  req_timeout(30) |>
  req_perform()

body <- resp_body_string(resp)
id_matches <- regmatches(body, gregexpr('"listingId"\\s*:\\s*"(\\d+)"', body))[[1]]
listing_ids <- unique(gsub('[^0-9]', "", id_matches))
cat("Found", length(listing_ids), "listing IDs from search\n")

# Fetch first listing page
if (length(listing_ids) > 0) {
  listing_id <- listing_ids[1]
  listing_url <- paste0("https://www.ebay.com/itm/", listing_id)
  cat("\nFetching listing:", listing_url, "\n")

  resp2 <- request(listing_url) |>
    req_headers(`User-Agent` = ua) |>
    req_timeout(30) |>
    req_perform()

  body2 <- resp_body_string(resp2)
  page <- read_html(body2)

  # Try standard selectors
  title <- html_text(html_node(page, "h1.x-item-title__mainTitle, h1[itemprop='name']"),
                     trim = TRUE)
  cat("Title:", title, "\n")

  # Get all product images
  all_imgs <- unique(regmatches(body2,
    gregexpr("https://i\\.ebayimg\\.com/images/g/[^\"'\\s>]+", body2))[[1]])
  cat("Image URLs found:", length(all_imgs), "\n")
  for (img in head(all_imgs, 10)) {
    cat("  ", img, "\n")
  }

  # Try to get the main product image via meta og:image
  og_image <- html_attr(html_node(page, "meta[property='og:image']"), "content")
  if (!is.na(og_image)) {
    cat("\nog:image:", og_image, "\n")
  }
}
