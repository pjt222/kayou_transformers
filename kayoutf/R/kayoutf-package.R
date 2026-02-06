#' @keywords internal
"_PACKAGE"

#' kayoutf: Kayou Transformers Trading Card Database
#'
#' A comprehensive, queryable database of all Kayou Transformers trading cards.
#' Data is stored as Parquet files and queried via DuckDB, with convenience
#' functions returning tibbles.
#'
#' @section Main functions:
#' \describe{
#'   \item{[kt_cards()]}{Query cards with optional filters}
#'   \item{[kt_sets()]}{List all card sets}
#'   \item{[kt_rarities()]}{List rarity tiers}
#'   \item{[kt_products()]}{List pack/product types}
#'   \item{[kt_characters()]}{List characters}
#'   \item{[kt_connection()]}{Get DuckDB connection for advanced queries}
#'   \item{[kt_tbl()]}{Get lazy dbplyr table for advanced queries}
#' }
#'
#' @name kayoutf-package
#' @aliases kayoutf
NULL
