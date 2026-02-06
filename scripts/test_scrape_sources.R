#!/usr/bin/env Rscript
# Quick diagnostic: test each scrape source individually
library(httr2)
library(rvest)
library(jsonlite)

ua <- "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36"

cat("=== eBay search tests ===\n\n")

ebay_queries <- c(
  "kayou transformers card",
  "kayou transformers TFKB01",
  "kayou transformers movie card SR",
  "kayou transformers drift crosshairs barricade card"
)

for (query in ebay_queries) {
  tryCatch({
    resp <- request("https://www.ebay.com/sch/i.html") |>
      req_url_query(`_nkw` = query, `_sacat` = "0", LH_BIN = "1", `_ipg` = "24") |>
      req_headers(`User-Agent` = ua) |>
      req_timeout(30) |>
      req_perform()

    page <- read_html(resp_body_string(resp))
    items <- html_nodes(page, ".s-item")
    titles <- html_text(html_nodes(page, ".s-item__title"), trim = TRUE)
    titles <- titles[!grepl("^Shop on eBay$", titles)]
    cat(sprintf("  [%d results] %s\n", length(titles), query))
    if (length(titles) > 0) {
      cat(paste0("    - ", head(titles, 5), "\n"), sep = "")
    }
  }, error = function(e) {
    cat(sprintf("  [ERROR] %s: %s\n", query, conditionMessage(e)))
  })
  Sys.sleep(2)
}

cat("\n=== TCA category page test ===\n\n")

tryCatch({
  resp <- request("https://tradingcardarchives.com/product-category/transformers/kayou/") |>
    req_headers(`User-Agent` = ua) |>
    req_timeout(30) |>
    req_perform()

  page <- read_html(resp_body_string(resp))
  product_links <- page |>
    html_nodes("a.woocommerce-LoopProduct-link, .products a[href*='product']") |>
    html_attr("href")
  product_links <- unique(product_links[grepl("kayou-transformers", product_links)])

  cat("  Page 1 card pages:", length(product_links), "\n")
  cat(paste0("    - ", head(product_links, 5), "\n"), sep = "")
}, error = function(e) {
  cat("  ERROR:", conditionMessage(e), "\n")
})

cat("\n=== Baidu image search test ===\n\n")

baidu_queries <- c(
  "\u5361\u6e38 \u53d8\u5f62\u91d1\u521a",
  "\u5361\u6e38 \u53d8\u5f62\u91d1\u521a TFKB01",
  "\u5361\u6e38 \u53d8\u5f62\u91d1\u521a \u4e8c\u5f39 \u7535\u5f71 SR HR AR"
)

for (query in baidu_queries) {
  tryCatch({
    encoded_query <- utils::URLencode(query)
    search_url <- paste0(
      "https://image.baidu.com/search/acjson",
      "?tn=resultjson_com",
      "&word=", encoded_query,
      "&pn=0&rn=10&ie=utf-8"
    )
    resp <- request(search_url) |>
      req_headers(
        `User-Agent` = ua,
        Accept = "application/json",
        Referer = "https://image.baidu.com/"
      ) |>
      req_timeout(30) |>
      req_perform()

    body <- resp_body_string(resp)
    cat(sprintf("  [%d bytes] %s\n", nchar(body), query))

    parsed <- tryCatch(fromJSON(body, simplifyVector = FALSE), error = function(e) NULL)
    if (!is.null(parsed) && !is.null(parsed$data)) {
      n_items <- sum(vapply(parsed$data, function(x) !is.null(x$thumbURL), logical(1)))
      cat("    Items with thumbURL:", n_items, "\n")
    } else {
      cat("    No parseable data (may be HTML/captcha)\n")
      # Show first 200 chars
      cat("    Preview:", substr(body, 1, 200), "\n")
    }
  }, error = function(e) {
    cat(sprintf("  [ERROR] %s: %s\n", query, conditionMessage(e)))
  })
  Sys.sleep(3)
}

cat("\nDone.\n")
