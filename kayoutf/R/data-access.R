#' Query cards from the database
#'
#' Returns a tibble of cards, optionally filtered by set, rarity, character,
#' or faction.
#'
#' @param set Character. Filter by set code (e.g. "TFEU01"). Default `NULL`
#'   returns all sets.
#' @param rarity Character. Filter by rarity code (e.g. "SSR"). Default `NULL`.
#' @param character Character. Filter by character name (partial match).
#'   Default `NULL`.
#' @param faction Character. Filter by faction (e.g. "Autobot", "Decepticon").
#'   Default `NULL`.
#'
#' @return A [tibble::tibble].
#' @export
#'
#' @examples
#' \dontrun{
#' kt_cards()
#' kt_cards(set = "TFEU01")
#' kt_cards(set = "TFEU01", rarity = "SSR")
#' kt_cards(faction = "Autobot")
#' }
kt_cards <- function(set = NULL, rarity = NULL, character = NULL,
                     faction = NULL) {
  con <- kt_connection()
  query <- "SELECT * FROM cards WHERE 1=1"
  params <- list()

  if (!is.null(set)) {
    query <- paste0(query, " AND set_code = ?")
    params <- c(params, list(set))
  }
  if (!is.null(rarity)) {
    query <- paste0(query, " AND rarity_code = ?")
    params <- c(params, list(rarity))
  }
  if (!is.null(character)) {
    query <- paste0(query, " AND character_name ILIKE ?")
    params <- c(params, list(paste0("%", character, "%")))
  }
  if (!is.null(faction)) {
    query <- paste0(query, " AND faction = ?")
    params <- c(params, list(faction))
  }

  query <- paste0(query, " ORDER BY set_code, rarity_code, card_number")

  result <- DBI::dbGetQuery(con, query, params = params)
  tibble::as_tibble(result)
}

#' List all card sets
#'
#' @return A [tibble::tibble] of set metadata.
#' @export
#'
#' @examples
#' \dontrun{
#' kt_sets()
#' }
kt_sets <- function() {
  con <- kt_connection()
  result <- DBI::dbGetQuery(con, "SELECT * FROM sets ORDER BY release_year, set_code")
  tibble::as_tibble(result)
}

#' List rarity tiers
#'
#' @param set Character. Filter by set code. Default `NULL` returns all.
#'
#' @return A [tibble::tibble] of rarity definitions.
#' @export
#'
#' @examples
#' \dontrun{
#' kt_rarities()
#' kt_rarities(set = "TFEU01")
#' }
kt_rarities <- function(set = NULL) {
  con <- kt_connection()
  if (is.null(set)) {
    result <- DBI::dbGetQuery(
      con,
      "SELECT * FROM rarities ORDER BY set_code, sort_order"
    )
  } else {
    result <- DBI::dbGetQuery(
      con,
      "SELECT * FROM rarities WHERE set_code = ? ORDER BY sort_order",
      params = list(set)
    )
  }

  tibble::as_tibble(result)
}

#' List characters
#'
#' @param faction Character. Filter by faction. Default `NULL` returns all.
#'
#' @return A [tibble::tibble] of character reference data.
#' @export
#'
#' @examples
#' \dontrun{
#' kt_characters()
#' kt_characters(faction = "Autobot")
#' }
kt_characters <- function(faction = NULL) {
  con <- kt_connection()
  if (is.null(faction)) {
    result <- DBI::dbGetQuery(
      con,
      "SELECT * FROM characters ORDER BY character_name"
    )
  } else {
    result <- DBI::dbGetQuery(
      con,
      "SELECT * FROM characters WHERE faction = ? ORDER BY character_name",
      params = list(faction)
    )
  }
  tibble::as_tibble(result)
}

