#!/usr/bin/env Rscript
# Debug eBay HTML structure
library(httr2)
library(rvest)

ua <- "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36"

resp <- request("https://www.ebay.com/sch/i.html") |>
  req_url_query(`_nkw` = "kayou transformers card", `_sacat` = "0",
                LH_BIN = "1", `_ipg` = "24") |>
  req_headers(`User-Agent` = ua) |>
  req_timeout(30) |>
  req_perform()

body <- resp_body_string(resp)
page <- read_html(body)

cat("Body length:", nchar(body), "\n")

# Check all s-item nodes
items <- html_nodes(page, ".s-item")
cat("s-item count:", length(items), "\n\n")

# Look at first few items in detail
for (i in seq_len(min(3, length(items)))) {
  item <- items[[i]]
  cat("--- Item", i, "---\n")
  title <- html_text(html_node(item, ".s-item__title"), trim = TRUE)
  cat("Title:", title, "\n")
  img <- html_node(item, ".s-item__image-wrapper img")
  if (!is.na(html_attr(img, "src"))) {
    cat("Img src:", html_attr(img, "src"), "\n")
  }
  if (!is.na(html_attr(img, "data-src"))) {
    cat("Img data-src:", html_attr(img, "data-src"), "\n")
  }
  link <- html_attr(html_node(item, ".s-item__link"), "href")
  cat("Link:", substr(link, 1, 100), "\n\n")
}

# Check for "no results" message
no_results <- html_text(html_node(page, ".srp-save-null-search__heading"), trim = TRUE)
if (!is.na(no_results)) {
  cat("No results message:", no_results, "\n")
}

# Count total results from page
results_count <- html_text(html_node(page, ".srp-controls__count-heading"), trim = TRUE)
if (!is.na(results_count)) {
  cat("Results count heading:", results_count, "\n")
}

# Check if results are in JSON-LD or script tags
scripts <- html_nodes(page, "script")
cat("\nScript tags:", length(scripts), "\n")

# Look for item data in JSON
json_scripts <- html_text(scripts[grepl("itemListElement|ListingResults", html_text(scripts))])
if (length(json_scripts) > 0) {
  cat("Found JSON with listing data in", length(json_scripts), "script tags\n")
  cat("First 500 chars:", substr(json_scripts[1], 1, 500), "\n")
}
