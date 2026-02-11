# TFKB01 - Cybertron Collection Series B (parallel subset in TF02 boxes)
# Source: Physical card inspection for rarity denominators
# Data completeness: Minimal - only 3 rarities confirmed, likely incomplete
# Known characters: TFKB01-AR-005 = Megatron

source("data-raw/00_helpers.R")

set_code <- "TFKB01"

# --- AR: Augmented Reality (8 cards) ---
# Confirmed from TFKB01-AR-005/008 = Megatron
ar_chars <- c(rep(NA_character_, 4), "Megatron", rep(NA_character_, 3))
ar_factions <- c(rep(NA_character_, 4), "Decepticon", rep(NA_character_, 3))
ar_cards <- make_cards(set_code, "AR", 8, character_name = ar_chars, faction = ar_factions,
                       card_type = "augmented_reality")

# --- HR: Holographic Rare (20 cards) ---
hr_cards <- make_cards(set_code, "HR", 20, card_type = "lenticular")

# --- SR: Super Rare (20 cards) ---
sr_cards <- make_cards(set_code, "SR", 20)

tfkb01_cards <- dplyr::bind_rows(ar_cards, hr_cards, sr_cards)
saveRDS(tfkb01_cards, "data-raw/sources/tfkb01_cards.rds")