#' List products (pack types)
#'
#' @param set Character. Filter by set code. Default `NULL` returns all.
#'
#' @return A [tibble::tibble] of product/pack metadata.
#' @export
#'
#' @examples
#' \dontrun{
#' kt_products()
#' kt_products(set = "TFEU01")
#' }
kt_products <- function(set = NULL) {
  con <- kt_connection()
  if (is.null(set)) {
    result <- DBI::dbGetQuery(
      con,
      "SELECT * FROM products ORDER BY set_code, product_id"
    )
  } else {
    result <- DBI::dbGetQuery(
      con,
      "SELECT * FROM products WHERE set_code = ? ORDER BY product_id",
      params = list(set)
    )
  }
  tibble::as_tibble(result)
}

#' List data sources and provenance
#'
#' Returns a tibble of source metadata tracking where card data originates,
#' optionally filtered by set code or source type.
#'
#' @param set Character. Filter by set code (e.g. "TFEU01"). Default `NULL`
#'   returns all sets.
#' @param type Character. Filter by source type (e.g. "booklet", "website").
#'   Default `NULL` returns all types.
#'
#' @return A [tibble::tibble] of source metadata.
#' @export
#'
#' @examples
#' \dontrun{
#' kt_sources()
#' kt_sources(set = "TFEU01")
#' kt_sources(type = "booklet")
#' }
kt_sources <- function(set = NULL, type = NULL) {
  con <- kt_connection()
  query <- "SELECT * FROM sources WHERE 1=1"
  params <- list()

  if (!is.null(set)) {
    query <- paste0(query, " AND set_code = ?")
    params <- c(params, list(set))
  }
  if (!is.null(type)) {
    query <- paste0(query, " AND source_type = ?")
    params <- c(params, list(type))
  }

  query <- paste0(query, " ORDER BY set_code, source_id")

  result <- DBI::dbGetQuery(con, query, params = params)
  tibble::as_tibble(result)
}

#' Get a lazy dbplyr table
#'
#' Returns a lazy `tbl` object for advanced queries using dplyr verbs.
#' Requires the `dplyr` and `dbplyr` packages.
#'
#' @param table_name Character. One of "cards", "sets", "products", "rarities",
#'   "characters", "sources".
#'
#' @return A lazy `tbl` object (requires `dplyr::collect()` to materialize).
#' @export
#'
#' @examples
#' \dontrun{
#' kt_tbl("cards") |>
#'   dplyr::filter(faction == "Autobot") |>
#'   dplyr::collect()
#' }
kt_tbl <- function(table_name) {
  valid_tables <- c("cards", "sets", "products", "rarities", "characters", "sources")
  if (!table_name %in% valid_tables) {
    stop(
      "Unknown table: ", table_name, ". ",
      "Valid tables: ", paste(valid_tables, collapse = ", "),
      call. = FALSE
    )
  }

  if (!requireNamespace("dplyr", quietly = TRUE)) {
    stop("Package 'dplyr' is required for kt_tbl(). Install it with install.packages('dplyr').", call. = FALSE)
  }

  con <- kt_connection()
  dplyr::tbl(con, table_name)
}

#' Browse the card database in a Shiny app
#'
#' Launches an interactive Shiny application for browsing and filtering
#' cards, sets, rarities, characters, and products. Requires the `shiny`,
#' `bslib`, `bsicons`, and `DT` packages.
#'
#' @param repo_root Optional path to the kayou_transformers repository root.
#'   When provided, the Gallery tab can display scraped card images. If `NULL`
#'   (the default), the app will attempt to auto-detect the repo root.
#' @param port Port number for the Shiny app. Defaults to 3838.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' kt_browse()
#' kt_browse(repo_root = "/path/to/kayou_transformers")
#' }
kt_browse <- function(repo_root = NULL, port = 3838) {
  if (!requireNamespace("shiny", quietly = TRUE)) {
    stop("Package 'shiny' is required for kt_browse(). ",
         "Install it with install.packages('shiny').", call. = FALSE)
  }
  old_opt <- getOption("kayoutf.repo_root")
  options(kayoutf.repo_root = repo_root)
  on.exit(options(kayoutf.repo_root = old_opt), add = TRUE)
  shiny::runApp(system.file("app", package = "kayoutf"), port = port)
}
