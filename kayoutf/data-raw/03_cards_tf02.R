# TF02 - Cybertron Collection Series 2 card data
# Source: TCDB, eBay listings
# Data completeness: Minimal - structure assumed identical to TF01
# Known characters: Venom (SR-019), Chopshop (SR-020), Fireflight (SSR-002), Mirage (HR-012)

library(tibble)

set_code <- "TF02"

make_cards <- function(rarity_code, card_count, characters = NA, factions = NA,
                       card_type = "character") {
  check_len <- function(x, name) {
    if (!(length(x) == 1L && is.na(x[1L])) && length(x) != card_count) {
      stop(sprintf("%s-%s: '%s' has length %d, expected %d",
                   set_code, rarity_code, name, length(x), card_count),
           call. = FALSE)
    }
  }
  check_len(characters, "characters")
  check_len(factions, "factions")

  tibble(
    card_id = paste0(set_code, "-", rarity_code, "-", sprintf("%03d", seq_len(card_count))),
    set_code = set_code,
    rarity_code = rarity_code,
    card_number = sprintf("%03d", seq_len(card_count)),
    card_name_en = rep(NA_character_, card_count),
    card_name_zh = rep(NA_character_, card_count),
    character_name = if (length(characters) == card_count) characters else rep(NA_character_, card_count),
    faction = if (length(factions) == card_count) factions else rep(NA_character_, card_count),
    card_type = card_type,
    is_parallel = FALSE,
    parallel_of = NA_character_,
    product_exclusive = NA_character_,
    print_run = NA_integer_,
    image_url = NA_character_
  )
}

# --- BP: Box-Pull (6 cards) ---
bp_cards <- make_cards("BP", 6, card_type = "augmented_reality")

# --- LR: Limited Rare (7 cards) ---
lr_cards <- make_cards("LR", 7)

# --- AR: Augmented Reality (8 cards) ---
ar_cards <- make_cards("AR", 8, card_type = "augmented_reality")

# --- UR: Ultra Rare (8 cards) ---
ur_cards <- make_cards("UR", 8)

# --- SHR: Super Holographic Rare (3 cards) ---
shr_cards <- make_cards("SHR", 3, card_type = "lenticular")

# --- SSR: Super Special Rare (16 cards) ---
# Confirmed: TF02-SSR-002 = Fireflight
ssr_chars <- c(NA_character_, "Fireflight", rep(NA_character_, 14))
ssr_factions <- c(NA_character_, "Autobot", rep(NA_character_, 14))
ssr_cards <- make_cards("SSR", 16, characters = ssr_chars, factions = ssr_factions)

# --- HR: Holographic Rare (20 cards) ---
# Confirmed: TF02-HR-012 = Mirage
hr_chars <- c(rep(NA_character_, 11), "Mirage", rep(NA_character_, 8))
hr_factions <- c(rep(NA_character_, 11), "Autobot", rep(NA_character_, 8))
hr_cards <- make_cards("HR", 20, characters = hr_chars, factions = hr_factions,
                        card_type = "lenticular")

# --- SR: Super Rare (20 cards) ---
# Confirmed: TF02-SR-019 = Venom, TF02-SR-020 = Chopshop
sr_chars <- c(rep(NA_character_, 18), "Venom", "Chopshop")
sr_factions <- c(rep(NA_character_, 18), "Decepticon", "Decepticon")
sr_cards <- make_cards("SR", 20, characters = sr_chars, factions = sr_factions)

# --- R: Rare / Base (36 cards) ---
r_cards <- make_cards("R", 36)

tf02_cards <- dplyr::bind_rows(
  bp_cards, lr_cards, ar_cards, ur_cards, shr_cards,
  ssr_cards, hr_cards, sr_cards, r_cards
)
saveRDS(tf02_cards, "data-raw/sources/tf02_cards.rds")
