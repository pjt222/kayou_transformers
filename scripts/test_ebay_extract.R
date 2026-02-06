#!/usr/bin/env Rscript
# Extract eBay listing data from the large embedded script
library(httr2)
library(rvest)
library(jsonlite)

ua <- "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36"

resp <- request("https://www.ebay.com/sch/i.html") |>
  req_url_query(`_nkw` = "kayou transformers card", `_sacat` = "0",
                LH_BIN = "1", `_ipg` = "24") |>
  req_headers(`User-Agent` = ua) |>
  req_timeout(30) |>
  req_perform()

body <- resp_body_string(resp)
scripts <- html_text(html_nodes(read_html(body), "script"))

# Find the script with listingId
data_script <- scripts[grep("listingId", scripts)]
data_script <- data_script[nchar(data_script) > 10000]  # skip small ones

if (length(data_script) == 0) {
  cat("No large script with listingId found\n")
  quit(status = 1)
}

s <- data_script[1]
cat("Script length:", nchar(s), "\n")

# Look for patterns around listingId
# Extract a window around the first listingId occurrence
pos <- regexpr("listingId", s)
context_start <- max(1, pos - 200)
context_end <- min(nchar(s), pos + 300)
cat("Context around listingId:\n")
cat(substr(s, context_start, context_end), "\n\n")

# Search for "items" array or similar structures
# Look for patterns like "items":[{ or "listingSummaries"
patterns <- c('"items"\\s*:\\s*\\[', '"itemSummaries"\\s*:', '"listingId"\\s*:',
              '"image"\\s*:\\s*\\{', '"title"\\s*:\\s*"[Kk]ayou')
for (p in patterns) {
  matches <- gregexpr(p, s)[[1]]
  if (matches[1] > 0) {
    cat(sprintf("Pattern '%s': %d occurrences\n", p, length(matches)))
    # Show context of first match
    pos <- matches[1]
    cat("  First at pos", pos, ":", substr(s, pos, min(nchar(s), pos + 150)), "\n\n")
  }
}
