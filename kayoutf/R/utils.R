#' Generate a card ID
#'
#' @param set_code Set code (e.g. "TFEU01")
#' @param rarity_code Rarity code (e.g. "SSR")
#' @param number Card number (integer or character)
#'
#' @return Character string card ID (e.g. "TFEU01-SSR-001")
#' @keywords internal
make_card_id <- function(set_code, rarity_code, number) {
  paste0(set_code, "-", rarity_code, "-", sprintf("%03d", as.integer(number)))
}

#' Generate a rarity ID
#'
#' @param set_code Set code
#' @param rarity_code Rarity code
#'
#' @return Character string rarity ID
#' @keywords internal
make_rarity_id <- function(set_code, rarity_code) {
  paste0(set_code, "-", rarity_code)
}

#' Generate a product ID
#'
#' @param set_code Set code
#' @param product_suffix Product suffix (e.g. "super", "elite")
#'
#' @return Character string product ID
#' @keywords internal
make_product_id <- function(set_code, product_suffix) {
  paste0(set_code, "-", product_suffix)
}
