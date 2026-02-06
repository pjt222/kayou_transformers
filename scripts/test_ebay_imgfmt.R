#!/usr/bin/env Rscript
# Check eBay image URL format
library(httr2)

ua <- "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36"

resp <- request("https://www.ebay.com/sch/i.html") |>
  req_url_query(`_nkw` = "kayou transformers card", `_sacat` = "0",
                LH_BIN = "1", `_ipg` = "48") |>
  req_headers(`User-Agent` = ua) |>
  req_timeout(30) |>
  req_perform()

body <- resp_body_string(resp)

# All eBay image URLs
image_urls <- unique(regmatches(body,
  gregexpr("https://i\\.ebayimg\\.com/[^\"'\\s>]+", body))[[1]])

cat("Total eBay image URLs:", length(image_urls), "\n\n")

# Show all of them
for (img in image_urls) {
  cat("  ", img, "\n")
}
