# Shared helper for creating card tibbles across all sets
# Sourced by each 03_cards_*.R script

library(tibble)

#' Create a card tibble for a rarity tier within a set
#'
#' @param set_code Character. The set code (e.g. "TFEU01").
#' @param rarity_code Character. The rarity code (e.g. "SSR").
#' @param card_count Integer. Number of cards in this rarity.
#' @param card_name_en Character vector or scalar NA. English card names.
#' @param card_name_zh Character vector or scalar NA. Chinese card names.
#' @param character_name Character vector or scalar NA. Character names.
#' @param faction Character vector or scalar NA. Faction affiliations.
#' @param card_type Character scalar or vector. Card type(s).
#' @param is_parallel Logical. Whether these are parallel variants.
#' @param product_exclusive Character vector or scalar NA. Product exclusivity.
#' @param print_run Integer vector or scalar NA. Print run limits.
#' @param notes Character vector or scalar NA. Errata or special notes.
#' @return A tibble with one row per card.
make_cards <- function(set_code, rarity_code, card_count,
                       card_name_en = NA, card_name_zh = NA,
                       character_name = NA, faction = NA,
                       card_type = "character", is_parallel = FALSE,
                       product_exclusive = NA, print_run = NA,
                       notes = NA) {
  # Validate vector lengths: must be scalar NA or match card_count
  check_len <- function(x, name) {
    if (!(length(x) == 1L && is.na(x[1L])) && length(x) != card_count) {
      stop(sprintf("%s-%s: '%s' has length %d, expected %d",
                   set_code, rarity_code, name, length(x), card_count),
           call. = FALSE)
    }
  }
  check_len(card_name_en, "card_name_en")
  check_len(card_name_zh, "card_name_zh")
  check_len(character_name, "character_name")
  check_len(faction, "faction")
  check_len(product_exclusive, "product_exclusive")
  check_len(print_run, "print_run")
  check_len(notes, "notes")

  expand <- function(x, na_type = NA_character_) {
    if (length(x) == card_count) x else rep(na_type, card_count)
  }

  tibble(
    card_id = paste0(set_code, "-", rarity_code, "-", sprintf("%03d", seq_len(card_count))),
    set_code = set_code,
    rarity_code = rarity_code,
    card_number = sprintf("%03d", seq_len(card_count)),
    card_name_en = expand(card_name_en),
    card_name_zh = expand(card_name_zh),
    character_name = expand(character_name),
    faction = expand(faction),
    card_type = card_type,
    is_parallel = is_parallel,
    product_exclusive = expand(product_exclusive),
    print_run = expand(print_run, NA_integer_),
    notes = expand(notes)
  )
}
