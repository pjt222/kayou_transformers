# TFKB01 - Cybertron Collection Series B (parallel subset in TF02 boxes)
# Source: Physical card inspection for rarity denominators
# Data completeness: Minimal - only 3 rarities confirmed, likely incomplete
# Known characters: TFKB01-AR-005 = Megatron

library(tibble)

set_code <- "TFKB01"

make_cards <- function(rarity_code, card_count, characters = NA, factions = NA,
                       card_type = "character") {
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

# --- AR: Augmented Reality (8 cards) ---
# Confirmed from TFKB01-AR-005/008 = Megatron
ar_chars <- c(rep(NA_character_, 4), "Megatron", rep(NA_character_, 3))
ar_factions <- c(rep(NA_character_, 4), "Decepticon", rep(NA_character_, 3))
ar_cards <- make_cards("AR", 8, characters = ar_chars, factions = ar_factions,
                       card_type = "augmented_reality")

# --- HR: Holographic Rare (20 cards) ---
hr_cards <- make_cards("HR", 20, card_type = "lenticular")

# --- SR: Super Rare (20 cards) ---
sr_cards <- make_cards("SR", 20)

tfkb01_cards <- dplyr::bind_rows(ar_cards, hr_cards, sr_cards)
saveRDS(tfkb01_cards, "data-raw/sources/tfkb01_cards.rds")
