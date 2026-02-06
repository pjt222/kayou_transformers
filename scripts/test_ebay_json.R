#!/usr/bin/env Rscript
# Extract eBay listing data from embedded JSON
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

# eBay embeds search results as JSON in script tags
# Look for the srp-main-content data
# Common patterns: __NEXT_DATA__, window.__data, srp model

# Method 1: Search for itemSummaries or listing data in scripts
scripts <- html_text(html_nodes(read_html(body), "script"))
cat("Total scripts:", length(scripts), "\n")

# Search for patterns
for (pattern in c("itemImage", "listingId", "itemHref", "s-item")) {
  matches <- grep(pattern, scripts)
  cat(sprintf("  '%s' found in scripts: %s\n", pattern, paste(matches, collapse=", ")))
}

# Try to find the main data blob
data_scripts <- grep("itemImage|listingId", scripts, value = TRUE)
if (length(data_scripts) > 0) {
  cat("\nFound listing data in", length(data_scripts), "script(s)\n")
  # Extract JSON from first match
  for (i in seq_along(data_scripts)) {
    s <- data_scripts[i]
    cat(sprintf("\nScript %d length: %d\n", i, nchar(s)))
    cat("Preview:", substr(s, 1, 300), "\n")

    # Try to extract items array
    # eBay sometimes uses: "itemSummaries":[...]
    item_match <- regmatches(s, regexpr('"itemSummaries"\\s*:\\s*\\[', s))
    if (length(item_match) > 0) {
      cat("Found itemSummaries array!\n")
    }
  }
}

# Method 2: Look for data in srp-river section
# Sometimes eBay uses <li class="s-item" data-viewport>
# with all data in attributes
river <- html_nodes(read_html(body), "#srp-river-results, [data-view*='listing']")
cat("\nRiver sections:", length(river), "\n")

# Method 3: Look for JSON-LD structured data
ld_scripts <- html_text(html_nodes(read_html(body), "script[type='application/ld+json']"))
cat("JSON-LD scripts:", length(ld_scripts), "\n")
for (ld in ld_scripts) {
  parsed <- tryCatch(fromJSON(ld), error = function(e) NULL)
  if (!is.null(parsed)) {
    cat("  Type:", parsed$`@type`, "\n")
  }
}
