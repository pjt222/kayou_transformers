# TF02 - Cybertron Collection Series 2 card data
# Source: TCDB, eBay listings
# Data completeness: Minimal - structure assumed identical to TF01
# Known characters: Venom (SR-019), Chopshop (SR-020), Fireflight (SSR-002), Mirage (HR-012)

source("data-raw/00_helpers.R")

set_code <- "TF02"

# --- BP: Box-Pull (6 cards) ---
bp_cards <- make_cards(set_code, "BP", 6, card_type = "augmented_reality")

# --- LR: Limited Rare (7 cards) ---
lr_cards <- make_cards(set_code, "LR", 7)

# --- AR: Augmented Reality (8 cards) ---
ar_cards <- make_cards(set_code, "AR", 8, card_type = "augmented_reality")

# --- UR: Ultra Rare (8 cards) ---
ur_cards <- make_cards(set_code, "UR", 8)

# --- SHR: Super Holographic Rare (3 cards) ---
shr_cards <- make_cards(set_code, "SHR", 3, card_type = "lenticular")

# --- SSR: Super Special Rare (16 cards) ---
# Confirmed: TF02-SSR-002 = Fireflight
ssr_chars <- c(NA_character_, "Fireflight", rep(NA_character_, 14))
ssr_factions <- c(NA_character_, "Autobot", rep(NA_character_, 14))
ssr_cards <- make_cards(set_code, "SSR", 16, character_name = ssr_chars, faction = ssr_factions)

# --- HR: Holographic Rare (20 cards) ---
# Confirmed: TF02-HR-012 = Mirage
hr_chars <- c(rep(NA_character_, 11), "Mirage", rep(NA_character_, 8))
hr_factions <- c(rep(NA_character_, 11), "Autobot", rep(NA_character_, 8))
hr_cards <- make_cards(set_code, "HR", 20, character_name = hr_chars, faction = hr_factions,
                       card_type = "lenticular")

# --- SR: Super Rare (20 cards) ---
# Confirmed: TF02-SR-019 = Venom, TF02-SR-020 = Chopshop
sr_chars <- c(rep(NA_character_, 18), "Venom", "Chopshop")
sr_factions <- c(rep(NA_character_, 18), "Decepticon", "Decepticon")
sr_cards <- make_cards(set_code, "SR", 20, character_name = sr_chars, faction = sr_factions)

# --- R: Rare / Base (36 cards) ---
r_cards <- make_cards(set_code, "R", 36)

tf02_cards <- dplyr::bind_rows(
  bp_cards, lr_cards, ar_cards, ur_cards, shr_cards,
  ssr_cards, hr_cards, sr_cards, r_cards
)
saveRDS(tf02_cards, "data-raw/sources/tf02_cards.rds")
